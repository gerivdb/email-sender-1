<#
.SYNOPSIS
    DÃ©finit les fonctions de mesure de performance pour le module RoadmapParser.

.DESCRIPTION
    Ce script dÃ©finit les fonctions de mesure de performance utilisÃ©es par le module RoadmapParser.
    Il inclut des fonctions pour mesurer le temps d'exÃ©cution, l'utilisation de la mÃ©moire et le comptage d'opÃ©rations.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-23
#>

# Importer le script des fonctions de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$loggingFunctionsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Logging\LoggingFunctions.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $loggingFunctionsPath)) {
    throw "Le fichier LoggingFunctions.ps1 est introuvable Ã  l'emplacement : $loggingFunctionsPath"
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

# Fichiers temporaires pour stocker les donnÃ©es de performance
$script:PerformanceTimersFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceTimers.xml"
$script:PerformanceStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceStatistics.xml"
$script:PerformanceThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_PerformanceThresholds.xml"
$script:MemorySnapshotsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemorySnapshots.xml"
$script:MemoryStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemoryStatistics.xml"
$script:MemoryThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_MemoryThresholds.xml"
$script:OperationCountersFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationCounters.xml"
$script:OperationStatisticsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationStatistics.xml"
$script:OperationThresholdsFile = Join-Path -Path $env:TEMP -ChildPath "RoadmapParser_OperationThresholds.xml"

# Fonctions pour sauvegarder et charger les donnÃ©es de performance

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

# Fonction pour sauvegarder les instantanÃ©s de mÃ©moire dans un fichier
function Save-MemorySnapshots {
    if (Test-Path -Path $script:MemorySnapshotsFile) {
        $script:MemorySnapshots | Export-Clixml -Path $script:MemorySnapshotsFile -Force
    } else {
        $script:MemorySnapshots | Export-Clixml -Path $script:MemorySnapshotsFile
    }
}

# Fonction pour charger les instantanÃ©s de mÃ©moire depuis un fichier
function Import-MemorySnapshots {
    if (Test-Path -Path $script:MemorySnapshotsFile) {
        $script:MemorySnapshots = Import-Clixml -Path $script:MemorySnapshotsFile
    } else {
        $script:MemorySnapshots = @{}
    }
}

# Fonction pour sauvegarder les statistiques de mÃ©moire dans un fichier
function Save-MemoryStatistics {
    if (Test-Path -Path $script:MemoryStatisticsFile) {
        $script:MemoryStatistics | Export-Clixml -Path $script:MemoryStatisticsFile -Force
    } else {
        $script:MemoryStatistics | Export-Clixml -Path $script:MemoryStatisticsFile
    }
}

# Fonction pour charger les statistiques de mÃ©moire depuis un fichier
function Import-MemoryStatistics {
    if (Test-Path -Path $script:MemoryStatisticsFile) {
        $script:MemoryStatistics = Import-Clixml -Path $script:MemoryStatisticsFile
    } else {
        $script:MemoryStatistics = @{}
    }
}

# Fonction pour sauvegarder les seuils de mÃ©moire dans un fichier
function Save-MemoryThresholds {
    if (Test-Path -Path $script:MemoryThresholdsFile) {
        $script:MemoryThresholds | Export-Clixml -Path $script:MemoryThresholdsFile -Force
    } else {
        $script:MemoryThresholds | Export-Clixml -Path $script:MemoryThresholdsFile
    }
}

# Fonction pour charger les seuils de mÃ©moire depuis un fichier
function Import-MemoryThresholds {
    if (Test-Path -Path $script:MemoryThresholdsFile) {
        $script:MemoryThresholds = Import-Clixml -Path $script:MemoryThresholdsFile
    } else {
        $script:MemoryThresholds = @{}
    }
}

# Fonction pour sauvegarder les compteurs d'opÃ©rations dans un fichier
function Save-OperationCounters {
    if (Test-Path -Path $script:OperationCountersFile) {
        $script:OperationCounters | Export-Clixml -Path $script:OperationCountersFile -Force
    } else {
        $script:OperationCounters | Export-Clixml -Path $script:OperationCountersFile
    }
}

# Fonction pour charger les compteurs d'opÃ©rations depuis un fichier
function Import-OperationCounters {
    if (Test-Path -Path $script:OperationCountersFile) {
        $script:OperationCounters = Import-Clixml -Path $script:OperationCountersFile
    } else {
        $script:OperationCounters = @{}
    }
}

