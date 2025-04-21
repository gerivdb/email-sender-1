@echo off
echo Démarrage de n8n avec les serveurs MCP...
powershell -ExecutionPolicy Bypass -File "%~dp0McpN8nIntegration.ps1" -N8nUrl "http://localhost:5678" -ApiKey "" -McpPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp" -Action Start
echo n8n démarré avec les serveurs MCP.
