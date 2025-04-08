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
        Chemin où enregistrer les données d'utilisation
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
    
    # Créer le dossier de suivi d'utilisation
    $UsagePath = Join-Path -Path $OutputPath -ChildPath "usage"
    if (-not (Test-Path -Path $UsagePath)) {
        New-Item -ItemType Directory -Path $UsagePath -Force | Out-Null
    }
    
    Write-Host "Initialisation du suivi d'utilisation..." -ForegroundColor Cyan
    
    # Créer le fichier de données d'utilisation
    $UsageDataPath = Join-Path -Path $UsagePath -ChildPath "usage_data.json"
    $UsageData = @{
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Scripts = @()
    }
    
    # Initialiser les données d'utilisation pour chaque script
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
    
    # Enregistrer les données d'utilisation
    $UsageData | ConvertTo-Json -Depth 10 | Set-Content -Path $UsageDataPath
    
    Write-Host "  Données d'utilisation initialisées: $UsageDataPath" -ForegroundColor Green
    
    # Créer le script de suivi d'utilisation
    $UsageScriptPath = Join-Path -Path $UsagePath -ChildPath "Track-ScriptUsage.ps1"
    $UsageScriptContent = @"
<#
.SYNOPSIS
    Suit l'utilisation d'un script
.DESCRIPTION
    Enregistre l'exécution d'un script et ses performances
.PARAMETER ScriptPath
    Chemin du script exécuté
.PARAMETER ExecutionTime
    Temps d'exécution en millisecondes
.PARAMETER Status
    Statut de l'exécution (Success, Error)
.PARAMETER UsageDataPath
    Chemin vers le fichier de données d'utilisation
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

