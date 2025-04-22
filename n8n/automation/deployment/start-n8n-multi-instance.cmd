@echo off
echo Demarrage de n8n (multi-instance)...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\start-n8n-multi-instance.ps1" %*
