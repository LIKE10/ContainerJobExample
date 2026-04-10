using './prereqs.bicep'

param appName = 'containerjobexampler'
param location = 'canadacentral'

// Supply these at deploy time or replace with your values
param acrName = 'containerjobexampleacr'
param acrResourceGroup = 'containerjobexampleacr-rg'
