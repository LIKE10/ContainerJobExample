using './container-job.bicep'
extends './dev-defaults.bicepparam'

param jobName = 'containerjob-manualexample'
param containerName = 'manualexamplecontainerjob'

// These parameters are provided at deploy-time by the CI/CD pipeline
// or via az deployment group create --parameters.
//

param containerImage = 'containerjobtstacr.azurecr.io/manualexample:latest'
param containerRegistryServer = 'containerjobtstacr.azurecr.io'
param managedIdentityName = 'containerjobtst-id'

//param containerAppsEnvironmentId = $ContainerAppsEnvironmentId
//param appInsightsConnectionString = $AppInsightsConnectionString
param containerAppsEnvironmentId = '<REPLACE_WITH_CONTAINERAPPS_ENVIRONMENT_ID>'
param appInsightsConnectionString = '<REPLACE_WITH_APPINSIGHTS_CONNECTION_STRING>'
