<#
.SYNOPSIS
    Optimise l'exécution des tests TestOmnibus en fonction des données d'utilisation.
.DESCRIPTION
    Ce script analyse les données d'utilisation collectées par le système d'optimisation proactive
    pour déterminer les paramètres optimaux d'exécution des tests, comme le nombre de threads,
    l'ordre d'exécution des tests, etc.
.PARAMETER UsageDataPath
    Chemin vers le fichier de données d'utilisation.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'optimisation.
.EXAMPLE
    .\UsageBasedOptimizer.ps1 -UsageDataPath "D:\UsageData\usage_data.xml" -OutputPath "D:\TestResults"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$UsageDataPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results")
)

# Importer le module UsageMonitor si disponible
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UsageMonitor\UsageMonitor.psm1"
if (Test-Path -Path $usageMonitorPath) {
    Import-Module $usageMonitorPath -Force
}
else {
    Write-Warning "Module UsageMonitor non trouvé: $usageMonitorPath"
    Write-Warning "L'optimisation basée sur l'utilisation ne sera pas disponible."
}

# Fonction pour déterminer le nombre optimal de threads
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats
    )
    
    # Nombre de cœurs logiques disponibles
    $logicalCores = [Environment]::ProcessorCount
    
    # Nombre de threads par défaut (75% des cœurs disponibles)
    $defaultThreads = [Math]::Max(1, [Math]::Floor($logicalCores * 0.75))
    
    # Si les données d'utilisation ne sont pas disponibles, utiliser la valeur par défaut
    if (-not $UsageStats) {
        return $defaultThreads
    }
    
    try {
        # Analyser les données d'utilisation pour déterminer la charge système moyenne
        $resourceIntensiveScripts = $UsageStats.ResourceIntensiveScripts
        
        if ($resourceIntensiveScripts -and $resourceIntensiveScripts.Count -gt 0) {
            # Calculer un facteur d'ajustement basé sur l'intensité des ressources
            $adjustmentFactor = 1.0
            
            # Si plus de 30% des scripts sont intensifs en ressources, réduire le nombre de threads
            if ($resourceIntensiveScripts.Count -gt ($UsageStats.TopUsedScripts.Count * 0.3)) {
                $adjustmentFactor = 0.6
            }
            # Si plus de 50% des scripts sont intensifs en ressources, réduire davantage
            elseif ($resourceIntensiveScripts.Count -gt ($UsageStats.TopUsedScripts.Count * 0.5)) {
                $adjustmentFactor = 0.4
            }
            
            # Calculer le nombre optimal de threads
            $optimalThreads = [Math]::Max(1, [Math]::Floor($logicalCores * $adjustmentFactor))
            return $optimalThreads
        }
    }
    catch {
        Write-Warning "Erreur lors de l'analyse des données d'utilisation: $_"
    }
    
    # En cas d'erreur, utiliser la valeur par défaut
    return $defaultThreads
}

# Fonction pour déterminer l'ordre optimal d'exécution des tests
function Get-OptimalTestOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TestFiles,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats
    )
    
    # Si les données d'utilisation ne sont pas disponibles, retourner l'ordre original
    if (-not $UsageStats) {
        return $TestFiles
    }
    
    try {
        # Créer une liste pour stocker les tests avec leur priorité
        $prioritizedTests = @()
        
        foreach ($testFile in $TestFiles) {
            $testName = Split-Path -Path $testFile -Leaf
            $priority = 0
            
            # Vérifier si le test est dans la liste des tests qui échouent souvent
            $failingScripts = $UsageStats.MostFailingScripts
            if ($failingScripts -and $failingScripts.ContainsKey($testFile)) {
                # Plus le taux d'échec est élevé, plus la priorité est élevée
                $priority += [Math]::Min(100, $failingScripts[$testFile] * 10)
            }
            
            # Vérifier si le test est dans la liste des tests lents
            $slowScripts = $UsageStats.SlowestScripts
            if ($slowScripts -and $slowScripts.ContainsKey($testFile)) {
                # Les tests lents ont une priorité plus basse pour permettre aux tests rapides de s'exécuter en premier
                $priority -= [Math]::Min(50, $slowScripts[$testFile] / 100)
            }
            
            # Ajouter le test à la liste avec sa priorité
            $prioritizedTests += [PSCustomObject]@{
                Path = $testFile
                Name = $testName
                Priority = $priority
            }
        }
        
        # Trier les tests par priorité (décroissante)
        $sortedTests = $prioritizedTests | Sort-Object -Property Priority -Descending
        
        # Retourner les chemins des tests triés
        return $sortedTests.Path
    }
    catch {
        Write-Warning "Erreur lors de la détermination de l'ordre optimal des tests: $_"
        return $TestFiles
    }
}