# Fonction pour sauvegarder les statistiques d'opÃ©rations dans un fichier
function Save-OperationStatistics {
    if (Test-Path -Path $script:OperationStatisticsFile) {
        $script:OperationStatistics | Export-Clixml -Path $script:OperationStatisticsFile -Force
    } else {
        $script:OperationStatistics | Export-Clixml -Path $script:OperationStatisticsFile
    }
}

# Fonction pour charger les statistiques d'opÃ©rations depuis un fichier
function Import-OperationStatistics {
    if (Test-Path -Path $script:OperationStatisticsFile) {
        $script:OperationStatistics = Import-Clixml -Path $script:OperationStatisticsFile
    } else {
        $script:OperationStatistics = @{}
    }
}

# Fonction pour sauvegarder les seuils d'opÃ©rations dans un fichier
function Save-OperationThresholds {
    if (Test-Path -Path $script:OperationThresholdsFile) {
        $script:OperationThresholds | Export-Clixml -Path $script:OperationThresholdsFile -Force
    } else {
        $script:OperationThresholds | Export-Clixml -Path $script:OperationThresholdsFile
    }
}

# Fonction pour charger les seuils d'opÃ©rations depuis un fichier
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
    Elle permet de dÃ©finir les paramÃ¨tres de mesure tels que l'activation, le niveau de journalisation, etc.

.PARAMETER Enabled
    Indique si la mesure de performance est activÃ©e.
    Par dÃ©faut, c'est $true.

.PARAMETER LogLevel
    Le niveau de journalisation pour les mesures de performance.
    Par dÃ©faut, c'est LogLevelDebug.

.PARAMETER Category
    La catÃ©gorie Ã  utiliser pour la journalisation.
    Par dÃ©faut, c'est "Performance".

.EXAMPLE
    Set-PerformanceMeasurementConfiguration -Enabled $true -LogLevel $LogLevelDebug
    Configure la mesure de performance pour Ãªtre activÃ©e, avec un niveau de dÃ©bogage.

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

    # Mettre Ã  jour la configuration
    $script:PerformanceEnabled = $Enabled
    $script:PerformanceCategory = $Category
}

<#
.SYNOPSIS
    Obtient la configuration de mesure de performance.

.DESCRIPTION
    La fonction Get-PerformanceMeasurementConfiguration obtient la configuration de mesure de performance.
    Elle retourne un objet contenant les paramÃ¨tres de mesure actuels.

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
    DÃ©marre un chronomÃ¨tre pour mesurer le temps d'exÃ©cution.

.DESCRIPTION
    La fonction Start-PerformanceTimer dÃ©marre un chronomÃ¨tre pour mesurer le temps d'exÃ©cution.
    Elle crÃ©e un nouveau chronomÃ¨tre ou rÃ©initialise un chronomÃ¨tre existant.

.PARAMETER Name
    Le nom du chronomÃ¨tre.
    Ce nom est utilisÃ© pour identifier le chronomÃ¨tre lors de l'arrÃªt ou de la rÃ©initialisation.

