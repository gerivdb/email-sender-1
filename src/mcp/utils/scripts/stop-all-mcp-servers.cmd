@echo off
setlocal enabledelayedexpansion

echo =========================================================
echo           ARRÊT DES SERVEURS MCP EMAIL_SENDER_1
echo =========================================================
echo.

:: Obtenir le chemin du répertoire courant
set CURRENT_DIR=%~dp0

:: Arrêter les processus Node.js liés aux serveurs MCP
echo Arrêt des serveurs MCP...

:: Arrêter le serveur MCP Filesystem
echo 1. Arrêt du serveur MCP Filesystem...
taskkill /F /FI "WINDOWTITLE eq MCP Filesystem" /T >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Serveur MCP Filesystem arrêté.
) else (
    echo Le serveur MCP Filesystem n'était pas en cours d'exécution.
)

:: Arrêter tous les processus Node.js liés aux serveurs MCP
echo 2. Arrêt de tous les processus Node.js liés aux serveurs MCP...
taskkill /F /FI "IMAGENAME eq node.exe" /FI "WINDOWTITLE eq MCP*" /T >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Tous les processus Node.js liés aux serveurs MCP ont été arrêtés.
) else (
    echo Aucun processus Node.js lié aux serveurs MCP n'était en cours d'exécution.
)

:: Vérifier si les serveurs sont arrêtés
echo.
echo Vérification des serveurs MCP...
powershell -ExecutionPolicy Bypass -File "%CURRENT_DIR%check-mcp-servers.ps1"

echo.
echo Les serveurs MCP sont arrêtés.
echo.
