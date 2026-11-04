#!/bin/sh
# Builds both images in ACR and points the jobs at them. Values come from azd env outputs.
set -eu

TAG="azd-$(date +%Y%m%d%H%M%S)"

az acr build --registry "$AZURE_CONTAINER_REGISTRY_NAME" --image "manualexample:$TAG" src/ManualExample
az acr build --registry "$AZURE_CONTAINER_REGISTRY_NAME" --image "scheduledexample:$TAG" src/ScheduledExample

az containerapp job update --name "$AZURE_MANUAL_JOB_NAME" --resource-group "$AZURE_RESOURCE_GROUP" \
  --image "$AZURE_CONTAINER_REGISTRY_ENDPOINT/manualexample:$TAG" >/dev/null
az containerapp job update --name "$AZURE_SCHEDULED_JOB_NAME" --resource-group "$AZURE_RESOURCE_GROUP" \
  --image "$AZURE_CONTAINER_REGISTRY_ENDPOINT/scheduledexample:$TAG" >/dev/null

echo "Start the manual job: az containerapp job start --name $AZURE_MANUAL_JOB_NAME --resource-group $AZURE_RESOURCE_GROUP"
