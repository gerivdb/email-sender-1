@echo off
setlocal enabledelayedexpansion

echo =========================================================
echo           DÉMARRAGE DES SERVEURS MCP EMAIL_SENDER_1
echo =========================================================
echo.

:: Vérifier si Node.js est installé
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Erreur: Node.js n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Node.js avant de continuer.
    exit /b 1
)

:: Obtenir le chemin du répertoire courant
set CURRENT_DIR=%~dp0
cd %CURRENT_DIR%\..\..\..

:: Créer les répertoires nécessaires
if not exist "logs\mcp" mkdir logs\mcp
if not exist "src\mcp\storage\filesystem" mkdir src\mcp\storage\filesystem

:: Vérifier si le fichier de configuration existe
if not exist "projet\config\mcp-config.json" (
    echo Erreur: Le fichier de configuration n'existe pas: projet\config\mcp-config.json
    echo Création d'un fichier de configuration par défaut...
    
    echo {> projet\config\mcp-config.json
    echo   "enabled": true,>> projet\config\mcp-config.json
    echo   "servers": {>> projet\config\mcp-config.json
    echo     "filesystem": {>> projet\config\mcp-config.json
    echo       "enabled": true,>> projet\config\mcp-config.json
    echo       "port": 3000,>> projet\config\mcp-config.json
    echo       "host": "localhost",>> projet\config\mcp-config.json
    echo       "apiKey": "test-api-key",>> projet\config\mcp-config.json
    echo       "logLevel": "info",>> projet\config\mcp-config.json
    echo       "storagePath": "src/mcp/storage/filesystem">> projet\config\mcp-config.json
    echo     },>> projet\config\mcp-config.json
    echo     "github": {>> projet\config\mcp-config.json
    echo       "enabled": false,>> projet\config\mcp-config.json
    echo       "port": 3001,>> projet\config\mcp-config.json
    echo       "host": "localhost",>> projet\config\mcp-config.json
    echo       "apiKey": "test-api-key-github",>> projet\config\mcp-config.json
    echo       "logLevel": "info",>> projet\config\mcp-config.json
    echo       "repositories": [>> projet\config\mcp-config.json
    echo         {>> projet\config\mcp-config.json
    echo           "owner": "augmentcode",>> projet\config\mcp-config.json
    echo           "repo": "mcp",>> projet\config\mcp-config.json
    echo           "branch": "main">> projet\config\mcp-config.json
    echo         }>> projet\config\mcp-config.json
    echo       ]>> projet\config\mcp-config.json
    echo     },>> projet\config\mcp-config.json
    echo     "gcp": {>> projet\config\mcp-config.json
    echo       "enabled": false,>> projet\config\mcp-config.json
    echo       "port": 3002,>> projet\config\mcp-config.json
    echo       "host": "localhost",>> projet\config\mcp-config.json
    echo       "apiKey": "test-api-key-gcp",>> projet\config\mcp-config.json
    echo       "logLevel": "info",>> projet\config\mcp-config.json
    echo       "projectId": "augment-mcp",>> projet\config\mcp-config.json
    echo       "bucketName": "augment-mcp-storage">> projet\config\mcp-config.json
    echo     }>> projet\config\mcp-config.json
    echo   },>> projet\config\mcp-config.json
    echo   "tools": {>> projet\config\mcp-config.json
    echo     "memory": {>> projet\config\mcp-config.json
    echo       "enabled": true,>> projet\config\mcp-config.json
    echo       "defaultProvider": "filesystem">> projet\config\mcp-config.json
    echo     },>> projet\config\mcp-config.json
    echo     "documentation": {>> projet\config\mcp-config.json
    echo       "enabled": true,>> projet\config\mcp-config.json
    echo       "defaultProvider": "filesystem">> projet\config\mcp-config.json
    echo     },>> projet\config\mcp-config.json
    echo     "code": {>> projet\config\mcp-config.json
    echo       "enabled": true,>> projet\config\mcp-config.json
    echo       "defaultProvider": "filesystem">> projet\config\mcp-config.json
    echo     }>> projet\config\mcp-config.json
    echo   },>> projet\config\mcp-config.json
    echo   "logging": {>> projet\config\mcp-config.json
    echo     "level": "info",>> projet\config\mcp-config.json
    echo     "file": true,>> projet\config\mcp-config.json
    echo     "console": true,>> projet\config\mcp-config.json
    echo     "path": "logs/mcp">> projet\config\mcp-config.json
    echo   },>> projet\config\mcp-config.json
    echo   "security": {>> projet\config\mcp-config.json
    echo     "requireApiKey": true,>> projet\config\mcp-config.json
    echo     "allowedOrigins": ["http://localhost:5678", "http://localhost:8080"]>> projet\config\mcp-config.json
    echo   },>> projet\config\mcp-config.json
    echo   "performance": {>> projet\config\mcp-config.json
    echo     "cacheEnabled": true,>> projet\config\mcp-config.json
    echo     "cacheTTL": 3600,>> projet\config\mcp-config.json
    echo     "maxConcurrentRequests": 10>> projet\config\mcp-config.json
    echo   }>> projet\config\mcp-config.json
    echo }>> projet\config\mcp-config.json
    
    echo Fichier de configuration créé avec succès.
)

:: Démarrer le serveur MCP Filesystem
echo 1. Démarrage du serveur MCP Filesystem...
start "MCP Filesystem" /B node src\mcp\servers\filesystem\server.js --port 3000 --host localhost --apiKey test-api-key --logLevel info > logs\mcp\filesystem.log 2>&1
if %ERRORLEVEL% neq 0 (
    echo Erreur lors du démarrage du serveur MCP Filesystem.
) else (
    echo Serveur MCP Filesystem démarré sur localhost:3000.
)

:: Attendre quelques secondes pour que les serveurs démarrent
timeout /t 5 /nobreak > nul

:: Vérifier si les serveurs sont en cours d'exécution
echo.
echo Vérification des serveurs MCP...
powershell -ExecutionPolicy Bypass -File "%CURRENT_DIR%check-mcp-servers.ps1"

echo.
echo Les serveurs MCP sont démarrés. Utilisez Ctrl+C pour les arrêter.
echo.
