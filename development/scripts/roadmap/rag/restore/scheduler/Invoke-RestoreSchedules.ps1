# Invoke-RestoreSchedules.ps1
# Script pour exécuter les planifications de création de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScheduleName,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateNextRun,
    
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

# Fonction pour exécuter un scriptblock à partir d'une chaîne
function Invoke-ScriptBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptString,
        
        [Parameter(Mandatory = $true)]
        [object]$EventData
    )
    
    try {
        $scriptBlock = [scriptblock]::Create($ScriptString)
        return & $scriptBlock $EventData
    } catch {
        Write-Log "Error executing script: $_" -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si une planification doit être exécutée
function Test-ScheduleDue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Schedule,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Si la planification est forcée, elle est due
    if ($Force) {
        return $true
    }
    
    # Si la planification est désactivée, elle n'est pas due
    if (-not $Schedule.enabled) {
        return $false
    }
    
    # Si la planification a une date de fin et qu'elle est dépassée, elle n'est pas due
    if (-not [string]::IsNullOrEmpty($Schedule.end_time)) {
        $endTime = [DateTime]::Parse($Schedule.end_time)
        if ((Get-Date) -gt $endTime) {
            return $false
        }
    }
    
    # Si la planification a une date de dernière exécution, vérifier si elle est due
    if (-not [string]::IsNullOrEmpty($Schedule.last_run)) {
        $lastRun = [DateTime]::Parse($Schedule.last_run)
        $now = Get-Date
        
        # Vérifier si la planification est due en fonction de sa fréquence
        switch ($Schedule.frequency) {
            "Hourly" {
                $nextRun = $lastRun.AddHours($Schedule.interval)
                return $now -ge $nextRun
            }
            "Daily" {
                $nextRun = $lastRun.AddDays($Schedule.interval)
                return $now -ge $nextRun
            }
            "Weekly" {
                $nextRun = $lastRun.AddDays($Schedule.interval * 7)
                return $now -ge $nextRun
            }
            "Monthly" {
                $nextRun = $lastRun.AddMonths($Schedule.interval)
                return $now -ge $nextRun
            }
            "Custom" {
                # Pour les planifications personnalisées, utiliser l'expression cron
                # Cette vérification est simplifiée et pourrait nécessiter une bibliothèque cron complète
                return $true
            }
            default {
                return $false
            }
        }
    } else {
        # Si la planification n'a jamais été exécutée, elle est due
        return $true
    }
}

# Fonction pour calculer la prochaine exécution d'une planification
function Get-NextScheduledRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Schedule
    )
    
    $now = Get-Date
    
    # Calculer la prochaine exécution en fonction de la fréquence
    switch ($Schedule.frequency) {
        "Hourly" {
            $nextRun = $now.AddHours($Schedule.interval)
            $nextRun = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day $nextRun.Day -Hour $nextRun.Hour -Minute ([int]$Schedule.cron_expression.Split(" ")[0]) -Second 0
            return $nextRun
        }
        "Daily" {
            $nextRun = $now.AddDays($Schedule.interval)
            $cronParts = $Schedule.cron_expression.Split(" ")
            $nextRun = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day $nextRun.Day -Hour ([int]$cronParts[1]) -Minute ([int]$cronParts[0]) -Second 0
            return $nextRun
        }
        "Weekly" {
            # Pour les planifications hebdomadaires, trouver le prochain jour de la semaine spécifié
            $cronParts = $Schedule.cron_expression.Split(" ")
            $daysOfWeek = $cronParts[4].Split(",") | ForEach-Object { [int]$_ }
            
            $nextRun = $now
            $found = $false
            
            # Parcourir les 7 prochains jours pour trouver le prochain jour de la semaine spécifié
            for ($i = 0; $i -lt 7 * $Schedule.interval; $i++) {
                $nextRun = $now.AddDays($i)
                $dayOfWeek = [int]$nextRun.DayOfWeek
                
                if ($daysOfWeek -contains $dayOfWeek) {
                    $found = $true
                    break
                }
            }
            
            if ($found) {
                $nextRun = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day $nextRun.Day -Hour ([int]$cronParts[1]) -Minute ([int]$cronParts[0]) -Second 0
                return $nextRun
            } else {
                return $now.AddDays(7 * $Schedule.interval)
            }
        }
        "Monthly" {
            # Pour les planifications mensuelles, trouver le prochain jour du mois spécifié
            $cronParts = $Schedule.cron_expression.Split(" ")
            $daysOfMonth = $cronParts[2].Split(",") | ForEach-Object { [int]$_ }
            
            $nextRun = $now.AddMonths($Schedule.interval)
            $nextRun = Get-Date -Year $nextRun.Year -Month $nextRun.Month -Day ([int]$daysOfMonth[0]) -Hour ([int]$cronParts[1]) -Minute ([int]$cronParts[0]) -Second 0
            
            # Si le jour spécifié est déjà passé ce mois-ci, passer au mois suivant
            if ($nextRun -lt $now) {
                $nextRun = $nextRun.AddMonths(1)
            }
            
            return $nextRun
        }
        "Custom" {
            # Pour les planifications personnalisées, une implémentation complète de cron serait nécessaire
            # Cette implémentation simplifiée retourne simplement le lendemain à la même heure
            return $now.AddDays(1)
        }
        default {
            return $now.AddDays(1)
        }
    }
}

