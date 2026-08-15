# Tamper Protection helper.
# Microsoft protects this setting from direct registry modification.
param([switch]$Silent)

$ErrorActionPreference='Stop'

function Get-TamperState {
    try {
        $status=Get-MpComputerStatus -ErrorAction Stop
        if($null -eq $status.IsTamperProtected){return 'Unknown'}
        if([bool]$status.IsTamperProtected){return 'Enabled'}
        return 'Disabled'
    } catch {
        return 'Unknown'
    }
}

$state=Get-TamperState
if($state -eq 'Disabled'){
    Write-Host '[OK] Tamper Protection is already disabled.' -ForegroundColor Green
    exit 0
}
if($state -eq 'Unknown'){
    Write-Host '[ERROR] Tamper Protection state could not be verified.' -ForegroundColor Red
    exit 1
}
if($Silent){
    Write-Host '[ACTION REQUIRED] Disable Tamper Protection manually.' -ForegroundColor Yellow
    exit 2
}

Write-Host 'Windows Security will open.' -ForegroundColor Cyan
Write-Host 'Turn off Tamper Protection under Virus and threat protection settings.'
Start-Process 'windowsdefender://Threatsettings'
$null=Read-Host 'After changing the setting, press Enter to verify'

$state=Get-TamperState
if($state -eq 'Disabled'){
    Write-Host '[OK] Tamper Protection is disabled.' -ForegroundColor Green
    exit 0
}
Write-Host ('[ERROR] Tamper Protection is {0}.' -f $state) -ForegroundColor Red
exit 2
