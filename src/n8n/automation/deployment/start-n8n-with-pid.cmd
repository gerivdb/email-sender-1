@echo off
echo Demarrage de n8n avec gestion du PID...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\start-n8n-with-pid.ps1" %*
