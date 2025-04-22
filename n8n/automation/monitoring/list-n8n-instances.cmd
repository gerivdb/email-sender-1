@echo off
echo Liste des instances n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\list-n8n-instances.ps1" %*
