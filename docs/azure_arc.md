# Deploying to Azure Arc

This template supports deployment to Azure Arc. The following document lists the requirements to setup Azure Arc to support the template, as well as how you deploy the application to an Arc-enable Kubernetes Cluster.

- [Deploying to Azure Arc](#deploying-to-azure-arc)
  - [Prerequisites](#prerequisites)
  - [Regions and resource group support](#regions-and-resource-group-support)
    - [Azure Arc enabled App Service](#azure-arc-enabled-app-service)

## Prerequisites

In order to deploy this template to Azure Arc, you need to have the Arc-enabled Kubernetes Cluster created. This template assumes this has already been done. To learn more about configuring an Arc environment for App Service, please see this [blog](https://aka.ms/ArcEnabledAppServices-Build2021-Blog).

It's also requred to have Arc-enabled dataservices Data Controller installed in the Arc Cluster, please see more [here](https://docs.microsoft.com/en-us/azure/azure-arc/data/create-data-controller). This repository assumes a directly connected data controller.

## Regions and resource group support

As some of the Arc features are still in preview, [please check here for latest information](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster) 

### Azure Arc enabled App Service and Data Services

Following these guidelines will deploy the webapi to an ARC-enabled Kubernetes cluster.

In order to deploy to an Custom Location with App and data services for Arc, you will need to collect the following information from those resource in Azure:

- Resource id id of the custom location: customLocationId
- Resource id id of the App Service Kubernetes Environment: kubeEnvironmentId
- Resource id of the Azure Arc data controller: dataControllerId

If any of these are provided, all need to be provided.

To deploy from local environment run the deployment script

```
./deploy/scripts/install.sh \
   --resource-name-prefix <resource group name> \
   --environment-tag <name tag for all resources> \
   --resource-group-tag <tag> \
   --location <location (eastus or westeurope)> \
   --node-env development \
   --kube-environment-id <kubeEnvironmentId> \
   --custom-location-id <customLocationId> \
   --data-controller-id <dataControlleId>
```

To deploy using the GitHub Actions Workflow, the following is needed in the [config.yaml](../deploy/config.yaml) file:

```
AZURE_LOCATION: "northeurope"       #Location of Azure hosted resources, e.g. Azure Monitor
RESOURCE_NAME_PREFIX: "nodewebapi"  #Resource name prefix
ENVIRONMENT_TAG: "test"             #Resource tag
WEBAPI_NODE_ENV: "development"      #nodeEnv parameter
KUBE_ENVIRONMENT_ID: ""             #kubeEnvironmentId to host the webapi on Arc
CUSTOM_LOCATION_ID: ""              #customLocationId for the kubeEnvironment
DATA_CONTROLLER_ID: ""              #dataControllerId
```
