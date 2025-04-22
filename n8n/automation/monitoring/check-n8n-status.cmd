@echo off
echo Surveillance du port et de l'API n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\check-n8n-status-main.ps1" %*
