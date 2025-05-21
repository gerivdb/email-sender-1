@echo off
setlocal enabledelayedexpansion

echo ===================================
echo Générateur de Plan de Développement
echo ===================================
echo.

set /p VERSION="Numéro de version du plan (ex: v24): "
set /p TITLE="Titre du plan de développement: "
set /p DESCRIPTION="Description du plan (objectif principal): "
set /p PHASES="Nombre de phases (1-6): "

powershell -ExecutionPolicy Bypass -File "development\scripts\Generate-PlanDevUTF8.ps1" -Version "%VERSION%" -Title "%TITLE%" -Description "%DESCRIPTION%" -Phases %PHASES%

if %ERRORLEVEL% NEQ 0 (
    echo Une erreur s'est produite lors de la génération du plan.
    exit /b 1
)

echo.
echo Appuyez sur une touche pour quitter...
pause > nul
