using './acr.bicep'
extends './dev-defaults.bicepparam'

param appName = 'containerjobtst'
// Only require a Basic SKU for this configuration
param acrSku = 'Basic'

