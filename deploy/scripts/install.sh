#!/usr/bin/env bash

# Pipelines are considered failed if any of the constituent commands fail
set -o pipefail

usage()
{
    cat <<END
Usage: install --resource-name-prefix <resource name prefix> --environment-tag <environment tag> --location <Azure region> --resource-group-tag <resource group tag> [--overwrite] [--resource-group-name <resource group name>] [--node-env <node environment>]

Deploys the node-webapi sample to specified Azure region by performing the following steps:
  1. Create resource group for the application.
  2. Create Azure assets.
  3. Initialize and seed the database.
  4. Deploy the web site to the App Service instance.

Options:
  --overwrite
    Will delete the existing RG if it exists.
  --resource-group-name <resource group name>
    Use specified name for the resource group instead of default one.
  --node-env <node environment>
    Forces the use of specific node environment as the application runtime setting (default: development).

Example invocation: install --resource-name-prefix webapi --environment-tag dev --location westus2 --resource-group-tag 20210506a

Assumptions: 
  1. The environment has Docker, Azure CLI, and jq installed.
  2. The user is logged-in to Azure via Azure CLI, 
     and the desired Azure subscription is set.

Names of Azure resources often need to be globally unique. 
Use <resource name prefix> parameter to ensure that.
To avoid name validation issues use only lowercase letters and numbers 
for both parameter values.

The resource group name and tag has to both match for existing resource groups.
This is to ensure you're not unintentionally overwriting an existing resource group.
If the resource group name and tag matches, the existing resource group will be updated.
Use the --overwrite option to have the script delete an existing resource group,
and create a new one using the same name.
END
}

## Generates random password that meets Postgres Server password complexity criteria
get_postgres_pwd() {
    declare -a lcase=() ucase=() numbers=()
    for i in {a..z}; do
        lcase[$RANDOM]=$i
    done
    for i in {A..Z}; do
        ucase[$RANDOM]=$i
    done
    for i in {0..9}; do
        numbers[$RANDOM]=$i
    done

    declare output_chars="${lcase[*]::5}${ucase[*]::5}${numbers[*]::4}"
    randval=${output_chars//[[:space:]]/}
    randval=$(echo "$randval" | fold -w1 | shuf | tr -d '\n')
    echo ${randval}
}

# Check if we have Azure accounts
accounts=$(az account list --all --only-show-errors | jq length)
if [[ $accounts == 0 ]]; then
    echo "Please sign in to Azure, and re-run the script."
    exit 1
fi

overwrite=''
resource_name_prefix=''
environment_tag=''
region=''
rg_tag=''
node_env='development'
resource_group_name=''

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-name-prefix )
            resource_name_prefix="$2"; shift 2 ;;
        --environment-tag )
            environment_tag="$2"; shift 2 ;;
        --location )
            region="$2"; shift 2 ;;
        --resource-group-tag )
            rg_tag="$2"; shift 2 ;;
        --overwrite )
            overwrite='yes'; shift ;;
        --resource-group-name )
            resource_group_name="$2"; shift 2 ;;
        --node-env )
            node_env="$2"; shift 2 ;;
        -h | --help )
            usage; exit 2 ;;
        *)
            echo "Unknown option '${1}'"; echo ""; usage; exit 3 ;;
    esac
done

# Validate the required script arguments are available
if [[ ((! $resource_name_prefix) || (! $environment_tag)) || (! $region) || (! $rg_tag) ]]; then
    usage
    exit 3
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
workspace_dir="${script_dir}/../.."
webapi_src_dir="${workspace_dir}/services/webapi"

if [[ ! $resource_group_name ]]; then
    if [[ $GITHUB_REPOSITORY ]]; then
        # GITHUB_REPOSITORY includes owner name ('owner/repository'); we only want to use the repository name
        resource_group_name="rg-${GITHUB_REPOSITORY##*/}-${environment_tag}"
    else
        resource_group_name="rg-${resource_name_prefix}-${environment_tag}"
    fi
fi

# Create the resource group
## If overwrite option is used, delete and then create
if [[ ($overwrite) ]]; then
    echo "Deleting resource group '${resource_group_name}'..."
    az group delete --resource-group "$resource_group_name" --yes
    if [[ $? -ne 0 ]]; then
        echo "Resource group could not be deleted"
        exit 4
    fi
    echo "Creating resource group '${resource_group_name}'..."
    resource_group_id=$(az group create --resource-group "$resource_group_name" --location "$region" --tag "repo=$rg_tag" | jq -r '.id')
    if [[ $? -ne 0 ]]; then
        echo "Resource group '${resource_group_name}' could not be created"
        exit 5
    fi
