$ErrorActionPreference = 'Stop'
$tag = "azd-$(Get-Date -Format 'yyyyMMddHHmmss')"

function Invoke-Az { & az @args; if ($LASTEXITCODE -ne 0) { throw "az $($args[0..2] -join ' ') failed" } }

Invoke-Az acr build --registry $env:AZURE_CONTAINER_REGISTRY_NAME --image "manualexample:$tag" src/ManualExample
Invoke-Az acr build --registry $env:AZURE_CONTAINER_REGISTRY_NAME --image "scheduledexample:$tag" src/ScheduledExample

Invoke-Az containerapp job update --name $env:AZURE_MANUAL_JOB_NAME --resource-group $env:AZURE_RESOURCE_GROUP `
  --image "$($env:AZURE_CONTAINER_REGISTRY_ENDPOINT)/manualexample:$tag" --output none
Invoke-Az containerapp job update --name $env:AZURE_SCHEDULED_JOB_NAME --resource-group $env:AZURE_RESOURCE_GROUP `
  --image "$($env:AZURE_CONTAINER_REGISTRY_ENDPOINT)/scheduledexample:$tag" --output none

Write-Host "Start the manual job: az containerapp job start --name $($env:AZURE_MANUAL_JOB_NAME) --resource-group $($env:AZURE_RESOURCE_GROUP)"
