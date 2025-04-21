@echo off
cd /d "%~dp0"

echo ===================================================
echo Création des liens symboliques pour n8n
echo ===================================================

cd ..\..\

echo Création du lien symbolique pour start-n8n.cmd...
mklink start-n8n.cmd n8n-unified\scripts\start-n8n-docker.cmd

echo Création du lien symbolique pour stop-n8n.cmd...
mklink stop-n8n.cmd n8n-unified\scripts\stop-n8n-docker.cmd

echo.
echo Liens symboliques créés avec succès.
echo ===================================================
