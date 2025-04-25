@echo off
REM Script batch pour executer Example-Integration.ps1 avec le bon encodage
chcp 65001
powershell -ExecutionPolicy Bypass -File "%~dp0Example-Integration.ps1"
pause
