@echo off
echo Test structurel de n8n...
echo.
cd /d "%~dp0"
call n8n\automation\diagnostics\test-structure.cmd %*
