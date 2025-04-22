---
to: mcp/core/server/<%= name %>.ps1
---
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    
.PARAMETER Port
    Port sur lequel le serveur MCP écoute.
    
.PARAMETER LogLevel
    Niveau de journalisation (DEBUG, INFO, WARNING, ERROR).
    
.EXAMPLE
    .\<%= name %>.ps1 -Port 8000
    Démarre le serveur sur le port 8000.
    
.NOTES
    Version: 1.0.0
    Auteur: <%= author || 'MCP Team' %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [int]$Port = 8000,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO"
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
Import-Module -Name (Join-Path -Path $modulesPath -ChildPath "MCPManager.psm1") -Force

# Configuration du serveur
$serverConfig = @{
    Port = $Port
    LogLevel = $LogLevel
    MaxConnections = 10
    Timeout = 30
    AllowedIPs = @("127.0.0.1", "::1")
    EnableCompression = $true
}

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    # Vérifier le niveau de log
    $logLevels = @{
        "DEBUG" = 0
        "INFO" = 1
        "WARNING" = 2
        "ERROR" = 3
    }
    
    if ($logLevels[$Level] -lt $logLevels[$LogLevel]) {
        return
    }
    
    # Formater le message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Écrire dans la console avec la couleur appropriée
    switch ($Level) {
        "DEBUG" { Write-Verbose $logMessage }
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
    }
}

# Fonction principale
function Start-Server {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    Write-Log "Démarrage du serveur <%= name %> sur le port $($serverConfig.Port)..." -Level "INFO"
    
    if ($PSCmdlet.ShouldProcess("Serveur <%= name %>", "Démarrer")) {
        try {
            # Initialiser le serveur MCP
            Initialize-MCPServer -Port $serverConfig.Port -LogLevel $serverConfig.LogLevel
            
            # Enregistrer les outils disponibles
            Register-MCPTools
            
            # Démarrer le serveur
            Start-MCPServer
            
            Write-Log "Serveur <%= name %> démarré avec succès" -Level "INFO"
        }
        catch {
            Write-Log "Erreur lors du démarrage du serveur <%= name %> : $_" -Level "ERROR"
            exit 1
        }
    }
}

# Fonction pour enregistrer les outils disponibles
function Register-MCPTools {
    [CmdletBinding()]
    param()
    
    Write-Log "Enregistrement des outils..." -Level "INFO"
    
    # Exemple d'outil : obtenir des informations système
    Register-MCPTool -Name "get_system_info" -ScriptBlock {
        param($params)
        
        return @{
            os = [System.Environment]::OSVersion.ToString()
            hostname = [System.Environment]::MachineName
            username = [System.Environment]::UserName
            cpu_count = [System.Environment]::ProcessorCount
            memory_total = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
            powershell_version = $PSVersionTable.PSVersion.ToString()
        }
    }
    
    # Exemple d'outil : exécuter une commande PowerShell
    Register-MCPTool -Name "run_powershell_command" -ScriptBlock {
        param($params)
        
        if (-not $params.ContainsKey("command")) {
            return @{
                error = "Le paramètre 'command' est requis"
            }
        }
        
        try {
            $result = Invoke-Expression -Command $params.command
            return @{
                result = $result
                success = $true
            }
        }
        catch {
            return @{
                error = $_.Exception.Message
                success = $false
            }
        }
    }
    
    Write-Log "Outils enregistrés avec succès" -Level "INFO"
}

# Démarrer le serveur
Start-Server
