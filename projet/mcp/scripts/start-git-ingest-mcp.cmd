@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du serveur MCP Git Ingest...

:: Vérifier les arguments
set HTTP_MODE=false
set PORT=8001

if "%1"=="--http" (
    set HTTP_MODE=true
    if not "%2"=="" set PORT=%2
)

if "%1"=="--port" (
    if not "%2"=="" set PORT=%2
)

:: Démarrer le serveur en fonction du mode
if "%HTTP_MODE%"=="true" (
    echo Mode HTTP activé sur le port %PORT%
    powershell -ExecutionPolicy Bypass -File "start-git-ingest-mcp.ps1" -Http -Port %PORT%
) else (
    echo Mode STDIO activé
    powershell -ExecutionPolicy Bypass -File "start-git-ingest-mcp.ps1"
)

echo Serveur MCP Git Ingest arrêté.
pause
