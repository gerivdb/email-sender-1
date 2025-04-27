<#
.SYNOPSIS
    Optimise l'exÃ©cution des tests TestOmnibus en fonction des donnÃ©es d'utilisation.
.DESCRIPTION
    Ce script analyse les donnÃ©es d'utilisation collectÃ©es par le systÃ¨me d'optimisation proactive
    pour dÃ©terminer les paramÃ¨tres optimaux d'exÃ©cution des tests, comme le nombre de threads,
    l'ordre d'exÃ©cution des tests, etc.
.PARAMETER UsageDataPath
    Chemin vers le fichier de donnÃ©es d'utilisation.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'optimisation.
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
    Write-Warning "Module UsageMonitor non trouvÃ©: $usageMonitorPath"
    Write-Warning "L'optimisation basÃ©e sur l'utilisation ne sera pas disponible."
}

# Fonction pour dÃ©terminer le nombre optimal de threads
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats
    )
    
    # Nombre de cÅ“urs logiques disponibles
    $logicalCores = [Environment]::ProcessorCount
    
    # Nombre de threads par dÃ©faut (75% des cÅ“urs disponibles)
    $defaultThreads = [Math]::Max(1, [Math]::Floor($logicalCores * 0.75))
    
    # Si les donnÃ©es d'utilisation ne sont pas disponibles, utiliser la valeur par dÃ©faut
    if (-not $UsageStats) {
        return $defaultThreads
    }
    
    try {
        # Analyser les donnÃ©es d'utilisation pour dÃ©terminer la charge systÃ¨me moyenne
        $resourceIntensiveScripts = $UsageStats.ResourceIntensiveScripts
        
        if ($resourceIntensiveScripts -and $resourceIntensiveScripts.Count -gt 0) {
            # Calculer un facteur d'ajustement basÃ© sur l'intensitÃ© des ressources
            $adjustmentFactor = 1.0
            
            # Si plus de 30% des scripts sont intensifs en ressources, rÃ©duire le nombre de threads
            if ($resourceIntensiveScripts.Count -gt ($UsageStats.TopUsedScripts.Count * 0.3)) {
                $adjustmentFactor = 0.6
            }
            # Si plus de 50% des scripts sont intensifs en ressources, rÃ©duire davantage
            elseif ($resourceIntensiveScripts.Count -gt ($UsageStats.TopUsedScripts.Count * 0.5)) {
                $adjustmentFactor = 0.4
            }
            
            # Calculer le nombre optimal de threads
            $optimalThreads = [Math]::Max(1, [Math]::Floor($logicalCores * $adjustmentFactor))
            return $optimalThreads
        }
    }
    catch {
        Write-Warning "Erreur lors de l'analyse des donnÃ©es d'utilisation: $_"
    }
    
    # En cas d'erreur, utiliser la valeur par dÃ©faut
    return $defaultThreads
}

# Fonction pour dÃ©terminer l'ordre optimal d'exÃ©cution des tests
function Get-OptimalTestOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TestFiles,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UsageStats
    )
    
    # Si les donnÃ©es d'utilisation ne sont pas disponibles, retourner l'ordre original
    if (-not $UsageStats) {
        return $TestFiles
    }
    
    try {
        # CrÃ©er une liste pour stocker les tests avec leur prioritÃ©
        $prioritizedTests = @()
        
        foreach ($testFile in $TestFiles) {
            $testName = Split-Path -Path $testFile -Leaf
            $priority = 0
            
            # VÃ©rifier si le test est dans la liste des tests qui Ã©chouent souvent
            $failingScripts = $UsageStats.MostFailingScripts
            if ($failingScripts -and $failingScripts.ContainsKey($testFile)) {
                # Plus le taux d'Ã©chec est Ã©levÃ©, plus la prioritÃ© est Ã©levÃ©e
                $priority += [Math]::Min(100, $failingScripts[$testFile] * 10)
            }
            
            # VÃ©rifier si le test est dans la liste des tests lents
            $slowScripts = $UsageStats.SlowestScripts
            if ($slowScripts -and $slowScripts.ContainsKey($testFile)) {
                # Les tests lents ont une prioritÃ© plus basse pour permettre aux tests rapides de s'exÃ©cuter en premier
                $priority -= [Math]::Min(50, $slowScripts[$testFile] / 100)
            }
            
            # Ajouter le test Ã  la liste avec sa prioritÃ©
            $prioritizedTests += [PSCustomObject]@{
                Path = $testFile
                Name = $testName
                Priority = $priority
            }
        }
        
        # Trier les tests par prioritÃ© (dÃ©croissante)
        $sortedTests = $prioritizedTests | Sort-Object -Property Priority -Descending
        
        # Retourner les chemins des tests triÃ©s
        return $sortedTests.Path
    }
    catch {
        Write-Warning "Erreur lors de la dÃ©termination de l'ordre optimal des tests: $_"
        return $TestFiles
    }
}

