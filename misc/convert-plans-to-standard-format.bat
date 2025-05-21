@echo off
setlocal enabledelayedexpansion

echo ===================================
echo Conversion des Plans au Format Standard
echo ===================================
echo.

echo Ce script va convertir les plans de développement v2 à v5 au format standard.
echo Les plans originaux seront archivés dans un sous-dossier "archive".
echo.

set /p ARCHIVE=Archiver les plans originaux ? (O/N) [O]: 
if /i "!ARCHIVE!"=="" set ARCHIVE=O
if /i "!ARCHIVE!"=="O" (
    set ARCHIVE_PARAM=-ArchiveOriginals
) else (
    set ARCHIVE_PARAM=-ArchiveOriginals:$false
)

set /p FORCE=Forcer l'écrasement des fichiers existants ? (O/N) [N]: 
if /i "!FORCE!"=="" set FORCE=N
if /i "!FORCE!"=="O" (
    set FORCE_PARAM=-Force
) else (
    set FORCE_PARAM=
)

echo.
echo Conversion en cours...
echo.

powershell -ExecutionPolicy Bypass -File "development\scripts\Convert-PlansToStandardFormat.ps1" %ARCHIVE_PARAM% %FORCE_PARAM%

if %ERRORLEVEL% NEQ 0 (
    echo Une erreur s'est produite lors de la conversion des plans.
    exit /b 1
)

echo.
echo Appuyez sur une touche pour quitter...
pause > nul
