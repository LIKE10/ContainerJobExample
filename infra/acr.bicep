targetScope = 'subscription'

@description('Azure region for the container registry resource group and registry')
param location string = deployment().location

@description('Base name used to derive all resource names')
param appName string

@description('Name of the resource group that will contain the Azure Container Registry')
param acrResourceGroup string = '${appName}acr-rg'

@description('Name of the Azure Container Registry')
param acrName string = '${appName}acr'

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Tags to apply to the resources')
param environmentTags object

// ── Resource Group ───────────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: acrResourceGroup
  location: location
  tags: environmentTags
}

// ── Azure Container Registry ────────────────────────────────────────────────
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    location: location
    acrName: acrName
    acrSku: acrSku
    tagValues: environmentTags
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output resourceGroupName string = rg.name
output acrId string = containerRegistry.outputs.acrId
output acrName string = containerRegistry.outputs.acrName
output acrLoginServer string = containerRegistry.outputs.acrLoginServer
