@echo off
cd /d "%~dp0"

echo Génération d'un nouveau serveur MCP avec Hygen...

:: Vérifier si les arguments minimaux sont fournis
if "%~1"=="" (
    echo Erreur: Nom du serveur MCP manquant.
    echo Usage: generate-mcp-server.cmd ^<name^> ^<description^> ^<command^> ^<args^> [env-vars] [port] [--no-config] [--no-docs]
    echo Exemple: generate-mcp-server.cmd git-ingest "permet d'explorer et de lire les structures de dépôts GitHub et les fichiers importants" npx "-y,--package=git+https://github.com/adhikasp/mcp-git-ingest,mcp-git-ingest" "N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true" 8001
    exit /b 1
)

if "%~2"=="" (
    echo Erreur: Description du serveur MCP manquante.
    echo Usage: generate-mcp-server.cmd ^<name^> ^<description^> ^<command^> ^<args^> [env-vars] [port] [--no-config] [--no-docs]
    exit /b 1
)

if "%~3"=="" (
    echo Erreur: Commande pour démarrer le serveur manquante.
    echo Usage: generate-mcp-server.cmd ^<name^> ^<description^> ^<command^> ^<args^> [env-vars] [port] [--no-config] [--no-docs]
    exit /b 1
)

if "%~4"=="" (
    echo Erreur: Arguments de la commande manquants.
    echo Usage: generate-mcp-server.cmd ^<name^> ^<description^> ^<command^> ^<args^> [env-vars] [port] [--no-config] [--no-docs]
    exit /b 1
)

:: Récupérer les paramètres
set NAME=%~1
set DESCRIPTION=%~2
set COMMAND=%~3
set ARGS=%~4
set ENV_VARS=%~5
set PORT=%~6

:: Vérifier les options
set NO_CONFIG=
set NO_DOCS=

for %%i in (%*) do (
    if "%%i"=="--no-config" set NO_CONFIG=true
    if "%%i"=="--no-docs" set NO_DOCS=true
)

:: Préparer les arguments pour le script PowerShell
set PS_ARGS=-Name "%NAME%" -Description "%DESCRIPTION%" -Command "%COMMAND%" -Args "%ARGS%"

if not "%ENV_VARS%"=="" set PS_ARGS=%PS_ARGS% -EnvVars "%ENV_VARS%"
if not "%PORT%"=="" set PS_ARGS=%PS_ARGS% -Port %PORT%
if defined NO_CONFIG set PS_ARGS=%PS_ARGS% -NoConfig
if defined NO_DOCS set PS_ARGS=%PS_ARGS% -NoDocs

:: Exécuter le script PowerShell
powershell -ExecutionPolicy Bypass -File "generate-mcp-server.ps1" %PS_ARGS%

echo Génération terminée.
pause
