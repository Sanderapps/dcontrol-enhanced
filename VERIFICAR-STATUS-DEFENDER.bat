@echo off
setlocal
title Verificar Status do Windows Defender

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\dControl-Enhanced.ps1" -Action status
set "rc=%errorLevel%"
if not "%rc%"=="0" echo [ERRO] Nao foi possivel obter o status completo. Codigo: %rc%
pause
exit /b %rc%