.PARAMETER Reset
    Indique si le chronomÃ¨tre doit Ãªtre rÃ©initialisÃ© s'il existe dÃ©jÃ .
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Start-PerformanceTimer -Name "MaFonction"
    DÃ©marre un chronomÃ¨tre nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # VÃ©rifier si le chronomÃ¨tre existe dÃ©jÃ 
    if ($script:PerformanceTimers.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "Le chronomÃ¨tre '$Name' est dÃ©jÃ  en cours d'exÃ©cution." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # CrÃ©er ou rÃ©initialiser le chronomÃ¨tre
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

    Write-Log -Message "ChronomÃ¨tre '$Name' dÃ©marrÃ©." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    ArrÃªte un chronomÃ¨tre et enregistre le temps d'exÃ©cution.

.DESCRIPTION
    La fonction Stop-PerformanceTimer arrÃªte un chronomÃ¨tre et enregistre le temps d'exÃ©cution.
    Elle met Ã  jour les statistiques pour le chronomÃ¨tre spÃ©cifiÃ©.

.PARAMETER Name
    Le nom du chronomÃ¨tre Ã  arrÃªter.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Stop-PerformanceTimer -Name "MaFonction"
    ArrÃªte le chronomÃ¨tre nommÃ© "MaFonction" et journalise le rÃ©sultat.

.OUTPUTS
    [double] Le temps d'exÃ©cution en millisecondes.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # VÃ©rifier si le chronomÃ¨tre existe
    if (-not $script:PerformanceTimers.ContainsKey($Name)) {
        Write-Log -Message "Le chronomÃ¨tre '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # ArrÃªter le chronomÃ¨tre
    $stopwatch = $script:PerformanceTimers[$Name]
    $stopwatch.Stop()
    $elapsedMilliseconds = $stopwatch.Elapsed.TotalMilliseconds

    # Mettre Ã  jour les statistiques
    $stats = $script:PerformanceStatistics[$Name]
    $stats.Count++
    $stats.TotalMilliseconds += $elapsedMilliseconds
    $stats.MinMilliseconds = [Math]::Min($stats.MinMilliseconds, $elapsedMilliseconds)
    $stats.MaxMilliseconds = [Math]::Max($stats.MaxMilliseconds, $elapsedMilliseconds)
    $stats.LastMilliseconds = $elapsedMilliseconds
    $stats.AverageMilliseconds = $stats.TotalMilliseconds / $stats.Count

    # Journaliser le rÃ©sultat si demandÃ©
    if ($LogResult) {
        $message = "ChronomÃ¨tre '$Name' arrÃªtÃ©. Temps Ã©coulÃ©: $($elapsedMilliseconds.ToString("F2")) ms."

        # VÃ©rifier si un seuil est dÃ©fini pour ce chronomÃ¨tre
        if ($script:PerformanceThresholds.ContainsKey($Name)) {
            $threshold = $script:PerformanceThresholds[$Name]
            if ($elapsedMilliseconds -gt $threshold) {
                $message += " ATTENTION: Seuil de $threshold ms dÃ©passÃ©!"
                Write-Log -Message $message -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            } else {
                Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
            }
        } else {
            Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        }
    }

    # Retourner le temps Ã©coulÃ©
    return $elapsedMilliseconds
}

<#
.SYNOPSIS
    RÃ©initialise un chronomÃ¨tre.

.DESCRIPTION
    La fonction Reset-PerformanceTimer rÃ©initialise un chronomÃ¨tre.
    Elle arrÃªte le chronomÃ¨tre s'il est en cours d'exÃ©cution et le redÃ©marre.

.PARAMETER Name
    Le nom du chronomÃ¨tre Ã  rÃ©initialiser.

.EXAMPLE
    Reset-PerformanceTimer -Name "MaFonction"
    RÃ©initialise le chronomÃ¨tre nommÃ© "MaFonction".

.OUTPUTS
    [void]
#>
function Reset-PerformanceTimer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # VÃ©rifier si le chronomÃ¨tre existe
    if (-not $script:PerformanceTimers.ContainsKey($Name)) {
        Write-Log -Message "Le chronomÃ¨tre '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # ArrÃªter le chronomÃ¨tre s'il est en cours d'exÃ©cution
    $stopwatch = $script:PerformanceTimers[$Name]
    if ($stopwatch.IsRunning) {
        $stopwatch.Stop()
    }

    # RedÃ©marrer le chronomÃ¨tre
    $stopwatch.Reset()
    $stopwatch.Start()

    Write-Log -Message "ChronomÃ¨tre '$Name' rÃ©initialisÃ©." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Obtient les statistiques de performance pour un chronomÃ¨tre.

.DESCRIPTION
    La fonction Get-PerformanceStatistics obtient les statistiques de performance pour un chronomÃ¨tre.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exÃ©cutions, le temps total, etc.

.PARAMETER Name
    Le nom du chronomÃ¨tre.
    Si non spÃ©cifiÃ©, retourne les statistiques pour tous les chronomÃ¨tres.

.EXAMPLE
    Get-PerformanceStatistics -Name "MaFonction"
    Obtient les statistiques pour le chronomÃ¨tre nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Si un nom est spÃ©cifiÃ©, retourner les statistiques pour ce chronomÃ¨tre
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

    # Sinon, retourner les statistiques pour tous les chronomÃ¨tres
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
    DÃ©finit un seuil de performance pour un chronomÃ¨tre.

.DESCRIPTION
    La fonction Set-PerformanceThreshold dÃ©finit un seuil de performance pour un chronomÃ¨tre.
    Si le temps d'exÃ©cution dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom du chronomÃ¨tre.

.PARAMETER ThresholdMilliseconds
    Le seuil en millisecondes.

.EXAMPLE
    Set-PerformanceThreshold -Name "MaFonction" -ThresholdMilliseconds 100
    DÃ©finit un seuil de 100 ms pour le chronomÃ¨tre nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # DÃ©finir le seuil
    $script:PerformanceThresholds[$Name] = $ThresholdMilliseconds

    Write-Log -Message "Seuil de performance pour '$Name' dÃ©fini Ã  $ThresholdMilliseconds ms." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure le temps d'exÃ©cution d'un bloc de code.

.DESCRIPTION
    La fonction Measure-ExecutionTime mesure le temps d'exÃ©cution d'un bloc de code.
    Elle dÃ©marre un chronomÃ¨tre, exÃ©cute le bloc de code, puis arrÃªte le chronomÃ¨tre.

.PARAMETER Name
    Le nom du chronomÃ¨tre.

.PARAMETER ScriptBlock
    Le bloc de code Ã  exÃ©cuter.

.PARAMETER InputObject
    L'objet Ã  passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments Ã  passer au bloc de code.

.EXAMPLE
    Measure-ExecutionTime -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure le temps d'exÃ©cution de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le rÃ©sultat du bloc de code et le temps d'exÃ©cution.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        # ExÃ©cuter le bloc de code sans mesure
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

    # DÃ©marrer le chronomÃ¨tre
    Start-PerformanceTimer -Name $Name

    # ExÃ©cuter le bloc de code
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
        # ArrÃªter le chronomÃ¨tre en cas d'erreur
        $elapsedMilliseconds = Stop-PerformanceTimer -Name $Name

        # Relancer l'erreur
        throw $_
    }

    # ArrÃªter le chronomÃ¨tre
    $elapsedMilliseconds = Stop-PerformanceTimer -Name $Name

    # Retourner le rÃ©sultat et le temps d'exÃ©cution
    return [PSCustomObject]@{
        Result              = $result
        ElapsedMilliseconds = $elapsedMilliseconds
    }
}

