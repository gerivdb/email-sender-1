@echo off
REM Script pour configurer l'environnement de développement pour Hygen
REM Auteur: MCP Team
REM Date de création: 2023-05-15

echo Configuration de l'environnement de développement pour Hygen...
powershell -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\setup\ensure-hygen-environment.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la configuration de l'environnement de développement
    exit /b %ERRORLEVEL%
)

echo Configuration terminée avec succès
exit /b 0
