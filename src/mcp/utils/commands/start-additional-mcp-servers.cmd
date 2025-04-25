@echo off
echo ===================================================
echo    DEMARRAGE DES SERVEURS MCP SUPPLEMENTAIRES
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0start-additional-mcp-servers.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
