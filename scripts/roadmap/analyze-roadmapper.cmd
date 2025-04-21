@echo off
echo Analyse du depot GitHub roadmapper...
echo.

cd /d "%~dp0"
node "mcp-servers\gitingest-mcp\analyze-github-repo.js" https://github.com/csgoh/roadmapper

echo.
echo Processus termine. Verifiez les resultats dans le dossier mcp-servers\gitingest-mcp\output
echo.
pause
