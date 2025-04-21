@echo off
echo ===================================================
echo      CONFIGURATION DES SERVEURS MCP DANS VS CODE
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0configure-vscode-mcp.ps1"

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
