@echo off
echo === Demarrage de BifrostMCP ===
echo.

echo [1] Verification de l'installation...
if not exist "bifrost.config.json" (
    echo - bifrost.config.json : MANQUANT
    echo Executez d'abord le script de configuration.
    exit /b 1
) else (
    echo - bifrost.config.json : OK
)

if not exist "src\mcp\batch\mcp-bifrost.cmd" (
    echo - mcp-bifrost.cmd : MANQUANT
    echo Executez d'abord le script de configuration.
    exit /b 1
) else (
    echo - mcp-bifrost.cmd : OK
)
echo.

echo [2] Demarrage de BifrostMCP...
echo Utilisez la commande "Bifrost MCP: Start Server" dans VSCode pour demarrer le serveur.
echo Ou executez la commande suivante dans PowerShell :
echo.
echo    .\src\mcp\use-mcp.ps1 bifrost
echo.
echo Appuyez sur une touche pour executer cette commande...
pause > nul

powershell -ExecutionPolicy Bypass -File .\src\mcp\use-mcp.ps1 bifrost
