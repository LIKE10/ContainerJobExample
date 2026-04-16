@description('Azure region for the job')
param location string

@description('Name of the Container App Job')
param jobName string

@description('Resource ID of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Container image reference (e.g. myacr.azurecr.io/myapp:latest)')
param containerImage string

@description('Container name within the job')
param containerName string

@description('Container registry server (e.g. myacr.azurecr.io)')
param containerRegistryServer string

@description('Name of the user-assigned managed identity with acrPull permissions')
param managedIdentityName string

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
param tagValues object

@description('Maximum time in seconds a replica can run before being terminated')
param replicaTimeout int = 600

@description('Maximum number of retries for a failed replica')
param replicaRetryLimit int = 1

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

// ── Container App Job ───────────────────────────────────────────────────────
resource containerAppJob 'Microsoft.App/jobs@2025-10-02-preview' = {
  name: jobName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  tags: tagValues
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      triggerType: triggerType
      replicaTimeout: replicaTimeout
      replicaRetryLimit: replicaRetryLimit
      scheduleTriggerConfig: triggerType == 'Schedule' ? {
        cronExpression: cronExpression
        parallelism: 1
        replicaCompletionCount: 1
      } : null
      registries: [
        {
          server: containerRegistryServer
          identity: userIdentity.id
        }
      ]
      secrets: [
        {
          name: 'appinsights-connection-string'
          value: appInsightsConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerName
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: userIdentity.properties.clientId
            }
          ]
        }
      ]
    }
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────
output jobId string = containerAppJob.id
output jobName string = containerAppJob.name
