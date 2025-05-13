@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Analyse d'un dépôt GitHub avec MCP Git Ingest...

:: Vérifier si l'URL du dépôt est fournie
if "%~1"=="" (
    echo Erreur: URL du dépôt GitHub manquante.
    echo Usage: analyze-github-repo.cmd ^<repo-url^> [output-dir] [max-files]
    echo Exemple: analyze-github-repo.cmd https://github.com/mem0ai/mem0 output/mem0-analysis 200
    exit /b 1
)

:: Récupérer les paramètres
set REPO_URL=%~1
set OUTPUT_DIR=output/repo-analysis
set MAX_FILES=100

if not "%~2"=="" set OUTPUT_DIR=%~2
if not "%~3"=="" set MAX_FILES=%~3

:: Exécuter le script PowerShell
powershell -ExecutionPolicy Bypass -File "analyze-github-repo.ps1" -RepoUrl "%REPO_URL%" -OutputDir "%OUTPUT_DIR%" -MaxFiles %MAX_FILES%

echo Analyse terminée.
pause
