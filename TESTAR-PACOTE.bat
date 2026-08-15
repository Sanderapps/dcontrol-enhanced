@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tests\Test-Package.ps1"
exit /b %errorLevel%
