@echo off
cd /d "%~dp0"

echo Analyse du dépôt mem0ai/mem0 avec MCP Git Ingest...

:: Définir les paramètres
set REPO_URL=https://github.com/mem0ai/mem0
set OUTPUT_DIR=output/mem0-analysis
set MAX_FILES=200

:: Exécuter le script d'analyse
call analyze-github-repo.cmd %REPO_URL% %OUTPUT_DIR% %MAX_FILES%

echo Analyse terminée.
pause
