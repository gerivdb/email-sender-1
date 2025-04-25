@echo off
echo Arret de n8n (instance)...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\stop-n8n-instance.ps1" %*
