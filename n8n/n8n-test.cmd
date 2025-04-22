@echo off
echo Tests d'integration n8n...
echo.
cd /d "%~dp0"
call n8n\automation\tests\integration-tests.cmd %*
