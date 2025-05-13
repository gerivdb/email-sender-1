@echo off
cd /d "%~dp0"

echo Installation et configuration du serveur MCP Git Ingest...

:: Vérifier les arguments
set FORCE=

if "%1"=="--force" set FORCE=true

:: Exécuter le script PowerShell
if defined FORCE (
    powershell -ExecutionPolicy Bypass -File "setup-mcp-git-ingest.ps1" -Force
) else (
    powershell -ExecutionPolicy Bypass -File "setup-mcp-git-ingest.ps1"
)

echo Installation terminée.
pause
