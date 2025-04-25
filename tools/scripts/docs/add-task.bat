@echo off
REM Script batch pour faciliter l'ajout de tâches à la roadmap

setlocal enabledelayedexpansion

set "category="
set "description="
set "estimated="
set "start="
set "note="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto check_args
if /i "%~1"=="-category" (
    set "category=-CategoryId %~2"
    shift
) else if /i "%~1"=="-description" (
    set "description=-Description '%~2'"
    shift
) else if /i "%~1"=="-estimated" (
    set "estimated=-EstimatedDays '%~2'"
    shift
) else if /i "%~1"=="-start" (
    set "start=-Start"
) else if /i "%~1"=="-note" (
    set "note=-Note '%~2'"
    shift
)
shift
goto parse_args

:check_args
if "%category%"=="" (
    echo Erreur: Le parametre -category est obligatoire.
    goto show_help
)
if "%description%"=="" (
    echo Erreur: Le parametre -description est obligatoire.
    goto show_help
)

goto execute

:show_help
echo Utilisation du script add-task.bat:
echo   add-task [options]
echo.
echo Options:
echo   -category ID            : ID de la categorie (obligatoire, ex: 1, 2, etc.)
echo   -description "texte"    : Description de la tache (obligatoire)
echo   -estimated "jours"      : Estimation en jours (optionnel, ex: "1-2", "3")
echo   -start                  : Marquer la tache comme demarree (optionnel)
echo   -note "texte"           : Ajouter une note a la tache (optionnel)
echo.
echo Exemples:
echo   add-task -category 1 -description "Ma nouvelle tache"
echo   add-task -category 2 -description "Tache complexe" -estimated "3-5" -start
echo   add-task -category 3 -description "Tache avec note" -note "Priorite haute"
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Add-Task.ps1" %category% %description% %estimated% %start% %note%

:end
endlocal
