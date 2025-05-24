<#
.SYNOPSIS
    Optimise dynamiquement la parallÃ©lisation des scripts PowerShell.
.DESCRIPTION
    Ce script analyse les donnÃ©es d'utilisation collectÃ©es par le module UsageMonitor
    et optimise dynamiquement la parallÃ©lisation des scripts PowerShell en fonction
    de la charge systÃ¨me observÃ©e et des patterns d'utilisation.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de parallÃ©lisation.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de donnÃ©es d'utilisation.
.PARAMETER Apply
    Indique si les optimisations doivent Ãªtre appliquÃ©es automatiquement.
.EXAMPLE
    .\Optimize-Parallelization.ps1 -Apply
.NOTES
    Auteur: Augment Agent
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "parallelization_config.json"),
    
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [switch]$Apply
)

# Importer le module UsageMonitor
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $modulePath -Force

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour obtenir les informations systÃ¨me actuelles
function Get-SystemInfo {
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $processorInfo = Get-CimInstance -ClassName Win32_Processor
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    
    $systemInfo = [PSCustomObject]@{
        TotalProcessors = $computerInfo.NumberOfProcessors
        LogicalProcessors = $computerInfo.NumberOfLogicalProcessors
        PhysicalMemoryGB = [math]::Round($memoryInfo.Sum / 1GB, 2)
        FreeMemoryGB = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
        ProcessorLoadPercent = $processorInfo.LoadPercentage
        AvailableMemoryPercent = [math]::Round(($osInfo.FreePhysicalMemory / ($memoryInfo.Sum / 1KB)) * 100, 2)
    }
    
    return $systemInfo
}

# Fonction pour calculer le nombre optimal de threads
function Measure-OptimalThreads {
    param (
        [PSCustomObject]$SystemInfo,
        [PSCustomObject]$UsageStats
    )
    
    # Nombre de base de threads (nombre de processeurs logiques)
    $baseThreads = $SystemInfo.LogicalProcessors
    
    # Facteur d'ajustement basÃ© sur la charge CPU
    $cpuFactor = 1 - ($SystemInfo.ProcessorLoadPercent / 100)
    
    # Facteur d'ajustement basÃ© sur la mÃ©moire disponible
    $memoryFactor = $SystemInfo.AvailableMemoryPercent / 100
    
    # Calculer le nombre optimal de threads
    $optimalThreads = [math]::Max(1, [math]::Round($baseThreads * [math]::Min($cpuFactor, $memoryFactor)))
    
    return $optimalThreads
}

# Fonction pour analyser les dÃ©pendances entre les tÃ¢ches
function Test-TaskDependencies {
    param (
        [PSCustomObject]$UsageStats
    )
    
    $dependencies = @{}
    
    # Analyser les scripts les plus utilisÃ©s
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $metrics = $script:UsageDatabase.GetMetricsForScript($scriptPath)
        
        # Identifier les scripts qui sont souvent exÃ©cutÃ©s ensemble
        $executionTimes = $metrics | ForEach-Object { $_.StartTime }
        
        # Rechercher d'autres scripts exÃ©cutÃ©s dans une fenÃªtre de temps proche
        foreach ($otherScriptPath in $UsageStats.TopUsedScripts.Keys) {
            if ($scriptPath -eq $otherScriptPath) {
                continue
            }
            
            $otherMetrics = $script:UsageDatabase.GetMetricsForScript($otherScriptPath)
            $otherExecutionTimes = $otherMetrics | ForEach-Object { $_.StartTime }
            
            $correlations = 0
            
            foreach ($time in $executionTimes) {
                $closeExecutions = $otherExecutionTimes | Where-Object { [math]::Abs(($_ - $time).TotalSeconds) -lt 60 }
                $correlations += $closeExecutions.Count
            }
            
            if ($correlations -gt 0) {
                if (-not $dependencies.ContainsKey($scriptPath)) {
                    $dependencies[$scriptPath] = @{}
                }
                
                $dependencies[$scriptPath][$otherScriptPath] = $correlations
            }
        }
    }
    
    return $dependencies
}

