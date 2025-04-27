<#
.SYNOPSIS
    Exemple d'utilisation du cache prÃ©dictif.
.DESCRIPTION
    Ce script dÃ©montre l'utilisation du module de cache prÃ©dictif
    avec diffÃ©rents scÃ©narios d'utilisation.
.NOTES
    Auteur: Augment Agent
    Date: 12/04/2025
    Version: 1.0
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PredictiveCache.psm1"
Import-Module $modulePath -Force

# DÃ©finir les chemins
$databasePath = Join-Path -Path $env:TEMP -ChildPath "PredictiveCache\usage.db"
$cachePath = Join-Path -Path $env:TEMP -ChildPath "PredictiveCache\cache"

# CrÃ©er les rÃ©pertoires si nÃ©cessaires
$databaseDir = Split-Path -Path $databasePath -Parent
if (-not (Test-Path -Path $databaseDir)) {
    New-Item -Path $databaseDir -ItemType Directory -Force | Out-Null
}

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour simuler une opÃ©ration coÃ»teuse
function Invoke-ExpensiveOperation {
    param(
        [string]$Key,
        [int]$DurationMs = 500
    )

    Write-Host "  ExÃ©cution de l'opÃ©ration coÃ»teuse pour la clÃ© '$Key'..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds $DurationMs

    # Simuler un rÃ©sultat
    return "RÃ©sultat pour $Key (gÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
}

# Fonction pour simuler une sÃ©quence d'accÃ¨s
function Invoke-AccessSequence {
    param(
        [object]$Cache,
        [string[]]$Keys,
        [int]$Iterations = 3
    )

    for ($i = 0; $i -lt $Iterations; $i++) {
        $iterationNumber = $i + 1
        $iterationText = "`n  ItÃ©ration $iterationNumber/$Iterations :"
        Write-Host $iterationText -ForegroundColor Magenta

        foreach ($key in $Keys) {
            $result = Get-PSCacheItem -Cache $Cache.BaseCache -Key $key -GenerateValue {
                Invoke-ExpensiveOperation -Key $key
            }

            Write-Host "    AccÃ¨s Ã  '$key': $result" -ForegroundColor Gray
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
        }
    }
}

# === DÃ©monstration 1: CrÃ©ation et configuration du cache prÃ©dictif ===
Show-SectionTitle "CrÃ©ation et configuration du cache prÃ©dictif"

# CrÃ©er le cache prÃ©dictif
$cache = New-PredictiveCache -Name "DemoCache" -UsageDatabase $databasePath -CachePath $cachePath -MaxMemoryItems 100 -DefaultTTLSeconds 3600

# Configurer les options
Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true

Write-Host "Cache prÃ©dictif crÃ©Ã© et configurÃ©:" -ForegroundColor Green
Write-Host "  Nom: $($cache.Name)" -ForegroundColor White
Write-Host "  Base de donnÃ©es: $($cache.UsageDatabasePath)" -ForegroundColor White
Write-Host "  PrÃ©chargement: $($cache.PreloadEnabled)" -ForegroundColor White
Write-Host "  TTL adaptatif: $($cache.AdaptiveTTLEnabled)" -ForegroundColor White
Write-Host "  Suivi des dÃ©pendances: $($cache.DependencyTrackingEnabled)" -ForegroundColor White

# === DÃ©monstration 2: Utilisation de base du cache ===
Show-SectionTitle "Utilisation de base du cache"

# DÃ©finir quelques clÃ©s
$keys = @(
    "User:Profile:123",
    "User:Settings:123",
    "User:Data:123",
    "Product:Info:456",
    "Product:Price:456",
    "Product:Stock:456"
)

# Simuler une sÃ©quence d'accÃ¨s
Invoke-AccessSequence -Cache $cache -Keys $keys -Iterations 3

# === DÃ©monstration 3: Analyse des prÃ©dictions ===
Show-SectionTitle "Analyse des prÃ©dictions"

