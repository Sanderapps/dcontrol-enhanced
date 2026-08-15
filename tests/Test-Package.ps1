$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$failures=@()

function Check([bool]$Condition,[string]$Message){
    if($Condition){Write-Host ('[OK] '+$Message) -ForegroundColor Green}
    else{$script:failures+=$Message;Write-Host ('[FAIL] '+$Message) -ForegroundColor Red}
}

$required=@(
    'DCONTROL-MENU.bat',
    'ATIVAR-DEFENDER-ENHANCED.bat',
    'DESABILITAR-DEFENDER-ENHANCED.bat',
    'VERIFICAR-STATUS-DEFENDER.bat',
    'DESATIVAR-TAMPER-PROTECTION.bat',
    'data\dControl-Enhanced.ps1',
    'data\dControl-Enhanced.Core.ps1',
    'data\Desativar-TamperProtection.ps1',
    'data\dcontrol\dControl.ini'
)
foreach($item in $required){
    Check (Test-Path -LiteralPath (Join-Path $root $item)) ('Exists: '+$item)
}

$flowBats=@(
    'ATIVAR-DEFENDER-ENHANCED.bat',
    'DESABILITAR-DEFENDER-ENHANCED.bat',
    'VERIFICAR-STATUS-DEFENDER.bat'
)
foreach($item in $flowBats){
    $text=Get-Content -LiteralPath (Join-Path $root $item) -Raw
    Check ($text -match 'set "rc=%errorLevel%"') ('Captures exit code: '+$item)
    Check ($text -match 'exit /b %rc%') ('Propagates exit code: '+$item)
}
$menu=Get-Content -LiteralPath (Join-Path $root 'DCONTROL-MENU.bat') -Raw
foreach($item in $flowBats){
    Check ($menu -match [regex]::Escape($item)) ('Menu references: '+$item)
}
Check ($menu -match [regex]::Escape('DESATIVAR-TAMPER-PROTECTION.bat')) 'Menu references Tamper launcher'
Check ($menu -match [regex]::Escape('TESTAR-PACOTE.bat')) 'Menu references package tests'
$tamperBat=Get-Content -LiteralPath (Join-Path $root 'DESATIVAR-TAMPER-PROTECTION.bat') -Raw
Check ($tamperBat -match [regex]::Escape('%~dp0data\Desativar-TamperProtection.ps1')) 'Tamper launcher target is correct'
Check (-not (Test-Path -LiteralPath (Join-Path $root 'data\ativar-defender.reg'))) 'Legacy enable REG was removed'
Check (-not (Test-Path -LiteralPath (Join-Path $root 'data\desabilitar-defender.reg'))) 'Legacy disable REG was removed'

$scripts=@(
    'data\dControl-Enhanced.ps1',
    'data\dControl-Enhanced.Core.ps1',
    'data\Desativar-TamperProtection.ps1'
)
foreach($item in $scripts){
    $tokens=$null;$errors=$null
    $path=Join-Path $root $item
    [System.Management.Automation.Language.Parser]::ParseFile(
        $path,[ref]$tokens,[ref]$errors
    )|Out-Null
    Check ($errors.Count -eq 0) ('PowerShell syntax: '+$item)
}

$core=Join-Path $root 'data\dControl-Enhanced.Core.ps1'
$coreText=Get-Content -LiteralPath $core -Raw
$nonAscii=([IO.File]::ReadAllBytes($core)|Where-Object{$_ -gt 127}).Count
Check ($nonAscii -eq 0) 'Core is ASCII-compatible with Windows PowerShell 5.1'
Check ($coreText -notmatch 'Rename-Item') 'Core does not rename protected binaries'
Check ($coreText -notmatch '# NEXT') 'No temporary build marker remains'
Check ($coreText -match 'Save-State') 'Registry snapshot is implemented'
Check ($coreText -match 'Restore-State') 'Registry restore is implemented'
$saveIndex=$coreText.IndexOf('Save-State',$coreText.IndexOf('function Invoke-Disable'))
$runIndex=$coreText.IndexOf('Run-DControl',$coreText.IndexOf('function Invoke-Disable'))
Check ($saveIndex -ge 0 -and $saveIndex -lt $runIndex) 'Snapshot precedes dControl disable action'

$tamper=Get-Content -LiteralPath (Join-Path $root 'data\Desativar-TamperProtection.ps1') -Raw
Check ($tamper -notmatch 'Set-ItemProperty') 'Tamper helper does not force registry values'

$exe=Join-Path $root 'data\dcontrol\dControl.exe'
$expected='1EF6C1A4DFDC39B63BFE650CA81AB89510DE6C0D3D7C608AC5BE80033E559326'
if(Test-Path -LiteralPath $exe){
    $actual=(Get-FileHash -Algorithm SHA256 -LiteralPath $exe).Hash
    Check ($actual -eq $expected) 'dControl.exe matches the vendor SHA-256'
} else {
    Write-Host '[WARN] dControl.exe is not distributed; obtain it from Sordum.' -ForegroundColor Yellow
}

if($failures.Count){
    Write-Host ''
    Write-Host ('FAILED: {0} check(s)' -f $failures.Count) -ForegroundColor Red
    exit 1
}
Write-Host ''
Write-Host 'All package checks passed.' -ForegroundColor Green
exit 0
