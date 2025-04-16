@echo off
echo ===================================================
echo      DEMARRAGE COMPLET DES SERVEURS MCP
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0start-all-mcp-complete.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
