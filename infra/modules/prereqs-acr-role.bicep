@description('Name of the existing Azure Container Registry')
param acrName string

@description('Principal ID of the managed identity to grant acrPull')
param managedIdentityPrincipalId string

// Well-known role definition ID for AcrPull
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentityPrincipalId, acrPullRoleDefinitionId)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
