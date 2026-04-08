namespace ManualExample;

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
        try
        {
            _logger.LogInformation("Manual job started at {Time}", DateTimeOffset.UtcNow);
            _logger.LogInformation("Running manual job as identity: {0}", Environment.GetEnvironmentVariable("AZURE_CLIENT_ID"));

            await DoWorkAsync(stoppingToken);

            _logger.LogInformation("Manual job completed successfully at {Time}", DateTimeOffset.UtcNow);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Manual job was cancelled");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Manual job failed with an unhandled exception");
            throw;
        }
        finally
        {
            _lifetime.StopApplication();
        }
    }

    private async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Executing manual job work item");

        // Simulate workload — replace with real business logic
        await Task.Delay(TimeSpan.FromSeconds(2), cancellationToken);

        _logger.LogInformation("Manual job work item completed");
    }
}
