@echo off
echo Lancement du script d'auto-confirmation des boites de dialogue "Keep All"...
powershell -ExecutionPolicy Bypass -File "%~dp0..\..\utils\automation\Start-AutoConfirmKeepAll.ps1" %*
if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors du lancement du script. Code d'erreur: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)
echo Script lance avec succes.
echo Pour arreter le script, appuyez sur Ctrl+Alt+Q ou executez: Stop-Process -Name AutoHotkey
