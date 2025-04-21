@echo off
cd /d "%~dp0"

echo Installation du nœud MCP Client...

npx n8n install n8n-nodes-base.mcpClient

echo Installation terminée.
