#Requires -Version 5.1
<#
.SYNOPSIS
    Installe une tÃ¢che planifiÃ©e pour vÃ©rifier l'organisation des scripts.
.DESCRIPTION
    Ce script installe une tÃ¢che planifiÃ©e Windows qui exÃ©cute rÃ©guliÃ¨rement
    le script Check-ScriptsOrganization.ps1 pour vÃ©rifier l'organisation des scripts.
.PARAMETER TaskName
    Nom de la tÃ¢che planifiÃ©e.
.PARAMETER Frequency
    FrÃ©quence d'exÃ©cution de la tÃ¢che (Daily, Weekly, Monthly).
.PARAMETER Time
    Heure d'exÃ©cution de la tÃ¢che (format HH:mm).
.PARAMETER Force
    Force l'installation de la tÃ¢che sans demander de confirmation.
.EXAMPLE
    .\Install-OrganizationCheckTask.ps1 -TaskName "CheckScriptsOrganization" -Frequency Daily -Time "09:00" -Force
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-10
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

# Fonction pour Ã©crire dans le journal
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

# VÃ©rifier si l'utilisateur a les droits d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "Ce script doit Ãªtre exÃ©cutÃ© avec des droits d'administrateur." -Level "ERROR"
    Write-Log "Veuillez relancer PowerShell en tant qu'administrateur et rÃ©exÃ©cuter ce script." -Level "INFO"
    exit 1
}

# Chemin du script de vÃ©rification
$scriptDir = $PSScriptRoot
$checkScriptPath = Join-Path -Path $scriptDir -ChildPath "Check-ScriptsOrganization.ps1"

# VÃ©rifier si le script de vÃ©rification existe
if (-not (Test-Path -Path $checkScriptPath)) {
    Write-Log "Le script Check-ScriptsOrganization.ps1 n'existe pas: $checkScriptPath" -Level "ERROR"
    exit 1
}

# CrÃ©er l'action de la tÃ¢che
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$checkScriptPath`" -SendEmail"

# CrÃ©er le dÃ©clencheur de la tÃ¢che
$trigger = switch ($Frequency) {
    "Daily" { New-ScheduledTaskTrigger -Daily -At $Time }
    "Weekly" { New-ScheduledTaskTrigger -Weekly -At $Time -DaysOfWeek Monday }
    "Monthly" { New-ScheduledTaskTrigger -Monthly -At $Time -DaysOfMonth 1 }
}

# CrÃ©er les paramÃ¨tres de la tÃ¢che
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Log "La tÃ¢che '$TaskName' existe dÃ©jÃ ." -Level "WARNING"
    
    if ($Force -or $PSCmdlet.ShouldProcess($TaskName, "Remplacer la tÃ¢che existante")) {
        # Supprimer la tÃ¢che existante
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "TÃ¢che existante supprimÃ©e." -Level "INFO"
    }
    else {
        Write-Log "OpÃ©ration annulÃ©e." -Level "INFO"
        exit 0
    }
}

# CrÃ©er la tÃ¢che
if ($PSCmdlet.ShouldProcess($TaskName, "CrÃ©er la tÃ¢che planifiÃ©e")) {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "VÃ©rifie l'organisation des scripts de maintenance"
    
    Write-Log "TÃ¢che planifiÃ©e '$TaskName' crÃ©Ã©e avec succÃ¨s." -Level "SUCCESS"
    Write-Log "  FrÃ©quence: $Frequency" -Level "INFO"
    Write-Log "  Heure: $Time" -Level "INFO"
    Write-Log "  Script: $checkScriptPath" -Level "INFO"
}
else {
    Write-Log "CrÃ©ation de la tÃ¢che annulÃ©e." -Level "INFO"
}

Write-Log "Installation terminÃ©e." -Level "SUCCESS"
