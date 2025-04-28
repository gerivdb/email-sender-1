#Requires -Version 5.1
<#
.SYNOPSIS
    Planifie des sauvegardes automatiques pour la configuration MCP.
.DESCRIPTION
    Ce script crée une tâche planifiée pour sauvegarder automatiquement la configuration MCP
    à une fréquence spécifiée.
.PARAMETER Frequency
    Fréquence des sauvegardes (Daily, Weekly, Monthly). Par défaut: Daily.
.PARAMETER DayOfWeek
    Jour de la semaine pour les sauvegardes hebdomadaires. Par défaut: Sunday.
.PARAMETER Time
    Heure des sauvegardes au format HH:mm. Par défaut: 02:00.
.PARAMETER CreateZip
    Crée un fichier ZIP au lieu d'un répertoire.
.PARAMETER IncludeData
    Inclut les données en plus de la configuration.
.PARAMETER Force
    Force la création de la tâche sans demander de confirmation.
.EXAMPLE
    .\schedule-mcp-backups.ps1 -Frequency Daily -Time 02:30 -CreateZip
    Planifie des sauvegardes quotidiennes à 2h30 du matin au format ZIP.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Frequency = "Daily",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")]
    [string]$DayOfWeek = "Sunday",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern("^([01]?[0-9]|2[0-3]):[0-5][0-9]$")]
    [string]$Time = "02:00",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateZip,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeData,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$backupScript = Join-Path -Path $scriptPath -ChildPath "backup-mcp-config.ps1"

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

function Create-BackupTask {
    param (
        [string]$ScriptPath,
        [string]$Frequency,
        [string]$DayOfWeek,
        [string]$Time,
        [bool]$CreateZip,
        [bool]$IncludeData
    )
    
    try {
        # Créer une tâche planifiée pour sauvegarder la configuration MCP
        $taskName = "MCPConfigAutoBackup"
        $taskDescription = "Sauvegarde automatiquement la configuration MCP"
        
        # Construire les arguments
        $arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Force"
        
        if ($CreateZip) {
            $arguments += " -CreateZip"
        }
        
        if ($IncludeData) {
            $arguments += " -IncludeData"
        }
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
        
        # Créer le déclencheur en fonction de la fréquence
        $timeParts = $Time -split ":"
        $hour = [int]$timeParts[0]
        $minute = [int]$timeParts[1]
        
        $trigger = switch ($Frequency) {
            "Daily" {
                New-ScheduledTaskTrigger -Daily -At "$Time"
            }
            "Weekly" {
                New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At "$Time"
            }
            "Monthly" {
                New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "$Time"
            }
        }
        
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

# Corps principal du script
try {
    Write-Log "Planification des sauvegardes automatiques de la configuration MCP..." -Level "TITLE"
    
    # Vérifier si le script de sauvegarde existe
    if (-not (Test-Path $backupScript)) {
        Write-Log "Script de sauvegarde non trouvé: $backupScript" -Level "ERROR"
        exit 1
    }
    
    # Afficher les paramètres
    Write-Log "Paramètres de planification:" -Level "INFO"
    Write-Log "- Fréquence: $Frequency" -Level "INFO"
    if ($Frequency -eq "Weekly") {
        Write-Log "- Jour de la semaine: $DayOfWeek" -Level "INFO"
    }
    Write-Log "- Heure: $Time" -Level "INFO"
    Write-Log "- Créer un fichier ZIP: $($CreateZip.ToString())" -Level "INFO"
    Write-Log "- Inclure les données: $($IncludeData.ToString())" -Level "INFO"
    
    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous planifier des sauvegardes automatiques de la configuration MCP avec ces paramètres ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Planification annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Créer la tâche planifiée
    if ($PSCmdlet.ShouldProcess("MCP Configuration", "Schedule automatic backups")) {
        $result = Create-BackupTask -ScriptPath $backupScript -Frequency $Frequency -DayOfWeek $DayOfWeek -Time $Time -CreateZip $CreateZip -IncludeData $IncludeData
        
        if ($result) {
            Write-Log "Sauvegardes automatiques de la configuration MCP planifiées avec succès." -Level "SUCCESS"
        }
        else {
            Write-Log "Échec de la planification des sauvegardes automatiques de la configuration MCP." -Level "ERROR"
            exit 1
        }
    }
} catch {
    Write-Log "Erreur lors de la planification des sauvegardes automatiques de la configuration MCP: $_" -Level "ERROR"
    exit 1
}