# Fonction pour gÃ©nÃ©rer une configuration de parallÃ©lisation optimisÃ©e
function New-ParallelizationConfig {
    param (
        [int]$OptimalThreads,
        [hashtable]$TaskDependencies,
        [PSCustomObject]$UsageStats
    )
    
    $config = @{
        GlobalSettings = @{
            DefaultMaxThreads = $OptimalThreads
            DefaultThrottleLimit = [math]::Max(1, [math]::Round($OptimalThreads * 0.8))
            AdaptiveScaling = $true
            MonitorSystemLoad = $true
        }
        ScriptSpecificSettings = @{}
        TaskPriorities = @{}
        DependencyGroups = @{}
    }
    
    # Configurer les scripts les plus lents pour utiliser plus de threads
    foreach ($scriptPath in $UsageStats.SlowestScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        
        $config.ScriptSpecificSettings[$scriptPath] = @{
            MaxThreads = [math]::Min($OptimalThreads + 2, $SystemInfo.LogicalProcessors)
            ThrottleLimit = [math]::Min($OptimalThreads + 1, $SystemInfo.LogicalProcessors)
            Priority = "High"
        }
    }
    
    # Configurer les scripts intensifs en ressources pour utiliser moins de threads
    foreach ($scriptPath in $UsageStats.ResourceIntensiveScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        
        $config.ScriptSpecificSettings[$scriptPath] = @{
            MaxThreads = [math]::Max(1, [math]::Round($OptimalThreads * 0.7))
            ThrottleLimit = [math]::Max(1, [math]::Round($OptimalThreads * 0.6))
            Priority = "Low"
        }
    }
    
    # Configurer les prioritÃ©s des tÃ¢ches
    $priority = 100
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $config.TaskPriorities[$scriptPath] = $priority
        $priority -= 10
    }
    
    # Configurer les groupes de dÃ©pendances
    $groupId = 1
    foreach ($scriptPath in $TaskDependencies.Keys) {
        $relatedScripts = $TaskDependencies[$scriptPath].Keys | Where-Object { $TaskDependencies[$scriptPath][$_] -gt 5 }
        
        if ($relatedScripts.Count -gt 0) {
            $config.DependencyGroups["Group$groupId"] = @{
                Scripts = @($scriptPath) + $relatedScripts
                ExecuteTogether = $true
            }
            
            $groupId++
        }
    }
    
    return $config
}

# Fonction pour appliquer la configuration de parallÃ©lisation
function Set-ParallelizationConfig {
    param (
        [hashtable]$Config,
        [string]$ConfigPath
    )
    
    # Sauvegarder la configuration dans un fichier JSON
    $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
    
    Write-Log "Configuration de parallÃ©lisation sauvegardÃ©e: $ConfigPath" -Level "SUCCESS"
    
    # Rechercher les scripts qui utilisent Invoke-OptimizedParallel
    $parallelScripts = Get-ChildItem -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -Filter "*.ps1" -Recurse |
        Where-Object { (Get-Content -Path $_.FullName -Raw) -match "Invoke-OptimizedParallel" }
    
    Write-Log "Nombre de scripts utilisant la parallÃ©lisation trouvÃ©s: $($parallelScripts.Count)" -Level "INFO"
    
    if ($Apply) {
        foreach ($script in $parallelScripts) {
            $scriptPath = $script.FullName
            $scriptName = $script.Name
            
            Write-Log "Application de la configuration Ã : $scriptName" -Level "INFO"
            
            $content = Get-Content -Path $scriptPath -Raw
            
            # Rechercher les appels Ã  Invoke-OptimizedParallel
            if ($content -match "Invoke-OptimizedParallel\s+(?:-ScriptBlock\s+)?(\`$\w+|\{[^}]+\})(?:\s+-InputObject\s+)?(\`$\w+)?(?:\s+-MaxThreads\s+)?(\d+)?") {
                $currentMaxThreads = $matches[3]
                
                if ($currentMaxThreads) {
                    # Remplacer le nombre de threads par une rÃ©fÃ©rence Ã  la configuration
                    $newContent = $content -replace "(-MaxThreads\s+)(\d+)", "`$1`$(`$parallelConfig.GlobalSettings.DefaultMaxThreads)"
                    
                    # Ajouter le code pour charger la configuration
                    $configLoader = @"
# Charger la configuration de parallÃ©lisation
`$parallelConfigPath = "$ConfigPath"
`$parallelConfig = `$null
if (Test-Path -Path `$parallelConfigPath) {
    try {
        `$parallelConfig = Get-Content -Path `$parallelConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Warning "Impossible de charger la configuration de parallÃ©lisation: `$_"
        `$parallelConfig = [PSCustomObject]@{
            GlobalSettings = [PSCustomObject]@{
                DefaultMaxThreads = [System.Environment]::ProcessorCount
                DefaultThrottleLimit = [System.Environment]::ProcessorCount
            }
        }
    }
}
else {
    `$parallelConfig = [PSCustomObject]@{
        GlobalSettings = [PSCustomObject]@{
            DefaultMaxThreads = [System.Environment]::ProcessorCount
            DefaultThrottleLimit = [System.Environment]::ProcessorCount
        }
    }
}

"@
                    
                    # InsÃ©rer le code de chargement de configuration au dÃ©but du script
                    $newContent = $newContent -replace "(?<=^.*?(?:\r\n|\r|\n))", $configLoader
                    
                    # Sauvegarder le script modifiÃ©
                    Set-Content -Path $scriptPath -Value $newContent -Force
                    
                    Write-Log "Configuration appliquÃ©e Ã : $scriptName" -Level "SUCCESS"
                }
                else {
                    Write-Log "Aucun paramÃ¨tre MaxThreads trouvÃ© dans: $scriptName" -Level "WARNING"
                }
            }
            else {
                Write-Log "Aucun appel Ã  Invoke-OptimizedParallel trouvÃ© dans: $scriptName" -Level "WARNING"
            }
        }
    }
    else {
        Write-Log "Mode simulation: la configuration n'a pas Ã©tÃ© appliquÃ©e aux scripts. Utilisez -Apply pour appliquer les modifications." -Level "WARNING"
    }
}

