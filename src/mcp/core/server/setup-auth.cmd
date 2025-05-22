@echo off
echo Configuration de l'authentification pour le MCP GCP...
echo.
echo Ce script va vous aider à obtenir un jeton d'accès pour le MCP GCP.
echo Vous serez redirigé vers une page web pour autoriser l'application.
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

node ..\..\servers\gcp-mcp\get-access-token.js
