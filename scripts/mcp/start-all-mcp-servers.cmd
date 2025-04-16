@echo off
echo ===================================================
echo      DEMARRAGE DES SERVEURS MCP EMAIL_SENDER_1
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0start-all-mcp-servers.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