# Fonction pour générer une configuration optimisée pour TestOmnibus
function Get-OptimizedTestOmnibusConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TestFiles,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results")
    )
    
    # Déterminer le nombre optimal de threads
    $optimalThreads = Get-OptimalThreadCount -UsageStats $UsageStats
    
    # Déterminer l'ordre optimal d'exécution des tests
    $optimalTestOrder = Get-OptimalTestOrder -TestFiles $TestFiles -UsageStats $UsageStats
    
    # Créer la configuration optimisée
    $optimizedConfig = @{
        MaxThreads = $optimalThreads
        OutputPath = $OutputPath
        GenerateHtmlReport = $true
        CollectPerformanceData = $true
        OptimizedTestOrder = $optimalTestOrder
    }
    
    return $optimizedConfig
}

# Point d'entrée principal
try {
    # Vérifier si le module UsageMonitor est disponible
    if (-not (Get-Command -Name Initialize-UsageMonitor -ErrorAction SilentlyContinue)) {
        Write-Warning "La fonction Initialize-UsageMonitor n'est pas disponible. L'optimisation basée sur l'utilisation ne sera pas disponible."
        return @{
            MaxThreads = [Environment]::ProcessorCount
            OutputPath = $OutputPath
            GenerateHtmlReport = $true
            CollectPerformanceData = $true
        }
    }
    
    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $UsageDataPath
    Write-Host "Moniteur d'utilisation initialisé avec la base de données: $UsageDataPath" -ForegroundColor Green
    
    # Récupérer les statistiques d'utilisation
    $usageStats = Get-ScriptUsageStatistics
    Write-Host "Statistiques d'utilisation récupérées" -ForegroundColor Green
    
    # Récupérer la liste des fichiers de test
    $testFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\ProactiveOptimization\tests") -Filter "*.Tests.ps1" -Recurse | Select-Object -ExpandProperty FullName
    Write-Host "Fichiers de test trouvés: $($testFiles.Count)" -ForegroundColor Green
    
    # Générer une configuration optimisée
    $optimizedConfig = Get-OptimizedTestOmnibusConfig -TestFiles $testFiles -UsageStats $usageStats -OutputPath $OutputPath
    Write-Host "Configuration optimisée générée" -ForegroundColor Green
    
    # Afficher la configuration optimisée
    Write-Host "Nombre optimal de threads: $($optimizedConfig.MaxThreads)" -ForegroundColor Cyan
    Write-Host "Ordre optimal d'exécution des tests:" -ForegroundColor Cyan
    foreach ($testPath in $optimizedConfig.OptimizedTestOrder) {
        Write-Host "  - $(Split-Path -Path $testPath -Leaf)" -ForegroundColor Cyan
    }
    
    # Retourner la configuration optimisée
    return $optimizedConfig
}
catch {
    Write-Error "Erreur lors de l'optimisation de TestOmnibus: $_"
    
    # En cas d'erreur, retourner une configuration par défaut
    return @{
        MaxThreads = [Environment]::ProcessorCount
        OutputPath = $OutputPath
        GenerateHtmlReport = $true
        CollectPerformanceData = $true
    }
}
