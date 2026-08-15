@echo off
setlocal
title Gerenciar Tamper Protection

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\Desativar-TamperProtection.ps1"
set "rc=%errorLevel%"
if not "%rc%"=="0" echo [AVISO] Tamper Protection nao foi confirmado como desativado.
pause
exit /b %rc%
