using './main.bicep'

// Override these values for your environment.
// Sensitive parameters should be supplied
// via GitHub Actions secrets or az deployment group create --parameters.

param appName = 'containerjobexample'
param location = 'canadacentral'

// manualContainerImage, scheduledContainerImage, containerRegistryServer,
// and managedIdentityResourceId are provided
// at deploy-time by the CI/CD pipeline.
