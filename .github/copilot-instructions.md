# Copilot Instructions

## Build & Run

```bash
# Build the entire solution
dotnet build ContainerJobExample.sln

# Run a specific project locally
dotnet run --project src/ManualExample/ManualExample.csproj
dotnet run --project src/ScheduledExample/ScheduledExample.csproj

# Docker builds (run from repo root)
docker build --tag manualexample:local --file Dockerfile .
docker build --tag scheduledexample:local --file Dockerfile.scheduled .
```

There are no tests configured in this repository.

```bash
# Validate Bicep templates locally
az bicep lint --file infra/main.bicep
az bicep build --file infra/main.bicep
```

Bicep lint and build also run automatically on push/PR when files under `infra/` change (`.github/workflows/validate-bicep.yml`).

## Architecture

This repo contains .NET 10 Worker Services that run as **Azure Container Apps Jobs** — short-lived containers that execute a task and exit (not long-running web services).

Each job follows this flow: `Program.cs` configures the host → registers a `Worker` as a `BackgroundService` → `Worker.ExecuteAsync` runs the job logic → calls `IHostApplicationLifetime.StopApplication()` to terminate the container.

**Infrastructure** is defined in `infra/main.bicep` and provisions: Log Analytics → Application Insights → Container Apps Environment → two Container App Jobs (manual-trigger and cron-schedule). A pre-existing user-assigned managed identity with `acrPull` is required for ACR authentication.

**CI/CD** (`.github/workflows/deploy.yml`) is manual-dispatch only and runs: Build → Containerize (tagged with GitHub run ID) → Deploy to Azure.

## Conventions

### Worker pattern
Every job must follow this structure in `Worker.ExecuteAsync`:
- `try` block: log start, call `DoWorkAsync`, log completion
- `catch (OperationCanceledException)`: log warning (don't rethrow)
- `catch (Exception)`: log error, rethrow
- `finally`: always call `_lifetime.StopApplication()` — this is critical for the container to exit cleanly

Put business logic in the private `DoWorkAsync` method, not directly in `ExecuteAsync`.

### Logging
All projects use **Serilog** with two sinks: Console and Application Insights. Use Serilog structured message templates with named placeholders (e.g., `_logger.LogInformation("Job started at {Time}", DateTimeOffset.UtcNow)`). The Application Insights connection string is injected via the `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable.

### Adding a new job
1. Create a new project under `src/` using `Microsoft.NET.Sdk.Worker` targeting `net10.0`
2. Add the same three NuGet packages: `Microsoft.ApplicationInsights.WorkerService`, `Serilog.AspNetCore`, `Serilog.Sinks.ApplicationInsights`
3. Copy the `Program.cs` host setup pattern (App Insights + Serilog configuration)
4. Implement a `Worker : BackgroundService` following the try/catch/finally pattern above
5. Add a `Dockerfile.<name>` at the repo root (multi-stage: sdk build → aspnet runtime)
6. Add the corresponding Container App Job resource in `infra/main.bicep`
7. Update `.github/workflows/deploy.yml` to build, containerize, and deploy the new job