# Point d'entrÃ©e principal
Write-Log "DÃ©marrage de l'optimisation de la parallÃ©lisation..." -Level "TITLE"

# VÃ©rifier si le fichier de base de donnÃ©es existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de donnÃ©es spÃ©cifiÃ© n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Initialiser le moniteur d'utilisation avec la base de donnÃ©es spÃ©cifiÃ©e
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de donnÃ©es d'utilisation chargÃ©e: $DatabasePath" -Level "INFO"

# RÃ©cupÃ©rer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation rÃ©cupÃ©rÃ©es" -Level "INFO"

# Obtenir les informations systÃ¨me
$systemInfo = Get-SystemInfo
Write-Log "Informations systÃ¨me rÃ©cupÃ©rÃ©es:" -Level "INFO"
Write-Log "  - Processeurs logiques: $($systemInfo.LogicalProcessors)" -Level "INFO"
Write-Log "  - MÃ©moire physique: $($systemInfo.PhysicalMemoryGB) GB" -Level "INFO"
Write-Log "  - Charge processeur: $($systemInfo.ProcessorLoadPercent)%" -Level "INFO"
Write-Log "  - MÃ©moire disponible: $($systemInfo.AvailableMemoryPercent)%" -Level "INFO"

# Calculer le nombre optimal de threads
$optimalThreads = Measure-OptimalThreads -SystemInfo $systemInfo -UsageStats $usageStats
Write-Log "Nombre optimal de threads calculÃ©: $optimalThreads" -Level "INFO"

# Analyser les dÃ©pendances entre les tÃ¢ches
$taskDependencies = Test-TaskDependencies -UsageStats $usageStats
Write-Log "DÃ©pendances entre les tÃ¢ches analysÃ©es: $($taskDependencies.Count) scripts avec dÃ©pendances" -Level "INFO"

# GÃ©nÃ©rer la configuration de parallÃ©lisation
$parallelizationConfig = New-ParallelizationConfig -OptimalThreads $optimalThreads -TaskDependencies $taskDependencies -UsageStats $usageStats
Write-Log "Configuration de parallÃ©lisation gÃ©nÃ©rÃ©e" -Level "INFO"

# Appliquer la configuration
Set-ParallelizationConfig -Config $parallelizationConfig -ConfigPath $ConfigPath

Write-Log "Optimisation de la parallÃ©lisation terminÃ©e." -Level "TITLE"


