#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les serveurs MCP pour un démarrage automatique.
.DESCRIPTION
    Ce script enregistre les serveurs MCP pour un démarrage automatique au démarrage de Windows
    ou à la connexion de l'utilisateur.
.PARAMETER StartupType
    Type de démarrage (System, User). Par défaut: User.
.PARAMETER Force
    Force l'enregistrement sans demander de confirmation.
.EXAMPLE
    .\register-mcp-startup.ps1 -StartupType System
    Enregistre les serveurs MCP pour un démarrage automatique au démarrage de Windows.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("System", "User")]
    [string]$StartupType = "User",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$startMcpScript = Join-Path -Path $scriptPath -ChildPath "start-mcp-server.ps1"

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

function Register-SystemStartup {
    param (
        [string]$ScriptPath
    )
    
    try {
        # Créer une tâche planifiée pour démarrer les serveurs MCP au démarrage du système
        $taskName = "MCPServersAutoStart"
        $taskDescription = "Démarre automatiquement les serveurs MCP au démarrage du système"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Force"
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Supprimer la tâche si elle existe déjà
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Créer la tâche
        Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings
        
        Write-Log "Tâche planifiée '$taskName' créée avec succès." -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la création de la tâche planifiée: $_" -Level "ERROR"
        return $false
    }
}

function Register-UserStartup {
    param (
        [string]$ScriptPath
    )
    
    try {
        # Créer un raccourci dans le dossier de démarrage de l'utilisateur
        $startupFolder = [System.Environment]::GetFolderPath("Startup")
        $shortcutPath = Join-Path -Path $startupFolder -ChildPath "MCPServersAutoStart.lnk"
        
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Force"
        $shortcut.WorkingDirectory = Split-Path -Parent $ScriptPath
        $shortcut.Description = "Démarre automatiquement les serveurs MCP"
        $shortcut.IconLocation = "powershell.exe,0"
        $shortcut.Save()
        
        Write-Log "Raccourci créé dans le dossier de démarrage: $shortcutPath" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Erreur lors de la création du raccourci: $_" -Level "ERROR"
        return $false
    }
}

# Corps principal du script
try {
    Write-Log "Enregistrement des serveurs MCP pour un démarrage automatique..." -Level "TITLE"
    
    # Vérifier si le script de démarrage existe
    if (-not (Test-Path $startMcpScript)) {
        Write-Log "Script de démarrage non trouvé: $startMcpScript" -Level "ERROR"
        exit 1
    }
    
    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous enregistrer les serveurs MCP pour un démarrage automatique de type $StartupType ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Enregistrement annulé par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Enregistrer le démarrage automatique
    if ($PSCmdlet.ShouldProcess("MCP Servers", "Register for $StartupType startup")) {
        $result = switch ($StartupType) {
            "System" { Register-SystemStartup -ScriptPath $startMcpScript }
            "User" { Register-UserStartup -ScriptPath $startMcpScript }
        }
        
        if ($result) {
            Write-Log "Serveurs MCP enregistrés pour un démarrage automatique de type $StartupType." -Level "SUCCESS"
        }
        else {
            Write-Log "Échec de l'enregistrement des serveurs MCP pour un démarrage automatique." -Level "ERROR"
            exit 1
        }
    }
} catch {
    Write-Log "Erreur lors de l'enregistrement des serveurs MCP pour un démarrage automatique: $_" -Level "ERROR"
    exit 1
}
