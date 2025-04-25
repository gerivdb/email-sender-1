@echo off
REM Script batch pour mettre à jour les tests unitaires pour la compatibilité multi-terminaux

setlocal enabledelayedexpansion

set "tests_folder=.\tests"
set "whatif="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-folder" (
    set "tests_folder=%~2"
    shift
) else if /i "%~1"=="-whatif" (
    set "whatif=-WhatIf"
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Utilisation du script update-terminal-tests.bat:
echo   update-terminal-tests [options]
echo.
echo Options:
echo   -folder "chemin"        : Dossier de tests (défaut: .\tests)
echo   -whatif                 : Simuler les modifications sans les appliquer
echo   -help                   : Afficher cette aide
echo.
echo Exemples:
echo   update-terminal-tests                 : Mettre à jour les tests unitaires
echo   update-terminal-tests -whatif         : Simuler la mise à jour
echo   update-terminal-tests -folder ".\tests\custom" : Mettre à jour un dossier spécifique
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Update-TerminalTests.ps1" -TestsFolder "%tests_folder%" %whatif%

:end
endlocal
