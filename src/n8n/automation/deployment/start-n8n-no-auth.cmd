@echo off
echo Demarrage de n8n sans authentification...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\start-n8n-no-auth.ps1"
