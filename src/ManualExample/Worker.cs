using System.IdentityModel.Tokens.Jwt;
using Azure.Core;
using Azure.Identity;

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

            _logger.LogInformation("--- Raw Token ---");

            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(rawToken);

            _logger.LogInformation("--- Decoded Token Contents ---");
            _logger.LogInformation("Header:  {SerializeToJson}", jwtToken.Header.SerializeToJson());
            _logger.LogInformation("Issuer:  {JwtTokenIssuer}", jwtToken.Issuer);
            _logger.LogInformation("Subject: {JwtTokenSubject}", jwtToken.Subject);
            _logger.LogInformation("Expires: {JwtTokenValidTo} (UTC)", jwtToken.ValidTo);

            _logger.LogInformation("--- Claims ---");
            foreach (var claim in jwtToken.Claims)
            {
                _logger.LogInformation("{ClaimType}: {ClaimValue}", claim.Type, claim.Value);
            }
        }
        catch (AuthenticationFailedException e)
        {
            _logger.LogError("Authentication Failed: {EMessage}", e.Message);
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
