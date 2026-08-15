@echo off
setlocal
title Desabilitar Windows Defender Enhanced

net session >nul 2>&1
if not "%errorLevel%"=="0" (
    echo [ERRO] Execute este arquivo como Administrador.
    pause
    exit /b 1
)

echo.
echo AVISO: desabilitar o antivirus deixa o computador vulneravel.
echo O processo sera interrompido se Tamper Protection nao puder ser verificado.
echo No dControl, clique em Disable Windows Defender e feche a janela.
echo.
pause

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\dControl-Enhanced.ps1" -Action disable
set "rc=%errorLevel%"
if not "%rc%"=="0" (
    echo.
    echo [ERRO] A desativacao nao foi confirmada. Codigo: %rc%
    pause
    exit /b %rc%
)

echo.
echo [OK] Desativacao confirmada. Reinicie o Windows.
pause
exit /b 0
