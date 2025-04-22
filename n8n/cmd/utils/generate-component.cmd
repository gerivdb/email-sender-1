@echo off
setlocal

echo ===================================
echo Generateur de composants n8n
echo ===================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\utils\Generate-N8nComponent.ps1"

endlocal
