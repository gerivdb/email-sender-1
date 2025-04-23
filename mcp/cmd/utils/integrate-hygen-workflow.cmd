@echo off
REM Script pour intégrer Hygen dans le processus de développement MCP
REM Auteur: MCP Team
REM Date de création: 2023-05-15

echo Intégration de Hygen dans le processus de développement MCP...
powershell -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\utils\Integrate-HygenWorkflow.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de l'intégration de Hygen dans le processus de développement MCP
    exit /b %ERRORLEVEL%
)

echo Intégration terminée avec succès
exit /b 0
