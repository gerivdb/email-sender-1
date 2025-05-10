# Register-RestoreSchedule.ps1
# Script pour enregistrer une planification de création de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScheduleName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "Custom")]
    [string]$Frequency = "Daily",
    
    [Parameter(Mandatory = $false)]
    [int]$Interval = 1,
    
    [Parameter(Mandatory = $false)]
    [string]$CronExpression,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartTime,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndTime,
    
    [Parameter(Mandatory = $false)]
    [string[]]$DaysOfWeek,
    
    [Parameter(Mandatory = $false)]
    [int[]]$DaysOfMonth,
    
    [Parameter(Mandatory = $false)]
    [int[]]$MonthsOfYear,
    
    [Parameter(Mandatory = $false)]
    [string[]]$TimeWindows,
    
    [Parameter(Mandatory = $false)]
    [int]$Priority = 5,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Condition,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Action,
    
    [Parameter(Mandatory = $false)]
    [switch]$Enabled = $true,
    
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

# Fonction pour générer un nom de planification par défaut
function Get-DefaultScheduleName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Frequency,
        
        [Parameter(Mandatory = $true)]
        [int]$Interval
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "RestoreSchedule-$Frequency-$Interval-$timestamp"
}

# Fonction pour obtenir le chemin du fichier de configuration des planifications
function Get-SchedulesConfigPath {
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $schedulesPath = Join-Path -Path $configPath -ChildPath "schedules"
    
    if (-not (Test-Path -Path $schedulesPath)) {
        New-Item -Path $schedulesPath -ItemType Directory -Force | Out-Null
    }
    
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
        Write-Log "Schedules saved to: $schedulesPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving schedules: $_" -Level "Error"
        return $false
    }
}

# Fonction pour valider une expression cron
function Test-CronExpression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CronExpression
    )
    
    # Expression régulière pour valider le format cron
    $cronRegex = "^(\*|([0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-9])|\*\/([0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9]|5[0-9])) (\*|([0-9]|1[0-9]|2[0-3])|\*\/([0-9]|1[0-9]|2[0-3])) (\*|([1-9]|1[0-9]|2[0-9]|3[0-1])|\*\/([1-9]|1[0-9]|2[0-9]|3[0-1])) (\*|([1-9]|1[0-2])|\*\/([1-9]|1[0-2])) (\*|([0-6])|\*\/([0-6]))$"
    
    return $CronExpression -match $cronRegex
}

# Fonction pour convertir une fréquence en expression cron
function ConvertTo-CronExpression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "Custom")]
        [string]$Frequency,
        
        [Parameter(Mandatory = $true)]
        [int]$Interval,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DaysOfWeek,
        
        [Parameter(Mandatory = $false)]
        [int[]]$DaysOfMonth
    )
    
    # Définir l'heure par défaut si non spécifiée
    if ($null -eq $StartTime) {
        $StartTime = Get-Date -Hour 0 -Minute 0 -Second 0
    }
    
    $minute = $StartTime.Minute
    $hour = $StartTime.Hour
    
    # Créer l'expression cron en fonction de la fréquence
    switch ($Frequency) {
        "Hourly" {
            # Toutes les X heures à la minute spécifiée
            if ($Interval -eq 1) {
                return "$minute * * * *"
            } else {
                return "$minute */$Interval * * *"
            }
        }
        "Daily" {
            # Tous les X jours à l'heure spécifiée
            if ($Interval -eq 1) {
                return "$minute $hour * * *"
            } else {
                return "$minute $hour */$Interval * *"
            }
        }
        "Weekly" {
            # Toutes les X semaines aux jours spécifiés
            $dayOfWeek = if ($null -ne $DaysOfWeek -and $DaysOfWeek.Count -gt 0) {
                ($DaysOfWeek | ForEach-Object { 
                    switch ($_) {
                        "Monday" { 1 }
                        "Tuesday" { 2 }
                        "Wednesday" { 3 }
                        "Thursday" { 4 }
                        "Friday" { 5 }
                        "Saturday" { 6 }
                        "Sunday" { 0 }
                        default { $_ }
                    }
                }) -join ","
            } else {
                "*"
            }
            
            return "$minute $hour * * $dayOfWeek"
        }
        "Monthly" {
            # Tous les X mois aux jours spécifiés
            $dayOfMonth = if ($null -ne $DaysOfMonth -and $DaysOfMonth.Count -gt 0) {
                ($DaysOfMonth | Sort-Object) -join ","
            } else {
                "1"
            }
            
            if ($Interval -eq 1) {
                return "$minute $hour $dayOfMonth * *"
            } else {
                return "$minute $hour $dayOfMonth */$Interval *"
            }
        }
        default {
            # Par défaut, tous les jours à minuit
            return "0 0 * * *"
        }
    }
}