# Optimiser le cache
Optimize-PredictiveCache -Cache $cache

# Obtenir les statistiques
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "Statistiques du cache prÃ©dictif:" -ForegroundColor Green
Write-Host "  Hits de prÃ©diction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prÃ©diction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  PrÃ©cision des prÃ©dictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Ã‰lÃ©ments prÃ©chargÃ©s: $($stats.PreloadedItems)" -ForegroundColor White
Write-Host "  Ajustements de TTL: $($stats.TTLAdjustments)" -ForegroundColor White

# === DÃ©monstration 4: SÃ©quences d'accÃ¨s et prÃ©chargement ===
Show-SectionTitle "SÃ©quences d'accÃ¨s et prÃ©chargement"

# DÃ©finir des sÃ©quences d'accÃ¨s typiques
$userSequence = @(
    "User:Profile:123",
    "User:Settings:123",
    "User:Data:123"
)

$productSequence = @(
    "Product:Info:456",
    "Product:Price:456",
    "Product:Stock:456"
)

# Simuler les sÃ©quences
Write-Host "Simulation de la sÃ©quence utilisateur:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $userSequence -Iterations 2

Write-Host "`nSimulation de la sÃ©quence produit:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $productSequence -Iterations 2

# Optimiser Ã  nouveau
Optimize-PredictiveCache -Cache $cache

# Obtenir les statistiques mises Ã  jour
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "`nStatistiques mises Ã  jour:" -ForegroundColor Green
Write-Host "  Hits de prÃ©diction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prÃ©diction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  PrÃ©cision des prÃ©dictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Ã‰lÃ©ments prÃ©chargÃ©s: $($stats.PreloadedItems)" -ForegroundColor White

# === DÃ©monstration 5: DÃ©pendances entre clÃ©s ===
Show-SectionTitle "DÃ©pendances entre clÃ©s"

# CrÃ©er un gestionnaire de dÃ©pendances
$usageCollector = New-UsageCollector -DatabasePath $databasePath -CacheName $cache.BaseCache.Name
$dependencyManager = New-DependencyManager -BaseCache $cache.BaseCache -UsageCollector $usageCollector

# Ajouter des dÃ©pendances manuelles
Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "User:Profile:123" -TargetKey "User:Data:123" -Strength 0.9
Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "Product:Info:456" -TargetKey "Product:Price:456" -Strength 0.8

# Activer la dÃ©tection automatique
Set-DependencyManagerOptions -DependencyManager $dependencyManager -AutoDetectDependencies $true

# Simuler des accÃ¨s pour crÃ©er des dÃ©pendances
Write-Host "Simulation d'accÃ¨s pour crÃ©er des dÃ©pendances:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $userSequence -Iterations 1
Invoke-AccessSequence -Cache $cache -Keys $productSequence -Iterations 1

# DÃ©tecter les dÃ©pendances
$dependencyManager.DetectDependencies()

# Afficher les dÃ©pendances
$dependencies = $dependencyManager.GetDependencyStatistics()

Write-Host "`nStatistiques des dÃ©pendances:" -ForegroundColor Green
Write-Host "  Sources: $($dependencies.TotalSources)" -ForegroundColor White
Write-Host "  Cibles: $($dependencies.TotalTargets)" -ForegroundColor White
Write-Host "  DÃ©pendances totales: $($dependencies.TotalDependencies)" -ForegroundColor White
Write-Host "  Force moyenne: $([Math]::Round($dependencies.AverageStrength * 100, 2))%" -ForegroundColor White

# === DÃ©monstration 6: TTL adaptatifs ===
Show-SectionTitle "TTL adaptatifs"

# CrÃ©er un optimiseur de TTL
$ttlOptimizer = New-TTLOptimizer -BaseCache $cache.BaseCache -UsageCollector $usageCollector

