using './prereqs.bicep'

param appName = 'containerjobexample'
param location = 'canadacentral'

// Supply these at deploy time or replace with your values
param acrName = 'hangfirejobs'
param acrResourceGroup = 'azure-aks-jobs-rg'
