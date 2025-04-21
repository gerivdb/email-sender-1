@echo off
cd /d "%~dp0"

echo Installation des nœuds communautaires...

npx n8n community-nodes add n8n-nodes-base.mcpClient

echo Installation terminée.
