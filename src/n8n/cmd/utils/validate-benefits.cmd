@echo off
setlocal

echo ===================================
echo Validation des benefices de Hygen
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup

echo Options disponibles:
echo 1. Mesurer les benefices de Hygen
echo 2. Collecter les retours des utilisateurs
echo 3. Generer le rapport global de validation
echo 4. Executer toutes les etapes
echo Q. Quitter
echo.

set /p choice="Votre choix (1-4, Q): "

if "%choice%"=="1" (
    echo.
    echo Mesure des benefices de Hygen...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\measure-hygen-benefits.ps1"
) else if "%choice%"=="2" (
    echo.
    echo Collecte des retours des utilisateurs...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\collect-user-feedback.ps1" -Interactive
) else if "%choice%"=="3" (
    echo.
    echo Generation du rapport global de validation...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\generate-validation-report.ps1"
) else if "%choice%"=="4" (
    echo.
    echo Execution de toutes les etapes...
    echo.
    echo Etape 1: Mesure des benefices de Hygen...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\measure-hygen-benefits.ps1"
    echo.
    echo Etape 2: Collecte des retours des utilisateurs...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\collect-user-feedback.ps1"
    echo.
    echo Etape 3: Generation du rapport global de validation...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%\generate-validation-report.ps1"
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
