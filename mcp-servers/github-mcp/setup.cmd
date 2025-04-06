@echo off
echo Configuration du serveur MCP GitHub...
echo.
echo Ce script va configurer le serveur MCP GitHub pour interagir avec votre depot GitHub.
echo.
echo Prerequis:
echo 1. Node.js doit etre installe
echo 2. npm doit etre installe
echo.
echo Appuyez sur une touche pour continuer...
pause > nul

:: Executer le script
node "%~dp0setup.js"

echo.
echo Processus termine. Verifiez les instructions ci-dessus.
echo.
pause
