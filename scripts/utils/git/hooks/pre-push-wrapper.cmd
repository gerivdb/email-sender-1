@echo off
:: Wrapper amélioré pour le hook pre-push qui appelle le script PowerShell
:: Ce fichier doit être copié dans .git/hooks/pre-push

setlocal EnableDelayedExpansion

echo Exécution du hook pre-push...

:: Obtenir le chemin du répertoire Git avec guillemets pour gérer les espaces
for /f "usebackq delims=" %%i in (`git rev-parse --git-dir`) do set "GIT_DIR=%%i"
for /f "usebackq delims=" %%i in (`git rev-parse --show-toplevel`) do set "PROJECT_ROOT=%%i"

:: Définir le chemin du script PowerShell
set "SCRIPT_PATH=!PROJECT_ROOT!\scripts\utils\git\hooks\pre-push.ps1"

:: Vérifier si le script existe
if exist "!SCRIPT_PATH!" (
    :: Exécuter le script PowerShell avec des guillemets pour gérer les espaces
    powershell -ExecutionPolicy Bypass -NoProfile -File "!SCRIPT_PATH!"

    :: Vérifier le code de sortie
    if !ERRORLEVEL! neq 0 (
        echo Erreur lors de l'exécution du hook pre-push
        exit /b !ERRORLEVEL!
    )
) else (
    echo Avertissement: Script pre-push non trouvé à !SCRIPT_PATH!
    echo Le push continuera sans vérification
)

endlocal
exit /b 0
