@echo off
setlocal

echo ===================================
echo Finalisation de l'installation de Hygen
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup\finalize-hygen-installation.ps1

echo Options disponibles:
echo 1. Verifier uniquement
echo 2. Verifier et corriger
echo 3. Verifier et corriger (sans test propre)
echo Q. Quitter
echo.

set /p choice="Votre choix (1-3, Q): "

if "%choice%"=="1" (
    echo.
    echo Verification de l'installation de Hygen...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else if "%choice%"=="2" (
    echo.
    echo Verification et correction de l'installation de Hygen...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Fix
) else if "%choice%"=="3" (
    echo.
    echo Verification et correction de l'installation de Hygen (sans test propre)...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Fix -SkipCleanTest
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
    echo Finalisation echouee!
    exit /b 1
) else (
    echo.
    echo Finalisation terminee.
    echo.
    echo Appuyez sur une touche pour continuer...
    pause > nul
    exit /b 0
)

endlocal
