<#
.SYNOPSIS
    Définit les fonctions de mesure de performance pour le module RoadmapParser.

.DESCRIPTION
    Ce script définit les fonctions de mesure de performance utilisées par le module RoadmapParser.
    Il inclut des fonctions pour mesurer le temps d'exécution, l'utilisation de la mémoire et le comptage d'opérations.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-23
#>

# Importer le script des fonctions de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$loggingFunctionsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Logging\LoggingFunctions.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $loggingFunctionsPath)) {
    throw "Le fichier LoggingFunctions.ps1 est introuvable à l'emplacement : $loggingFunctionsPath"
}

# Importer le script
. $loggingFunctionsPath

# Variables globales pour la gestion des mesures de performance
$script:PerformanceTimers = @{}
$script:PerformanceStatistics = @{}
$script:PerformanceEnabled = $true
$script:PerformanceLogLevel = $script:LogLevelDebug
$script:PerformanceCategory = "Performance"
$script:PerformanceThresholds = @{}
$script:MemorySnapshots = @{}
$script:MemoryStatistics = @{}
$script:MemoryThresholds = @{}
$script:OperationCounters = @{}
$script:OperationStatistics = @{}
$script:OperationThresholds = @{}

# Fichiers temporaires pour stocker les données de performance
$script:PerformanceTimersFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceTimers.xml"
$script:PerformanceStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceStatistics.xml"
$script:PerformanceThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceThresholds.xml"
$script:MemorySnapshotsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemorySnapshots.xml"
$script:MemoryStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemoryStatistics.xml"
$script:MemoryThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemoryThresholds.xml"
$script:OperationCountersFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationCounters.xml"
$script:OperationStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationStatistics.xml"
$script:OperationThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationThresholds.xml"

# Fonctions pour sauvegarder et charger les données de performance

# Fonction pour sauvegarder les timers dans un fichier
function Save-PerformanceTimers {
    if (Test-Path -Path $script:PerformanceTimersFile) {
        $script:PerformanceTimers | Export-Clixml -Path $script:PerformanceTimersFile -Force
    } else {
        $script:PerformanceTimers | Export-Clixml -Path $script:PerformanceTimersFile
    }
}

# Fonction pour charger les timers depuis un fichier
function Import-PerformanceTimers {
    if (Test-Path -Path $script:PerformanceTimersFile) {
        $script:PerformanceTimers = Import-Clixml -Path $script:PerformanceTimersFile
    } else {
        $script:PerformanceTimers = @{}
    }
}

# Fonction pour sauvegarder les statistiques de performance dans un fichier
function Save-PerformanceStatistics {
    if (Test-Path -Path $script:PerformanceStatisticsFile) {
        $script:PerformanceStatistics | Export-Clixml -Path $script:PerformanceStatisticsFile -Force
    } else {
        $script:PerformanceStatistics | Export-Clixml -Path $script:PerformanceStatisticsFile
    }
}

# Fonction pour charger les statistiques de performance depuis un fichier
function Import-PerformanceStatistics {
    if (Test-Path -Path $script:PerformanceStatisticsFile) {
        $script:PerformanceStatistics = Import-Clixml -Path $script:PerformanceStatisticsFile
    } else {
        $script:PerformanceStatistics = @{}
    }
}

# Fonction pour sauvegarder les seuils de performance dans un fichier
function Save-PerformanceThresholds {
    if (Test-Path -Path $script:PerformanceThresholdsFile) {
        $script:PerformanceThresholds | Export-Clixml -Path $script:PerformanceThresholdsFile -Force
    } else {
        $script:PerformanceThresholds | Export-Clixml -Path $script:PerformanceThresholdsFile
    }
}

# Fonction pour charger les seuils de performance depuis un fichier
function Import-PerformanceThresholds {
    if (Test-Path -Path $script:PerformanceThresholdsFile) {
        $script:PerformanceThresholds = Import-Clixml -Path $script:PerformanceThresholdsFile
    } else {
        $script:PerformanceThresholds = @{}
    }
}

# Fonction pour sauvegarder les instantanés de mémoire dans un fichier
function Save-MemorySnapshots {
    if (Test-Path -Path $script:MemorySnapshotsFile) {
        $script:MemorySnapshots | Export-Clixml -Path $script:MemorySnapshotsFile -Force
    } else {
        $script:MemorySnapshots | Export-Clixml -Path $script:MemorySnapshotsFile
    }
}

# Fonction pour charger les instantanés de mémoire depuis un fichier
function Import-MemorySnapshots {
    if (Test-Path -Path $script:MemorySnapshotsFile) {
        $script:MemorySnapshots = Import-Clixml -Path $script:MemorySnapshotsFile
    } else {
        $script:MemorySnapshots = @{}
    }
}

# Fonction pour sauvegarder les statistiques de mémoire dans un fichier
function Save-MemoryStatistics {
    if (Test-Path -Path $script:MemoryStatisticsFile) {
        $script:MemoryStatistics | Export-Clixml -Path $script:MemoryStatisticsFile -Force
    } else {
        $script:MemoryStatistics | Export-Clixml -Path $script:MemoryStatisticsFile
    }
}

# Fonction pour charger les statistiques de mémoire depuis un fichier
function Import-MemoryStatistics {
    if (Test-Path -Path $script:MemoryStatisticsFile) {
        $script:MemoryStatistics = Import-Clixml -Path $script:MemoryStatisticsFile
    } else {
        $script:MemoryStatistics = @{}
    }
}

