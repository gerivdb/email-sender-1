@echo off
cd /d "%~dp0"

echo ===================================================
echo Exécution des tests unitaires n8n-unified
echo ===================================================

powershell -ExecutionPolicy Bypass -File ".\Run-Tests.ps1"

echo ===================================================