# Configurer les paramÃ¨tres
Set-TTLOptimizerParameters -TTLOptimizer $ttlOptimizer -MinimumTTL 300 -MaximumTTL 43200 -FrequencyWeight 0.6 -RecencyWeight 0.3 -StabilityWeight 0.1

# Mettre Ã  jour les rÃ¨gles
$ttlOptimizer.UpdateTTLRules()

# Tester l'optimisation de TTL
$testKeys = @(
    "User:Profile:123",
    "Product:Info:456",
    "RarelyAccessed:789"
)

Write-Host "Optimisation des TTL:" -ForegroundColor Green

foreach ($key in $testKeys) {
    $defaultTTL = $cache.BaseCache.DefaultTTLSeconds
    $optimizedTTL = $ttlOptimizer.OptimizeTTL($key, $defaultTTL)

    Write-Host "  ClÃ©: $key" -ForegroundColor White
    Write-Host "    TTL par dÃ©faut: $defaultTTL secondes" -ForegroundColor Gray
    Write-Host "    TTL optimisÃ©: $optimizedTTL secondes" -ForegroundColor Gray
    Write-Host "    Facteur d'ajustement: $([Math]::Round($optimizedTTL / $defaultTTL, 2))x" -ForegroundColor Gray
    Write-Host ""
}

# === DÃ©monstration 7: Performance et ressources ===
Show-SectionTitle "Performance et ressources"

# Mesurer le temps d'accÃ¨s avec et sans cache prÃ©dictif
$testKey = "PerformanceTest:123"

# Sans prÃ©chargement
$cache.PreloadEnabled = $false
$startTime = Get-Date
$result = Get-PSCacheItem -Cache $cache.BaseCache -Key $testKey -GenerateValue {
    Invoke-ExpensiveOperation -Key $testKey -DurationMs 1000
}
$endTime = Get-Date
$withoutPreloadTime = ($endTime - $startTime).TotalMilliseconds

# Avec prÃ©chargement
$cache.PreloadEnabled = $true
Optimize-PredictiveCache -Cache $cache

# PrÃ©charger la clÃ©
$cache.TriggerPreload()

# Mesurer le temps d'accÃ¨s
$startTime = Get-Date
$result = Get-PSCacheItem -Cache $cache.BaseCache -Key $testKey -GenerateValue {
    Invoke-ExpensiveOperation -Key $testKey -DurationMs 1000
}
$endTime = Get-Date
$withPreloadTime = ($endTime - $startTime).TotalMilliseconds

Write-Host "Comparaison des performances:" -ForegroundColor Green
Write-Host "  Temps d'accÃ¨s sans prÃ©chargement: $([Math]::Round($withoutPreloadTime, 2)) ms" -ForegroundColor White
Write-Host "  Temps d'accÃ¨s avec prÃ©chargement: $([Math]::Round($withPreloadTime, 2)) ms" -ForegroundColor White
Write-Host "  AmÃ©lioration: $([Math]::Round(($withoutPreloadTime - $withPreloadTime) / $withoutPreloadTime * 100, 2))%" -ForegroundColor White

# === DÃ©monstration 8: Nettoyage et finalisation ===
Show-SectionTitle "Nettoyage et finalisation"

# Obtenir les statistiques finales
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "Statistiques finales du cache prÃ©dictif:" -ForegroundColor Green
Write-Host "  Hits de base: $($stats.BaseCache.Hits)" -ForegroundColor White
Write-Host "  Misses de base: $($stats.BaseCache.Misses)" -ForegroundColor White
Write-Host "  Hits de prÃ©diction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prÃ©diction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  PrÃ©cision des prÃ©dictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Ã‰lÃ©ments prÃ©chargÃ©s: $($stats.PreloadedItems)" -ForegroundColor White
Write-Host "  Ajustements de TTL: $($stats.TTLAdjustments)" -ForegroundColor White

Write-Host "`nDÃ©monstration terminÃ©e!" -ForegroundColor Green
