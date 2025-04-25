@echo off
echo ===================================
echo Demarrage de n8n avec verification des MCP
echo ===================================
echo.

echo [1] Verification des variables d'environnement...
powershell -Command "$env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE='true'; [Environment]::SetEnvironmentVariable('N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE', 'true', 'Process')"
echo Variable N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE definie.
echo.

echo [2] Verification des fichiers batch...
if exist mcp-standard.cmd (
    echo - mcp-standard.cmd : OK
) else (
    echo - mcp-standard.cmd : MANQUANT
)

if exist mcp-notion.cmd (
    echo - mcp-notion.cmd : OK
) else (
    echo - mcp-notion.cmd : MANQUANT
)

if exist gateway.exe.cmd (
    echo - gateway.exe.cmd : OK
) else (
    echo - gateway.exe.cmd : MANQUANT
)

if exist mcp-git-ingest.cmd (
    echo - mcp-git-ingest.cmd : OK
) else (
    echo - mcp-git-ingest.cmd : MANQUANT
)
echo.

echo [3] Verification des identifiants MCP...
if exist .n8n\credentials.db (
    echo - Fichier credentials.db : OK
) else (
    echo - Fichier credentials.db : MANQUANT
    echo Executez le script configure-n8n-mcp.ps1 pour configurer les identifiants MCP.
)
echo.

echo [4] Demarrage de n8n...
echo Une fois n8n demarre, accedez a http://localhost:5678 dans votre navigateur
echo.
echo Appuyez sur Ctrl+C pour arreter n8n
echo.
npx n8n start
