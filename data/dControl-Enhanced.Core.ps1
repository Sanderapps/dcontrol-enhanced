# dControl Enhanced core.
# Built separately and connected only after validation.
[CmdletBinding()]
param(
    [ValidateSet('disable','enable','status')]
    [string]$Action = 'status'
)
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$dControl = Join-Path $base 'dcontrol\dControl.exe'
$stateFile = Join-Path $base 'dcontrol-enhanced-state.json'
$settings = @()
$policy='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
$settings+=,@($policy,'DisableAntiVirus',1)
$settings+=,@($policy,'DisableSpecialRunningModes',1)
$settings+=,@($policy,'ServiceKeepAlive',0)
$updates=Join-Path $policy 'Signature Updates'
$spynet=Join-Path $policy 'Spynet'
$settings+=,@($updates,'ForceUpdateFromMU',0)
$settings+=,@($spynet,'DisableBlockAtFirstSeen',1)
function Test-Admin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    $p=New-Object Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-TamperState {
    try {
        $s=Get-MpComputerStatus -ErrorAction Stop
        if($null -eq $s.IsTamperProtected){return 'Unknown'}
        if([bool]$s.IsTamperProtected){return 'Enabled'}
        return 'Disabled'
    } catch {return 'Unknown'}
}
function Get-DefenderState {
    try {
        $s=Get-MpComputerStatus -ErrorAction Stop
        if([bool]$s.AntivirusEnabled -or [bool]$s.RealTimeProtectionEnabled){
            return 'Enabled'
        }
        return 'Disabled'
    } catch {
        $svc=Get-Service WinDefend -ErrorAction SilentlyContinue
        if($null -eq $svc){return 'Unknown'}
        if($svc.Status -eq 'Running'){return 'Enabled'}
        if($svc.Status -eq 'Stopped' -and $svc.StartType -eq 'Disabled'){
            return 'Disabled'
        }
        return 'Unknown'
    }
}

