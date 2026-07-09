# Azure Bicep Deployment Guide (`acr.bicep`, `prereqs.bicep`, `container-job.bicep`)

## Summary

This guide documents a PowerShell-first deployment flow for:
1. Creating the Azure Container Registry foundation (`infra\acr.bicep`)
2. Creating shared prerequisites (`infra\prereqs.bicep`)
3. Deploying/updating container jobs (`infra\container-job.bicep`) by a separate team

It also separates required Azure permissions for:
- **Platform deployment team** (ACR + prerequisites)
- **Container job deployment team** (job updates/deployments)

## Prerequisites

- Azure CLI installed (`az --version`)
- Bicep CLI available through Azure CLI (`az bicep version`)
- Access to the target Azure subscription
- PowerShell 7+ (or Windows PowerShell 5.1)
- Please ensure all .bicepparam contain the expected values or specify parameters at deploy-time

## PowerShell Deployment Steps

### 1. Authenticate and set context

```powershell
$SubscriptionId = "<subscription-guid>"
$Location       = "canadacentral"

az login
az account set --subscription $SubscriptionId
```

### 2. (Optional but recommended) Validate templates

```powershell
az bicep lint  --file "infra\acr.bicep"
az bicep build --file "infra\acr.bicep"

az bicep lint  --file "infra\prereqs.bicep"
az bicep build --file "infra\prereqs.bicep"

az bicep lint  --file "infra\container-job.bicep"
az bicep build --file "infra\container-job.bicep"
```

### 3. Deploy ACR foundation (`acr.bicep`) — platform team

```powershell
az deployment sub create `
  --name "deploy-acr-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
  --location $Location `
  --template-file "infra\acr.bicep" `
  --parameters "infra\acr.bicepparam"
```

### 4. Deploy prerequisites (`prereqs.bicep`) — platform team

```powershell
$PrereqsDeploymentName = "deploy-prereqs-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

az deployment sub create `
  --name $PrereqsDeploymentName `
  --location $Location `
  --template-file "infra\prereqs.bicep" `
  --parameters "infra\prereqs.bicepparam"
```

### 5. Capture outputs for the container-job team

```powershell
$PrereqsOutputs = az deployment sub show `
  --name $PrereqsDeploymentName `
  --query "properties.outputs" `
  --output json | ConvertFrom-Json

$AppResourceGroup          = $PrereqsOutputs.resourceGroupName.value
$ManagedIdentityResourceId = $PrereqsOutputs.managedIdentityResourceId.value
$AppInsightsConnString     = $PrereqsOutputs.appInsightsConnectionString.value
$ContainerEnvName          = $PrereqsOutputs.containerAppsEnvironmentName.value

# Build the environment resource ID expected by container-job.bicep
$ContainerAppsEnvironmentId = "/subscriptions/$SubscriptionId/resourceGroups/$AppResourceGroup/providers/Microsoft.App/managedEnvironments/$ContainerEnvName"
```

### 6. Deploy or update container job(s) (`container-job.bicep`) — job team

> Run once per job (manual/scheduled) with the appropriate parameters.

```powershell
$ContainerImage  = "<acr-login-server>/<image-name>:<tag>"      # e.g. containerjobexampleacr.azurecr.io/manualexample:20260521.1
$RegistryServer  = "<acr-login-server>"                         # e.g. containerjobexampleacr.azurecr.io
$JobName         = "<job-name>"                                 # e.g. containerjobexample-manual-job
$ContainerName   = "<container-name>"                           # e.g. manualcontainer
$ManagedIdentity = "<managed-identity-name>"                    # e.g. containerjobexampler-id
$TriggerType     = "Manual"                                     # or "Schedule"
$CronExpression  = "0 0 * * *"                                  # only used for Schedule

az deployment group create `
  --name "deploy-job-$JobName-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
  --resource-group $AppResourceGroup `
  --template-file "infra\container-job.bicep" `
  --parameters "infra\container-job.bicepparam" `
  --parameters `
      jobName="$JobName" `
      containerName="$ContainerName" `
      containerImage="$ContainerImage" `
      containerRegistryServer="$RegistryServer" `
      managedIdentityName="$ManagedIdentity" `
      containerAppsEnvironmentId="$ContainerAppsEnvironmentId" `
      appInsightsConnectionString="$AppInsightsConnString" `
      triggerType="$TriggerType" `
      cronExpression="$CronExpression"
```

## Required Azure Permissions

### A) Platform deployment team (`acr.bicep` + `prereqs.bicep`)

At minimum, this team must be able to:
1. Create resource groups at subscription scope
2. Create ACR, managed identity, Log Analytics, Application Insights, and Container Apps environment
3. Create RBAC role assignments on the ACR scope (`AcrPull` for the managed identity)

**Recommended built-in role combination**

| Scope | Role | Why |
|---|---|---|
| Subscription | Contributor | Deploy subscription-scope Bicep and create resource groups/resources |
| ACR resource group (or ACR resource) | User Access Administrator | Create `Microsoft.Authorization/roleAssignments` for AcrPull |

**Alternative:** `Owner` at required scopes also works (includes both resource and RBAC assignment permissions).

### B) Container job deployment team (`container-job.bicep`)

At minimum, this team must be able to:
1. Run resource-group deployments (`Microsoft.Resources/deployments/*`)
2. Create/update Azure Container Apps Jobs (`Microsoft.App/jobs/*`)
3. Read existing user-assigned identity and Container Apps Environment references
4. Start jobs after deployment (if operationally required)

**Recommended built-in role**

| Scope | Role | Why |
|---|---|---|
| Application resource group (`<appName>-rg`) | Contributor | Deploy and update `Microsoft.App/jobs` and related deployment resources |

If this team also needs to assign RBAC roles, add **User Access Administrator** at the relevant scope; otherwise, keep RBAC assignment with the platform team.

## Operational Notes

- `acr.bicep` and `prereqs.bicep` are **subscription-scope** deployments.
- `container-job.bicep` is a **resource-group-scope** deployment.
- `container-job.bicep` references an existing user-assigned identity and injects `APPLICATIONINSIGHTS_CONNECTION_STRING` as a secret into the job.
- For scheduled jobs, set `triggerType = "Schedule"` and provide `cronExpression`; for ad-hoc jobs, use `triggerType = "Manual"`.
