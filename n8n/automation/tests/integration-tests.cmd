@echo off
echo Tests d'integration n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\integration-tests.ps1" %*
