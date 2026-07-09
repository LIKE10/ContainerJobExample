targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Name of the Container App Job')
param jobName string

@description('Container image reference (e.g. myacr.azurecr.io/myapp:latest)')
param containerImage string

@description('Container name within the job')
param containerName string

@description('Container registry server (e.g. myacr.azurecr.io)')
param containerRegistryServer string

@description('Name of the user-assigned managed identity with acrPull permissions')
param managedIdentityName string

@description('Resource ID of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Application Insights connection string')
@secure()
param appInsightsConnectionString string

@description('Trigger type for the job')
@allowed([
  'Manual'
  'Schedule'
])
param triggerType string = 'Manual'

@description('Cron expression for scheduled jobs (e.g. "0 0 * * *" for daily at midnight UTC)')
param cronExpression string = '0 0 * * *'

@description('CPU allocation for the container')
param cpu string = '0.25'

@description('Memory allocation for the container')
param memory string = '0.5Gi'

@description('Tags to apply to the Container App Job')
param environmentTags object

// ── Container App Job ───────────────────────────────────────────────────────
module containerJob 'modules/container-app-job.bicep' = {
  name: 'container-app-job'
  params: {
    location: location
    jobName: jobName
    containerAppsEnvironmentId: containerAppsEnvironmentId
    containerImage: containerImage
    containerName: containerName
    containerRegistryServer: containerRegistryServer
    managedIdentityName: managedIdentityName
    appInsightsConnectionString: appInsightsConnectionString
    triggerType: triggerType
    cronExpression: cronExpression
    cpu: cpu
    memory: memory
    tagValues: environmentTags
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output jobId string = containerJob.outputs.jobId
output jobName string = containerJob.outputs.jobName
