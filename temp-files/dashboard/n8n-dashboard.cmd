@echo off
echo Tableau de bord n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\n8n-dashboard.ps1" %*
