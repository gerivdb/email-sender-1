@echo off
REM Script pour démarrer le serveur MCP Filesystem pour notre projet n8n
REM Ce script lance le serveur MCP avec accès au répertoire du projet

echo Démarrage du serveur MCP Filesystem...
echo Répertoire autorisé : %~dp0..\..\

REM Vérification de l'installation de MCP
where mcp-server-filesystem >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Le serveur MCP Filesystem n'est pas installé.
    echo Installation en cours...
    npm install -g @modelcontextprotocol/server-filesystem
    if %ERRORLEVEL% NEQ 0 (
        echo Échec de l'installation. Veuillez installer manuellement avec :
        echo npm install -g @modelcontextprotocol/server-filesystem
        exit /b 1
    )
    echo Installation réussie.
)

echo.
echo Démarrage du serveur MCP Filesystem...
echo Le serveur sera accessible pour Claude et d'autres modèles d'IA.
echo Appuyez sur Ctrl+C pour arrêter le serveur.
echo.

REM Lancement du serveur avec le répertoire du projet
mcp-server-filesystem "%~dp0..\.."

REM Ce script ne devrait jamais atteindre cette ligne sauf en cas d'erreur
echo Le serveur s'est arrêté de manière inattendue.
pause
