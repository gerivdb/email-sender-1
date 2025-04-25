@echo off
echo Verification de l'etat de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\check-n8n-pid-status.ps1" %*
