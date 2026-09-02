@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name used to derive all resource names')
param appName string

@description('Container image reference for the manual job (e.g. myacr.azurecr.io/manualexample:run-123)')
param manualContainerImage string

@description('Container image reference for the scheduled job (e.g. myacr.azurecr.io/scheduledexample:run-123)')
param scheduledContainerImage string

@description('Container registry server (e.g. myacr.azurecr.io)')
param containerRegistryServer string

@description('Resource ID of the pre-defined user-assigned managed identity that has acrPull permissions on the container registry')
param managedIdentityResourceId string

@description('Cron expression for the scheduled job (e.g. "0 0 * * *" for daily at midnight UTC)')
param scheduledJobCron string = '0 0 * * *'

@description('Tags to apply to the resources')
param environmentTags object

// ── Log Analytics Workspace ──────────────────────────────────────────────────
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${appName}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ── Application Insights ─────────────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-ai'
  location: location
  kind: 'other'
  properties: {
    Application_Type: 'other'
    WorkspaceResourceId: logAnalytics.id
  }
}

// ── Container Apps Environment ───────────────────────────────────────────────
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${appName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// ── Manual Container App Job ─────────────────────────────────────────────────
resource manualContainerAppJob 'Microsoft.App/jobs@2025-10-02-preview' = {
  name: '${appName}-manual-job'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      triggerType: 'Manual'
      replicaTimeout: 600
      replicaRetryLimit: 1
      registries: [
        {
          server: containerRegistryServer
          identity: managedIdentityResourceId
        }
      ]
      secrets: [
        {
          name: 'appinsights-connection-string'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'manualexample'
          image: manualContainerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection-string'
            }
          ]
        }
      ]
    }
  }
}

// ── Scheduled Container App Job ──────────────────────────────────────────────
resource scheduledContainerAppJob 'Microsoft.App/jobs@2025-10-02-preview' = {
  name: '${appName}-scheduled-job'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      triggerType: 'Schedule'
      replicaTimeout: 600
      replicaRetryLimit: 1
      scheduleTriggerConfig: {
        cronExpression: scheduledJobCron
        parallelism: 1
        replicaCompletionCount: 1
      }
      registries: [
        {
          server: containerRegistryServer
          identity: managedIdentityResourceId
        }
      ]
      secrets: [
        {
          name: 'appinsights-connection-string'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'scheduledexample'
          image: scheduledContainerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection-string'
            }
          ]
        }
      ]
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output manualContainerAppJobName string = manualContainerAppJob.name
output scheduledContainerAppJobName string = scheduledContainerAppJob.name
output containerAppsEnvironmentName string = containerAppsEnvironment.name
