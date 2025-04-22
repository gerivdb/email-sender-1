@echo off
setlocal

echo ===================================
echo Validation des scripts d'utilitaires Hygen
echo ===================================
echo.

set SCRIPT_PATH=%~dp0..\..\scripts\setup\validate-hygen-utilities.ps1

echo Options disponibles:
echo 1. Tester tous les scripts d'utilitaires
echo 2. Tester tous les scripts d'utilitaires en mode interactif
echo 3. Tester tous les scripts d'utilitaires avec tests de performance
echo 4. Tester tous les scripts d'utilitaires en mode interactif avec tests de performance
echo 5. Tester tous les scripts d'utilitaires et conserver les fichiers generes
echo Q. Quitter
echo.

set /p choice="Votre choix (1-5, Q): "

if "%choice%"=="1" (
    echo.
    echo Test de tous les scripts d'utilitaires...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
) else if "%choice%"=="2" (
    echo.
    echo Test de tous les scripts d'utilitaires en mode interactif...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Interactive
) else if "%choice%"=="3" (
    echo.
    echo Test de tous les scripts d'utilitaires avec tests de performance...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -PerformanceTest
) else if "%choice%"=="4" (
    echo.
    echo Test de tous les scripts d'utilitaires en mode interactif avec tests de performance...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -Interactive -PerformanceTest
) else if "%choice%"=="5" (
    echo.
    echo Test de tous les scripts d'utilitaires et conservation des fichiers generes...
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
