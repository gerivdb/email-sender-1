#Requires -Version 5.1
<#
.SYNOPSIS
    Planifie des mises à jour automatiques pour les serveurs MCP.
.DESCRIPTION
    Ce script crée une tâche planifiée pour mettre à jour automatiquement les serveurs MCP
    à une fréquence spécifiée.
.PARAMETER Frequency
    Fréquence des mises à jour (Daily, Weekly, Monthly). Par défaut: Weekly.
.PARAMETER DayOfWeek
    Jour de la semaine pour les mises à jour hebdomadaires. Par défaut: Sunday.
.PARAMETER Time
    Heure des mises à jour au format HH:mm. Par défaut: 03:00.
.PARAMETER Force
    Force la création de la tâche sans demander de confirmation.
.EXAMPLE
    .\schedule-mcp-updates.ps1 -Frequency Daily -Time 04:00
    Planifie des mises à jour quotidiennes à 4h du matin.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Frequency = "Weekly",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")]
    [string]$DayOfWeek = "Sunday",
    
    [Parameter(Mandatory = $false)]
    [ValidatePattern("^([01]?[0-9]|2[0-3]):[0-5][0-9]$")]
    [string]$Time = "03:00",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $scriptsRoot).Parent.FullName
$updateScript = Join-Path -Path $mcpRoot -ChildPath "versioning\scripts\update-mcp-components.ps1"

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

function Create-UpdateTask {
    param (
        [string]$ScriptPath,
        [string]$Frequency,
        [string]$DayOfWeek,
        [string]$Time
    )
    
    try {
        # Créer une tâche planifiée pour mettre à jour les serveurs MCP
        $taskName = "MCPServersAutoUpdate"
        $taskDescription = "Met à jour automatiquement les serveurs MCP"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Force"
        
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
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -WakeToRun
        
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
    Write-Log "Planification des mises à jour automatiques des serveurs MCP..." -Level "TITLE"
    
    # Vérifier si le script de mise à jour existe
    if (-not (Test-Path $updateScript)) {
        Write-Log "Script de mise à jour non trouvé: $updateScript" -Level "ERROR"
        exit 1
    }
    
    # Afficher les paramètres
    Write-Log "Paramètres de planification:" -Level "INFO"
    Write-Log "- Fréquence: $Frequency" -Level "INFO"
    if ($Frequency -eq "Weekly") {
        Write-Log "- Jour de la semaine: $DayOfWeek" -Level "INFO"
    }
    Write-Log "- Heure: $Time" -Level "INFO"
    
    # Demander confirmation
    if (-not $Force) {
        $confirmation = Read-Host "Voulez-vous planifier des mises à jour automatiques des serveurs MCP avec ces paramètres ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Planification annulée par l'utilisateur." -Level "WARNING"
            exit 0
        }
    }
    
    # Créer la tâche planifiée
    if ($PSCmdlet.ShouldProcess("MCP Servers", "Schedule automatic updates")) {
        $result = Create-UpdateTask -ScriptPath $updateScript -Frequency $Frequency -DayOfWeek $DayOfWeek -Time $Time
        
        if ($result) {
            Write-Log "Mises à jour automatiques des serveurs MCP planifiées avec succès." -Level "SUCCESS"
        }
        else {
            Write-Log "Échec de la planification des mises à jour automatiques des serveurs MCP." -Level "ERROR"
            exit 1
        }
    }
} catch {
    Write-Log "Erreur lors de la planification des mises à jour automatiques des serveurs MCP: $_" -Level "ERROR"
    exit 1
}
