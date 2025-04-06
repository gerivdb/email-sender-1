@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
cd /d "%~dp0"

echo Démarrage du MCP GitHub...

:: Vérifier si un token GitHub est configuré
if "%GITHUB_TOKEN%"=="" (
    :: Vérifier si un fichier .env existe
    if exist "%~dp0..\..\..\\.env" (
        for /f "tokens=2 delims==" %%a in ('findstr /C:"GITHUB_TOKEN" "%~dp0..\..\..\\.env"') do set GITHUB_TOKEN=%%a
        if not "%GITHUB_TOKEN%"=="" (
            echo Token GitHub trouvé dans le fichier .env
        )
    )
    
    :: Si toujours pas de token, informer l'utilisateur
    if "%GITHUB_TOKEN%"=="" (
        echo Aucun token GitHub trouvé. Le serveur fonctionnera en mode anonyme avec des limites de taux plus strictes.
    )
) else (
    echo Token GitHub configuré
)

:: Lancement du serveur MCP GitHub
mcp-server-github
