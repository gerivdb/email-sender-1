@echo off
echo Verification de la presence des workflows n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\verify-workflows.ps1" %*
