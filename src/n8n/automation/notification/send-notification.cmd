@echo off
echo Envoi de notification...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0\send-notification.ps1" %*
