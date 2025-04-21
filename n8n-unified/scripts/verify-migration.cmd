@echo off
cd /d "%~dp0"

echo ===================================================
echo Vérification de la migration n8n
echo ===================================================

set SUCCESS=true

echo Vérification de la structure des dossiers...
if not exist ..\config (
    echo [ERREUR] Dossier config manquant.
    set SUCCESS=false
)
if not exist ..\data (
    echo [ERREUR] Dossier data manquant.
    set SUCCESS=false
)
if not exist ..\data\credentials (
    echo [ERREUR] Dossier data\credentials manquant.
    set SUCCESS=false
)
if not exist ..\data\workflows (
    echo [ERREUR] Dossier data\workflows manquant.
    set SUCCESS=false
)
if not exist ..\docker (
    echo [ERREUR] Dossier docker manquant.
    set SUCCESS=false
)
if not exist ..\docker\docker-compose.yml (
    echo [ERREUR] Fichier docker-compose.yml manquant.
    set SUCCESS=false
)
if not exist ..\integrations (
    echo [ERREUR] Dossier integrations manquant.
    set SUCCESS=false
)
if not exist ..\scripts (
    echo [ERREUR] Dossier scripts manquant.
    set SUCCESS=false
)
if not exist ..\docs (
    echo [ERREUR] Dossier docs manquant.
    set SUCCESS=false
)

echo.
echo Vérification des fichiers essentiels...
if not exist ..\data\database.sqlite (
    echo [AVERTISSEMENT] Fichier database.sqlite manquant.
)
if not exist ..\data\config (
    echo [AVERTISSEMENT] Fichier config manquant.
)

echo.
echo Vérification des scripts...
if not exist start-n8n-docker.cmd (
    echo [ERREUR] Script start-n8n-docker.cmd manquant.
    set SUCCESS=false
)
if not exist stop-n8n-docker.cmd (
    echo [ERREUR] Script stop-n8n-docker.cmd manquant.
    set SUCCESS=false
)
if not exist backup-workflows.cmd (
    echo [ERREUR] Script backup-workflows.cmd manquant.
    set SUCCESS=false
)
if not exist restore-workflows.cmd (
    echo [ERREUR] Script restore-workflows.cmd manquant.
    set SUCCESS=false
)

echo.
echo Vérification de l'état de n8n...
docker ps | findstr n8n-unified > nul
if %errorlevel% equ 0 (
    echo [OK] Le conteneur n8n-unified est en cours d'exécution.
) else (
    echo [AVERTISSEMENT] Le conteneur n8n-unified n'est pas en cours d'exécution.
)

echo.
if "%SUCCESS%"=="true" (
    echo Vérification terminée avec succès.
    echo Tous les éléments nécessaires sont présents.
) else (
    echo Vérification terminée avec des erreurs.
    echo Veuillez corriger les problèmes signalés.
)
echo ===================================================
