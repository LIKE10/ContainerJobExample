targetScope = 'subscription'

@description('Azure region for the container registry resource group and registry')
param location string = deployment().location

@description('Name of the resource group that will contain the Azure Container Registry')
param acrResourceGroup string

@description('Name of the Azure Container Registry')
param acrName string

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

// ── Resource Group ───────────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: acrResourceGroup
  location: location
}

// ── Azure Container Registry ────────────────────────────────────────────────
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    location: location
    acrName: acrName
    acrSku: acrSku
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output resourceGroupName string = rg.name
output acrId string = containerRegistry.outputs.acrId
output acrName string = containerRegistry.outputs.acrName
output acrLoginServer string = containerRegistry.outputs.acrLoginServer