# Fonction pour gÃ©nÃ©rer une configuration optimisÃ©e pour TestOmnibus
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
    
    # DÃ©terminer le nombre optimal de threads
    $optimalThreads = Get-OptimalThreadCount -UsageStats $UsageStats
    
    # DÃ©terminer l'ordre optimal d'exÃ©cution des tests
    $optimalTestOrder = Get-OptimalTestOrder -TestFiles $TestFiles -UsageStats $UsageStats
    
    # CrÃ©er la configuration optimisÃ©e
    $optimizedConfig = @{
        MaxThreads = $optimalThreads
        OutputPath = $OutputPath
        GenerateHtmlReport = $true
        CollectPerformanceData = $true
        OptimizedTestOrder = $optimalTestOrder
    }
    
    return $optimizedConfig
}

# Point d'entrÃ©e principal
try {
    # VÃ©rifier si le module UsageMonitor est disponible
    if (-not (Get-Command -Name Initialize-UsageMonitor -ErrorAction SilentlyContinue)) {
        Write-Warning "La fonction Initialize-UsageMonitor n'est pas disponible. L'optimisation basÃ©e sur l'utilisation ne sera pas disponible."
        return @{
            MaxThreads = [Environment]::ProcessorCount
            OutputPath = $OutputPath
            GenerateHtmlReport = $true
            CollectPerformanceData = $true
        }
    }
    
    # Initialiser le moniteur d'utilisation
    Initialize-UsageMonitor -DatabasePath $UsageDataPath
    Write-Host "Moniteur d'utilisation initialisÃ© avec la base de donnÃ©es: $UsageDataPath" -ForegroundColor Green
    
    # RÃ©cupÃ©rer les statistiques d'utilisation
    $usageStats = Get-ScriptUsageStatistics
    Write-Host "Statistiques d'utilisation rÃ©cupÃ©rÃ©es" -ForegroundColor Green
    
    # RÃ©cupÃ©rer la liste des fichiers de test
    $testFiles = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\ProactiveOptimization\tests") -Filter "*.Tests.ps1" -Recurse | Select-Object -ExpandProperty FullName
    Write-Host "Fichiers de test trouvÃ©s: $($testFiles.Count)" -ForegroundColor Green
    
    # GÃ©nÃ©rer une configuration optimisÃ©e
    $optimizedConfig = Get-OptimizedTestOmnibusConfig -TestFiles $testFiles -UsageStats $usageStats -OutputPath $OutputPath
    Write-Host "Configuration optimisÃ©e gÃ©nÃ©rÃ©e" -ForegroundColor Green
    
    # Afficher la configuration optimisÃ©e
    Write-Host "Nombre optimal de threads: $($optimizedConfig.MaxThreads)" -ForegroundColor Cyan
    Write-Host "Ordre optimal d'exÃ©cution des tests:" -ForegroundColor Cyan
    foreach ($testPath in $optimizedConfig.OptimizedTestOrder) {
        Write-Host "  - $(Split-Path -Path $testPath -Leaf)" -ForegroundColor Cyan
    }
    
    # Retourner la configuration optimisÃ©e
    return $optimizedConfig
}
catch {
    Write-Error "Erreur lors de l'optimisation de TestOmnibus: $_"
    
    # En cas d'erreur, retourner une configuration par dÃ©faut
    return @{
        MaxThreads = [Environment]::ProcessorCount
        OutputPath = $OutputPath
        GenerateHtmlReport = $true
        CollectPerformanceData = $true
    }
}
