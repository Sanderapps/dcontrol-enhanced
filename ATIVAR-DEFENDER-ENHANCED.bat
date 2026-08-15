@echo off
setlocal
title Ativar Windows Defender Enhanced

net session >nul 2>&1
if not "%errorLevel%"=="0" (
    echo [ERRO] Execute este arquivo como Administrador.
    pause
    exit /b 1
)

echo.
echo O dControl sera aberto. Clique em Enable Windows Defender e feche a janela.
echo As configuracoes extras serao restauradas a partir do snapshot original.
echo.
pause

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\dControl-Enhanced.ps1" -Action enable
set "rc=%errorLevel%"
if not "%rc%"=="0" (
    echo.
    echo [ERRO] A ativacao nao foi confirmada. Codigo: %rc%
    pause
    exit /b %rc%
)

echo.
echo [OK] Ativacao confirmada. Reinicie o Windows e atualize o Defender.
pause
exit /b 0