else
    resource_group=$(az group show --resource-group "$resource_group_name" 2>/dev/null)
    if [[ (! $resource_group) ]]; then
        ## If the resource group does not exists, then create it
        echo "Creating resource group '${resource_group_name}'..."
        resource_group_id=$(az group create --resource-group "$resource_group_name" --location "$region" --tag "repo=$rg_tag" | jq -r '.id')
        if [[ $? -ne 0 ]]; then
            echo "Resource group '${resource_group_name}' could not be created"
            exit 5
        fi
    else
        ## If the resource does exists, but the tag "repo" doesn't match, exit as we don't assume ownership of the resource group
        resource_group_id=$(echo $resource_group | jq -r '.id')
        tag=$(echo $resource_group | jq -r '.tags.repo')
        if [[ ($tag != $rg_tag) ]]; then
            echo "Resource group '${resource_group_name}' already exists, but has a different 'repo' tag: '${tag}' vs '${rg_tag}'. Use a different <resource name prefix> or the --overwrite option."
            exit 6
        else
            echo "Resource group '${resource_group_name}' with tag '${rg_tag}' already exists, reusing."
        fi
    fi
fi


deployment_name="deploy-${resource_name_prefix}-${environment_tag}"

read -r -d '' request_common <<END
"type": "create-resource-name",
"namePrefix": "${resource_name_prefix}",
"environmentTag": "${environment_tag}",
"uniqueSuffixSource": "${resource_group_id}"
END
read -r -d '' batch_request <<END
{ "operations": [
    { ${request_common}, "resourceType": "Microsoft.Web/serverfarms" },
    { ${request_common}, "resourceType": "Microsoft.Web/sites" },
    { ${request_common}, "resourceType": "Microsoft.OperationalInsights/workspaces" },
    { ${request_common}, "resourceType": "Microsoft.Insights/components" },
    { ${request_common}, "resourceType": "Microsoft.DBForPostgreSQL/servers" },
    { ${request_common}, "resourceType": "Microsoft.DBForPostgreSQL/servers/databases" }
]}
END
batch_output=$(echo $batch_request | docker run -i --rm ghtools.azurecr.io/vp-cli:0.1.1-alpha ./vp batch)
if [[ $? -ne 0 ]]; then
    echo "Could not compute names for Azure resources"
    exit 7
fi
readarray -t resource_names <<< "$batch_output"
webApiHostingPlanName=${resource_names[0]}
webApiName=${resource_names[1]}
logAnalyticsName=${resource_names[2]}
appInsightsName=${resource_names[3]}
dbServerName=${resource_names[4]}
dbName=${resource_names[5]}

# Runs bicep deployment
echo "Running ARM deployment..."
az bicep install
postgres_password=$(get_postgres_pwd)
deployment_result=$(az deployment group create \
    --resource-group "$resource_group_name" \
    --name "$deployment_name" \
    --template-file "${workspace_dir}/deploy/infra/main.bicep" \
    --parameters location=${region} \
        postgresAdminPassword=${postgres_password} \
        webApiHostingPlanName=${webApiHostingPlanName} \
        webApiName=${webApiName} \
        logAnalyticsName=${logAnalyticsName} \
        appInsightsName=${appInsightsName} \
        dbServerName=${dbServerName} \
        dbName=${dbName} \
        webapiNodeEnv=${node_env})
if [[ $? -ne 0 ]]; then
    echo "Deployment failed"
    exit 7
fi

# Write the bicep deployment output to stdout
echo "Deployment output: " $deployment_result

web_api_id=$(echo "$deployment_result" | jq -r '.properties.outputs.webapiId.value')
postgres_host=$(echo "$deployment_result" | jq -r '.properties.outputs.postgresHost.value')
postgres_db=$(echo "$deployment_result" | jq -r '.properties.outputs.postgresDb.value')
postgres_user=$(echo "$deployment_result" | jq -r '.properties.outputs.postgresUser.value')

# Copies database connection information to env. vars for the database migration script
echo "Initializing the database..."
export PGDB=$postgres_db
export PGHOST=$postgres_host
export PGUSER="${postgres_user}@${postgres_host}"
export PGSSLMODE=require
export PGPASSWORD=$postgres_password

# Runs database migration and seeds the database
npm run migrate_db --prefix=${webapi_src_dir}
# Seeding uses the database migration framework (umzug), so this will only be applied once to any database
npm run seed_db --prefix=${webapi_src_dir}
if [[ $? -ne 0 ]]; then
    echo "Database migration failed"
    exit 8
fi

# Runs webapi deployment
echo "Deploying the website..."
az webapp deployment source config-zip \
    --ids "$web_api_id" \
    --src "${workspace_dir}/output/app/webapi.zip"
if [[ $? -ne 0 ]]; then
    echo "Website deployment failed"
    exit 9
fi

# Outputs the webapi url
host_name=$(az webapp show --ids "$web_api_id" | jq -r '.defaultHostName')
echo "Application deployed, the URL is https://${host_name}"
