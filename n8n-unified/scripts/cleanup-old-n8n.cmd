@echo off
cd /d "%~dp0"

echo ===================================================
echo Nettoyage des anciens fichiers n8n
echo ===================================================

cd ..\..\

echo Ce script va supprimer les anciens fichiers n8n qui ne sont plus nécessaires.
echo Les fichiers suivants seront supprimés :
echo - Tous les scripts start-n8n-*.cmd (sauf start-n8n.cmd)
echo - Tous les scripts reset-n8n-*.cmd
echo - Tous les scripts reinstall-n8n-*.cmd
echo - Le dossier n8n (clone du dépôt GitHub)
echo.
echo ATTENTION : Les données n8n existantes ne seront PAS supprimées.
echo.
set /p confirm=Êtes-vous sûr de vouloir continuer? (o/n): 

if /i not "%confirm%"=="o" (
    echo Opération annulée.
    exit /b 0
)

echo.
echo Suppression des scripts n8n...
del /q start-n8n-debug.cmd 2>nul
del /q start-n8n-default-user.cmd 2>nul
del /q start-n8n-encryption.cmd 2>nul
del /q start-n8n-env.cmd 2>nul
del /q start-n8n-global.cmd 2>nul
del /q start-n8n-import-credentials.cmd 2>nul
del /q start-n8n-local.cmd 2>nul
del /q start-n8n-no-auth.cmd 2>nul
del /q start-n8n-npx.cmd 2>nul
del /q start-n8n-simple.cmd 2>nul
del /q start-n8n-skip-auth.cmd 2>nul
del /q start-n8n-tunnel-env.cmd 2>nul
del /q start-n8n-tunnel-global.cmd 2>nul
del /q start-n8n-tunnel-only.cmd 2>nul
del /q start-n8n-tunnel.cmd 2>nul
del /q reset-n8n-local.cmd 2>nul
del /q reset-n8n.cmd 2>nul
del /q reinstall-n8n-full.cmd 2>nul
del /q reinstall-n8n.cmd 2>nul
del /q install-n8n-local.cmd 2>nul

echo.
echo Suppression du dossier n8n (clone du dépôt GitHub)...
if exist n8n (
    rmdir /s /q n8n
)

echo.
echo Nettoyage terminé.
echo ===================================================