# Fonction pour sauvegarder les seuils de mémoire dans un fichier
function Save-MemoryThresholds {
    if (Test-Path -Path $script:MemoryThresholdsFile) {
        $script:MemoryThresholds | Export-Clixml -Path $script:MemoryThresholdsFile -Force
    } else {
        $script:MemoryThresholds | Export-Clixml -Path $script:MemoryThresholdsFile
    }
}

# Fonction pour charger les seuils de mémoire depuis un fichier
function Import-MemoryThresholds {
    if (Test-Path -Path $script:MemoryThresholdsFile) {
        $script:MemoryThresholds = Import-Clixml -Path $script:MemoryThresholdsFile
    } else {
        $script:MemoryThresholds = @{}
    }
}

# Fonction pour sauvegarder les compteurs d'opérations dans un fichier
function Save-OperationCounters {
    if (Test-Path -Path $script:OperationCountersFile) {
        $script:OperationCounters | Export-Clixml -Path $script:OperationCountersFile -Force
    } else {
        $script:OperationCounters | Export-Clixml -Path $script:OperationCountersFile
    }
}

# Fonction pour charger les compteurs d'opérations depuis un fichier
function Import-OperationCounters {
    if (Test-Path -Path $script:OperationCountersFile) {
        $script:OperationCounters = Import-Clixml -Path $script:OperationCountersFile
    } else {
        $script:OperationCounters = @{}
    }
}

# Fonction pour sauvegarder les statistiques d'opérations dans un fichier
function Save-OperationStatistics {
    if (Test-Path -Path $script:OperationStatisticsFile) {
        $script:OperationStatistics | Export-Clixml -Path $script:OperationStatisticsFile -Force
    } else {
        $script:OperationStatistics | Export-Clixml -Path $script:OperationStatisticsFile
    }
}

# Fonction pour charger les statistiques d'opérations depuis un fichier
function Import-OperationStatistics {
    if (Test-Path -Path $script:OperationStatisticsFile) {
        $script:OperationStatistics = Import-Clixml -Path $script:OperationStatisticsFile
    } else {
        $script:OperationStatistics = @{}
    }
}

# Fonction pour sauvegarder les seuils d'opérations dans un fichier
function Save-OperationThresholds {
    if (Test-Path -Path $script:OperationThresholdsFile) {
        $script:OperationThresholds | Export-Clixml -Path $script:OperationThresholdsFile -Force
    } else {
        $script:OperationThresholds | Export-Clixml -Path $script:OperationThresholdsFile
    }
}

# Fonction pour charger les seuils d'opérations depuis un fichier
function Import-OperationThresholds {
    if (Test-Path -Path $script:OperationThresholdsFile) {
        $script:OperationThresholds = Import-Clixml -Path $script:OperationThresholdsFile
    } else {
        $script:OperationThresholds = @{}
    }
}

<#
.SYNOPSIS
    Configure les options de mesure de performance.

.DESCRIPTION
    La fonction Set-PerformanceMeasurementConfiguration configure les options de mesure de performance.
    Elle permet de définir les paramètres de mesure tels que l'activation, le niveau de journalisation, etc.

.PARAMETER Enabled
    Indique si la mesure de performance est activée.
    Par défaut, c'est $true.

.PARAMETER LogLevel
    Le niveau de journalisation pour les mesures de performance.
    Par défaut, c'est LogLevelDebug.

.PARAMETER Category
    La catégorie à utiliser pour la journalisation.
    Par défaut, c'est "Performance".

.EXAMPLE
    Set-PerformanceMeasurementConfiguration -Enabled $true -LogLevel $LogLevelDebug
    Configure la mesure de performance pour être activée, avec un niveau de débogage.

.OUTPUTS
    [void]
#>
function Set-PerformanceMeasurementConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [object]$LogLevel = $script:LogLevelDebug,

        [Parameter(Mandatory = $false)]
        [string]$Category = "Performance"
    )

    # Valider le niveau de journalisation
    $script:PerformanceLogLevel = ConvertTo-LogLevel -Value $LogLevel

    # Mettre à jour la configuration
    $script:PerformanceEnabled = $Enabled
    $script:PerformanceCategory = $Category
}

<#
.SYNOPSIS
    Obtient la configuration de mesure de performance.

.DESCRIPTION
    La fonction Get-PerformanceMeasurementConfiguration obtient la configuration de mesure de performance.
    Elle retourne un objet contenant les paramètres de mesure actuels.

.EXAMPLE
    Get-PerformanceMeasurementConfiguration
    Obtient la configuration de mesure de performance.

.OUTPUTS
    [PSCustomObject] Un objet contenant la configuration de mesure de performance.
#>
function Get-PerformanceMeasurementConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    return [PSCustomObject]@{
        Enabled    = $script:PerformanceEnabled
        LogLevel   = $script:PerformanceLogLevel
        LevelName  = Get-LogLevelName -LogLevel $script:PerformanceLogLevel
        Category   = $script:PerformanceCategory
        Timers     = $script:PerformanceTimers.Keys
        Statistics = $script:PerformanceStatistics.Keys
        Thresholds = $script:PerformanceThresholds.Keys
    }
}

<#
.SYNOPSIS
    Démarre un chronomètre pour mesurer le temps d'exécution.

.DESCRIPTION
    La fonction Start-PerformanceTimer démarre un chronomètre pour mesurer le temps d'exécution.
    Elle crée un nouveau chronomètre ou réinitialise un chronomètre existant.

.PARAMETER Name
    Le nom du chronomètre.
    Ce nom est utilisé pour identifier le chronomètre lors de l'arrêt ou de la réinitialisation.

.PARAMETER Reset
    Indique si le chronomètre doit être réinitialisé s'il existe déjà.
    Par défaut, c'est $true.

