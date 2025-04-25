@echo off
setlocal

echo ===================================
echo Installation de Hygen pour n8n
echo ===================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0..\..\scripts\setup\install-hygen.ps1"

echo.
echo Appuyez sur une touche pour continuer...
pause > nul

endlocal
