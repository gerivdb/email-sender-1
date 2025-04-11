<#
.SYNOPSIS
    Optimise dynamiquement la parallélisation des scripts PowerShell.
.DESCRIPTION
    Ce script analyse les données d'utilisation collectées par le module UsageMonitor
    et optimise dynamiquement la parallélisation des scripts PowerShell en fonction
    de la charge système observée et des patterns d'utilisation.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de parallélisation.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de données d'utilisation.
.PARAMETER Apply
    Indique si les optimisations doivent être appliquées automatiquement.
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

# Fonction pour écrire des messages de log
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

# Fonction pour obtenir les informations système actuelles
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
function Calculate-OptimalThreads {
    param (
        [PSCustomObject]$SystemInfo,
        [PSCustomObject]$UsageStats
    )
    
    # Nombre de base de threads (nombre de processeurs logiques)
    $baseThreads = $SystemInfo.LogicalProcessors
    
    # Facteur d'ajustement basé sur la charge CPU
    $cpuFactor = 1 - ($SystemInfo.ProcessorLoadPercent / 100)
    
    # Facteur d'ajustement basé sur la mémoire disponible
    $memoryFactor = $SystemInfo.AvailableMemoryPercent / 100
    
    # Calculer le nombre optimal de threads
    $optimalThreads = [math]::Max(1, [math]::Round($baseThreads * [math]::Min($cpuFactor, $memoryFactor)))
    
    return $optimalThreads
}

# Fonction pour analyser les dépendances entre les tâches
function Analyze-TaskDependencies {
    param (
        [PSCustomObject]$UsageStats
    )
    
    $dependencies = @{}
    
    # Analyser les scripts les plus utilisés
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $metrics = $script:UsageDatabase.GetMetricsForScript($scriptPath)
        
        # Identifier les scripts qui sont souvent exécutés ensemble
        $executionTimes = $metrics | ForEach-Object { $_.StartTime }
        
        # Rechercher d'autres scripts exécutés dans une fenêtre de temps proche
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

# Fonction pour générer une configuration de parallélisation optimisée
function Generate-ParallelizationConfig {
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
    
    # Configurer les priorités des tâches
    $priority = 100
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $config.TaskPriorities[$scriptPath] = $priority
        $priority -= 10
    }
    
    # Configurer les groupes de dépendances
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

# Fonction pour appliquer la configuration de parallélisation
function Apply-ParallelizationConfig {
    param (
        [hashtable]$Config,
        [string]$ConfigPath
    )
    
    # Sauvegarder la configuration dans un fichier JSON
    $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
    
    Write-Log "Configuration de parallélisation sauvegardée: $ConfigPath" -Level "SUCCESS"
    
    # Rechercher les scripts qui utilisent Invoke-OptimizedParallel
    $parallelScripts = Get-ChildItem -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -Filter "*.ps1" -Recurse |
        Where-Object { (Get-Content -Path $_.FullName -Raw) -match "Invoke-OptimizedParallel" }
    
    Write-Log "Nombre de scripts utilisant la parallélisation trouvés: $($parallelScripts.Count)" -Level "INFO"
    
    if ($Apply) {
        foreach ($script in $parallelScripts) {
            $scriptPath = $script.FullName
            $scriptName = $script.Name
            
            Write-Log "Application de la configuration à: $scriptName" -Level "INFO"
            
            $content = Get-Content -Path $scriptPath -Raw
            
            # Rechercher les appels à Invoke-OptimizedParallel
            if ($content -match "Invoke-OptimizedParallel\s+(?:-ScriptBlock\s+)?(\`$\w+|\{[^}]+\})(?:\s+-InputObject\s+)?(\`$\w+)?(?:\s+-MaxThreads\s+)?(\d+)?") {
                $currentMaxThreads = $matches[3]
                
                if ($currentMaxThreads) {
                    # Remplacer le nombre de threads par une référence à la configuration
                    $newContent = $content -replace "(-MaxThreads\s+)(\d+)", "`$1`$(`$parallelConfig.GlobalSettings.DefaultMaxThreads)"
                    
                    # Ajouter le code pour charger la configuration
                    $configLoader = @"
# Charger la configuration de parallélisation
`$parallelConfigPath = "$ConfigPath"
`$parallelConfig = `$null
if (Test-Path -Path `$parallelConfigPath) {
    try {
        `$parallelConfig = Get-Content -Path `$parallelConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Warning "Impossible de charger la configuration de parallélisation: `$_"
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
                    
                    # Insérer le code de chargement de configuration au début du script
                    $newContent = $newContent -replace "(?<=^.*?(?:\r\n|\r|\n))", $configLoader
                    
                    # Sauvegarder le script modifié
                    Set-Content -Path $scriptPath -Value $newContent -Force
                    
                    Write-Log "Configuration appliquée à: $scriptName" -Level "SUCCESS"
                }
                else {
                    Write-Log "Aucun paramètre MaxThreads trouvé dans: $scriptName" -Level "WARNING"
                }
            }
            else {
                Write-Log "Aucun appel à Invoke-OptimizedParallel trouvé dans: $scriptName" -Level "WARNING"
            }
        }
    }
    else {
        Write-Log "Mode simulation: la configuration n'a pas été appliquée aux scripts. Utilisez -Apply pour appliquer les modifications." -Level "WARNING"
    }
}

# Point d'entrée principal
Write-Log "Démarrage de l'optimisation de la parallélisation..." -Level "TITLE"

# Vérifier si le fichier de base de données existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de données spécifié n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Initialiser le moniteur d'utilisation avec la base de données spécifiée
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de données d'utilisation chargée: $DatabasePath" -Level "INFO"

# Récupérer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation récupérées" -Level "INFO"

# Obtenir les informations système
$systemInfo = Get-SystemInfo
Write-Log "Informations système récupérées:" -Level "INFO"
Write-Log "  - Processeurs logiques: $($systemInfo.LogicalProcessors)" -Level "INFO"
Write-Log "  - Mémoire physique: $($systemInfo.PhysicalMemoryGB) GB" -Level "INFO"
Write-Log "  - Charge processeur: $($systemInfo.ProcessorLoadPercent)%" -Level "INFO"
Write-Log "  - Mémoire disponible: $($systemInfo.AvailableMemoryPercent)%" -Level "INFO"

# Calculer le nombre optimal de threads
$optimalThreads = Calculate-OptimalThreads -SystemInfo $systemInfo -UsageStats $usageStats
Write-Log "Nombre optimal de threads calculé: $optimalThreads" -Level "INFO"

# Analyser les dépendances entre les tâches
$taskDependencies = Analyze-TaskDependencies -UsageStats $usageStats
Write-Log "Dépendances entre les tâches analysées: $($taskDependencies.Count) scripts avec dépendances" -Level "INFO"

# Générer la configuration de parallélisation
$parallelizationConfig = Generate-ParallelizationConfig -OptimalThreads $optimalThreads -TaskDependencies $taskDependencies -UsageStats $usageStats
Write-Log "Configuration de parallélisation générée" -Level "INFO"

# Appliquer la configuration
Apply-ParallelizationConfig -Config $parallelizationConfig -ConfigPath $ConfigPath

Write-Log "Optimisation de la parallélisation terminée." -Level "TITLE"