# Fonction pour vérifier si une planification est dans une fenêtre temporelle
function Test-TimeWindow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Schedule
    )
    
    # Si aucune fenêtre temporelle n'est spécifiée, la planification est toujours dans la fenêtre
    if ($null -eq $Schedule.time_windows -or $Schedule.time_windows.Count -eq 0) {
        return $true
    }
    
    $now = Get-Date
    $currentTime = $now.ToString("HH:mm")
    
    # Vérifier si l'heure actuelle est dans l'une des fenêtres temporelles
    foreach ($window in $Schedule.time_windows) {
        $parts = $window.Split("-")
        
        if ($parts.Count -eq 2) {
            $startTime = $parts[0].Trim()
            $endTime = $parts[1].Trim()
            
            if ($currentTime -ge $startTime -and $currentTime -le $endTime) {
                return $true
            }
        }
    }
    
    return $false
}

# Fonction pour journaliser l'exécution d'une planification
function Write-ScheduleLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScheduleName,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$EventData,
        
        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ""
    )
    
    # Créer le répertoire de journalisation s'il n'existe pas
    $logPath = Join-Path -Path $parentPath -ChildPath "logs"
    
    if (-not (Test-Path -Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    # Générer le nom du fichier de journal
    $logFileName = "schedule_log_$(Get-Date -Format 'yyyyMMdd').json"
    $logFilePath = Join-Path -Path $logPath -ChildPath $logFileName
    
    # Créer l'entrée de journal
    $logEntry = @{
        timestamp = (Get-Date).ToString("o")
        schedule_name = $ScheduleName
        event_data = $EventData
        success = $Success
        error_message = $ErrorMessage
    }
    
    # Charger le journal existant ou créer un nouveau
    if (Test-Path -Path $logFilePath) {
        try {
            $log = Get-Content -Path $logFilePath -Raw | ConvertFrom-Json
        } catch {
            $log = @()
        }
    } else {
        $log = @()
    }
    
    # Ajouter l'entrée au journal
    $log += $logEntry
    
    # Sauvegarder le journal
    try {
        $log | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFilePath -Encoding UTF8
    } catch {
        Write-Log "Error writing schedule log: $_" -Level "Error"
    }
}

# Fonction pour exécuter les planifications
function Invoke-RestoreSchedules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ScheduleName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateNextRun
    )
    
    # Charger les planifications
    $schedules = Get-Schedules
    
    if ($null -eq $schedules -or $schedules.Count -eq 0) {
        Write-Log "No schedules found" -Level "Info"
        return $false
    }
    
    # Filtrer les planifications par nom si spécifié
    if (-not [string]::IsNullOrEmpty($ScheduleName)) {
        $schedules = $schedules | Where-Object { $_.name -eq $ScheduleName }
        
        if ($null -eq $schedules -or $schedules.Count -eq 0) {
            Write-Log "Schedule not found: $ScheduleName" -Level "Warning"
            return $false
        }
    }
    
    Write-Log "Found $($schedules.Count) schedules" -Level "Info"
    
    # Initialiser le compteur de planifications exécutées
    $schedulesExecuted = 0
    
    # Traiter chaque planification
    foreach ($schedule in $schedules) {
        Write-Log "Processing schedule: $($schedule.name)" -Level "Debug"
        
        # Vérifier si la planification doit être exécutée
        $isDue = Test-ScheduleDue -Schedule $schedule -Force:$Force
        
        if (-not $isDue) {
            Write-Log "Schedule not due: $($schedule.name)" -Level "Debug"
            
            # Mettre à jour la prochaine exécution si demandé
            if ($UpdateNextRun) {
                $schedule.next_run = (Get-NextScheduledRun -Schedule $schedule).ToString("o")
            }
            
            continue
        }
        
        # Vérifier si la planification est dans une fenêtre temporelle
        $isInWindow = Test-TimeWindow -Schedule $schedule
        
        if (-not $isInWindow) {
            Write-Log "Schedule not in time window: $($schedule.name)" -Level "Debug"
            continue
        }
        
        # Créer l'objet d'événement
        $eventData = @{
            ScheduleName = $schedule.name
            ScheduleTime = (Get-Date).ToString("o")
            Parameters = $schedule.parameters
        }
        
        # Vérifier si la planification a une condition
        if (-not [string]::IsNullOrEmpty($schedule.condition)) {
            # Exécuter la condition
            $conditionResult = Invoke-ScriptBlock -ScriptString $schedule.condition -EventData $eventData
            
            if (-not $conditionResult) {
                Write-Log "Schedule condition not met: $($schedule.name)" -Level "Debug"
                continue
            }
        }
        
        # Vérifier si la planification a une action
        if (-not [string]::IsNullOrEmpty($schedule.action)) {
            # Exécuter l'action
            Write-Log "Executing action for schedule: $($schedule.name)" -Level "Info"
            
            try {
                $actionResult = Invoke-ScriptBlock -ScriptString $schedule.action -EventData $eventData
                
                if ($actionResult) {
                    Write-Log "Action executed successfully for schedule: $($schedule.name)" -Level "Info"
                    $schedulesExecuted++
                    
                    # Mettre à jour la date de dernière exécution
                    $schedule.last_run = (Get-Date).ToString("o")
                    
                    # Mettre à jour la prochaine exécution
                    $schedule.next_run = (Get-NextScheduledRun -Schedule $schedule).ToString("o")
                    
                    # Journaliser l'exécution réussie
                    Write-ScheduleLog -ScheduleName $schedule.name -EventData $eventData -Success $true
                } else {
                    Write-Log "Action failed for schedule: $($schedule.name)" -Level "Warning"
                    
                    # Journaliser l'échec
                    Write-ScheduleLog -ScheduleName $schedule.name -EventData $eventData -Success $false -ErrorMessage "Action returned false"
                }
            } catch {
                Write-Log "Error executing action for schedule: $($schedule.name): $_" -Level "Error"
                
                # Journaliser l'erreur
                Write-ScheduleLog -ScheduleName $schedule.name -EventData $eventData -Success $false -ErrorMessage $_.ToString()
            }
        } else {
            Write-Log "No action defined for schedule: $($schedule.name)" -Level "Warning"
        }
    }
    
    # Sauvegarder les planifications mises à jour
    Save-Schedules -Schedules $schedules
    
    Write-Log "Executed $schedulesExecuted out of $($schedules.Count) schedules" -Level "Info"
    
    return $schedulesExecuted -gt 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-RestoreSchedules -ScheduleName $ScheduleName -Force:$Force -UpdateNextRun:$UpdateNextRun
}