.EXAMPLE
    Start-PerformanceTimer -Name "MaFonction"
    Démarre un chronomètre nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Start-PerformanceTimer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Reset = $true
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Vérifier si le chronomètre existe déjà
    if ($script:PerformanceTimers.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "Le chronomètre '$Name' est déjà en cours d'exécution." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # Créer ou réinitialiser le chronomètre
    $script:PerformanceTimers[$Name] = [System.Diagnostics.Stopwatch]::StartNew()

    # Initialiser les statistiques si elles n'existent pas
    if (-not $script:PerformanceStatistics.ContainsKey($Name)) {
        $script:PerformanceStatistics[$Name] = @{
            Count               = 0
            TotalMilliseconds   = 0
            MinMilliseconds     = [double]::MaxValue
            MaxMilliseconds     = 0
            LastMilliseconds    = 0
            AverageMilliseconds = 0
        }
    }

    Write-Log -Message "Chronomètre '$Name' démarré." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Arrête un chronomètre et enregistre le temps d'exécution.

.DESCRIPTION
    La fonction Stop-PerformanceTimer arrête un chronomètre et enregistre le temps d'exécution.
    Elle met à jour les statistiques pour le chronomètre spécifié.

.PARAMETER Name
    Le nom du chronomètre à arrêter.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $true.

.EXAMPLE
    Stop-PerformanceTimer -Name "MaFonction"
    Arrête le chronomètre nommé "MaFonction" et journalise le résultat.

.OUTPUTS
    [double] Le temps d'exécution en millisecondes.
#>
function Stop-PerformanceTimer {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult = $true
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Vérifier si le chronomètre existe
    if (-not $script:PerformanceTimers.ContainsKey($Name)) {
        Write-Log -Message "Le chronomètre '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Arrêter le chronomètre
    $stopwatch = $script:PerformanceTimers[$Name]
    $stopwatch.Stop()
    $elapsedMilliseconds = $stopwatch.Elapsed.TotalMilliseconds

    # Mettre à jour les statistiques
    $stats = $script:PerformanceStatistics[$Name]
    $stats.Count++
    $stats.TotalMilliseconds += $elapsedMilliseconds
    $stats.MinMilliseconds = [Math]::Min($stats.MinMilliseconds, $elapsedMilliseconds)
    $stats.MaxMilliseconds = [Math]::Max($stats.MaxMilliseconds, $elapsedMilliseconds)
    $stats.LastMilliseconds = $elapsedMilliseconds
    $stats.AverageMilliseconds = $stats.TotalMilliseconds / $stats.Count

    # Journaliser le résultat si demandé
    if ($LogResult) {
        $message = "Chronomètre '$Name' arrêté. Temps écoulé: $($elapsedMilliseconds.ToString("F2")) ms."

        # Vérifier si un seuil est défini pour ce chronomètre
        if ($script:PerformanceThresholds.ContainsKey($Name)) {
            $threshold = $script:PerformanceThresholds[$Name]
            if ($elapsedMilliseconds -gt $threshold) {
                $message += " ATTENTION: Seuil de $threshold ms dépassé!"
                Write-Log -Message $message -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            } else {
                Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
            }
        } else {
            Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        }
    }

    # Retourner le temps écoulé
    return $elapsedMilliseconds
}

<#
.SYNOPSIS
    Réinitialise un chronomètre.

.DESCRIPTION
    La fonction Reset-PerformanceTimer réinitialise un chronomètre.
    Elle arrête le chronomètre s'il est en cours d'exécution et le redémarre.

.PARAMETER Name
    Le nom du chronomètre à réinitialiser.

.EXAMPLE
    Reset-PerformanceTimer -Name "MaFonction"
    Réinitialise le chronomètre nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Reset-PerformanceTimer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Vérifier si le chronomètre existe
    if (-not $script:PerformanceTimers.ContainsKey($Name)) {
        Write-Log -Message "Le chronomètre '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # Arrêter le chronomètre s'il est en cours d'exécution
    $stopwatch = $script:PerformanceTimers[$Name]
    if ($stopwatch.IsRunning) {
        $stopwatch.Stop()
    }

    # Redémarrer le chronomètre
    $stopwatch.Reset()
    $stopwatch.Start()

    Write-Log -Message "Chronomètre '$Name' réinitialisé." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Obtient les statistiques de performance pour un chronomètre.

.DESCRIPTION
    La fonction Get-PerformanceStatistics obtient les statistiques de performance pour un chronomètre.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, le temps total, etc.

.PARAMETER Name
    Le nom du chronomètre.
    Si non spécifié, retourne les statistiques pour tous les chronomètres.

.EXAMPLE
    Get-PerformanceStatistics -Name "MaFonction"
    Obtient les statistiques pour le chronomètre nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques de performance.
#>
function Get-PerformanceStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Si un nom est spécifié, retourner les statistiques pour ce chronomètre
    if ($Name) {
        if (-not $script:PerformanceStatistics.ContainsKey($Name)) {
            Write-Log -Message "Aucune statistique disponible pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            return $null
        }

        $stats = $script:PerformanceStatistics[$Name]
        return [PSCustomObject]@{
            Name                = $Name
            Count               = $stats.Count
            TotalMilliseconds   = $stats.TotalMilliseconds
            MinMilliseconds     = $stats.MinMilliseconds
            MaxMilliseconds     = $stats.MaxMilliseconds
            LastMilliseconds    = $stats.LastMilliseconds
            AverageMilliseconds = $stats.AverageMilliseconds
        }
    }

    # Sinon, retourner les statistiques pour tous les chronomètres
    $result = @()
    foreach ($key in $script:PerformanceStatistics.Keys) {
        $stats = $script:PerformanceStatistics[$key]
        $result += [PSCustomObject]@{
            Name                = $key
            Count               = $stats.Count
            TotalMilliseconds   = $stats.TotalMilliseconds
            MinMilliseconds     = $stats.MinMilliseconds
            MaxMilliseconds     = $stats.MaxMilliseconds
            LastMilliseconds    = $stats.LastMilliseconds
            AverageMilliseconds = $stats.AverageMilliseconds
        }
    }

    return $result
}

<#
.SYNOPSIS
    Définit un seuil de performance pour un chronomètre.

.DESCRIPTION
    La fonction Set-PerformanceThreshold définit un seuil de performance pour un chronomètre.
    Si le temps d'exécution dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom du chronomètre.

.PARAMETER ThresholdMilliseconds
    Le seuil en millisecondes.

.EXAMPLE
    Set-PerformanceThreshold -Name "MaFonction" -ThresholdMilliseconds 100
    Définit un seuil de 100 ms pour le chronomètre nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Set-PerformanceThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [double]$ThresholdMilliseconds
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Définir le seuil
    $script:PerformanceThresholds[$Name] = $ThresholdMilliseconds

    Write-Log -Message "Seuil de performance pour '$Name' défini à $ThresholdMilliseconds ms." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure le temps d'exécution d'un bloc de code.

.DESCRIPTION
    La fonction Measure-ExecutionTime mesure le temps d'exécution d'un bloc de code.
    Elle démarre un chronomètre, exécute le bloc de code, puis arrête le chronomètre.

.PARAMETER Name
    Le nom du chronomètre.

.PARAMETER ScriptBlock
    Le bloc de code à exécuter.

.PARAMETER InputObject
    L'objet à passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments à passer au bloc de code.

.EXAMPLE
    Measure-ExecutionTime -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure le temps d'exécution de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le résultat du bloc de code et le temps d'exécution.
#>
function Measure-ExecutionTime {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        # Exécuter le bloc de code sans mesure
        if ($InputObject) {
            if ($ArgumentList) {
                return $InputObject | & $ScriptBlock @ArgumentList
            } else {
                return $InputObject | & $ScriptBlock
            }
        } else {
            if ($ArgumentList) {
                return & $ScriptBlock @ArgumentList
            } else {
                return & $ScriptBlock
            }
        }
    }

    # Démarrer le chronomètre
    Start-PerformanceTimer -Name $Name

    # Exécuter le bloc de code
    $result = $null
    try {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = $InputObject | & $ScriptBlock @ArgumentList
            } else {
                $result = $InputObject | & $ScriptBlock
            }
        } else {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = & $ScriptBlock @ArgumentList
            } else {
                $result = & $ScriptBlock
            }
        }
    } catch {
        # Arrêter le chronomètre en cas d'erreur
        $elapsedMilliseconds = Stop-PerformanceTimer -Name $Name

        # Relancer l'erreur
        throw $_
    }

    # Arrêter le chronomètre
    $elapsedMilliseconds = Stop-PerformanceTimer -Name $Name

    # Retourner le résultat et le temps d'exécution
    return [PSCustomObject]@{
        Result              = $result
        ElapsedMilliseconds = $elapsedMilliseconds
    }
}

