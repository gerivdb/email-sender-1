@echo off
echo Démarrage du MCP GCP...

:: Vérifier si le fichier token.json existe
if not exist "%~dp0\token.json" (
    echo Le fichier token.json n'existe pas.
    echo Vous devez d'abord configurer l'authentification.
    echo Exécutez setup-auth.cmd pour configurer l'authentification.
    exit /b 1
)

:: Configuration des variables d'environnement pour l'authentification
set GOOGLE_APPLICATION_CREDENTIALS=%~dp0\token.json

:: Variables d'environnement pour N8N
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

:: Démarrage du MCP GCP
npx gcp-mcp
