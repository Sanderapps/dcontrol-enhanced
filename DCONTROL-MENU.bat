@echo off
setlocal EnableExtensions
title dControl Enhanced - Menu Principal

:menu
cls
echo ============================================================
echo                    DCONTROL ENHANCED
echo ============================================================
echo.
echo  [1] Testar integridade do pacote
echo  [2] Verificar status do Defender
echo  [3] Verificar / abrir Tamper Protection
echo  [4] Desabilitar Windows Defender
echo  [5] Ativar Windows Defender
echo  [6] Abrir guia de uso
echo  [7] Abrir pagina oficial do dControl
echo  [8] Abrir repositorio no GitHub
echo  [0] Sair
echo.
choice /c 123456780 /n /m "Escolha uma opcao: "

if errorlevel 9 goto end
if errorlevel 8 goto github
if errorlevel 7 goto vendor
if errorlevel 6 goto docs
if errorlevel 5 goto enable
if errorlevel 4 goto disable
if errorlevel 3 goto tamper
if errorlevel 2 goto status
if errorlevel 1 goto test
goto menu

:test
cls
call "%~dp0TESTAR-PACOTE.bat"
echo.
pause
goto menu

:status
cls
call "%~dp0VERIFICAR-STATUS-DEFENDER.bat"
goto menu

:tamper
cls
call "%~dp0DESATIVAR-TAMPER-PROTECTION.bat"
goto menu

:disable
cls
call "%~dp0DESABILITAR-DEFENDER-ENHANCED.bat"
goto menu

:enable
cls
call "%~dp0ATIVAR-DEFENDER-ENHANCED.bat"
goto menu

:docs
start "" notepad.exe "%~dp0COMO-USAR.txt"
goto menu

:github
start "" "https://github.com/Sanderapps/dcontrol-enhanced"
goto menu

:vendor
start "" "https://www.sordum.org/9480/defender-control-v2-1/"
goto menu

:end
endlocal
exit /b 0