<#
.SYNOPSIS
    Prend un instantané de l'utilisation de la mémoire.

.DESCRIPTION
    La fonction Start-MemorySnapshot prend un instantané de l'utilisation de la mémoire.
    Elle enregistre l'utilisation actuelle de la mémoire pour une comparaison ultérieure.

.PARAMETER Name
    Le nom de l'instantané.
    Ce nom est utilisé pour identifier l'instantané lors de la comparaison.

.PARAMETER Reset
    Indique si l'instantané doit être réinitialisé s'il existe déjà.
    Par défaut, c'est $true.

.EXAMPLE
    Start-MemorySnapshot -Name "MaFonction"
    Prend un instantané de l'utilisation de la mémoire nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Start-MemorySnapshot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Reset = $true
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les instantanés et les statistiques
    Import-MemorySnapshots
    Import-MemoryStatistics

    # Vérifier si l'instantané existe déjà
    if ($script:MemorySnapshots.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "L'instantané de mémoire '$Name' existe déjà." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # Obtenir l'utilisation actuelle de la mémoire
    $process = Get-Process -Id $PID
    $memoryUsage = $process.WorkingSet64

    # Créer ou réinitialiser l'instantané
    $script:MemorySnapshots[$Name] = @{
        StartMemory = $memoryUsage
        EndMemory   = $null
        MemoryUsed  = $null
        StartTime   = Get-Date
        EndTime     = $null
    }

    # Initialiser les statistiques si elles n'existent pas
    if (-not $script:MemoryStatistics.ContainsKey($Name)) {
        $script:MemoryStatistics[$Name] = @{
            Count        = 0
            TotalBytes   = 0
            MinBytes     = [double]::MaxValue
            MaxBytes     = 0
            LastBytes    = 0
            AverageBytes = 0
        }
    }

    # Sauvegarder les instantanés et les statistiques
    Save-MemorySnapshots
    Save-MemoryStatistics

    Write-Log -Message "Instantané de mémoire '$Name' démarré. Mémoire initiale: $($memoryUsage / 1MB) MB." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Arrête un instantané de mémoire et calcule l'utilisation de la mémoire.

.DESCRIPTION
    La fonction Stop-MemorySnapshot arrête un instantané de mémoire et calcule l'utilisation de la mémoire.
    Elle met à jour les statistiques pour l'instantané spécifié.

.PARAMETER Name
    Le nom de l'instantané à arrêter.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $true.

.PARAMETER ForceGC
    Indique si le garbage collector doit être forcé avant de mesurer l'utilisation finale de la mémoire.
    Par défaut, c'est $false.

.EXAMPLE
    Stop-MemorySnapshot -Name "MaFonction"
    Arrête l'instantané de mémoire nommé "MaFonction" et journalise le résultat.

.OUTPUTS
    [double] L'utilisation de la mémoire en octets.
#>
function Stop-MemorySnapshot {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult = $true,

        [Parameter(Mandatory = $false)]
        [switch]$ForceGC = $false
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les instantanés, les statistiques et les seuils
    Import-MemorySnapshots
    Import-MemoryStatistics
    Import-MemoryThresholds

    # Vérifier si l'instantané existe
    if (-not $script:MemorySnapshots.ContainsKey($Name)) {
        Write-Log -Message "L'instantané de mémoire '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Forcer le garbage collector si demandé
    if ($ForceGC) {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }

    # Obtenir l'utilisation actuelle de la mémoire
    $process = Get-Process -Id $PID
    $memoryUsage = $process.WorkingSet64

    # Mettre à jour l'instantané
    $snapshot = $script:MemorySnapshots[$Name]
    $snapshot.EndMemory = $memoryUsage
    $memoryDiff = $memoryUsage - $snapshot.StartMemory
    $snapshot.MemoryUsed = [Math]::Max(0, $memoryDiff)  # Assurer que l'utilisation de la mémoire n'est jamais négative
    $snapshot.EndTime = Get-Date

    # Mettre à jour les statistiques
    $stats = $script:MemoryStatistics[$Name]
    $stats.Count++
    $stats.TotalBytes += $snapshot.MemoryUsed
    $stats.MinBytes = [Math]::Min($stats.MinBytes, $snapshot.MemoryUsed)
    $stats.MaxBytes = [Math]::Max($stats.MaxBytes, $snapshot.MemoryUsed)
    $stats.LastBytes = $snapshot.MemoryUsed
    $stats.AverageBytes = $stats.TotalBytes / $stats.Count

    # Sauvegarder les instantanés et les statistiques
    Save-MemorySnapshots
    Save-MemoryStatistics

    # Journaliser le résultat si demandé
    if ($LogResult) {
        $memoryUsedMB = $snapshot.MemoryUsed / 1MB
        $message = "Instantané de mémoire '$Name' arrêté. Utilisation de la mémoire: $($memoryUsedMB.ToString("F2")) MB."

        # Vérifier si un seuil est défini pour cet instantané
        if ($script:MemoryThresholds.ContainsKey($Name)) {
            $threshold = $script:MemoryThresholds[$Name]
            if ($snapshot.MemoryUsed -gt $threshold) {
                $thresholdMB = $threshold / 1MB
                $message += " ATTENTION: Seuil de $thresholdMB MB dépassé!"
                Write-Log -Message $message -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            } else {
                Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
            }
        } else {
            Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        }
    }

    # Retourner l'utilisation de la mémoire
    return $snapshot.MemoryUsed
}

<#
.SYNOPSIS
    Réinitialise un instantané de mémoire.

.DESCRIPTION
    La fonction Reset-MemorySnapshot réinitialise un instantané de mémoire.
    Elle arrête l'instantané s'il est en cours et le redémarre.

.PARAMETER Name
    Le nom de l'instantané à réinitialiser.

.EXAMPLE
    Reset-MemorySnapshot -Name "MaFonction"
    Réinitialise l'instantané de mémoire nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Reset-MemorySnapshot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Vérifier si l'instantané existe
    if (-not $script:MemorySnapshots.ContainsKey($Name)) {
        Write-Log -Message "L'instantané de mémoire '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # Arrêter l'instantané s'il est en cours
    if ($null -eq $script:MemorySnapshots[$Name].EndMemory) {
        Stop-MemorySnapshot -Name $Name -LogResult:$false
    }

    # Redémarrer l'instantané
    Start-MemorySnapshot -Name $Name -Reset

    Write-Log -Message "Instantané de mémoire '$Name' réinitialisé." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Obtient les statistiques de mémoire pour un instantané.

.DESCRIPTION
    La fonction Get-MemoryStatistics obtient les statistiques de mémoire pour un instantané.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, l'utilisation totale, etc.

.PARAMETER Name
    Le nom de l'instantané.
    Si non spécifié, retourne les statistiques pour tous les instantanés.

.EXAMPLE
    Get-MemoryStatistics -Name "MaFonction"
    Obtient les statistiques pour l'instantané nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques de mémoire.
#>
function Get-MemoryStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Charger les statistiques
    Import-MemoryStatistics

    # Si un nom est spécifié, retourner les statistiques pour cet instantané
    if ($Name) {
        if (-not $script:MemoryStatistics.ContainsKey($Name)) {
            Write-Log -Message "Aucune statistique de mémoire disponible pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            return $null
        }

        $stats = $script:MemoryStatistics[$Name]
        return [PSCustomObject]@{
            Name         = $Name
            Count        = $stats.Count
            TotalBytes   = $stats.TotalBytes
            MinBytes     = $stats.MinBytes
            MaxBytes     = $stats.MaxBytes
            LastBytes    = $stats.LastBytes
            AverageBytes = $stats.AverageBytes
            TotalMB      = $stats.TotalBytes / 1MB
            MinMB        = $stats.MinBytes / 1MB
            MaxMB        = $stats.MaxBytes / 1MB
            LastMB       = $stats.LastBytes / 1MB
            AverageMB    = $stats.AverageBytes / 1MB
        }
    }

    # Sinon, retourner les statistiques pour tous les instantanés
    $result = @()
    foreach ($key in $script:MemoryStatistics.Keys) {
        $stats = $script:MemoryStatistics[$key]
        $result += [PSCustomObject]@{
            Name         = $key
            Count        = $stats.Count
            TotalBytes   = $stats.TotalBytes
            MinBytes     = $stats.MinBytes
            MaxBytes     = $stats.MaxBytes
            LastBytes    = $stats.LastBytes
            AverageBytes = $stats.AverageBytes
            TotalMB      = $stats.TotalBytes / 1MB
            MinMB        = $stats.MinBytes / 1MB
            MaxMB        = $stats.MaxBytes / 1MB
            LastMB       = $stats.LastBytes / 1MB
            AverageMB    = $stats.AverageBytes / 1MB
        }
    }

    return $result
}

<#
.SYNOPSIS
    Définit un seuil de mémoire pour un instantané.

.DESCRIPTION
    La fonction Set-MemoryThreshold définit un seuil de mémoire pour un instantané.
    Si l'utilisation de la mémoire dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom de l'instantané.

.PARAMETER ThresholdBytes
    Le seuil en octets.

.PARAMETER ThresholdMB
    Le seuil en mégaoctets.

.EXAMPLE
    Set-MemoryThreshold -Name "MaFonction" -ThresholdMB 100
    Définit un seuil de 100 MB pour l'instantané nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Set-MemoryThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [double]$ThresholdBytes,

        [Parameter(Mandatory = $false)]
        [double]$ThresholdMB
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les seuils
    Import-MemoryThresholds

    # Convertir le seuil en octets si spécifié en MB
    if ($PSBoundParameters.ContainsKey('ThresholdMB')) {
        $ThresholdBytes = $ThresholdMB * 1MB
    }

    # Vérifier si le seuil est spécifié
    if (-not $PSBoundParameters.ContainsKey('ThresholdBytes') -and -not $PSBoundParameters.ContainsKey('ThresholdMB')) {
        Write-Log -Message "Aucun seuil spécifié pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # Définir le seuil
    $script:MemoryThresholds[$Name] = $ThresholdBytes

    # Sauvegarder les seuils
    Save-MemoryThresholds

    $thresholdMB = $ThresholdBytes / 1MB
    Write-Log -Message "Seuil de mémoire pour '$Name' défini à $($thresholdMB.ToString("F2")) MB." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure l'utilisation de la mémoire d'un bloc de code.

.DESCRIPTION
    La fonction Measure-MemoryUsage mesure l'utilisation de la mémoire d'un bloc de code.
    Elle prend un instantané avant et après l'exécution du bloc de code, puis calcule la différence.

.PARAMETER Name
    Le nom de la mesure.

.PARAMETER ScriptBlock
    Le bloc de code à exécuter.

.PARAMETER InputObject
    L'objet à passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments à passer au bloc de code.

.PARAMETER ForceGC
    Indique si le garbage collector doit être forcé avant de mesurer l'utilisation finale de la mémoire.
    Par défaut, c'est $false.

.EXAMPLE
    Measure-MemoryUsage -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure l'utilisation de la mémoire de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le résultat du bloc de code et l'utilisation de la mémoire.
#>
function Measure-MemoryUsage {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch]$ForceGC = $false
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        # Exécuter le bloc de code sans mesure
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                return $InputObject | & $ScriptBlock @ArgumentList
            } else {
                return $InputObject | & $ScriptBlock
            }
        } else {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                return & $ScriptBlock @ArgumentList
            } else {
                return & $ScriptBlock
            }
        }
    }

    # Démarrer l'instantané de mémoire
    Start-MemorySnapshot -Name $Name

    # Exécuter le bloc de code
    $result = $null
    try {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = $InputObject | & $ScriptBlock @ArgumentList
            } else {
                $result = $InputObject | & $ScriptBlock
            }
        } else {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = & $ScriptBlock @ArgumentList
            } else {
                $result = & $ScriptBlock
            }
        }
    } catch {
        # Arrêter l'instantané en cas d'erreur
        $memoryUsed = Stop-MemorySnapshot -Name $Name -ForceGC:$ForceGC

        # Relancer l'erreur
        throw $_
    }

    # Arrêter l'instantané
    $memoryUsed = Stop-MemorySnapshot -Name $Name -ForceGC:$ForceGC

    # Retourner le résultat et l'utilisation de la mémoire
    return [PSCustomObject]@{
        Result          = $result
        MemoryUsedBytes = $memoryUsed
        MemoryUsedMB    = $memoryUsed / 1MB
    }
}

