@echo off
REM Script batch pour corriger l'encodage des fichiers de test

setlocal enabledelayedexpansion

set "folder_path=.\tests"
set "recursive="
set "whatif="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-folder" (
    set "folder_path=%~2"
    shift
) else if /i "%~1"=="-recursive" (
    set "recursive=-Recursive"
) else if /i "%~1"=="-whatif" (
    set "whatif=-WhatIf"
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Utilisation du script fix-encoding.bat:
echo   fix-encoding [options]
echo.
echo Options:
echo   -folder "chemin"        : Dossier à traiter (défaut: .\tests)
echo   -recursive              : Traiter les sous-dossiers
echo   -whatif                 : Simuler les modifications sans les appliquer
echo   -help                   : Afficher cette aide
echo.
echo Exemples:
echo   fix-encoding                          : Corriger l'encodage des fichiers de test
echo   fix-encoding -recursive               : Corriger l'encodage de façon récursive
echo   fix-encoding -whatif                  : Simuler la correction
echo   fix-encoding -folder ".\data"         : Corriger un dossier spécifique
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Fix-Encoding.ps1" -FolderPath "%folder_path%" %recursive% %whatif%

:end
endlocal
