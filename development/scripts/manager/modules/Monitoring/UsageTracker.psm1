# Module de suivi d'utilisation pour le Script Manager
# Ce module suit l'utilisation des scripts
# Author: Script Manager
# Version: 1.0
# Tags: monitoring, usage, scripts

function Initialize-UsageTracker {
    <#
    .SYNOPSIS
        Initialise le suivi d'utilisation
    .DESCRIPTION
        Configure le suivi d'utilisation pour les scripts
    .PARAMETER Inventory
        Objet d'inventaire des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les donnÃ©es d'utilisation
    .EXAMPLE
        Initialize-UsageTracker -Inventory $inventory -OutputPath "monitoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Inventory,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le dossier de suivi d'utilisation
    $UsagePath = Join-Path -Path $OutputPath -ChildPath "usage"
    if (-not (Test-Path -Path $UsagePath)) {
        New-Item -ItemType Directory -Path $UsagePath -Force | Out-Null
    }
    
    Write-Host "Initialisation du suivi d'utilisation..." -ForegroundColor Cyan
    
    # CrÃ©er le fichier de donnÃ©es d'utilisation
    $UsageDataPath = Join-Path -Path $UsagePath -ChildPath "usage_data.json"
    $UsageData = @{
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Scripts = @()
    }
    
    # Initialiser les donnÃ©es d'utilisation pour chaque script
    foreach ($Script in $Inventory.Scripts) {
        $UsageData.Scripts += [PSCustomObject]@{
            Path = $Script.Path
            Name = $Script.Name
            Type = $Script.Type
            ExecutionCount = 0
            LastExecution = $null
            AverageExecutionTime = 0
            TotalExecutionTime = 0
            Executions = @()
        }
    }
    
    # Enregistrer les donnÃ©es d'utilisation
    $UsageData | ConvertTo-Json -Depth 10 | Set-Content -Path $UsageDataPath
    
    Write-Host "  DonnÃ©es d'utilisation initialisÃ©es: $UsageDataPath" -ForegroundColor Green
    
    # CrÃ©er le script de suivi d'utilisation
    $UsageScriptPath = Join-Path -Path $UsagePath -ChildPath "Track-ScriptUsage.ps1"
    $UsageScriptContent = @"
<#
.SYNOPSIS
    Suit l'utilisation d'un script
.DESCRIPTION
    Enregistre l'exÃ©cution d'un script et ses performances
.PARAMETER ScriptPath
    Chemin du script exÃ©cutÃ©
.PARAMETER ExecutionTime
    Temps d'exÃ©cution en millisecondes
.PARAMETER Status
    Statut de l'exÃ©cution (Success, Error)
.PARAMETER UsageDataPath
    Chemin vers le fichier de donnÃ©es d'utilisation
.EXAMPLE
    .\Track-ScriptUsage.ps1 -ScriptPath "scripts\myscript.ps1" -ExecutionTime 1500 -Status "Success" -UsageDataPath "monitoring\usage\usage_data.json"
#>

param (
    [Parameter(Mandatory=`$true)]
    [string]`$ScriptPath,
    
    [Parameter(Mandatory=`$true)]
    [int]`$ExecutionTime,
    
    [Parameter(Mandatory=`$true)]
    [ValidateSet("Success", "Error")]
    [string]`$Status,
    
    [Parameter(Mandatory=`$true)]
    [string]`$UsageDataPath
)

# VÃ©rifier si le fichier de donnÃ©es d'utilisation existe
if (-not (Test-Path -Path `$UsageDataPath)) {
    Write-Error "Fichier de donnÃ©es d'utilisation non trouvÃ©: `$UsageDataPath"
    exit 1
}

# Charger les donnÃ©es d'utilisation
try {
    `$UsageData = Get-Content -Path `$UsageDataPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des donnÃ©es d'utilisation: `$_"
    exit 1
}

# Trouver le script dans les donnÃ©es d'utilisation
`$ScriptData = `$UsageData.Scripts | Where-Object { `$_.Path -eq `$ScriptPath }

if (-not `$ScriptData) {
    # Le script n'existe pas dans les donnÃ©es d'utilisation, l'ajouter
    `$ScriptName = Split-Path -Leaf `$ScriptPath
    `$ScriptType = switch -Regex (`$ScriptName) {
        "\.ps1`$" { "PowerShell" }
        "\.py`$" { "Python" }
        "\.cmd`$|\.bat`$" { "Batch" }
        "\.sh`$" { "Shell" }
        default { "Unknown" }
    }
    
    `$ScriptData = [PSCustomObject]@{
        Path = `$ScriptPath
        Name = `$ScriptName
        Type = `$ScriptType
        ExecutionCount = 0
        LastExecution = `$null
        AverageExecutionTime = 0
        TotalExecutionTime = 0
        Executions = @()
    }
    
    `$UsageData.Scripts += `$ScriptData
}

# Mettre Ã  jour les donnÃ©es d'utilisation
`$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
`$ScriptData.ExecutionCount += 1
`$ScriptData.LastExecution = `$Timestamp
`$ScriptData.TotalExecutionTime += `$ExecutionTime
`$ScriptData.AverageExecutionTime = `$ScriptData.TotalExecutionTime / `$ScriptData.ExecutionCount

# Ajouter l'exÃ©cution Ã  l'historique
`$Execution = [PSCustomObject]@{
    Timestamp = `$Timestamp
    ExecutionTime = `$ExecutionTime
    Status = `$Status
}

# Limiter l'historique Ã  100 exÃ©cutions
`$ScriptData.Executions += `$Execution
if (`$ScriptData.Executions.Count -gt 100) {
    `$ScriptData.Executions = `$ScriptData.Executions | Select-Object -Last 100
}

# Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
`$UsageData.LastUpdate = `$Timestamp

# Enregistrer les donnÃ©es d'utilisation
`$UsageData | ConvertTo-Json -Depth 10 | Set-Content -Path `$UsageDataPath

Write-Host "Utilisation du script enregistrÃ©e: `$ScriptPath" -ForegroundColor Green
"@
    
    Set-Content -Path $UsageScriptPath -Value $UsageScriptContent
    
    Write-Host "  Script de suivi d'utilisation crÃ©Ã©: $UsageScriptPath" -ForegroundColor Green
    
    # CrÃ©er le wrapper PowerShell pour suivre l'utilisation
    $WrapperScriptPath = Join-Path -Path $UsagePath -ChildPath "Invoke-ScriptWithTracking.ps1"
    $WrapperScriptContent = @"
<#
.SYNOPSIS
    ExÃ©cute un script avec suivi d'utilisation
.DESCRIPTION
    ExÃ©cute un script et suit son utilisation (temps d'exÃ©cution, statut)
.PARAMETER ScriptPath
    Chemin du script Ã  exÃ©cuter
.PARAMETER Arguments
    Arguments Ã  passer au script
.PARAMETER UsageDataPath
    Chemin vers le fichier de donnÃ©es d'utilisation
.EXAMPLE
    .\Invoke-ScriptWithTracking.ps1 -ScriptPath "scripts\myscript.ps1" -Arguments "-Param1 Value1" -UsageDataPath "monitoring\usage\usage_data.json"
#>

param (
    [Parameter(Mandatory=`$true)]
    [string]`$ScriptPath,
    
    [Parameter()]
    [string]`$Arguments = "",
    
    [Parameter(Mandatory=`$true)]
    [string]`$UsageDataPath
)

# VÃ©rifier si le script existe
if (-not (Test-Path -Path `$ScriptPath)) {
    Write-Error "Script non trouvÃ©: `$ScriptPath"
    exit 1
}

# VÃ©rifier si le fichier de donnÃ©es d'utilisation existe
if (-not (Test-Path -Path `$UsageDataPath)) {
    Write-Error "Fichier de donnÃ©es d'utilisation non trouvÃ©: `$UsageDataPath"
    exit 1
}

# Obtenir le chemin du script de suivi d'utilisation
`$UsageTrackerPath = Join-Path -Path (Split-Path -Parent `$UsageDataPath) -ChildPath "Track-ScriptUsage.ps1"

if (-not (Test-Path -Path `$UsageTrackerPath)) {
    Write-Error "Script de suivi d'utilisation non trouvÃ©: `$UsageTrackerPath"
    exit 1
}

# DÃ©marrer le chronomÃ¨tre
`$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ExÃ©cuter le script
try {
    # DÃ©terminer comment exÃ©cuter le script selon son type
    `$Extension = [System.IO.Path]::GetExtension(`$ScriptPath).ToLower()
    
    switch (`$Extension) {
        ".ps1" {
            # ExÃ©cuter le script PowerShell
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                & `$ScriptPath
            } else {
                Invoke-Expression "`& `$ScriptPath `$Arguments"
            }
        }
        ".py" {
            # ExÃ©cuter le script Python
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                python `$ScriptPath
            } else {
                python `$ScriptPath `$Arguments
            }
        }
        ".cmd" {
            # ExÃ©cuter le script Batch
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                cmd /c `$ScriptPath
            } else {
                cmd /c "`$ScriptPath `$Arguments"
            }
        }
        ".bat" {
            # ExÃ©cuter le script Batch
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                cmd /c `$ScriptPath
            } else {
                cmd /c "`$ScriptPath `$Arguments"
            }
        }
        ".sh" {
            # ExÃ©cuter le script Shell
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                bash `$ScriptPath
            } else {
                bash `$ScriptPath `$Arguments
            }
        }
        default {
            Write-Error "Type de script non pris en charge: `$Extension"
            exit 1
        }
    }
    
    `$Status = "Success"
} catch {
    Write-Error "Erreur lors de l'exÃ©cution du script: `$_"
    `$Status = "Error"
}

# ArrÃªter le chronomÃ¨tre
`$Stopwatch.Stop()
`$ExecutionTime = [int]`$Stopwatch.ElapsedMilliseconds

# Enregistrer l'utilisation
& `$UsageTrackerPath -ScriptPath `$ScriptPath -ExecutionTime `$ExecutionTime -Status `$Status -UsageDataPath `$UsageDataPath
"@
    
    Set-Content -Path $WrapperScriptPath -Value $WrapperScriptContent
    
    Write-Host "  Script wrapper crÃ©Ã©: $WrapperScriptPath" -ForegroundColor Green
    
    return [PSCustomObject]@{
        UsagePath = $UsagePath
        UsageDataPath = $UsageDataPath
        UsageScriptPath = $UsageScriptPath
        WrapperScriptPath = $WrapperScriptPath
    }
}

function Get-ScriptUsageStats {
    <#
    .SYNOPSIS
        RÃ©cupÃ¨re les statistiques d'utilisation des scripts
    .DESCRIPTION
        Charge et analyse les donnÃ©es d'utilisation des scripts
    .PARAMETER UsageDataPath
        Chemin vers le fichier de donnÃ©es d'utilisation
    .PARAMETER TopCount
        Nombre de scripts les plus utilisÃ©s Ã  retourner
    .EXAMPLE
        Get-ScriptUsageStats -UsageDataPath "monitoring\usage\usage_data.json" -TopCount 10
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UsageDataPath,
        
        [Parameter()]
        [int]$TopCount = 0
    )
    
    # VÃ©rifier si le fichier de donnÃ©es d'utilisation existe
    if (-not (Test-Path -Path $UsageDataPath)) {
        Write-Error "Fichier de donnÃ©es d'utilisation non trouvÃ©: $UsageDataPath"
        return $null
    }
    
    # Charger les donnÃ©es d'utilisation
    try {
        $UsageData = Get-Content -Path $UsageDataPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement des donnÃ©es d'utilisation: $_"
        return $null
    }
    
    # Calculer les statistiques globales
    $TotalExecutions = ($UsageData.Scripts | Measure-Object -Property ExecutionCount -Sum).Sum
    $TotalExecutionTime = ($UsageData.Scripts | Measure-Object -Property TotalExecutionTime -Sum).Sum
    $AverageExecutionTime = if ($TotalExecutions -gt 0) { $TotalExecutionTime / $TotalExecutions } else { 0 }
    
    # Obtenir les scripts les plus utilisÃ©s
    $TopScripts = $UsageData.Scripts | Sort-Object -Property ExecutionCount -Descending
    
    if ($TopCount -gt 0) {
        $TopScripts = $TopScripts | Select-Object -First $TopCount
    }
    
    # CrÃ©er l'objet de statistiques
    $Stats = [PSCustomObject]@{
        LastUpdate = $UsageData.LastUpdate
        TotalScripts = $UsageData.Scripts.Count
        TotalExecutions = $TotalExecutions
        TotalExecutionTime = $TotalExecutionTime
        AverageExecutionTime = $AverageExecutionTime
        ScriptsWithUsage = ($UsageData.Scripts | Where-Object { $_.ExecutionCount -gt 0 } | Measure-Object).Count
        TopScripts = $TopScripts
    }
    
    return $Stats
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-UsageTracker, Get-ScriptUsageStats
