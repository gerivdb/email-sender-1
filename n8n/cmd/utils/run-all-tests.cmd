@echo off
setlocal

echo ===================================
echo Execution de tous les tests Hygen
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup\run-all-hygen-tests.ps1

echo Options disponibles:
echo 1. Executer tous les tests
echo 2. Executer tous les tests en mode interactif
echo 3. Executer tous les tests avec tests de performance
echo 4. Executer tous les tests en mode interactif avec tests de performance
echo 5. Executer tous les tests et conserver les fichiers generes
echo Q. Quitter
echo.

set /p choice="Votre choix (1-5, Q): "

if "%choice%"=="1" (
    echo.
    echo Execution de tous les tests...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else if "%choice%"=="2" (
    echo.
    echo Execution de tous les tests en mode interactif...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Interactive
) else if "%choice%"=="3" (
    echo.
    echo Execution de tous les tests avec tests de performance...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -PerformanceTest
) else if "%choice%"=="4" (
    echo.
    echo Execution de tous les tests en mode interactif avec tests de performance...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Interactive -PerformanceTest
) else if "%choice%"=="5" (
    echo.
    echo Execution de tous les tests et conservation des fichiers generes...
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
