@echo off
echo ===================================================
echo      EXECUTION DES TESTS UNITAIRES MCP
echo ===================================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0TestOmnibus.ps1" -InstallPester -GenerateReport

echo.
echo Appuyez sur une touche pour fermer cette fenetre...
pause > nul
