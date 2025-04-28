@echo off
set N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
powershell -ExecutionPolicy Bypass -File "%~dp0gateway.ps1" %*
