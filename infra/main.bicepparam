using './main.bicep'

// Override these values for your environment.
// Sensitive parameters (containerRegistryPassword) should be supplied
// via GitHub Actions secrets or az deployment group create --parameters.

param appName = 'containerjobexample'
param location = 'canadacentral'

// manualContainerImage, scheduledContainerImage, containerRegistryServer,
// containerRegistryUsername, and containerRegistryPassword are provided
// at deploy-time by the CI/CD pipeline.