<#
.SYNOPSIS
    Prend un instantanÃ© de l'utilisation de la mÃ©moire.

.DESCRIPTION
    La fonction Start-MemorySnapshot prend un instantanÃ© de l'utilisation de la mÃ©moire.
    Elle enregistre l'utilisation actuelle de la mÃ©moire pour une comparaison ultÃ©rieure.

.PARAMETER Name
    Le nom de l'instantanÃ©.
    Ce nom est utilisÃ© pour identifier l'instantanÃ© lors de la comparaison.

.PARAMETER Reset
    Indique si l'instantanÃ© doit Ãªtre rÃ©initialisÃ© s'il existe dÃ©jÃ .
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Start-MemorySnapshot -Name "MaFonction"
    Prend un instantanÃ© de l'utilisation de la mÃ©moire nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les instantanÃ©s et les statistiques
    Import-MemorySnapshots
    Import-MemoryStatistics

    # VÃ©rifier si l'instantanÃ© existe dÃ©jÃ 
    if ($script:MemorySnapshots.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "L'instantanÃ© de mÃ©moire '$Name' existe dÃ©jÃ ." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # Obtenir l'utilisation actuelle de la mÃ©moire
    $process = Get-Process -Id $PID
    $memoryUsage = $process.WorkingSet64

    # CrÃ©er ou rÃ©initialiser l'instantanÃ©
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

    # Sauvegarder les instantanÃ©s et les statistiques
    Save-MemorySnapshots
    Save-MemoryStatistics

    Write-Log -Message "InstantanÃ© de mÃ©moire '$Name' dÃ©marrÃ©. MÃ©moire initiale: $($memoryUsage / 1MB) MB." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    ArrÃªte un instantanÃ© de mÃ©moire et calcule l'utilisation de la mÃ©moire.

.DESCRIPTION
    La fonction Stop-MemorySnapshot arrÃªte un instantanÃ© de mÃ©moire et calcule l'utilisation de la mÃ©moire.
    Elle met Ã  jour les statistiques pour l'instantanÃ© spÃ©cifiÃ©.

.PARAMETER Name
    Le nom de l'instantanÃ© Ã  arrÃªter.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $true.

.PARAMETER ForceGC
    Indique si le garbage collector doit Ãªtre forcÃ© avant de mesurer l'utilisation finale de la mÃ©moire.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Stop-MemorySnapshot -Name "MaFonction"
    ArrÃªte l'instantanÃ© de mÃ©moire nommÃ© "MaFonction" et journalise le rÃ©sultat.

.OUTPUTS
    [double] L'utilisation de la mÃ©moire en octets.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les instantanÃ©s, les statistiques et les seuils
    Import-MemorySnapshots
    Import-MemoryStatistics
    Import-MemoryThresholds

    # VÃ©rifier si l'instantanÃ© existe
    if (-not $script:MemorySnapshots.ContainsKey($Name)) {
        Write-Log -Message "L'instantanÃ© de mÃ©moire '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Forcer le garbage collector si demandÃ©
    if ($ForceGC) {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
    }

    # Obtenir l'utilisation actuelle de la mÃ©moire
    $process = Get-Process -Id $PID
    $memoryUsage = $process.WorkingSet64

    # Mettre Ã  jour l'instantanÃ©
    $snapshot = $script:MemorySnapshots[$Name]
    $snapshot.EndMemory = $memoryUsage
    $memoryDiff = $memoryUsage - $snapshot.StartMemory
    $snapshot.MemoryUsed = [Math]::Max(0, $memoryDiff)  # Assurer que l'utilisation de la mÃ©moire n'est jamais nÃ©gative
    $snapshot.EndTime = Get-Date

    # Mettre Ã  jour les statistiques
    $stats = $script:MemoryStatistics[$Name]
    $stats.Count++
    $stats.TotalBytes += $snapshot.MemoryUsed
    $stats.MinBytes = [Math]::Min($stats.MinBytes, $snapshot.MemoryUsed)
    $stats.MaxBytes = [Math]::Max($stats.MaxBytes, $snapshot.MemoryUsed)
    $stats.LastBytes = $snapshot.MemoryUsed
    $stats.AverageBytes = $stats.TotalBytes / $stats.Count

    # Sauvegarder les instantanÃ©s et les statistiques
    Save-MemorySnapshots
    Save-MemoryStatistics

    # Journaliser le rÃ©sultat si demandÃ©
    if ($LogResult) {
        $memoryUsedMB = $snapshot.MemoryUsed / 1MB
        $message = "InstantanÃ© de mÃ©moire '$Name' arrÃªtÃ©. Utilisation de la mÃ©moire: $($memoryUsedMB.ToString("F2")) MB."

        # VÃ©rifier si un seuil est dÃ©fini pour cet instantanÃ©
        if ($script:MemoryThresholds.ContainsKey($Name)) {
            $threshold = $script:MemoryThresholds[$Name]
            if ($snapshot.MemoryUsed -gt $threshold) {
                $thresholdMB = $threshold / 1MB
                $message += " ATTENTION: Seuil de $thresholdMB MB dÃ©passÃ©!"
                Write-Log -Message $message -Level $script:LogLevelWarning -Source $script:PerformanceCategory
            } else {
                Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
            }
        } else {
            Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        }
    }

    # Retourner l'utilisation de la mÃ©moire
    return $snapshot.MemoryUsed
}

<#
.SYNOPSIS
    RÃ©initialise un instantanÃ© de mÃ©moire.

.DESCRIPTION
    La fonction Reset-MemorySnapshot rÃ©initialise un instantanÃ© de mÃ©moire.
    Elle arrÃªte l'instantanÃ© s'il est en cours et le redÃ©marre.

.PARAMETER Name
    Le nom de l'instantanÃ© Ã  rÃ©initialiser.

.EXAMPLE
    Reset-MemorySnapshot -Name "MaFonction"
    RÃ©initialise l'instantanÃ© de mÃ©moire nommÃ© "MaFonction".

.OUTPUTS
    [void]
#>
function Reset-MemorySnapshot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # VÃ©rifier si l'instantanÃ© existe
    if (-not $script:MemorySnapshots.ContainsKey($Name)) {
        Write-Log -Message "L'instantanÃ© de mÃ©moire '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # ArrÃªter l'instantanÃ© s'il est en cours
    if ($null -eq $script:MemorySnapshots[$Name].EndMemory) {
        Stop-MemorySnapshot -Name $Name -LogResult:$false
    }

    # RedÃ©marrer l'instantanÃ©
    Start-MemorySnapshot -Name $Name -Reset

    Write-Log -Message "InstantanÃ© de mÃ©moire '$Name' rÃ©initialisÃ©." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Obtient les statistiques de mÃ©moire pour un instantanÃ©.

.DESCRIPTION
    La fonction Get-MemoryStatistics obtient les statistiques de mÃ©moire pour un instantanÃ©.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exÃ©cutions, l'utilisation totale, etc.

.PARAMETER Name
    Le nom de l'instantanÃ©.
    Si non spÃ©cifiÃ©, retourne les statistiques pour tous les instantanÃ©s.

.EXAMPLE
    Get-MemoryStatistics -Name "MaFonction"
    Obtient les statistiques pour l'instantanÃ© nommÃ© "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques de mÃ©moire.
#>
function Get-MemoryStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Charger les statistiques
    Import-MemoryStatistics

    # Si un nom est spÃ©cifiÃ©, retourner les statistiques pour cet instantanÃ©
    if ($Name) {
        if (-not $script:MemoryStatistics.ContainsKey($Name)) {
            Write-Log -Message "Aucune statistique de mÃ©moire disponible pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
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

    # Sinon, retourner les statistiques pour tous les instantanÃ©s
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
    DÃ©finit un seuil de mÃ©moire pour un instantanÃ©.

.DESCRIPTION
    La fonction Set-MemoryThreshold dÃ©finit un seuil de mÃ©moire pour un instantanÃ©.
    Si l'utilisation de la mÃ©moire dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom de l'instantanÃ©.

.PARAMETER ThresholdBytes
    Le seuil en octets.

.PARAMETER ThresholdMB
    Le seuil en mÃ©gaoctets.

.EXAMPLE
    Set-MemoryThreshold -Name "MaFonction" -ThresholdMB 100
    DÃ©finit un seuil de 100 MB pour l'instantanÃ© nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les seuils
    Import-MemoryThresholds

    # Convertir le seuil en octets si spÃ©cifiÃ© en MB
    if ($PSBoundParameters.ContainsKey('ThresholdMB')) {
        $ThresholdBytes = $ThresholdMB * 1MB
    }

    # VÃ©rifier si le seuil est spÃ©cifiÃ©
    if (-not $PSBoundParameters.ContainsKey('ThresholdBytes') -and -not $PSBoundParameters.ContainsKey('ThresholdMB')) {
        Write-Log -Message "Aucun seuil spÃ©cifiÃ© pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return
    }

    # DÃ©finir le seuil
    $script:MemoryThresholds[$Name] = $ThresholdBytes

    # Sauvegarder les seuils
    Save-MemoryThresholds

    $thresholdMB = $ThresholdBytes / 1MB
    Write-Log -Message "Seuil de mÃ©moire pour '$Name' dÃ©fini Ã  $($thresholdMB.ToString("F2")) MB." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure l'utilisation de la mÃ©moire d'un bloc de code.

.DESCRIPTION
    La fonction Measure-MemoryUsage mesure l'utilisation de la mÃ©moire d'un bloc de code.
    Elle prend un instantanÃ© avant et aprÃ¨s l'exÃ©cution du bloc de code, puis calcule la diffÃ©rence.

.PARAMETER Name
    Le nom de la mesure.

.PARAMETER ScriptBlock
    Le bloc de code Ã  exÃ©cuter.

.PARAMETER InputObject
    L'objet Ã  passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments Ã  passer au bloc de code.

.PARAMETER ForceGC
    Indique si le garbage collector doit Ãªtre forcÃ© avant de mesurer l'utilisation finale de la mÃ©moire.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Measure-MemoryUsage -Name "MaFonction" -ScriptBlock { Get-Process }
    Mesure l'utilisation de la mÃ©moire de la commande Get-Process.

.OUTPUTS
    [PSCustomObject] Un objet contenant le rÃ©sultat du bloc de code et l'utilisation de la mÃ©moire.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        # ExÃ©cuter le bloc de code sans mesure
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

    # DÃ©marrer l'instantanÃ© de mÃ©moire
    Start-MemorySnapshot -Name $Name

    # ExÃ©cuter le bloc de code
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
        # ArrÃªter l'instantanÃ© en cas d'erreur
        $memoryUsed = Stop-MemorySnapshot -Name $Name -ForceGC:$ForceGC

        # Relancer l'erreur
        throw $_
    }

    # ArrÃªter l'instantanÃ©
    $memoryUsed = Stop-MemorySnapshot -Name $Name -ForceGC:$ForceGC

    # Retourner le rÃ©sultat et l'utilisation de la mÃ©moire
    return [PSCustomObject]@{
        Result          = $result
        MemoryUsedBytes = $memoryUsed
        MemoryUsedMB    = $memoryUsed / 1MB
    }
}

<#
.SYNOPSIS
    Initialise un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Initialize-OperationCounter initialise un compteur d'opÃ©rations.
    Elle crÃ©e un nouveau compteur ou rÃ©initialise un compteur existant.

.PARAMETER Name
    Le nom du compteur.
    Ce nom est utilisÃ© pour identifier le compteur lors de l'incrÃ©mentation ou de la rÃ©initialisation.

.PARAMETER Reset
    Indique si le compteur doit Ãªtre rÃ©initialisÃ© s'il existe dÃ©jÃ .
    Par dÃ©faut, c'est $true.

.PARAMETER InitialValue
    La valeur initiale du compteur.
    Par dÃ©faut, c'est 0.

.EXAMPLE
    Initialize-OperationCounter -Name "MaFonction"
    Initialise un compteur d'opÃ©rations nommÃ© "MaFonction" avec une valeur initiale de 0.

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les compteurs et les statistiques
    Import-OperationCounters
    Import-OperationStatistics

    # VÃ©rifier si le compteur existe dÃ©jÃ 
    if ($script:OperationCounters.ContainsKey($Name) -and -not $Reset) {
        Write-Log -Message "Le compteur d'opÃ©rations '$Name' existe dÃ©jÃ ." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
        return
    }

    # CrÃ©er ou rÃ©initialiser le compteur
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

    Write-Log -Message "Compteur d'opÃ©rations '$Name' initialisÃ© Ã  $InitialValue." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    IncrÃ©mente un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Add-OperationCounter incrÃ©mente un compteur d'opÃ©rations.
    Elle crÃ©e le compteur s'il n'existe pas.

.PARAMETER Name
    Le nom du compteur Ã  incrÃ©menter.

.PARAMETER IncrementBy
    La valeur Ã  ajouter au compteur.
    Par dÃ©faut, c'est 1.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $false.

.EXAMPLE
    Add-OperationCounter -Name "MaFonction"
    IncrÃ©mente le compteur d'opÃ©rations nommÃ© "MaFonction" de 1.

.OUTPUTS
    [int] La nouvelle valeur du compteur.
#>
function Add-OperationCounter {
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs et les seuils
    Import-OperationCounters
    Import-OperationThresholds

    # VÃ©rifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        # Initialiser le compteur
        Initialize-OperationCounter -Name $Name
    } else {
        # IncrÃ©menter le compteur
        $script:OperationCounters[$Name] += $IncrementBy

        # Sauvegarder les compteurs
        Save-OperationCounters
    }

    # Journaliser le rÃ©sultat si demandÃ©
    if ($LogResult) {
        $message = "Compteur d'opÃ©rations '$Name' incrÃ©mentÃ© de $IncrementBy. Nouvelle valeur: $($script:OperationCounters[$Name])."

        # VÃ©rifier si un seuil est dÃ©fini pour ce compteur
        if ($script:OperationThresholds.ContainsKey($Name)) {
            $threshold = $script:OperationThresholds[$Name]
            if ($script:OperationCounters[$Name] -gt $threshold) {
                $message += " ATTENTION: Seuil de $threshold dÃ©passÃ©!"
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
    RÃ©initialise un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Reset-OperationCounter rÃ©initialise un compteur d'opÃ©rations.
    Elle met Ã  jour les statistiques pour le compteur spÃ©cifiÃ©.

.PARAMETER Name
    Le nom du compteur Ã  rÃ©initialiser.

.PARAMETER LogResult
    Indique si le rÃ©sultat doit Ãªtre journalisÃ©.
    Par dÃ©faut, c'est $true.

.EXAMPLE
    Reset-OperationCounter -Name "MaFonction"
    RÃ©initialise le compteur d'opÃ©rations nommÃ© "MaFonction" et journalise le rÃ©sultat.

.OUTPUTS
    [int] La valeur du compteur avant la rÃ©initialisation.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs et les statistiques
    Import-OperationCounters
    Import-OperationStatistics

    # VÃ©rifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        Write-Log -Message "Le compteur d'opÃ©rations '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Obtenir la valeur actuelle du compteur
    $currentValue = $script:OperationCounters[$Name]

    # Mettre Ã  jour les statistiques
    $stats = $script:OperationStatistics[$Name]
    $stats.Count++
    $stats.TotalOperations += $currentValue
    $stats.MinOperations = [Math]::Min($stats.MinOperations, $currentValue)
    $stats.MaxOperations = [Math]::Max($stats.MaxOperations, $currentValue)
    $stats.LastOperations = $currentValue
    $stats.AverageOperations = $stats.TotalOperations / $stats.Count

    # RÃ©initialiser le compteur
    $script:OperationCounters[$Name] = 0

    # Sauvegarder les compteurs et les statistiques
    Save-OperationCounters
    Save-OperationStatistics

    # Journaliser le rÃ©sultat si demandÃ©
    if ($LogResult) {
        $message = "Compteur d'opÃ©rations '$Name' rÃ©initialisÃ©. Valeur prÃ©cÃ©dente: $currentValue."
        Write-Log -Message $message -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
    }

    # Retourner la valeur prÃ©cÃ©dente du compteur
    return $currentValue
}

<#
.SYNOPSIS
    Obtient la valeur d'un compteur d'opÃ©rations.

.DESCRIPTION
    La fonction Get-OperationCounter obtient la valeur d'un compteur d'opÃ©rations.
    Elle retourne 0 si le compteur n'existe pas.

.PARAMETER Name
    Le nom du compteur.

.EXAMPLE
    Get-OperationCounter -Name "MaFonction"
    Obtient la valeur du compteur d'opÃ©rations nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return 0
    }

    # Charger les compteurs
    Import-OperationCounters

    # VÃ©rifier si le compteur existe
    if (-not $script:OperationCounters.ContainsKey($Name)) {
        Write-Log -Message "Le compteur d'opÃ©rations '$Name' n'existe pas." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
        return 0
    }

    # Retourner la valeur du compteur
    return $script:OperationCounters[$Name]
}

<#
.SYNOPSIS
    Obtient les statistiques d'opÃ©rations pour un compteur.

.DESCRIPTION
    La fonction Get-OperationStatistics obtient les statistiques d'opÃ©rations pour un compteur.
    Elle retourne un objet contenant les statistiques telles que le nombre d'exÃ©cutions, le total d'opÃ©rations, etc.

.PARAMETER Name
    Le nom du compteur.
    Si non spÃ©cifiÃ©, retourne les statistiques pour tous les compteurs.

.EXAMPLE
    Get-OperationStatistics -Name "MaFonction"
    Obtient les statistiques pour le compteur nommÃ© "MaFonction".

.OUTPUTS
    [PSCustomObject] Un objet contenant les statistiques d'opÃ©rations.
#>
function Get-OperationStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Name
    )

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return $null
    }

    # Charger les statistiques
    Import-OperationStatistics

    # Si un nom est spÃ©cifiÃ©, retourner les statistiques pour ce compteur
    if ($Name) {
        if (-not $script:OperationStatistics.ContainsKey($Name)) {
            Write-Log -Message "Aucune statistique d'opÃ©rations disponible pour '$Name'." -Level $script:LogLevelWarning -Source $script:PerformanceCategory
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
    DÃ©finit un seuil d'opÃ©rations pour un compteur.

.DESCRIPTION
    La fonction Set-OperationThreshold dÃ©finit un seuil d'opÃ©rations pour un compteur.
    Si le nombre d'opÃ©rations dÃ©passe ce seuil, un avertissement sera journalisÃ©.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER Threshold
    Le seuil d'opÃ©rations.

.EXAMPLE
    Set-OperationThreshold -Name "MaFonction" -Threshold 1000
    DÃ©finit un seuil de 1000 opÃ©rations pour le compteur nommÃ© "MaFonction".

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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        return
    }

    # Charger les seuils
    Import-OperationThresholds

    # DÃ©finir le seuil
    $script:OperationThresholds[$Name] = $Threshold

    # Sauvegarder les seuils
    Save-OperationThresholds

    Write-Log -Message "Seuil d'opÃ©rations pour '$Name' dÃ©fini Ã  $Threshold." -Level $script:PerformanceLogLevel -Source $script:PerformanceCategory
}

