# Register-RestoreScheduleTask.ps1
# Script pour enregistrer une tâche planifiée dans le système d'exploitation
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "RestorePointScheduler",
    
    [Parameter(Mandatory = $false)]
    [string]$Description = "Exécute les planifications de points de restauration",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Minute", "Hourly", "Daily", "Weekly", "Monthly", "Once", "AtStartup", "AtLogon")]
    [string]$Frequency = "Hourly",
    
    [Parameter(Mandatory = $false)]
    [int]$Interval = 1,
    
    [Parameter(Mandatory = $false)]
    [switch]$Unregister,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour vérifier si une tâche planifiée existe
function Test-ScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        return $null -ne $task
    } catch {
        return $false
    }
}

# Fonction pour supprimer une tâche planifiée
function Unregister-RestoreScheduleTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    try {
        # Vérifier si la tâche existe
        if (Test-ScheduledTask -TaskName $TaskName) {
            # Supprimer la tâche
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Log "Scheduled task removed: $TaskName" -Level "Info"
            return $true
        } else {
            Write-Log "Scheduled task not found: $TaskName" -Level "Warning"
            return $false
        }
    } catch {
        Write-Log "Error removing scheduled task: $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer une tâche planifiée
function Register-RestoreScheduleTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$TaskName = "RestorePointScheduler",
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "Exécute les planifications de points de restauration",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Minute", "Hourly", "Daily", "Weekly", "Monthly", "Once", "AtStartup", "AtLogon")]
        [string]$Frequency = "Hourly",
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si la tâche existe déjà
    if (Test-ScheduledTask -TaskName $TaskName) {
        if ($Force) {
            # Supprimer la tâche existante
            Unregister-RestoreScheduleTask -TaskName $TaskName
        } else {
            Write-Log "Scheduled task already exists: $TaskName. Use -Force to replace." -Level "Warning"
            return $false
        }
    }
    
    # Chemin du script à exécuter
    $scriptToRun = Join-Path -Path $scriptPath -ChildPath "Invoke-RestoreSchedules.ps1"
    
    if (-not (Test-Path -Path $scriptToRun)) {
        Write-Log "Script not found: $scriptToRun" -Level "Error"
        return $false
    }
    
    # Créer l'action de la tâche
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptToRun`" -UpdateNextRun"
    
    # Créer le déclencheur de la tâche
    $trigger = $null
    
    switch ($Frequency) {
        "Minute" {
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $Interval) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        "Hourly" {
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $Interval) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        "Daily" {
            $trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date -Hour 0 -Minute 0 -Second 0).AddHours(1) -DaysInterval $Interval
        }
        "Weekly" {
            $trigger = New-ScheduledTaskTrigger -Weekly -At (Get-Date -Hour 0 -Minute 0 -Second 0).AddHours(1) -WeeksInterval $Interval -DaysOfWeek Monday
        }
        "Monthly" {
            $trigger = New-ScheduledTaskTrigger -Monthly -At (Get-Date -Hour 0 -Minute 0 -Second 0).AddHours(1) -DaysOfMonth 1
        }
        "Once" {
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
        }
        "AtStartup" {
            $trigger = New-ScheduledTaskTrigger -AtStartup
        }
        "AtLogon" {
            $trigger = New-ScheduledTaskTrigger -AtLogon
        }
    }
    
    # Créer les paramètres de la tâche
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -WakeToRun
    
    # Créer le principal de la tâche (utilisateur qui exécute la tâche)
    $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType S4U -RunLevel Highest
    
    # Créer la tâche
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $Description -Force:$Force
        Write-Log "Scheduled task created: $TaskName" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating scheduled task: $_" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    if ($Unregister) {
        Unregister-RestoreScheduleTask -TaskName $TaskName
    } else {
        Register-RestoreScheduleTask -TaskName $TaskName -Description $Description -Frequency $Frequency -Interval $Interval -Force:$Force
    }
}