<#
.SYNOPSIS
    Initialise un compteur d'opérations.

.DESCRIPTION
    La fonction Initialize-OperationCounter initialise un compteur d'opérations.
    Elle crée un nouveau compteur ou réinitialise un compteur existant.

.PARAMETER Name
    Le nom du compteur.
    Ce nom est utilisé pour identifier le compteur lors de l'incrémentation ou de la réinitialisation.

.PARAMETER Reset
    Indique si le compteur doit être réinitialisé s'il existe déjà.
    Par défaut, c'est $true.

.PARAMETER InitialValue
    La valeur initiale du compteur.
    Par défaut, c'est 0.

.EXAMPLE
    Initialize-OperationCounter -Name "MaFonction"
    Initialise un compteur d'opérations nommé "MaFonction" avec une valeur initiale de 0.

.OUTPUTS
    [void]
#>
function Initialize-OperationCounter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Reset,

        [Parameter(Mandatory = $false)]
        [int]$InitialValue = 0
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les compteurs et les statistiques
    Import-OperationCounters
    Import-OperationStatistics

    # Vérifier si le compteur existe déjà
    if ($script:OperationCounters.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "Le compteur d'opérations '$Name' existe déjà." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # Créer ou réinitialiser le compteur
    $script:OperationCounters[$Name] = $InitialValue

    # Initialiser les statistiques si elles n'existent pas
    if (-not $script:OperationStatistics.ContainsKey($Name)) {
        $script:OperationStatistics[$Name] = @{
            Count             = 0
            TotalOperations   = 0
            MinOperations     = [int]::MaxValue
            MaxOperations     = 0
            LastOperations    = 0
            AverageOperations = 0
        }
    }

    # Sauvegarder les compteurs et les statistiques
    Save-OperationCounters
    Save-OperationStatistics

    Write-Log -Message "Compteur d'opérations '$Name' initialisé à $InitialValue." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Incrémente un compteur d'opérations.

.DESCRIPTION
    La fonction Increment-OperationCounter incrémente un compteur d'opérations.
    Elle crée le compteur s'il n'existe pas.

.PARAMETER Name
    Le nom du compteur à incrémenter.

.PARAMETER IncrementBy
    La valeur à ajouter au compteur.
    Par défaut, c'est 1.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $false.

.EXAMPLE
    Increment-OperationCounter -Name "MaFonction"
    Incrémente le compteur d'opérations nommé "MaFonction" de 1.

.OUTPUTS
    [int] La nouvelle valeur du compteur.
#>
function Increment-OperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [int]$IncrementBy = 1,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs et les seuils
    Import-OperationCounters
    Import-OperationThresholds

    # Vérifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        # Initialiser le compteur
        Initialize-OperationCounter -Name $Name
    } else {
        # Incrémenter le compteur
        $script:OperationCounters[$Name] += $IncrementBy

        # Sauvegarder les compteurs
        Save-OperationCounters
    }

    # Journaliser le résultat si demandé
    if ($LogResult) {
        $message = "Compteur d'opérations '$Name' incrémenté de $IncrementBy. Nouvelle valeur: $($script:OperationCounters[$Name])."

        # Vérifier si un seuil est défini pour ce compteur
        if ($script:OperationThresholds.ContainsKey($Name)) {
            $threshold = $script:OperationThresholds[$Name]
            if ($script:OperationCounters[$Name] -gt $threshold) {
                $message += " ATTENTION: Seuil de $threshold dépassé!"
                Write-Log -Message $message -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            } else {
                Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
            }
        } else {
            Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        }
    }

    # Retourner la nouvelle valeur du compteur
    return $script:OperationCounters[$Name]
}

