@echo off
REM Script batch pour faciliter l'utilisation du script PowerShell Update-Roadmap-ASCII.ps1

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
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "Update-Roadmap-ASCII.ps1" %taskid% %complete% %start% %note%
goto end

:list_tasks
powershell -ExecutionPolicy Bypass -Command "& {$data = Get-Content -Path '%~dp0roadmap-data.json' -Raw | ConvertFrom-Json; Write-Host 'Liste des taches de la roadmap:'; foreach ($category in $data.categories) {Write-Host \"`nCategorie $($category.id): $($category.name) - Progression: $($category.progress)%\"; foreach ($task in $category.tasks) {$status = if ($task.completed) {'[TERMINE]'} elseif ($task.startDate) {'[EN COURS]'} else {'[A FAIRE]'}; Write-Host \"  $($task.id). $status $($task.description)\";}}}"
goto end

:show_help
echo Utilisation du script roadmap-ascii.bat:
echo   roadmap-ascii [options]
echo.
echo Options:
echo   list                    : Affiche la liste des taches
echo   help                    : Affiche cette aide
echo   -task ID                : ID de la tache a mettre a jour (ex: 1.1, 2.3, etc.)
echo   -complete               : Marque la tache comme terminee
echo   -start                  : Marque la tache comme demarree
echo   -note "texte"           : Ajoute une note a la tache
echo.
echo Exemples:
echo   roadmap-ascii           : Met a jour la roadmap
echo   roadmap-ascii list      : Liste toutes les taches
echo   roadmap-ascii -task 1.1 -start : Marque la tache 1.1 comme demarree
echo   roadmap-ascii -task 1.1 -complete : Marque la tache 1.1 comme terminee
echo   roadmap-ascii -task 1.1 -note "Mon commentaire" : Ajoute une note a la tache 1.1

:end
endlocal
