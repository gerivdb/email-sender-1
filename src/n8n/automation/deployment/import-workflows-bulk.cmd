@echo off
echo Importation en masse des workflows n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\import-workflows-bulk.ps1" %*
