@echo off
REM Script batch pour déployer le système de détection automatique des tâches

setlocal enabledelayedexpansion

set "conversations_folder=.\conversations"
set "auto_start="
set "add_to_roadmap="
set "create_shortcuts="
set "verbose="

REM Traitement des arguments
:parse_args
if "%~1"=="" goto execute
if /i "%~1"=="-folder" (
    set "conversations_folder=%~2"
    shift
) else if /i "%~1"=="-auto_start" (
    set "auto_start=-AutoStart"
) else if /i "%~1"=="-add_to_roadmap" (
    set "add_to_roadmap=-AddToRoadmap"
) else if /i "%~1"=="-create_shortcuts" (
    set "create_shortcuts=-CreateShortcuts"
) else if /i "%~1"=="-verbose" (
    set "verbose=-Verbose"
) else if /i "%~1"=="-help" (
    goto show_help
)
shift
goto parse_args

:show_help
echo Utilisation du script deploy.bat:
echo   deploy [options]
echo.
echo Options:
echo   -folder "chemin"        : Dossier de conversations (défaut: .\conversations)
echo   -auto_start             : Démarrer automatiquement la surveillance
echo   -add_to_roadmap         : Ajouter automatiquement les tâches à la roadmap
echo   -create_shortcuts       : Créer des raccourcis sur le bureau
echo   -verbose                : Afficher des informations détaillées
echo   -help                   : Afficher cette aide
echo.
echo Exemples:
echo   deploy                  : Déployer avec les options par défaut
echo   deploy -auto_start -add_to_roadmap : Déployer avec démarrage auto et ajout à la roadmap
echo   deploy -folder "C:\Conversations" : Déployer avec un dossier de conversations personnalisé
goto end

:execute
powershell -ExecutionPolicy Bypass -File "%~dp0Deploy-TaskDetection.ps1" -ConversationsFolder "%conversations_folder%" %auto_start% %add_to_roadmap% %create_shortcuts% %verbose%

:end
endlocal
