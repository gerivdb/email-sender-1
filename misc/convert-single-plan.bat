@echo off
setlocal enabledelayedexpansion

echo ===================================
echo Conversion d'un Plan au Format Standard
echo ===================================
echo.

echo Ce script va convertir un plan de développement au format standard.
echo Le plan original sera archivé dans un sous-dossier "archive".
echo.

set /p PLAN_PATH=Chemin du plan à convertir: 

if not exist "%PLAN_PATH%" (
    echo Le fichier n'existe pas : %PLAN_PATH%
    exit /b 1
)

set /p ARCHIVE=Archiver le plan original ? (O/N) [O]: 
if /i "!ARCHIVE!"=="" set ARCHIVE=O
if /i "!ARCHIVE!"=="O" (
    set ARCHIVE_PARAM=-ArchiveOriginal
) else (
    set ARCHIVE_PARAM=-ArchiveOriginal:$false
)

echo.
echo Conversion en cours...
echo.

powershell -ExecutionPolicy Bypass -File "development\scripts\Convert-SinglePlan.ps1" -PlanPath "%PLAN_PATH%" %ARCHIVE_PARAM%

if %ERRORLEVEL% NEQ 0 (
    echo Une erreur s'est produite lors de la conversion du plan.
    exit /b 1
)

echo.
echo Appuyez sur une touche pour quitter...
pause > nul
