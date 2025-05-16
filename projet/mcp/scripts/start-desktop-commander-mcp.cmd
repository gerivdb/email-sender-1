@echo off
cd /d "%~dp0..\.."

echo Démarrage du serveur MCP Desktop Commander...

:: Vérifier si le mode HTTP est demandé
set HTTP_MODE=
if "%1"=="--http" (
    set HTTP_MODE=--http
    echo Mode HTTP activé.
)

:: Vérifier si un port spécifique est demandé
set PORT=
if "%1"=="--port" (
    set PORT=--port %2
    echo Port spécifié: %2
)
if "%3"=="--port" (
    set PORT=--port %4
    echo Port spécifié: %4
)

:: Démarrer le serveur MCP Desktop Commander
npx -y @wonderwhy-er/desktop-commander %HTTP_MODE% %PORT%

echo Serveur MCP Desktop Commander démarré.
echo Utilisez Ctrl+C pour arrêter le serveur.
