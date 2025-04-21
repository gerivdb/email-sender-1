@echo off
cd /d "%~dp0"

echo ===================================================
echo Arrêt de n8n (version unifiée)
echo ===================================================

cd ..\docker

echo Arrêt des conteneurs n8n...
docker-compose down

echo.
echo n8n a été arrêté.
echo ===================================================
