@echo off
echo ===================================================
echo    CONFIGURATION DES SERVEURS MCP POUR CLAUDE DESKTOP
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0configure-claude-desktop-mcp.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