# Fonction pour créer une action de création de point de restauration
function New-RestorePointAction {
    [CmdletBinding()]
    param()
    
    $actionScript = @"
# Action de création de point de restauration planifiée
param(`$EventData)

# Importer le script de création de point de restauration
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$createRestorePointPath = Join-Path -Path `$scriptPath -ChildPath "..\..\New-RestorePoint.ps1"

if (Test-Path -Path `$createRestorePointPath) {
    . `$createRestorePointPath
} else {
    Write-Host "Required script not found: `$createRestorePointPath" -ForegroundColor Red
    return `$false
}

# Extraire les données de l'événement
`$scheduleName = `$EventData.ScheduleName
`$scheduleTime = `$EventData.ScheduleTime
`$parameters = `$EventData.Parameters

# Générer un nom pour le point de restauration
`$restorePointName = "Scheduled-`$scheduleName-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "scheduled" -Tags @("scheduled", `$scheduleName) -Description "Scheduled restore point created by schedule '`$scheduleName'" -SystemState @{
    schedule_name = `$scheduleName
    schedule_time = `$scheduleTime
    parameters = `$parameters
}

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour enregistrer une planification de création de points de restauration
function Register-RestoreSchedule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ScheduleName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hourly", "Daily", "Weekly", "Monthly", "Custom")]
        [string]$Frequency = "Daily",
        
        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$CronExpression,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndTime,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DaysOfWeek,
        
        [Parameter(Mandatory = $false)]
        [int[]]$DaysOfMonth,
        
        [Parameter(Mandatory = $false)]
        [int[]]$MonthsOfYear,
        
        [Parameter(Mandatory = $false)]
        [string[]]$TimeWindows,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 5,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom de planification par défaut si non fourni
    if ([string]::IsNullOrEmpty($ScheduleName)) {
        $ScheduleName = Get-DefaultScheduleName -Frequency $Frequency -Interval $Interval
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Schedule for creating restore points $Frequency (every $Interval)"
        
        if ($Frequency -eq "Weekly" -and $null -ne $DaysOfWeek -and $DaysOfWeek.Count -gt 0) {
            $Description += " on $($DaysOfWeek -join ", ")"
        } elseif ($Frequency -eq "Monthly" -and $null -ne $DaysOfMonth -and $DaysOfMonth.Count -gt 0) {
            $Description += " on day(s) $($DaysOfMonth -join ", ")"
        }
    }
    
    # Déterminer l'expression cron
    if ([string]::IsNullOrEmpty($CronExpression)) {
        if ($Frequency -eq "Custom") {
            Write-Log "CronExpression must be provided for Custom frequency" -Level "Error"
            return $false
        }
        
        $CronExpression = ConvertTo-CronExpression -Frequency $Frequency -Interval $Interval -StartTime $StartTime -DaysOfWeek $DaysOfWeek -DaysOfMonth $DaysOfMonth
    } else {
        # Valider l'expression cron
        if (-not (Test-CronExpression -CronExpression $CronExpression)) {
            Write-Log "Invalid cron expression: $CronExpression" -Level "Error"
            return $false
        }
    }
    
    # Créer une action par défaut si non fournie
    if ($null -eq $Action) {
        $Action = New-RestorePointAction
    }
    
    # Charger les planifications existantes
    $schedules = Get-Schedules
    
    # Vérifier si la planification existe déjà
    $existingSchedule = $schedules | Where-Object { $_.name -eq $ScheduleName }
    
    if ($null -ne $existingSchedule -and -not $Force) {
        Write-Log "Schedule already exists: $ScheduleName. Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Convertir les scriptblocks en chaînes
    $conditionString = if ($null -ne $Condition) { $Condition.ToString() } else { $null }
    $actionString = if ($null -ne $Action) { $Action.ToString() } else { $null }
    
    # Créer la nouvelle planification
    $newSchedule = @{
        name = $ScheduleName
        description = $Description
        frequency = $Frequency
        interval = $Interval
        cron_expression = $CronExpression
        start_time = if ($null -ne $StartTime) { $StartTime.ToString("o") } else { $null }
        end_time = if ($null -ne $EndTime) { $EndTime.ToString("o") } else { $null }
        days_of_week = $DaysOfWeek
        days_of_month = $DaysOfMonth
        months_of_year = $MonthsOfYear
        time_windows = $TimeWindows
        priority = $Priority
        parameters = $Parameters
        condition = $conditionString
        action = $actionString
        enabled = $Enabled
        last_run = $null
        next_run = $null
        created_at = (Get-Date).ToString("o")
        last_modified = (Get-Date).ToString("o")
    }
    
    # Mettre à jour ou ajouter la planification
    if ($null -ne $existingSchedule) {
        # Mettre à jour la planification existante
        $scheduleIndex = [array]::IndexOf($schedules, $existingSchedule)
        $schedules[$scheduleIndex] = $newSchedule
    } else {
        # Ajouter la nouvelle planification
        $schedules += $newSchedule
    }
    
    # Sauvegarder les planifications
    $result = Save-Schedules -Schedules $schedules
    
    if ($result) {
        Write-Log "Schedule registered successfully: $ScheduleName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register schedule: $ScheduleName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-RestoreSchedule -ScheduleName $ScheduleName -Description $Description -Frequency $Frequency -Interval $Interval -CronExpression $CronExpression -StartTime $StartTime -EndTime $EndTime -DaysOfWeek $DaysOfWeek -DaysOfMonth $DaysOfMonth -MonthsOfYear $MonthsOfYear -TimeWindows $TimeWindows -Priority $Priority -Parameters $Parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
}
