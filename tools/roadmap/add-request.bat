@echo off
REM Script batch pour capturer une demande spontanée et l'ajouter à la roadmap

setlocal enabledelayedexpansion

set "request="
set "category=7"
set "estimated=1-3"
set "start="
set "note="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto check_args
if /i "%~1"=="-request" (
    set "request=-Request '%~2'"
    shift
) else if /i "%~1"=="-category" (
    set "category=-Category %~2"
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
if "%request%"=="" (
    echo Erreur: Le parametre -request est obligatoire.
    goto show_help
)

goto execute

:show_help
echo Utilisation du script add-request.bat:
echo   add-request [options]
echo.
echo Options:
echo   -request "texte"        : Description de la demande (obligatoire)
echo   -category ID            : ID de la categorie (optionnel, defaut: 7)
echo   -estimated "jours"      : Estimation en jours (optionnel, defaut: "1-3")
echo   -start                  : Marquer la demande comme demarree (optionnel)
echo   -note "texte"           : Ajouter une note a la demande (optionnel)
echo.
echo Exemples:
echo   add-request -request "Ajouter une fonctionnalite X"
echo   add-request -request "Corriger le bug Y" -start -note "Urgent"
echo   add-request -request "Ameliorer la performance" -category 3 -estimated "2-4"
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Capture-Request-Simple.ps1" %request% -Category %category% -EstimatedDays %estimated% %start% %note%

:end
endlocal
