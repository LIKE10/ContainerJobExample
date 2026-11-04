targetScope = 'subscription'

@minLength(1)
@maxLength(20)
@description('azd environment name; used to derive all resource names')
param environmentName string

@description('Azure region for all resources')
param location string

@description('Cron expression for the scheduled job')
param scheduledJobCron string = '0 0 * * *'

@description('Placeholder image used until postprovision builds and deploys the real images')
param placeholderImage string = 'mcr.microsoft.com/k8se/quickstart-jobs:latest'

var appName = toLower(replace(environmentName, '-', ''))
var tags = {
  'azd-env-name': environmentName
  Project: 'ContainerJobExample'
  Environment: 'Development'
}

module acr '../acr.bicep' = {
  name: 'acr'
  params: {
    location: location
    appName: appName
    environmentTags: tags
  }
}

module prereqs '../prereqs.bicep' = {
  name: 'prereqs'
  dependsOn: [acr]
  params: {
    location: location
    appName: appName
    environmentTags: tags
  }
}

var appRgName = '${appName}-rg'

module manualJob '../modules/container-app-job.bicep' = {
  name: 'manual-job'
  scope: resourceGroup(appRgName)
  dependsOn: [prereqs]
  params: {
    location: location
    jobName: '${appName}-manual-job'
    containerName: 'manualexample'
    containerAppsEnvironmentId: resourceId(subscription().subscriptionId, appRgName, 'Microsoft.App/managedEnvironments', '${appName}-env')
    containerImage: placeholderImage
    containerRegistryServer: acr.outputs.acrLoginServer
    managedIdentityName: '${appName}-id'
    appInsightsConnectionString: prereqs.outputs.appInsightsConnectionString
    triggerType: 'Manual'
    tagValues: tags
  }
}

module scheduledJob '../modules/container-app-job.bicep' = {
  name: 'scheduled-job'
  scope: resourceGroup(appRgName)
  dependsOn: [prereqs]
  params: {
    location: location
    jobName: '${appName}-scheduled-job'
    containerName: 'scheduledexample'
    containerAppsEnvironmentId: resourceId(subscription().subscriptionId, appRgName, 'Microsoft.App/managedEnvironments', '${appName}-env')
    containerImage: placeholderImage
    containerRegistryServer: acr.outputs.acrLoginServer
    managedIdentityName: '${appName}-id'
    appInsightsConnectionString: prereqs.outputs.appInsightsConnectionString
    triggerType: 'Schedule'
    cronExpression: scheduledJobCron
    tagValues: tags
  }
}

// Outputs become azd environment variables for hooks
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = prereqs.outputs.resourceGroupName
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.acrLoginServer
output AZURE_MANUAL_JOB_NAME string = manualJob.outputs.jobName
output AZURE_SCHEDULED_JOB_NAME string = scheduledJob.outputs.jobName