# Vérifier si le fichier de données d'utilisation existe
if (-not (Test-Path -Path `$UsageDataPath)) {
    Write-Error "Fichier de données d'utilisation non trouvé: `$UsageDataPath"
    exit 1
}

# Charger les données d'utilisation
try {
    `$UsageData = Get-Content -Path `$UsageDataPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des données d'utilisation: `$_"
    exit 1
}

# Trouver le script dans les données d'utilisation
`$ScriptData = `$UsageData.Scripts | Where-Object { `$_.Path -eq `$ScriptPath }

if (-not `$ScriptData) {
    # Le script n'existe pas dans les données d'utilisation, l'ajouter
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

# Mettre à jour les données d'utilisation
`$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
`$ScriptData.ExecutionCount += 1
`$ScriptData.LastExecution = `$Timestamp
`$ScriptData.TotalExecutionTime += `$ExecutionTime
`$ScriptData.AverageExecutionTime = `$ScriptData.TotalExecutionTime / `$ScriptData.ExecutionCount

# Ajouter l'exécution à l'historique
`$Execution = [PSCustomObject]@{
    Timestamp = `$Timestamp
    ExecutionTime = `$ExecutionTime
    Status = `$Status
}

# Limiter l'historique à 100 exécutions
`$ScriptData.Executions += `$Execution
if (`$ScriptData.Executions.Count -gt 100) {
    `$ScriptData.Executions = `$ScriptData.Executions | Select-Object -Last 100
}

# Mettre à jour la date de dernière mise à jour
`$UsageData.LastUpdate = `$Timestamp

# Enregistrer les données d'utilisation
`$UsageData | ConvertTo-Json -Depth 10 | Set-Content -Path `$UsageDataPath

Write-Host "Utilisation du script enregistrée: `$ScriptPath" -ForegroundColor Green
"@
    
    Set-Content -Path $UsageScriptPath -Value $UsageScriptContent
    
    Write-Host "  Script de suivi d'utilisation créé: $UsageScriptPath" -ForegroundColor Green
    
    # Créer le wrapper PowerShell pour suivre l'utilisation
    $WrapperScriptPath = Join-Path -Path $UsagePath -ChildPath "Invoke-ScriptWithTracking.ps1"
    $WrapperScriptContent = @"
<#
.SYNOPSIS
    Exécute un script avec suivi d'utilisation
.DESCRIPTION
    Exécute un script et suit son utilisation (temps d'exécution, statut)
.PARAMETER ScriptPath
    Chemin du script à exécuter
.PARAMETER Arguments
    Arguments à passer au script
.PARAMETER UsageDataPath
    Chemin vers le fichier de données d'utilisation
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

# Vérifier si le script existe
if (-not (Test-Path -Path `$ScriptPath)) {
    Write-Error "Script non trouvé: `$ScriptPath"
    exit 1
}

# Vérifier si le fichier de données d'utilisation existe
if (-not (Test-Path -Path `$UsageDataPath)) {
    Write-Error "Fichier de données d'utilisation non trouvé: `$UsageDataPath"
    exit 1
}

# Obtenir le chemin du script de suivi d'utilisation
`$UsageTrackerPath = Join-Path -Path (Split-Path -Parent `$UsageDataPath) -ChildPath "Track-ScriptUsage.ps1"

if (-not (Test-Path -Path `$UsageTrackerPath)) {
    Write-Error "Script de suivi d'utilisation non trouvé: `$UsageTrackerPath"
    exit 1
}

# Démarrer le chronomètre
`$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Exécuter le script
try {
    # Déterminer comment exécuter le script selon son type
    `$Extension = [System.IO.Path]::GetExtension(`$ScriptPath).ToLower()
    
    switch (`$Extension) {
        ".ps1" {
            # Exécuter le script PowerShell
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                & `$ScriptPath
            } else {
                Invoke-Expression "`& `$ScriptPath `$Arguments"
            }
        }
        ".py" {
            # Exécuter le script Python
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                python `$ScriptPath
            } else {
                python `$ScriptPath `$Arguments
            }
        }
        ".cmd" {
            # Exécuter le script Batch
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                cmd /c `$ScriptPath
            } else {
                cmd /c "`$ScriptPath `$Arguments"
            }
        }
        ".bat" {
            # Exécuter le script Batch
            if ([string]::IsNullOrWhiteSpace(`$Arguments)) {
                cmd /c `$ScriptPath
            } else {
                cmd /c "`$ScriptPath `$Arguments"
            }
        }
        ".sh" {
            # Exécuter le script Shell
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
    Write-Error "Erreur lors de l'exécution du script: `$_"
    `$Status = "Error"
}

# Arrêter le chronomètre
`$Stopwatch.Stop()
`$ExecutionTime = [int]`$Stopwatch.ElapsedMilliseconds

# Enregistrer l'utilisation
& `$UsageTrackerPath -ScriptPath `$ScriptPath -ExecutionTime `$ExecutionTime -Status `$Status -UsageDataPath `$UsageDataPath
"@
    
    Set-Content -Path $WrapperScriptPath -Value $WrapperScriptContent
    
    Write-Host "  Script wrapper créé: $WrapperScriptPath" -ForegroundColor Green
    
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
        Récupère les statistiques d'utilisation des scripts
    .DESCRIPTION
        Charge et analyse les données d'utilisation des scripts
    .PARAMETER UsageDataPath
        Chemin vers le fichier de données d'utilisation
    .PARAMETER TopCount
        Nombre de scripts les plus utilisés à retourner
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
    
    # Vérifier si le fichier de données d'utilisation existe
    if (-not (Test-Path -Path $UsageDataPath)) {
        Write-Error "Fichier de données d'utilisation non trouvé: $UsageDataPath"
        return $null
    }
    
    # Charger les données d'utilisation
    try {
        $UsageData = Get-Content -Path $UsageDataPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement des données d'utilisation: $_"
        return $null
    }
    
    # Calculer les statistiques globales
    $TotalExecutions = ($UsageData.Scripts | Measure-Object -Property ExecutionCount -Sum).Sum
    $TotalExecutionTime = ($UsageData.Scripts | Measure-Object -Property TotalExecutionTime -Sum).Sum
    $AverageExecutionTime = if ($TotalExecutions -gt 0) { $TotalExecutionTime / $TotalExecutions } else { 0 }
    
    # Obtenir les scripts les plus utilisés
    $TopScripts = $UsageData.Scripts | Sort-Object -Property ExecutionCount -Descending
    
    if ($TopCount -gt 0) {
        $TopScripts = $TopScripts | Select-Object -First $TopCount
    }
    
    # Créer l'objet de statistiques
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
