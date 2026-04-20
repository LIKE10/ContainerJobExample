using Serilog.Context;

namespace ScheduledExample;

public class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly IHostApplicationLifetime _lifetime;

    public Worker(ILogger<Worker> logger, IHostApplicationLifetime lifetime)
    {
        _logger = logger;
        _lifetime = lifetime;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var executionId = Guid.NewGuid().ToString();
        using var executionIdContext = LogContext.PushProperty("ExecutionId", executionId);

        try
        {
            _logger.LogInformation("Scheduled job started. ExecutionId: {ExecutionId}, Time: {Time}", executionId, DateTimeOffset.UtcNow);
            _logger.LogInformation("Running scheduled job as identity: {AzureClientId}", Environment.GetEnvironmentVariable("AZURE_CLIENT_ID"));

            await DoWorkAsync(stoppingToken);

            _logger.LogInformation("Scheduled job completed successfully at {Time}", DateTimeOffset.UtcNow);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Scheduled job was cancelled");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Scheduled job failed with an unhandled exception");
            throw;
        }
        finally
        {
            _lifetime.StopApplication();
        }
    }

    private async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Executing scheduled job work item");

        // Simulate scheduled workload — replace with real business logic (e.g. nightly cleanup, report generation)
        await Task.Delay(TimeSpan.FromSeconds(2), cancellationToken);

        _logger.LogInformation("Scheduled job work item completed");
    }
}
