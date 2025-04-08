@echo off
setlocal EnableDelayedExpansion

:: Définir les variables d'environnement
set "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true"

:: Obtenir le chemin absolu du script sans espaces (format 8.3)
for %%i in ("%~dp0") do set "SCRIPT_DIR=%%~si"
cd /d "%SCRIPT_DIR%"

echo Démarrage du MCP Gateway...

:: Simulation du MCP Gateway (puisque le fichier original n'est pas trouvé)
echo Le MCP Gateway est en cours d'exécution (simulation).
echo Ce message est affiché car le fichier gateway.exe.cmd n'a pas été trouvé.
echo Pour une véritable intégration, veuillez installer le MCP Gateway.

:: Maintenir le processus actif
ping -n 30 127.0.0.1 > nul
