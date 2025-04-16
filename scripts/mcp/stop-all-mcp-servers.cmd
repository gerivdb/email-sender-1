@echo off
echo ===================================================
echo      ARRET DES SERVEURS MCP EMAIL_SENDER_1
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0stop-all-mcp-servers.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
