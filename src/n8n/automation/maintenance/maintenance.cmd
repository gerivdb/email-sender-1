@echo off
echo Maintenance n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\maintenance.ps1" %*
