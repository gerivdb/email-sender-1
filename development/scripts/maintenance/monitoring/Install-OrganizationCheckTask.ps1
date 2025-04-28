#Requires -Version 5.1
<#
.SYNOPSIS
    Installe une tâche planifiée pour vérifier l'organisation des scripts.
.DESCRIPTION
    Ce script installe une tâche planifiée Windows qui exécute régulièrement
    le script Check-ScriptsOrganization.ps1 pour vérifier l'organisation des scripts.
.PARAMETER TaskName
    Nom de la tâche planifiée.
.PARAMETER Frequency
    Fréquence d'exécution de la tâche (Daily, Weekly, Monthly).
.PARAMETER Time
    Heure d'exécution de la tâche (format HH:mm).
.PARAMETER Force
    Force l'installation de la tâche sans demander de confirmation.
.EXAMPLE
    .\Install-OrganizationCheckTask.ps1 -TaskName "CheckScriptsOrganization" -Frequency Daily -Time "09:00" -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-10
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "CheckScriptsOrganization",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly")]
    [string]$Frequency = "Daily",
    
    [Parameter(Mandatory = $false)]
    [string]$Time = "09:00",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour écrire dans le journal
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
    
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Vérifier si l'utilisateur a les droits d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "Ce script doit être exécuté avec des droits d'administrateur." -Level "ERROR"
    Write-Log "Veuillez relancer PowerShell en tant qu'administrateur et réexécuter ce script." -Level "INFO"
    exit 1
}

# Chemin du script de vérification
$scriptDir = $PSScriptRoot
$checkScriptPath = Join-Path -Path $scriptDir -ChildPath "Check-ScriptsOrganization.ps1"

# Vérifier si le script de vérification existe
if (-not (Test-Path -Path $checkScriptPath)) {
    Write-Log "Le script Check-ScriptsOrganization.ps1 n'existe pas: $checkScriptPath" -Level "ERROR"
    exit 1
}

# Créer l'action de la tâche
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$checkScriptPath`" -SendEmail"

# Créer le déclencheur de la tâche
$trigger = switch ($Frequency) {
    "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
    "Weekly" { New-ScheduledTaskTrigger -Weekly -At $Time -DaysOfWeek Monday }
    "Monthly" { New-ScheduledTaskTrigger -Monthly -At $Time -DaysOfMonth 1 }
}

# Créer les paramètres de la tâche
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Vérifier si la tâche existe déjà
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Log "La tâche '$TaskName' existe déjà." -Level "WARNING"
    
    if ($Force -or $PSCmdlet.ShouldProcess($TaskName, "Remplacer la tâche existante")) {
        # Supprimer la tâche existante
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "Tâche existante supprimée." -Level "INFO"
    }
    else {
        Write-Log "Opération annulée." -Level "INFO"
        exit 0
    }
}

# Créer la tâche
if ($PSCmdlet.ShouldProcess($TaskName, "Créer la tâche planifiée")) {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Vérifie l'organisation des scripts de maintenance"
    
    Write-Log "Tâche planifiée '$TaskName' créée avec succès." -Level "SUCCESS"
    Write-Log "  Fréquence: $Frequency" -Level "INFO"
    Write-Log "  Heure: $Time" -Level "INFO"
    Write-Log "  Script: $checkScriptPath" -Level "INFO"
}
else {
    Write-Log "Création de la tâche annulée." -Level "INFO"
}

Write-Log "Installation terminée." -Level "SUCCESS"
