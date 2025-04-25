@echo off
echo ===================================================
echo      VERIFICATION DES SERVEURS MCP EMAIL_SENDER_1
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0check-mcp-servers-improved.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
