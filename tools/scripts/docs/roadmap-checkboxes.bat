@echo off
REM Script batch pour mettre à jour les cases à cocher de la roadmap et analyser les phases terminées

setlocal enabledelayedexpansion

set "taskid="
set "phaseid="
set "complete="
set "start="
set "note="
set "analyze_phase="
set "update_structure="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-task" (
    set "taskid=-TaskId %~2"
    shift
) else if /i "%~1"=="-phase" (
    set "phaseid=-PhaseId %~2"
    shift
) else if /i "%~1"=="-complete" (
    set "complete=-Complete"
) else if /i "%~1"=="-start" (
    set "start=-Start"
) else if /i "%~1"=="-note" (
    set "note=-Note '%~2'"
    shift
) else if /i "%~1"=="-analyze" (
    set "analyze_phase=-AnalyzePhase"
) else if /i "%~1"=="-structure" (
    set "update_structure=-UpdateStructure"
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Utilisation du script roadmap-checkboxes.bat:
echo   roadmap-checkboxes [options]
echo.
echo Options:
echo   -task ID              : ID de la tâche à mettre à jour (ex: 1.1, 2.3, etc.)
echo   -phase ID             : ID de la phase à analyser (ex: 1, 2, etc.)
echo   -complete             : Marque la tâche comme terminée
echo   -start                : Marque la tâche comme démarrée
echo   -note "texte"         : Ajoute une note à la tâche
echo   -analyze              : Analyse une phase (à utiliser avec -phase)
echo   -structure            : Met à jour la structure de la roadmap avec des cases à cocher
echo   -help                 : Affiche cette aide
echo.
echo Exemples:
echo   roadmap-checkboxes -structure                  # Met à jour la structure de la roadmap
echo   roadmap-checkboxes -task 1.1 -start            # Marque la tâche 1.1 comme démarrée
echo   roadmap-checkboxes -task 1.1 -complete         # Marque la tâche 1.1 comme terminée
echo   roadmap-checkboxes -task 1.1 -note "Note"      # Ajoute une note à la tâche 1.1
echo   roadmap-checkboxes -phase 1 -analyze           # Analyse la phase 1
goto end

:execute
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "Update-RoadmapCheckboxes.ps1" %taskid% %phaseid% %complete% %start% %note% %analyze_phase% %update_structure%

:end
endlocal
