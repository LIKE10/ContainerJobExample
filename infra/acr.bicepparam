using './acr.bicep'

param location = 'canadacentral'
param acrResourceGroup = 'containerjobexampleacr-rg'
param acrName = 'containerjobexampleacr'
param acrSku = 'Basic'
param tagValues = {
  Department: 'NRC-CNRC'
  Environment: 'Development'
}
