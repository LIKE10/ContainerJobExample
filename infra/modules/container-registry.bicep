@description('Azure region for the container registry')
param location string

@description('Name of the Azure Container Registry')
param acrName string

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Tags to apply to the resources')
param tagValues object

// ── Azure Container Registry ────────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
  }
  tags: tagValues
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
