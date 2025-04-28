@echo off
REM Script batch pour analyser une phase terminée et mettre à jour le journal

setlocal enabledelayedexpansion

set "phaseid="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto check_args
if /i "%~1"=="-phase" (
    set "phaseid=%~2"
    shift
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:check_args
if "%phaseid%"=="" (
    echo Erreur: Le parametre -phase est obligatoire.
    goto show_help
)

goto execute

:show_help
echo Utilisation du script analyze-phase.bat:
echo   analyze-phase [options]
echo.
echo Options:
echo   -phase ID              : ID de la phase a analyser (obligatoire, ex: 1, 2, etc.)
echo   -help                  : Afficher cette aide
echo.
echo Exemples:
echo   analyze-phase -phase 1           # Analyser la phase 1
echo   analyze-phase -phase 2           # Analyser la phase 2
goto end

:execute
powershell -ExecutionPolicy Bypass -File "tools\roadmap\Generate-Journal.ps1" -PhaseId %phaseid%

:end
endlocal
