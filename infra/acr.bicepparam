extends './dev-defaults.bicepparam'

using './acr.bicep'

param appName = 'containerjobexample'
// Only require a Basic SKU for this configuration
param acrSku = 'Basic'

