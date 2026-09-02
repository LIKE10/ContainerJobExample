targetScope = 'subscription'

@description('Azure region for all resources')
param location string

@description('Base name used to derive all resource names')
param appName string

@description('Name of the existing Azure Container Registry')
param acrName string = '${appName}acr'

@description('Resource group that contains the existing Azure Container Registry')
param acrResourceGroup string  = '${appName}acr-rg'

@description('Tags to apply to the resources')
param environmentTags object

// ── Resource Group ───────────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${appName}-rg'
  location: location
}

resource acrRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: acrResourceGroup
}

// ── Resources ────────────────────────────────────────────────────────────────
module resources 'modules/prereqs-resources.bicep' = {
  name: 'prereqs-resources'
  scope: rg
  params: {
    appName: appName
    location: location
    tagValues: environmentTags
  }
}

// ── ACR Pull Role Assignment ─────────────────────────────────────────────────
module acrRoleAssignment 'modules/prereqs-acr-role.bicep' = {
  name: 'prereqs-acr-role'
  scope: acrRg
  params: {
    acrName: acrName
    managedIdentityPrincipalId: resources.outputs.managedIdentityPrincipalId
  }
}

// ── Outputs ──────────────────────────────────────────────────────────────────
output resourceGroupName string = rg.name
output managedIdentityResourceId string = resources.outputs.managedIdentityResourceId
output managedIdentityClientId string = resources.outputs.managedIdentityClientId
output appInsightsConnectionString string = resources.outputs.appInsightsConnectionString
output containerAppsEnvironmentName string = resources.outputs.containerAppsEnvironmentName
output logAnalyticsWorkspaceName string = resources.outputs.logAnalyticsWorkspaceName
