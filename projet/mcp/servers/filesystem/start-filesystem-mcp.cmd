@echo off
REM Script pour démarrer le serveur MCP Filesystem localement
cd /d %~dp0
npx @modelcontextprotocol/server-filesystem --config config.json
