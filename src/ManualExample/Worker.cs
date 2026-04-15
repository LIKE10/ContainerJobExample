using System.IdentityModel.Tokens.Jwt;
using Azure.Core;
using Azure.Identity;
using Serilog.Context;

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
        var executionId = Guid.NewGuid().ToString();
        using var executionIdContext = LogContext.PushProperty("ExecutionId", executionId);

        try
        {
            _logger.LogInformation("Manual job started. ExecutionId: {ExecutionId}, Time: {Time}", executionId, DateTimeOffset.UtcNow);
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

    private void DumpEnvironment()
    {
        var envVars = Environment.GetEnvironmentVariables()
            .Cast<System.Collections.DictionaryEntry>()
            .OrderBy(e => e.Key.ToString());

        foreach (var entry in envVars)
        {
            _logger.LogInformation("{Key} = {Value}", entry.Key, entry.Value);
        }
    }

    private void DumpCredentials()
    {
        var credential = new DefaultAzureCredential();
        var tokenRequestContext = new TokenRequestContext(["https://management.azure.com/.default"]);
        
        try
        {
            _logger.LogDebug("Fetching token from Azure Identity endpoint...");
    
            AccessToken token = credential.GetTokenAsync(tokenRequestContext).GetAwaiter().GetResult();
            string rawToken = token.Token;

            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(rawToken);
            
            // Always log only non-sensitive metadata
            _logger.LogInformation("Token client id {id}", jwtToken.Claims.First(c => c.Type == "appid").Value);
            _logger.LogInformation("Acquired token that expires at {JwtTokenValidTo} (UTC)", jwtToken.ValidTo);

            // Optional, gated, and redacted token introspection for debugging purposes only
            var enableTokenLogging = string.Equals(
                Environment.GetEnvironmentVariable("ENABLE_TOKEN_LOGGING"),
                "true",
                StringComparison.OrdinalIgnoreCase);

            if (enableTokenLogging)
            {
                _logger.LogDebug("--- Token Debug Information (redacted) ---");
                var claimTypes = jwtToken.Claims.Select(c => c.Type).Distinct().ToArray();
                _logger.LogDebug("Token contains {ClaimCount} claims of types: {ClaimTypes}", claimTypes.Length, claimTypes);
            }
            else
            {
                _logger.LogDebug("Detailed token logging is disabled. Set ENABLE_TOKEN_LOGGING=true to enable redacted token diagnostics.");
            }
        }
        catch (AuthenticationFailedException e)
        {
            _logger.LogError(e, "Authentication failed while fetching token from Azure Identity endpoint.");
            throw;
        }
    }
    
    private async Task DoWorkAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Executing manual job work item");

        DumpEnvironment();
        DumpCredentials();  
        
        // Simulate workload — replace with real business logic
        await Task.Delay(TimeSpan.FromSeconds(2), cancellationToken);

        _logger.LogInformation("Manual job work item completed");
    }
}
