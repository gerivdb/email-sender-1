@echo off
REM Script pour démarrer le serveur MCP GitHub pour notre projet
REM Ce script permet d'accéder aux dépôts GitHub via le Model Context Protocol

echo Démarrage du serveur MCP GitHub...

REM Vérification de l'installation de MCP GitHub
where mcp-server-github >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Le serveur MCP GitHub n'est pas installé.
    echo Installation en cours...
    npm install -g @modelcontextprotocol/server-github
    if %ERRORLEVEL% NEQ 0 (
        echo Échec de l'installation. Veuillez installer manuellement avec :
        echo npm install -g @modelcontextprotocol/server-github
        exit /b 1
    )
    echo Installation réussie.
)

REM Vérifier si un token GitHub est configuré
if "%GITHUB_TOKEN%"=="" (
    REM Vérifier si un fichier .env existe
    if exist "%~dp0..\..\\.env" (
        for /f "tokens=2 delims==" %%a in ('findstr /C:"GITHUB_TOKEN" "%~dp0..\..\\.env"') do set GITHUB_TOKEN=%%a
        if not "%GITHUB_TOKEN%"=="" (
            echo Token GitHub trouvé dans le fichier .env
        )
    )
    
    REM Si toujours pas de token, informer l'utilisateur
    if "%GITHUB_TOKEN%"=="" (
        echo Aucun token GitHub trouvé. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes.
    )
) else (
    echo Token GitHub configuré
)

echo.
echo Démarrage du serveur MCP GitHub...
echo Le serveur sera accessible pour Claude et d'autres modèles d'IA.
echo Appuyez sur Ctrl+C pour arrêter le serveur.
echo.

REM Lancement du serveur
mcp-server-github

REM Ce script ne devrait jamais atteindre cette ligne sauf en cas d'erreur
echo Le serveur s'est arrêté de manière inattendue.
pause
