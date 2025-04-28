#Requires -Version 5.1
<#
.SYNOPSIS
    Désinstalle les serveurs MCP.
.DESCRIPTION
    Ce script désinstalle les serveurs MCP en arrêtant les serveurs,
    supprimant les tâches planifiées et les raccourcis de démarrage,
    et en supprimant les fichiers si demandé.
.PARAMETER RemoveFiles
    Supprime les fichiers MCP après la désinstallation.
.PARAMETER Force
    Force la désinstallation sans demander de confirmation.
.EXAMPLE
    .\uninstall-mcp.ps1 -RemoveFiles
    Désinstalle les serveurs MCP et supprime les fichiers.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$RemoveFiles,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager"

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Remove-SystemStartup {
    try {
        # Supprimer la tâche planifiée
        $taskName = "MCPServersAutoStart"
        
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Log "Tâche planifiée '$taskName' supprimée avec succès." -Level "SUCCESS"
        }
        else {
            Write-Log "Tâche planifiée '$taskName' non trouvée." -Level "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Erreur lors de la suppression de la tâche planifiée: $_" -Level "ERROR"
        return $false
    }
}

function Remove-UserStartup {
    try {
        # Supprimer le raccourci dans le dossier de démarrage de l'utilisateur
        $startupFolder = [System.Environment]::GetFolderPath("Startup")
        $shortcutPath = Join-Path -Path $startupFolder -ChildPath "MCPServersAutoStart.lnk"
        
        if (Test-Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
            Write-Log "Raccourci supprimé du dossier de démarrage: $shortcutPath" -Level "SUCCESS"
        }
        else {
            Write-Log "Raccourci non trouvé dans le dossier de démarrage." -Level "INFO"
        }
        
        return $true
    }
    catch {
        Write-Log "Erreur lors de la suppression du raccourci: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Désinstallation des serveurs MCP..." -Level "TITLE"
    
    # Demander confirmation
    if (-not $Force) {
        $message = "Voulez-vous désinstaller les serveurs MCP"
        
        if ($RemoveFiles) {
            $message += " et supprimer tous les fichiers"
        }
        
        $message += " ? (O/N)"
        
        $confirmation = Read-Host $message
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Désinstallation annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Importer le module MCPManager
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        # Arrêter tous les serveurs
        if ($PSCmdlet.ShouldProcess("MCP Servers", "Stop all servers")) {
            Write-Log "Arrêt de tous les serveurs MCP..." -Level "INFO"
            Stop-MCPServer -Force
        }
    }
    else {
        Write-Log "Module MCPManager non trouvé: $modulePath" -Level "WARNING"
    }
    
    # Supprimer les tâches planifiées et les raccourcis
    if ($PSCmdlet.ShouldProcess("MCP Servers", "Remove startup tasks")) {
        Write-Log "Suppression des tâches de démarrage automatique..." -Level "INFO"
        Remove-SystemStartup | Out-Null
        Remove-UserStartup | Out-Null
    }
    
    # Supprimer les fichiers si demandé
    if ($RemoveFiles) {
        if ($PSCmdlet.ShouldProcess("MCP Files", "Remove all files")) {
            Write-Log "Suppression des fichiers MCP..." -Level "INFO"
            
            # Supprimer les fichiers MCP
            if (Test-Path $mcpRoot) {
                Remove-Item -Path $mcpRoot -Recurse -Force
                Write-Log "Fichiers MCP supprimés: $mcpRoot" -Level "SUCCESS"
            }
            else {
                Write-Log "Répertoire MCP non trouvé: $mcpRoot" -Level "WARNING"
            }
        }
    }
    
    Write-Log "Désinstallation des serveurs MCP terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de la désinstallation des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