<#
.SYNOPSIS
    Mesure le nombre d'opÃ©rations effectuÃ©es par un bloc de code.

.DESCRIPTION
    La fonction Measure-Operations mesure le nombre d'opÃ©rations effectuÃ©es par un bloc de code.
    Elle initialise un compteur, exÃ©cute le bloc de code, puis rÃ©initialise le compteur.

.PARAMETER Name
    Le nom du compteur.

.PARAMETER ScriptBlock
    Le bloc de code Ã  exÃ©cuter.

.PARAMETER InputObject
    L'objet Ã  passer au bloc de code.

.PARAMETER ArgumentList
    Les arguments Ã  passer au bloc de code.

.EXAMPLE
    Measure-Operations -Name "MaFonction" -ScriptBlock {
        for ($i = 0; $i -lt 1000; $i++) {
            Add-OperationCounter -Name "MaFonction"
        }
    }
    Mesure le nombre d'opÃ©rations effectuÃ©es par le bloc de code.

.OUTPUTS
    [PSCustomObject] Un objet contenant le rÃ©sultat du bloc de code et le nombre d'opÃ©rations.
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

    # VÃ©rifier si la mesure de performance est activÃ©e
    if (-not $script:PerformanceEnabled) {
        # ExÃ©cuter le bloc de code sans mesure
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

    # ExÃ©cuter le bloc de code
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
        # Obtenir le nombre d'opÃ©rations en cas d'erreur
        $operationCount = Get-OperationCounter -Name $Name

        # RÃ©initialiser le compteur
        Reset-OperationCounter -Name $Name -LogResult:$false

        # Relancer l'erreur
        throw $_
    }

    # Obtenir le nombre d'opÃ©rations
    $operationCount = Get-OperationCounter -Name $Name

    # RÃ©initialiser le compteur
    Reset-OperationCounter -Name $Name

    # Retourner le rÃ©sultat et le nombre d'opÃ©rations
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
Initialize-OperationCounter, Add-OperationCounter, Reset-OperationCounter,
Get-OperationCounter, Get-OperationStatistics, Set-OperationThreshold, Measure-Operations

