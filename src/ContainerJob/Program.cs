using ContainerJob;
using Microsoft.ApplicationInsights.Extensibility;
using Serilog;
using Serilog.Events;

var builder = Host.CreateApplicationBuilder(args);

// Configure Application Insights telemetry
builder.Services.AddApplicationInsightsTelemetryWorkerService(options =>
{
    options.ConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
});

// Configure Serilog with Console and Application Insights sinks
builder.Services.AddSerilog((services, loggerConfig) =>
{
    var telemetryConfiguration = services.GetRequiredService<TelemetryConfiguration>();

    loggerConfig
        .MinimumLevel.Information()
        .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
        .Enrich.FromLogContext()
        .WriteTo.Console(
            outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
        .WriteTo.ApplicationInsights(
            telemetryConfiguration,
            TelemetryConverter.Traces);
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
await host.RunAsync();
