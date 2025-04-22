@echo off
echo Verification des routes API de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\verify-n8n-api-routes.ps1" %*
