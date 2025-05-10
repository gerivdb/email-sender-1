# Set-RestoreTimeWindow.ps1
# Script pour définir les fenêtres temporelles pour les planifications de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScheduleName,
    
    [Parameter(Mandatory = $false)]
    [string[]]$TimeWindows,
    
    [Parameter(Mandatory = $false)]
    [switch]$Add,
    
    [Parameter(Mandatory = $false)]
    [switch]$Remove,
    
    [Parameter(Mandatory = $false)]
    [switch]$Clear,
    
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

# Fonction pour valider une fenêtre temporelle
function Test-TimeWindow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TimeWindow
    )
    
    # Expression régulière pour valider le format de fenêtre temporelle (HH:MM-HH:MM)
    $timeWindowRegex = "^([01]?[0-9]|2[0-3]):([0-5][0-9])-([01]?[0-9]|2[0-3]):([0-5][0-9])$"
    
    if ($TimeWindow -match $timeWindowRegex) {
        $parts = $TimeWindow.Split("-")
        $startTime = $parts[0]
        $endTime = $parts[1]
        
        # Vérifier que l'heure de début est antérieure à l'heure de fin
        $startDateTime = [DateTime]::ParseExact($startTime, "HH:mm", $null)
        $endDateTime = [DateTime]::ParseExact($endTime, "HH:mm", $null)
        
        return $startDateTime -lt $endDateTime
    }
    
    return $false
}

# Fonction pour définir les fenêtres temporelles d'une planification
function Set-RestoreTimeWindow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScheduleName,
        
        [Parameter(Mandatory = $false)]
        [string[]]$TimeWindows,
        
        [Parameter(Mandatory = $false)]
        [switch]$Add,
        
        [Parameter(Mandatory = $false)]
        [switch]$Remove,
        
        [Parameter(Mandatory = $false)]
        [switch]$Clear,
        
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
    
    # Initialiser les fenêtres temporelles si elles n'existent pas
    if ($null -eq $schedule.time_windows) {
        $schedule.time_windows = @()
    }
    
    # Effacer les fenêtres temporelles si demandé
    if ($Clear) {
        $schedule.time_windows = @()
        Write-Log "Time windows cleared for schedule: $ScheduleName" -Level "Info"
    }
    
    # Ajouter ou remplacer les fenêtres temporelles
    if ($null -ne $TimeWindows -and $TimeWindows.Count -gt 0) {
        # Valider les fenêtres temporelles
        $validTimeWindows = @()
        $invalidTimeWindows = @()
        
        foreach ($timeWindow in $TimeWindows) {
            if (Test-TimeWindow -TimeWindow $timeWindow) {
                $validTimeWindows += $timeWindow
            } else {
                $invalidTimeWindows += $timeWindow
                Write-Log "Invalid time window format: $timeWindow. Expected format: HH:MM-HH:MM" -Level "Warning"
            }
        }
        
        if ($invalidTimeWindows.Count -gt 0 -and -not $Force) {
            Write-Log "Some time windows are invalid. Use -Force to ignore invalid time windows." -Level "Error"
            return $false
        }
        
        if ($Add) {
            # Ajouter les fenêtres temporelles valides
            foreach ($timeWindow in $validTimeWindows) {
                if ($schedule.time_windows -notcontains $timeWindow) {
                    $schedule.time_windows += $timeWindow
                    Write-Log "Time window added: $timeWindow" -Level "Info"
                } else {
                    Write-Log "Time window already exists: $timeWindow" -Level "Debug"
                }
            }
        } elseif ($Remove) {
            # Supprimer les fenêtres temporelles spécifiées
            foreach ($timeWindow in $validTimeWindows) {
                if ($schedule.time_windows -contains $timeWindow) {
                    $schedule.time_windows = $schedule.time_windows | Where-Object { $_ -ne $timeWindow }
                    Write-Log "Time window removed: $timeWindow" -Level "Info"
                } else {
                    Write-Log "Time window not found: $timeWindow" -Level "Debug"
                }
            }
        } else {
            # Remplacer toutes les fenêtres temporelles
            $schedule.time_windows = $validTimeWindows
            Write-Log "Time windows replaced for schedule: $ScheduleName" -Level "Info"
        }
    }
    
    # Mettre à jour la date de dernière modification
    $schedule.last_modified = (Get-Date).ToString("o")
    
    # Sauvegarder les planifications
    $result = Save-Schedules -Schedules $schedules
    
    if ($result) {
        Write-Log "Time windows updated successfully for schedule: $ScheduleName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to update time windows for schedule: $ScheduleName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Set-RestoreTimeWindow -ScheduleName $ScheduleName -TimeWindows $TimeWindows -Add:$Add -Remove:$Remove -Clear:$Clear -Force:$Force
}
