using './container-job.bicep'

param jobName = 'containerjobexample-job'
param containerName = 'mycontainerjob'

// These parameters are provided at deploy-time by the CI/CD pipeline
// or via az deployment group create --parameters.
//
param containerImage = 'containerjobexampleacr.azurecr.io/ManualExample:latest'
param containerRegistryServer = 'containerjobexampleacr.azurecr.io'
param managedIdentityName = 'containerjobexampler-id'
param containerAppsEnvironmentId = '/subscriptions/30f38ab2-a851-4c7c-9203-d761be7c5102/resourceGroups/containerjobexampler-rg/providers/Microsoft.App/managedEnvironments/containerjobexampler-env'
param appInsightsConnectionString = 'InstrumentationKey=8a3b2dce-de89-4948-a943-f70ac9e8c0bb;IngestionEndpoint=https://canadacentral-1.in.applicationinsights.azure.com/;LiveEndpoint=https://canadacentral.livediagnostics.monitor.azure.com/;ApplicationId=7dcfa1bf-e4cb-4927-9d1a-942fba4cf458'
