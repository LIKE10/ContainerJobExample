using './main.bicep'

// Override these values for your environment.
// Sensitive parameters should be supplied
// via GitHub Actions secrets or az deployment group create --parameters.

param appName = 'containerjobexample'
param location = 'canadacentral'

param tags = {
  Environment: 'Production'
  Owner: 'ops-team@company.com'
  CostCenter: 'CC5678'
  Project: 'WebsiteRedesign'
  Department: 'Marketing'
  CreatedOn: '2026-04-17'
  Confidentiality: 'HighlyConfidential'
  Criticality: 'High'
}

// manualContainerImage, scheduledContainerImage, containerRegistryServer,
// and managedIdentityResourceId are provided
// at deploy-time by the CI/CD pipeline.
