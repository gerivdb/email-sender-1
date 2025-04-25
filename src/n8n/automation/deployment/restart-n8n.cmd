@echo off
echo Redemarrage de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\restart-n8n.ps1" %*
