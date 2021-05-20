Write-Output "Running webapi pre-init script..."

$WORKSPACE_DIR="$PSScriptRoot/../.."

New-Item -ItemType "directory" -Path "$WORKSPACE_DIR/.local/secrets" -Force

$DOCKER_TAG="ghtools.azurecr.io/vp-cli:0.1.2-alpha"

docker run -i --mount "type=bind,src=$WORKSPACE_DIR,dst=/workspace" --rm $DOCKER_TAG ./vp batch --configuration /workspace/scripts/webapi/pre-init.json --context /workspace

Write-Output "Completed pre-init script."