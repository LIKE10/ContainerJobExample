# ContainerJobExample

A .NET Worker Service packaged as a Docker container and deployed to **Azure Container Apps Jobs**. The job runs on-demand (manual trigger), executes a short-lived workload, and ships structured logs to **Application Insights** via Serilog.

---

## Project Structure

```
ContainerJobExample/
├── Dockerfile                    # Multi-stage Docker build (SDK → runtime)
├── infra/
│   ├── main.bicep                # Bicep template – Log Analytics, App Insights, Container Apps Env, Job
│   └── main.bicepparam           # Default parameter values (region, app name)
├── src/
│   └── ContainerJob/
│       ├── ContainerJob.csproj   # .NET 10 Worker Service project
│       ├── Program.cs            # Host setup with Serilog + Application Insights
│       └── Worker.cs             # BackgroundService that runs the job logic
└── .github/
    └── workflows/
        └── deploy.yml            # CI/CD: build → containerize → deploy
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
| `appName` | `containerjob` | Base name used to derive all Azure resource names |
| `location` | `canadacentral` | Azure region for all resources |

The following parameters are **not** stored in the param file and must be supplied at deploy time (see CI/CD section below):

| Parameter | Description |
|-----------|-------------|
| `containerImage` | Full image reference, e.g. `myacr.azurecr.io/containerjob:run-123` |
| `containerRegistryServer` | ACR login server, e.g. `myacr.azurecr.io` |
| `containerRegistryUsername` | ACR username |
| `containerRegistryPassword` | ACR password (marked `@secure()`) |

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
| `ACR_USERNAME` | ACR username |
| `ACR_PASSWORD` | ACR password |

---

## Local Development

```bash
# Restore dependencies
dotnet restore src/ContainerJob/ContainerJob.csproj

# Run locally
dotnet run --project src/ContainerJob/ContainerJob.csproj
```

### Build & run the Docker image locally

```bash
docker build --tag containerjob:local .
docker run --rm containerjob:local
```

---

## Infrastructure Deployment (manual)

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam \
  --parameters \
      containerImage="<acr>.azurecr.io/containerjob:<tag>" \
      containerRegistryServer="<acr>.azurecr.io" \
      containerRegistryUsername="<username>" \
      containerRegistryPassword="<password>"
```

---

## CI/CD Pipeline

The workflow at `.github/workflows/deploy.yml` is triggered manually (`workflow_dispatch`) and runs three sequential jobs:

1. **Build** – restores and publishes the .NET project, uploads the artifact.
2. **Containerize** – builds the Docker image tagged with the GitHub run ID and saves it as an artifact.
3. **Deploy** – logs in to Azure and ACR, pushes the image, deploys the Bicep template, then updates the Container App Job to use the new image.

---

## Running the Job

After deployment, trigger the job from the Azure Portal or via the Azure CLI:

```bash
az containerapp job start \
  --name <appName>-job \
  --resource-group <your-resource-group>
```