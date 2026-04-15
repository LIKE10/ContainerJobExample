using './prereqs.bicep'

param appName = 'containerjobexampler'
param location = 'canadacentral'
param tagValues = {
  Department: 'NRC-CNRC'
  Environment: 'Development'
}

// Supply these at deploy time or replace with your values
param acrName = 'containerjobexampleacr'
param acrResourceGroup = 'containerjobexampleacr-rg'
