@echo off
REM Script ultra-simple pour configurer le token GitHub

echo === Configuration ultra-simple du token GitHub ===
echo.
echo Ce script va configurer votre token GitHub dans le fichier .env
echo.

set /p TOKEN=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

echo # Configuration GitHub pour l'integration avec MCP > .env
echo GITHUB_TOKEN=%TOKEN% >> .env
echo GITHUB_OWNER=gerivdb >> .env
echo GITHUB_REPO=email-sender-1 >> .env

echo.
echo Token GitHub configure avec succes dans le fichier .env
echo Vous pouvez maintenant utiliser le serveur MCP GitHub avec votre token.
echo.

pause
