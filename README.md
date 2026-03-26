# ContainerJobExample

A collection of .NET Worker Services packaged as Docker containers and deployed to **Azure Container Apps Jobs**. Each example demonstrates a different job trigger type and ships structured logs to **Application Insights** via Serilog.

| Example | Trigger | Description |
|---------|---------|-------------|
| **ManualExample** | Manual | Triggered on-demand via the Azure Portal or CLI |
| **ScheduledExample** | Schedule (cron) | Triggered automatically on a recurring cron schedule |

---

## Project Structure

```
ContainerJobExample/
├── Dockerfile                       # Multi-stage Docker build for ManualExample
├── Dockerfile.scheduled             # Multi-stage Docker build for ScheduledExample
├── infra/
│   ├── main.bicep                   # Bicep template – Log Analytics, App Insights, Container Apps Env, both Jobs
│   └── main.bicepparam              # Default parameter values (region, app name)
├── src/
│   ├── ManualExample/
│   │   ├── ManualExample.csproj     # .NET 10 Worker Service project
│   │   ├── Program.cs               # Host setup with Serilog + Application Insights
│   │   └── Worker.cs                # BackgroundService that runs the manual job logic
│   └── ScheduledExample/
│       ├── ScheduledExample.csproj  # .NET 10 Worker Service project
│       ├── Program.cs               # Host setup with Serilog + Application Insights
│       └── Worker.cs                # BackgroundService that runs the scheduled job logic
└── .github/
    └── workflows/
        └── deploy.yml               # CI/CD: build → containerize → deploy (both examples)
```

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| [.NET SDK](https://dotnet.microsoft.com/download) | 10.0 |
| [Docker](https://www.docker.com/) | any recent version |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 2.60+ |
| [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) | 0.27+ |

An **Azure subscription** with an existing resource group and an **Azure Container Registry (ACR)** are also required.

---

## Configuration

### Bicep parameters (`infra/main.bicepparam`)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `appName` | `containerjobexample` | Base name used to derive all Azure resource names |
| `location` | `canadacentral` | Azure region for all resources |
| `scheduledJobCron` | `0 0 * * *` | Cron expression for the scheduled job (default: daily at midnight UTC) |

The following parameters are **not** stored in the param file and must be supplied at deploy time (see CI/CD section below):

| Parameter | Description |
|-----------|-------------|
| `manualContainerImage` | Full image reference for the manual job, e.g. `myacr.azurecr.io/manualexample:run-123` |
| `scheduledContainerImage` | Full image reference for the scheduled job, e.g. `myacr.azurecr.io/scheduledexample:run-123` |
| `containerRegistryServer` | ACR login server, e.g. `myacr.azurecr.io` |
| `managedIdentityResourceId` | Full resource ID of a pre-existing user-assigned managed identity that has `acrPull` permissions on the registry |

### GitHub Actions secrets

Configure the following secrets in **Settings → Secrets and variables → Actions** on the repository:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | JSON service-principal credentials for `azure/login` |
| `AZURE_RESOURCE_GROUP` | Target resource group name |
| `AZURE_LOCATION` | Azure region (e.g. `canadacentral`) |
| `APP_NAME` | Application base name (must match `appName` in the param file) |
| `ACR_NAME` | ACR resource name (without `.azurecr.io`) |
| `ACR_LOGIN_SERVER` | ACR login server, e.g. `myacr.azurecr.io` |
| `MANAGED_IDENTITY_RESOURCE_ID` | Full resource ID of the user-assigned managed identity used for ACR authentication |

---

## Local Development

```bash
# Restore and run ManualExample locally
dotnet restore src/ManualExample/ManualExample.csproj
dotnet run --project src/ManualExample/ManualExample.csproj

# Restore and run ScheduledExample locally
dotnet restore src/ScheduledExample/ScheduledExample.csproj
dotnet run --project src/ScheduledExample/ScheduledExample.csproj
```

### Build & run the Docker images locally

```bash
# ManualExample
docker build --tag manualexample:local --file Dockerfile .
docker run --rm manualexample:local

# ScheduledExample
docker build --tag scheduledexample:local --file Dockerfile.scheduled .
docker run --rm scheduledexample:local
```

---

## Infrastructure Deployment (manual)

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters \
      manualContainerImage="<acr>.azurecr.io/manualexample:<tag>" \
      scheduledContainerImage="<acr>.azurecr.io/scheduledexample:<tag>" \
      containerRegistryServer="<acr>.azurecr.io" \
      managedIdentityResourceId="<managed-identity-resource-id>"
```

---

## CI/CD Pipeline

The workflow at `.github/workflows/deploy.yml` is triggered manually (`workflow_dispatch`) and runs three sequential jobs:

1. **Build** – restores and publishes both .NET projects, uploads the artifacts.
2. **Containerize** – builds Docker images for both examples (tagged with the GitHub run ID) and saves them as artifacts.
3. **Deploy** – logs in to Azure and ACR, pushes both images, deploys the Bicep template, then updates both Container App Jobs to use the new images.

---

## Running the Jobs

### ManualExample

After deployment, trigger the manual job from the Azure Portal or via the Azure CLI:

```bash
az containerapp job start \
  --name <appName>-manual-job \
  --resource-group <your-resource-group>
```

### ScheduledExample

The scheduled job runs automatically according to the `scheduledJobCron` parameter (default: daily at midnight UTC). You can also trigger it manually:

```bash
az containerapp job start \
  --name <appName>-scheduled-job \
  --resource-group <your-resource-group>
```