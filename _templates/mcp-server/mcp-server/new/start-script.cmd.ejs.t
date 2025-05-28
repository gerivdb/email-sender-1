---
to: "projet/mcp/scripts/start-<%= name %>-mcp.cmd"
---
@echo off
<% if (needsEnv) { 
    const envVarsArray = envVars.split(',').map(v => v.trim());
    envVarsArray.forEach(envVar => {
        const [name, value] = envVar.split('=').map(v => v.trim());
        if (name && value) {
%>
set <%= name %>=<%= value %>
<%
        }
    });
} %>
cd /d "%~dp0"

echo Démarrage du serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>...

<% if (port) { %>
:: Vérifier les arguments
set HTTP_MODE=false
set PORT=<%= port %>

if "%1"=="--http" (
    set HTTP_MODE=true
    if not "%2"=="" set PORT=%2
)

if "%1"=="--port" (
    if not "%2"=="" set PORT=%2
)

:: Démarrer le serveur en fonction du mode
if "%HTTP_MODE%"=="true" (
    echo Mode HTTP activé sur le port %PORT%
    powershell -ExecutionPolicy Bypass -File "start-<%= name %>-mcp.ps1" -Http -Port %PORT%
) else (
    echo Mode STDIO activé
    powershell -ExecutionPolicy Bypass -File "start-<%= name %>-mcp.ps1"
)
<% } else { %>
:: Démarrer le serveur
powershell -ExecutionPolicy Bypass -File "start-<%= name %>-mcp.ps1"
<% } %>

echo Serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> arrêté.
pause
