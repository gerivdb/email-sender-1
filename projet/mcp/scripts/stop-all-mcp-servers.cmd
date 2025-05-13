@echo off
cd /d "%~dp0"

echo Arrêt de tous les serveurs MCP...

:: Arrêter tous les processus MCP
taskkill /f /fi "WINDOWTITLE eq MCP Filesystem*" 2>nul
taskkill /f /fi "WINDOWTITLE eq MCP GitHub*" 2>nul
taskkill /f /fi "WINDOWTITLE eq MCP Git Ingest*" 2>nul
taskkill /f /fi "WINDOWTITLE eq MCP GCP*" 2>nul
taskkill /f /fi "WINDOWTITLE eq MCP Notion*" 2>nul
taskkill /f /fi "WINDOWTITLE eq MCP Gateway*" 2>nul

:: Arrêter les processus Python liés à MCP
taskkill /f /im python.exe /fi "MODULES eq mcp_git_ingest.main*" 2>nul

echo Tous les serveurs MCP ont été arrêtés.
pause
