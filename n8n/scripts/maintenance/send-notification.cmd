@echo off
echo Envoi de notification...
echo.
cd /d "%~dp0"
call n8n\automation\notification\send-notification.cmd %*
