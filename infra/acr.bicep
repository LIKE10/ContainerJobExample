targetScope = 'resourceGroup'

@description('Azure region for the container registry')
param location string = resourceGroup().location

@description('Name of the Azure Container Registry')
param acrName string

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

// ── Azure Container Registry ────────────────────────────────────────────────
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  params: {
    location: location
    acrName: acrName
    acrSku: acrSku
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output acrId string = containerRegistry.outputs.acrId
output acrName string = containerRegistry.outputs.acrName
output acrLoginServer string = containerRegistry.outputs.acrLoginServer
