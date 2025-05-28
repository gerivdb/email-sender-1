---
to: "projet/mcp/servers/<%= name %>/start-<%= name %>-mcp.ps1"
---
#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>.
.DESCRIPTION
    Ce script permet de démarrer le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> qui <%= description.toLowerCase() %>.
<% if (port) { %>
.PARAMETER Http
    Démarre le serveur en mode HTTP au lieu de STDIO.
.PARAMETER Port
    Spécifie le port à utiliser pour le mode HTTP. Par défaut: <%= port %>.
<% } %>
.EXAMPLE
    .\start-<%= name %>-mcp.ps1
    Démarre le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %><% if (!port) { %> en mode STDIO<% } %>.
<% if (port) { %>
.EXAMPLE
    .\start-<%= name %>-mcp.ps1 -Http -Port <%= parseInt(port) + 1 %>
    Démarre le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> en mode HTTP sur le port <%= parseInt(port) + 1 %>.
<% } %>
#>

[CmdletBinding()]
param (
<% if (port) { %>
    [Parameter(Mandatory = $false)]
    [switch]$Http,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = <%= port %>
<% } %>
)

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

try {
    # Chemin du répertoire racine du projet
    $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\"
    $projectRoot = (Resolve-Path $projectRoot).Path
    
    # Chemin du fichier de configuration
    $configPath = Join-Path -Path $projectRoot -ChildPath "projet\mcp\config\servers\<%= name %>.json"
    
    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path $configPath)) {
        Write-Log "Le fichier de configuration $configPath n'existe pas." -Level "ERROR"
        exit 1
    }
    
<% if (needsEnv) { %>
    # Définir les variables d'environnement
<% 
    const envVarsArray = envVars.split(',').map(v => v.trim());
    envVarsArray.forEach(envVar => {
        const [name, value] = envVar.split('=').map(v => v.trim());
        if (name && value) {
%>
    $env:<%= name %> = "<%= value %>"
<%
        }
    });
%>
<% } %>
    
    # Démarrer le serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>
<% if (port) { %>
    if ($Http) {
        Write-Log "Démarrage du serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> en mode HTTP sur le port $Port..." -Level "INFO"
        
        # Créer les répertoires nécessaires s'ils n'existent pas
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
<% if (name === 'git-ingest') { %>
        if (-not (Test-Path $config.outputDir)) {
            New-Item -ItemType Directory -Path $config.outputDir -Force | Out-Null
            Write-Log "Répertoire de sortie créé: $($config.outputDir)" -Level "INFO"
        }
        
        if (-not (Test-Path $config.cloneDir)) {
            New-Item -ItemType Directory -Path $config.cloneDir -Force | Out-Null
            Write-Log "Répertoire de clonage créé: $($config.cloneDir)" -Level "INFO"
        }
<% } %>
        
        # Démarrer le serveur en mode HTTP
        <%= command %> <%= args.split(',').map(a => a.trim()).join(' ') %> --port $Port
    } else {
        Write-Log "Démarrage du serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> en mode STDIO..." -Level "INFO"
        
        # Démarrer le serveur en mode STDIO
        <%= command %> <%= args.split(',').map(a => a.trim()).join(' ') %> --stdio
    }
<% } else { %>
    Write-Log "Démarrage du serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>..." -Level "INFO"
    
    # Démarrer le serveur
    <%= command %> <%= args.split(',').map(a => a.trim()).join(' ') %>
<% } %>
    
    Write-Log "Serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %> arrêté." -Level "INFO"
} catch {
    Write-Log "Erreur lors du démarrage du serveur MCP <%= name.charAt(0).toUpperCase() + name.slice(1) %>: $_" -Level "ERROR"
    exit 1
}
