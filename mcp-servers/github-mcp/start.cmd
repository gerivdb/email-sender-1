@echo off
echo Démarrage du serveur MCP GitHub...
echo.
echo Ce script va démarrer le serveur MCP GitHub pour interagir avec votre dépôt GitHub.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Démarrer le serveur
mcp-server-github --config "%~dp0config.json"

echo.
echo Serveur arrêté.
echo.
pause