<#
.SYNOPSIS
    Réinitialise un compteur d'opérations.

.DESCRIPTION
    La fonction Reset-OperationCounter réinitialise un compteur d'opérations.
    Elle met à jour les statistiques pour le compteur spécifié.

.PARAMETER Name
    Le nom du compteur à réinitialiser.

.PARAMETER LogResult
    Indique si le résultat doit être journalisé.
    Par défaut, c'est $true.

.EXAMPLE
    Reset-OperationCounter -Name "MaFonction"
    Réinitialise le compteur d'opérations nommé "MaFonction" et journalise le résultat.

.OUTPUTS
    [int] La valeur du compteur avant la réinitialisation.
#>
function Reset-OperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$LogResult = $true
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs et les statistiques
    Import-OperationCounters
    Import-OperationStatistics

    # Vérifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        Write-Log -Message "Le compteur d'opérations '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Obtenir la valeur actuelle du compteur
    $currentValue = $script:OperationCounters[$Name]

    # Mettre à jour les statistiques
    $stats = $script:OperationStatistics[$Name]
    $stats.Count++
    $stats.TotalOperations += $currentValue
    $stats.MinOperations = [Math]::Min($stats.MinOperations, $currentValue)
    $stats.MaxOperations = [Math]::Max($stats.MaxOperations, $currentValue)
    $stats.LastOperations = $currentValue
    $stats.AverageOperations = $stats.TotalOperations / $stats.Count

    # Réinitialiser le compteur
    $script:OperationCounters[$Name] = 0

    # Sauvegarder les compteurs et les statistiques
    Save-OperationCounters
    Save-OperationStatistics

    # Journaliser le résultat si demandé
    if ($LogResult) {
        $message = "Compteur d'opérations '$Name' réinitialisé. Valeur précédente: $currentValue."
        Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
    }

    # Retourner la valeur précédente du compteur
    return $currentValue
}

