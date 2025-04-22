@echo off
echo n8n Manager
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\n8n-manager.ps1" %*
