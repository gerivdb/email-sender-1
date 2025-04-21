@echo off
echo ===================================================
echo      INSTALLATION DES DEPENDANCES MCP EMAIL_SENDER_1
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0install-mcp-dependencies.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
