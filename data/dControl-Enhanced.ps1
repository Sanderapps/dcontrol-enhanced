# Compatibility entry point. The validated implementation is in the Core file.
[CmdletBinding()]
param(
    [ValidateSet('disable','enable','status')]
    [string]$Action='status'
)
$core=Join-Path $PSScriptRoot 'dControl-Enhanced.Core.ps1'
& $core -Action $Action
exit $LASTEXITCODE
