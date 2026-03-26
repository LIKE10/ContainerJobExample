using './main.bicep'

// Override these values for your environment.
// Sensitive parameters (containerRegistryPassword) should be supplied
// via GitHub Actions secrets or az deployment group create --parameters.

param appName = 'containerjob'
param location = 'canadacentral'

// containerImage, containerRegistryServer, containerRegistryUsername,
// and containerRegistryPassword are provided at deploy-time by the CI/CD pipeline.