<#
.SYNOPSIS
    Obtient la valeur d'un compteur d'opérations.

.DESCRIPTION
    La fonction Get-OperationCounter obtient la valeur d'un compteur d'opérations.
    Elle retourne 0 si le compteur n'existe pas.

.PARAMETER Name
    Le nom du compteur.

.EXAMPLE
    Get-OperationCounter -Name "MaFonction"
    Obtient la valeur du compteur d'opérations nommé "MaFonction".

.OUTPUTS
    [int] La valeur du compteur.
#>
function Get-OperationCounter {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs
    Import-OperationCounters

    # Vérifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        Write-Log -Message "Le compteur d'opérations '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Retourner la valeur du compteur
    return $script:OperationCounters[$Name]
}

<#
.SYNOPSIS
    Obtient les statistiques d'opérations pour un compteur.

.DESCRIPTION
    La fonction Get-OperationStatistics obtient les statistiques d'opérations pour un compteur.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exécutions, le total d'opérations, etc.

.PARAMETER Name
    Le nom du compteur.
    Si non spécifié, retourne les statistiques pour tous les compteurs.

.EXAMPLE
    Get-OperationStatistics -Name "MaFonction"
    Obtient les statistiques pour le compteur nommé "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques d'opérations.
#>
function Get-OperationStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Charger les statistiques
    Import-OperationStatistics

    # Si un nom est spécifié, retourner les statistiques pour ce compteur
    if ($Name) {
        if (-not $script:OperationStatistics.ContainsKey($Name)) {
            Write-Log -Message "Aucune statistique d'opérations disponible pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            return $null
        }

        $stats = $script:OperationStatistics[$Name]
        return [PSCustomObject]@{
            Name              = $Name
            Count             = $stats.Count
            TotalOperations   = $stats.TotalOperations
            MinOperations     = $stats.MinOperations
            MaxOperations     = $stats.MaxOperations
            LastOperations    = $stats.LastOperations
            AverageOperations = $stats.AverageOperations
            CurrentValue      = Get-OperationCounter -Name $Name
        }
    }

    # Sinon, retourner les statistiques pour tous les compteurs
    $result = @()
    foreach ($key in $script:OperationStatistics.Keys) {
        $stats = $script:OperationStatistics[$key]
        $result += [PSCustomObject]@{
            Name              = $key
            Count             = $stats.Count
            TotalOperations   = $stats.TotalOperations
            MinOperations     = $stats.MinOperations
            MaxOperations     = $stats.MaxOperations
            LastOperations    = $stats.LastOperations
            AverageOperations = $stats.AverageOperations
            CurrentValue      = Get-OperationCounter -Name $key
        }
    }

    return $result
}

