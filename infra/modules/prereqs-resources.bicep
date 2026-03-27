@description('Azure region for all resources')
param location string

@description('Base name used to derive all resource names')
param appName string

// ── User-Assigned Managed Identity ───────────────────────────────────────────
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${appName}-id'
  location: location
}

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

// ── Outputs ──────────────────────────────────────────────────────────────────
output managedIdentityResourceId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output containerAppsEnvironmentName string = containerAppsEnvironment.name
output logAnalyticsWorkspaceName string = logAnalytics.name
