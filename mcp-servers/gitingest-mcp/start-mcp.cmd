@echo off
echo Demarrage du serveur MCP Gitingest...
echo.
echo Ce script va demarrer le serveur MCP Gitingest pour analyser des depots GitHub.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Demarrer le serveur
node "%~dp0start-mcp.js"

echo.
echo Serveur arrete.
echo.
pause