<#
.SYNOPSIS
    Définit un seuil d'opérations pour un compteur.

.DESCRIPTION
    La fonction Set-OperationThreshold définit un seuil d'opérations pour un compteur.
    Si le nombre d'opérations dépasse ce seuil, un avertissement sera journalisé.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER Threshold
    Le seuil d'opérations.

.EXAMPLE
    Set-OperationThreshold -Name "MaFonction" -Threshold 1000
    Définit un seuil de 1000 opérations pour le compteur nommé "MaFonction".

.OUTPUTS
    [void]
#>
function Set-OperationThreshold {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Threshold
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les seuils
    Import-OperationThresholds

    # Définir le seuil
    $script:OperationThresholds[$Name] = $Threshold

    # Sauvegarder les seuils
    Save-OperationThresholds

    Write-Log -Message "Seuil d'opérations pour '$Name' défini à $Threshold." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure le nombre d'opérations effectuées par un bloc de code.

.DESCRIPTION
    La fonction Measure-Operations mesure le nombre d'opérations effectuées par un bloc de code.
    Elle initialise un compteur, exécute le bloc de code, puis réinitialise le compteur.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER ScriptBlock
    Le bloc de code à exécuter.

.PARAMETER InputObject
    L'objet à passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments à passer au bloc de code.

.EXAMPLE
    Measure-Operations -Name "MaFonction" -ScriptBlock {
        for ($i = 0; $i -lt 1000; $i++) {
            Increment-OperationCounter -Name "MaFonction"
        }
    }
    Mesure le nombre d'opérations effectuées par le bloc de code.

.OUTPUTS
    [PSCustomObject] Un objet contenant le résultat du bloc de code et le nombre d'opérations.
#>
function Measure-Operations {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList
    )

    # Vérifier si la mesure de performance est activée
    if (-not $script:PerformanceEnabled) {
        # Exécuter le bloc de code sans mesure
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                return $InputObject | & $ScriptBlock @ArgumentList
            } else {
                return $InputObject | & $ScriptBlock
            }
        } else {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                return & $ScriptBlock @ArgumentList
            } else {
                return & $ScriptBlock
            }
        }
    }

    # Initialiser le compteur
    Initialize-OperationCounter -Name $Name -Reset

    # Exécuter le bloc de code
    $result = $null
    try {
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = $InputObject | & $ScriptBlock @ArgumentList
            } else {
                $result = $InputObject | & $ScriptBlock
            }
        } else {
            if ($PSBoundParameters.ContainsKey('ArgumentList')) {
                $result = & $ScriptBlock @ArgumentList
            } else {
                $result = & $ScriptBlock
            }
        }
    } catch {
        # Obtenir le nombre d'opérations en cas d'erreur
        $operationCount = Get-OperationCounter -Name $Name

        # Réinitialiser le compteur
        Reset-OperationCounter -Name $Name -LogResult:$false

        # Relancer l'erreur
        throw $_
    }

    # Obtenir le nombre d'opérations
    $operationCount = Get-OperationCounter -Name $Name

    # Réinitialiser le compteur
    Reset-OperationCounter -Name $Name

    # Retourner le résultat et le nombre d'opérations
    return [PSCustomObject]@{
        Result         = $result
        OperationCount = $operationCount
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Set-PerformanceMeasurementConfiguration, Get-PerformanceMeasurementConfiguration,
Start-PerformanceTimer, Stop-PerformanceTimer, Reset-PerformanceTimer,
Get-PerformanceStatistics, Set-PerformanceThreshold, Measure-ExecutionTime,
Start-MemorySnapshot, Stop-MemorySnapshot, Reset-MemorySnapshot,
Get-MemoryStatistics, Set-MemoryThreshold, Measure-MemoryUsage,
Initialize-OperationCounter, Increment-OperationCounter, Reset-OperationCounter,
Get-OperationCounter, Get-OperationStatistics, Set-OperationThreshold, Measure-Operations
