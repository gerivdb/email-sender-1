@echo off
setlocal

echo ===================================
echo Tests unitaires pour les templates Hygen MCP
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup\run-mcp-hygen-tests.ps1

echo Options disponibles:
echo 1. Executer les tests avec le chemin par defaut
echo 2. Executer les tests avec un chemin personnalise
echo Q. Quitter
echo.

set /p choice="Votre choix (1-2, Q): "

if "%choice%"=="1" (
    echo.
    echo Execution des tests avec le chemin par defaut...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else if "%choice%"=="2" (
    echo.
    set /p output_path="Chemin du rapport: "
    echo Execution des tests avec le chemin personnalise...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -OutputPath "%output_path%"
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
    echo Tests echoues!
    exit /b 1
) else (
    echo.
    echo Tests termines.
    echo.
    echo Appuyez sur une touche pour continuer...
    pause > nul
    exit /b 0
)

endlocal
