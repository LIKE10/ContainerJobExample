using './container-job.bicep'

param jobName = 'containerjobexample-job'
param containerName = 'mycontainerjob'

// These parameters are provided at deploy-time by the CI/CD pipeline
// or via az deployment group create --parameters.
//
// param containerImage = 'myacr.azurecr.io/myapp:latest'
// param containerRegistryServer = 'myacr.azurecr.io'
// param managedIdentityResourceId = '/subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/...'
// param containerAppsEnvironmentId = '/subscriptions/.../resourceGroups/.../providers/Microsoft.App/managedEnvironments/...'
// param appInsightsConnectionString = '...'