function Wait-State([string]$Expected) {
    for($attempt=0;$attempt -lt 20;$attempt++){
        if((Get-DefenderState) -eq $Expected){return $true}
        Start-Sleep -Seconds 1
    }
    return $false
}
function Save-State {
    if(Test-Path -LiteralPath $stateFile){
        Write-Host '[INFO] Existing registry snapshot preserved.' -ForegroundColor Yellow
        return
    }
    $entries=@()
    foreach($s in $settings){
        $exists=$false;$value=$null;$kind='DWord'
        if(Test-Path -LiteralPath $s[0]){
            $key=Get-Item -LiteralPath $s[0]
            if($key.GetValueNames() -contains $s[1]){
                $exists=$true
                $value=$key.GetValue($s[1],$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
                $kind=$key.GetValueKind($s[1]).ToString()
            }
        }
        $entries+=[pscustomobject]@{
            Path=$s[0];Name=$s[1];Existed=$exists;Value=$value;Kind=$kind
        }
    }
    $snapshot=[pscustomobject]@{
        Version=1;CreatedUtc=[DateTime]::UtcNow.ToString('o');Entries=$entries
    }
    $tmp=$stateFile+'.tmp'
    $snapshot|ConvertTo-Json -Depth 4|Set-Content -LiteralPath $tmp -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $stateFile -Force
    Write-Host '[OK] Original registry state saved.' -ForegroundColor Green
}
function Restore-State {
    if(-not(Test-Path -LiteralPath $stateFile)){
        Write-Host '[INFO] No enhanced registry snapshot found.' -ForegroundColor Yellow
        return
    }
    $snapshot=Get-Content -LiteralPath $stateFile -Raw|ConvertFrom-Json
    if($snapshot.Version -ne 1 -or $null -eq $snapshot.Entries){
        throw ('Invalid snapshot; preserved at {0}' -f $stateFile)
    }
    $failures=@()
    foreach($e in $snapshot.Entries){
        try {
            if([bool]$e.Existed){
                if(-not(Test-Path -LiteralPath $e.Path)){
                    New-Item -Path $e.Path -Force|Out-Null
                }
                New-ItemProperty -Path $e.Path -Name $e.Name -Value $e.Value -PropertyType $e.Kind -Force|Out-Null
            } elseif(Test-Path -LiteralPath $e.Path){
                Remove-ItemProperty -Path $e.Path -Name $e.Name -ErrorAction SilentlyContinue
            }
            Write-Host ('[OK] Restored {0}\{1}' -f $e.Path,$e.Name)
        } catch {
            $failures+=('{0}\{1}: {2}' -f $e.Path,$e.Name,$_.Exception.Message)
        }
    }
    if($failures.Count){
        throw ('Incomplete restore; snapshot preserved. '+($failures -join ' | '))
    }
    Remove-Item -LiteralPath $stateFile -Force
}
function Apply-Settings {
    Save-State
    try {
        foreach($s in $settings){
            if(-not(Test-Path -LiteralPath $s[0])){
                New-Item -Path $s[0] -Force|Out-Null
            }
            New-ItemProperty -Path $s[0] -Name $s[1] -Value $s[2] -PropertyType DWord -Force|Out-Null
            Write-Host ('[OK] Set {0}\{1}={2}' -f $s[0],$s[1],$s[2])
        }
    } catch {
        $message=$_.Exception.Message
        Restore-State
        throw ('Registry update failed and was rolled back: '+$message)
    }
}

function Run-DControl([string]$Instruction) {
    if(-not(Test-Path -LiteralPath $dControl -PathType Leaf)){
        throw ('dControl.exe not found. Download it from the official Sordum page and place it at: '+$dControl)
    }
    Write-Host $Instruction -ForegroundColor Yellow
    Write-Host 'Close dControl after choosing the requested action.'
    Start-Process -FilePath $dControl -Wait
}
function Show-Status {
    Write-Host ''
    Write-Host ('Defender:          {0}' -f (Get-DefenderState)) -ForegroundColor Cyan
    Write-Host ('Tamper Protection: {0}' -f (Get-TamperState)) -ForegroundColor Cyan
    Write-Host ('Rollback snapshot: {0}' -f (Test-Path -LiteralPath $stateFile)) -ForegroundColor Cyan
    Write-Host ''
    $names=@('WinDefend','WdNisSvc','WdFilter','WdBoot','Sense','SecurityHealthService')
    foreach($name in $names){
        $svc=Get-Service $name -ErrorAction SilentlyContinue
        if($null -eq $svc){Write-Host ('{0}: not found' -f $name)}
        else{Write-Host ('{0}: {1} ({2})' -f $name,$svc.Status,$svc.StartType)}
    }
}
function Invoke-Disable {
    $tamper=Get-TamperState
    if($tamper -eq 'Unknown'){
        throw 'Tamper Protection could not be verified; operation stopped.'
    }
    if($tamper -eq 'Enabled'){
        throw 'Disable Tamper Protection manually in Windows Security first.'
    }
    Save-State
    Run-DControl 'Choose Disable Windows Defender in dControl.'
    if(-not(Wait-State 'Disabled')){
        throw 'Defender was not confirmed disabled; no extra settings applied.'
    }
    Apply-Settings
    Write-Host '[SUCCESS] Disable operation confirmed.' -ForegroundColor Green
    Show-Status
}
function Invoke-Enable {
    Restore-State
    Run-DControl 'Choose Enable Windows Defender in dControl.'
    if(-not(Wait-State 'Enabled')){
        throw 'Defender was not confirmed enabled. Restart and check status.'
    }
    Write-Host '[SUCCESS] Enable operation confirmed.' -ForegroundColor Green
    Show-Status
}

try {
    if($Action -ne 'status' -and -not(Test-Admin)){
        throw 'Run this action from an elevated Administrator terminal.'
    }
    switch($Action){
        'disable'{Invoke-Disable}
        'enable'{Invoke-Enable}
        'status'{Show-Status}
    }
} catch {
    Write-Host ('[ERROR] {0}' -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
exit 0
