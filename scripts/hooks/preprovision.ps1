$ErrorActionPreference = 'Stop'

$appName = ($env:AZURE_ENV_NAME -replace '-', '').ToLowerInvariant()
if ($appName.Length -lt 2 -or $appName.Length -gt 18) {
  throw 'The normalized azd environment name must be between 2 and 18 characters to produce valid resource names.'
}
