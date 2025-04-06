@echo off
echo Configuration du serveur MCP Gitingest...
echo.
echo Ce script va configurer le serveur MCP Gitingest pour analyser des depots GitHub.
echo.
echo Prerequis:
echo 1. Node.js doit etre installe
echo 2. npm doit etre installe
echo 3. Git doit etre installe
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0setup-gitingest-mcp.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
