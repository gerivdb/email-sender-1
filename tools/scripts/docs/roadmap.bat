@echo off
REM Script batch pour faciliter l'utilisation du script PowerShell Update-Roadmap-Final.ps1

setlocal enabledelayedexpansion

set "taskid="
set "complete="
set "start="
set "note="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="list" (
    goto list_tasks
) else if /i "%~1"=="help" (
    goto show_help
) else if /i "%~1"=="-task" (
    set "taskid=-TaskId %~2"
    shift
) else if /i "%~1"=="-complete" (
    set "complete=-Complete"
) else if /i "%~1"=="-start" (
    set "start=-Start"
) else if /i "%~1"=="-note" (
    set "note=-Note '%~2'"
    shift
)
shift
goto parse_args

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Update-Roadmap-Final.ps1" %taskid% %complete% %start% %note%
goto end

:list_tasks
powershell -ExecutionPolicy Bypass -Command "& {$data = Get-Content -Path '%~dp0roadmap-data.json' -Raw | ConvertFrom-Json; Write-Host 'Liste des tâches de la roadmap:'; foreach ($category in $data.categories) {Write-Host \"`nCatégorie $($category.id): $($category.name) - Progression: $($category.progress)%\"; foreach ($task in $category.tasks) {$status = if ($task.completed) {'[TERMINÉ]'} elseif ($task.startDate) {'[EN COURS]'} else {'[À FAIRE]'}; Write-Host \"  $($task.id). $status $($task.description)\";}}}"
goto end

:show_help
echo Utilisation du script roadmap.bat:
echo   roadmap [options]
echo.
echo Options:
echo   list                    : Affiche la liste des tâches
echo   help                    : Affiche cette aide
echo   -task ID                : ID de la tâche à mettre à jour (ex: 1.1, 2.3, etc.)
echo   -complete               : Marque la tâche comme terminée
echo   -start                  : Marque la tâche comme démarrée
echo   -note "texte"           : Ajoute une note à la tâche
echo.
echo Exemples:
echo   roadmap                 : Met à jour la roadmap
echo   roadmap list            : Liste toutes les tâches
echo   roadmap -task 1.1 -start : Marque la tâche 1.1 comme démarrée
echo   roadmap -task 1.1 -complete : Marque la tâche 1.1 comme terminée
echo   roadmap -task 1.1 -note "Mon commentaire" : Ajoute une note à la tâche 1.1

:end
endlocal
