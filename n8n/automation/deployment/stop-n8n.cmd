@echo off
echo Arret de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\stop-n8n.ps1" %*
