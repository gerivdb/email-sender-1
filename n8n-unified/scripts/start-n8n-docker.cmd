@echo off
cd /d "%~dp0"

echo ===================================================
echo Démarrage de n8n avec Docker (version unifiée)
echo ===================================================

cd ..\docker

echo Vérification de l'état de Docker...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERREUR] Docker n'est pas en cours d'exécution ou n'est pas installé.
    echo Veuillez démarrer Docker Desktop et réessayer.
    exit /b 1
)

echo Démarrage de n8n...
docker-compose up -d

echo Vérification de l'état de n8n...
timeout /t 5 /nobreak >nul
docker-compose ps

echo.
echo n8n est accessible à l'adresse: http://localhost:5678
echo.
echo Pour arrêter n8n, exécutez stop-n8n-docker.cmd
echo ===================================================
