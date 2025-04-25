@echo off
echo Verification des ports n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\check-n8n-ports.ps1" %*
