@echo off
echo Test structurel de n8n...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\test-structure.ps1" %*
