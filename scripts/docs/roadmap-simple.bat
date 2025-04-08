@echo off
REM Script batch simplifié pour faciliter l'utilisation du script PowerShell Update-Roadmap-Simple.ps1

setlocal enabledelayedexpansion

set "taskid="
set "complete="
set "start="
set "note="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-task" (
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
powershell -ExecutionPolicy Bypass -File "%~dp0Update-Roadmap-Simple.ps1" %taskid% %complete% %start% %note%

endlocal
