@echo off
cd /d "%~dp0"

echo Démarrage de tous les serveurs MCP...

:: Démarrer le serveur MCP Filesystem
start "MCP Filesystem" cmd /c start-filesystem-mcp.cmd

:: Démarrer le serveur MCP GitHub
start "MCP GitHub" cmd /c start-github-mcp.cmd

:: Démarrer le serveur MCP Git Ingest
start "MCP Git Ingest" cmd /c start-git-ingest-mcp.cmd --http

:: Démarrer le serveur MCP GCP
start "MCP GCP" cmd /c start-gcp-mcp.cmd

:: Démarrer le serveur MCP Notion
start "MCP Notion" cmd /c start-notion-mcp.cmd

:: Démarrer le serveur MCP Gateway
start "MCP Gateway" cmd /c start-gateway-mcp.cmd

echo Tous les serveurs MCP ont été démarrés.
echo Utilisez stop-all-mcp-servers.cmd pour arrêter tous les serveurs.
pause
