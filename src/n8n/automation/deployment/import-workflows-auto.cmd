@echo off
echo Importation automatique des workflows n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\import-workflows-auto-main.ps1" %*
