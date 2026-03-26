@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name used to derive all resource names')
param appName string

@description('Container image reference (e.g. myacr.azurecr.io/containerjob:run-123)')
param containerImage string

@description('Container registry server (e.g. myacr.azurecr.io)')
param containerRegistryServer string

@description('Container registry username for pulling images')
param containerRegistryUsername string

@description('Container registry password for pulling images')
@secure()
param containerRegistryPassword string

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

// ── Container App Job ────────────────────────────────────────────────────────
resource containerAppJob 'Microsoft.App/jobs@2024-03-01' = {
  name: '${appName}-job'
  location: location
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      triggerType: 'Manual'
      replicaTimeout: 600
      replicaRetryLimit: 1
      registries: [
        {
          server: containerRegistryServer
          username: containerRegistryUsername
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistryPassword
        }
        {
          name: 'appinsights-connection-string'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'containerjob'
          image: containerImage
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
output containerAppJobName string = containerAppJob.name
output containerAppsEnvironmentName string = containerAppsEnvironment.name
