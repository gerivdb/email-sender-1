# Set-RestoreSchedulePriority.ps1
# Script pour définir la priorité des planifications de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScheduleName,
    
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [int]$Priority,
    
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

# Fonction pour obtenir le chemin du fichier de configuration des planifications
function Get-SchedulesConfigPath {
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    $schedulesPath = Join-Path -Path $configPath -ChildPath "schedules"
    return Join-Path -Path $schedulesPath -ChildPath "schedules.json"
}

# Fonction pour charger les planifications existantes
function Get-Schedules {
    [CmdletBinding()]
    param()
    
    $schedulesPath = Get-SchedulesConfigPath
    
    if (Test-Path -Path $schedulesPath) {
        try {
            $schedules = Get-Content -Path $schedulesPath -Raw | ConvertFrom-Json
            return $schedules
        } catch {
            Write-Log "Error loading schedules: $_" -Level "Error"
            return @()
        }
    } else {
        return @()
    }
}

# Fonction pour sauvegarder les planifications
function Save-Schedules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Schedules
    )
    
    $schedulesPath = Get-SchedulesConfigPath
    
    try {
        $Schedules | ConvertTo-Json -Depth 10 | Out-File -FilePath $schedulesPath -Encoding UTF8
        Write-Log "Schedules saved to: $schedulesPath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error saving schedules: $_" -Level "Error"
        return $false
    }
}

# Fonction pour définir la priorité d'une planification
function Set-RestoreSchedulePriority {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScheduleName,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 10)]
        [int]$Priority,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Charger les planifications
    $schedules = Get-Schedules
    
    # Vérifier si la planification existe
    $schedule = $schedules | Where-Object { $_.name -eq $ScheduleName }
    
    if ($null -eq $schedule) {
        Write-Log "Schedule not found: $ScheduleName" -Level "Error"
        return $false
    }
    
    # Vérifier si la priorité est différente
    if ($schedule.priority -eq $Priority) {
        Write-Log "Schedule already has priority $Priority: $ScheduleName" -Level "Info"
        return $true
    }
    
    # Mettre à jour la priorité
    $oldPriority = $schedule.priority
    $schedule.priority = $Priority
    
    # Mettre à jour la date de dernière modification
    $schedule.last_modified = (Get-Date).ToString("o")
    
    # Sauvegarder les planifications
    $result = Save-Schedules -Schedules $schedules
    
    if ($result) {
        Write-Log "Priority updated from $oldPriority to $Priority for schedule: $ScheduleName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to update priority for schedule: $ScheduleName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-RestoreSchedulePriority -ScheduleName $ScheduleName -Priority $Priority -Force:$Force
}
