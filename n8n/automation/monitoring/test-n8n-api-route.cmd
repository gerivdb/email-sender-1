@echo off
echo Test d'une route API de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\test-n8n-api-route.ps1" %*
