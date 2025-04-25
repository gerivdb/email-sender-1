@echo off
setlocal

echo ===================================
echo Validation des templates Hygen
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup\validate-hygen-templates.ps1

echo Options disponibles:
echo 1. Tester tous les templates
echo 2. Tester le template PowerShell
echo 3. Tester le template Workflow
echo 4. Tester le template Documentation
echo 5. Tester le template Integration
echo 6. Tester tous les templates et conserver les fichiers generes
echo Q. Quitter
echo.

set /p choice="Votre choix (1-6, Q): "

if "%choice%"=="1" (
    echo.
    echo Test de tous les templates...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else if "%choice%"=="2" (
    echo.
    echo Test du template PowerShell...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -TestPowerShell
) else if "%choice%"=="3" (
    echo.
    echo Test du template Workflow...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -TestWorkflow
) else if "%choice%"=="4" (
    echo.
    echo Test du template Documentation...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -TestDocumentation
) else if "%choice%"=="5" (
    echo.
    echo Test du template Integration...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -TestIntegration
) else if "%choice%"=="6" (
    echo.
    echo Test de tous les templates et conservation des fichiers generes...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -KeepGeneratedFiles
) else if /i "%choice%"=="Q" (
    echo.
    echo Operation annulee.
    exit /b 0
) else (
    echo.
    echo Choix invalide.
    exit /b 1
)

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Validation echouee!
    exit /b 1
) else (
    echo.
    echo Validation terminee.
    echo.
    echo Appuyez sur une touche pour continuer...
    pause > nul
    exit /b 0
)

endlocal
