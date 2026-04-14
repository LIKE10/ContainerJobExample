using Azure.Identity;
using ManualExample;
using Microsoft.ApplicationInsights.Extensibility;
using Serilog;

var builder = Host.CreateApplicationBuilder(args);

// Configure Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetryWorkerService(options =>
{
    options.ConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
});

// Configure managed identity credential for Azure service authentication
// If AZURE_CLIENT_ID is set, use the specified user-assigned managed identity
// Otherwise, use DefaultAzureCredential which automatically uses the runtime identity
var clientId = builder.Configuration["AZURE_CLIENT_ID"];
Azure.Core.TokenCredential credential = string.IsNullOrEmpty(clientId)
    ? new DefaultAzureCredential()
    : new ManagedIdentityCredential(ManagedIdentityId.FromUserAssignedClientId(clientId));
builder.Services.AddSingleton(credential);

// Configure Serilog with Console and Application Insights sinks
// MinimumLevel defaults to Information (see appsettings.json) and can be overridden
// at runtime via environment variables, e.g. Serilog__MinimumLevel__Default=Debug
builder.Services.AddSerilog((services, loggerConfig) =>
{
    var telemetryConfiguration = services.GetRequiredService<TelemetryConfiguration>();

    loggerConfig
        .ReadFrom.Configuration(builder.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithProperty("ExecutionId", "none")
        .WriteTo.Console(
            outputTemplate: "[{Level:u3}] [{ExecutionId}] {Message:lj}{NewLine}{Exception}")
        .WriteTo.ApplicationInsights(
            telemetryConfiguration,
            TelemetryConverter.Traces);
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
await host.RunAsync();
