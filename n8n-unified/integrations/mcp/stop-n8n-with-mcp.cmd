@echo off
echo Arrêt de n8n...
powershell -ExecutionPolicy Bypass -File "%~dp0McpN8nIntegration.ps1" -N8nUrl "http://localhost:5678" -ApiKey "" -McpPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp" -Action Stop
echo n8n arrêté.
