<#
.SYNOPSIS
    Exemple d'utilisation du cache prédictif.
.DESCRIPTION
    Ce script démontre l'utilisation du module de cache prédictif
    avec différents scénarios d'utilisation.
.NOTES
    Auteur: Augment Agent
    Date: 12/04/2025
    Version: 1.0
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PredictiveCache.psm1"
Import-Module $modulePath -Force

# Définir les chemins
$databasePath = Join-Path -Path $env:TEMP -ChildPath "PredictiveCache\usage.db"
$cachePath = Join-Path -Path $env:TEMP -ChildPath "PredictiveCache\cache"

# Créer les répertoires si nécessaires
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

# Fonction pour simuler une opération coûteuse
function Invoke-ExpensiveOperation {
    param(
        [string]$Key,
        [int]$DurationMs = 500
    )

    Write-Host "  Exécution de l'opération coûteuse pour la clé '$Key'..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds $DurationMs

    # Simuler un résultat
    return "Résultat pour $Key (généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
}

# Fonction pour simuler une séquence d'accès
function Invoke-AccessSequence {
    param(
        [object]$Cache,
        [string[]]$Keys,
        [int]$Iterations = 3
    )

    for ($i = 0; $i -lt $Iterations; $i++) {
        $iterationNumber = $i + 1
        $iterationText = "`n  Itération $iterationNumber/$Iterations :"
        Write-Host $iterationText -ForegroundColor Magenta

        foreach ($key in $Keys) {
            $result = Get-PSCacheItem -Cache $Cache.BaseCache -Key $key -GenerateValue {
                Invoke-ExpensiveOperation -Key $key
            }

            Write-Host "    Accès à '$key': $result" -ForegroundColor Gray
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
        }
    }
}

# === Démonstration 1: Création et configuration du cache prédictif ===
Show-SectionTitle "Création et configuration du cache prédictif"

# Créer le cache prédictif
$cache = New-PredictiveCache -Name "DemoCache" -UsageDatabase $databasePath -CachePath $cachePath -MaxMemoryItems 100 -DefaultTTLSeconds 3600

# Configurer les options
Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true

Write-Host "Cache prédictif créé et configuré:" -ForegroundColor Green
Write-Host "  Nom: $($cache.Name)" -ForegroundColor White
Write-Host "  Base de données: $($cache.UsageDatabasePath)" -ForegroundColor White
Write-Host "  Préchargement: $($cache.PreloadEnabled)" -ForegroundColor White
Write-Host "  TTL adaptatif: $($cache.AdaptiveTTLEnabled)" -ForegroundColor White
Write-Host "  Suivi des dépendances: $($cache.DependencyTrackingEnabled)" -ForegroundColor White

# === Démonstration 2: Utilisation de base du cache ===
Show-SectionTitle "Utilisation de base du cache"

# Définir quelques clés
$keys = @(
    "User:Profile:123",
    "User:Settings:123",
    "User:Data:123",
    "Product:Info:456",
    "Product:Price:456",
    "Product:Stock:456"
)

# Simuler une séquence d'accès
Invoke-AccessSequence -Cache $cache -Keys $keys -Iterations 3

# === Démonstration 3: Analyse des prédictions ===
Show-SectionTitle "Analyse des prédictions"

# Optimiser le cache
Optimize-PredictiveCache -Cache $cache

# Obtenir les statistiques
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "Statistiques du cache prédictif:" -ForegroundColor Green
Write-Host "  Hits de prédiction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prédiction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  Précision des prédictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Éléments préchargés: $($stats.PreloadedItems)" -ForegroundColor White
Write-Host "  Ajustements de TTL: $($stats.TTLAdjustments)" -ForegroundColor White

# === Démonstration 4: Séquences d'accès et préchargement ===
Show-SectionTitle "Séquences d'accès et préchargement"

# Définir des séquences d'accès typiques
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

# Simuler les séquences
Write-Host "Simulation de la séquence utilisateur:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $userSequence -Iterations 2

Write-Host "`nSimulation de la séquence produit:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $productSequence -Iterations 2

# Optimiser à nouveau
Optimize-PredictiveCache -Cache $cache

# Obtenir les statistiques mises à jour
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "`nStatistiques mises à jour:" -ForegroundColor Green
Write-Host "  Hits de prédiction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prédiction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  Précision des prédictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Éléments préchargés: $($stats.PreloadedItems)" -ForegroundColor White

# === Démonstration 5: Dépendances entre clés ===
Show-SectionTitle "Dépendances entre clés"

# Créer un gestionnaire de dépendances
$usageCollector = New-UsageCollector -DatabasePath $databasePath -CacheName $cache.BaseCache.Name
$dependencyManager = New-DependencyManager -BaseCache $cache.BaseCache -UsageCollector $usageCollector

# Ajouter des dépendances manuelles
Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "User:Profile:123" -TargetKey "User:Data:123" -Strength 0.9
Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "Product:Info:456" -TargetKey "Product:Price:456" -Strength 0.8

# Activer la détection automatique
Set-DependencyManagerOptions -DependencyManager $dependencyManager -AutoDetectDependencies $true

# Simuler des accès pour créer des dépendances
Write-Host "Simulation d'accès pour créer des dépendances:" -ForegroundColor Green
Invoke-AccessSequence -Cache $cache -Keys $userSequence -Iterations 1
Invoke-AccessSequence -Cache $cache -Keys $productSequence -Iterations 1

# Détecter les dépendances
$dependencyManager.DetectDependencies()

# Afficher les dépendances
$dependencies = $dependencyManager.GetDependencyStatistics()

Write-Host "`nStatistiques des dépendances:" -ForegroundColor Green
Write-Host "  Sources: $($dependencies.TotalSources)" -ForegroundColor White
Write-Host "  Cibles: $($dependencies.TotalTargets)" -ForegroundColor White
Write-Host "  Dépendances totales: $($dependencies.TotalDependencies)" -ForegroundColor White
Write-Host "  Force moyenne: $([Math]::Round($dependencies.AverageStrength * 100, 2))%" -ForegroundColor White

# === Démonstration 6: TTL adaptatifs ===
Show-SectionTitle "TTL adaptatifs"

# Créer un optimiseur de TTL
$ttlOptimizer = New-TTLOptimizer -BaseCache $cache.BaseCache -UsageCollector $usageCollector

# Configurer les paramètres
Set-TTLOptimizerParameters -TTLOptimizer $ttlOptimizer -MinimumTTL 300 -MaximumTTL 43200 -FrequencyWeight 0.6 -RecencyWeight 0.3 -StabilityWeight 0.1

# Mettre à jour les règles
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

    Write-Host "  Clé: $key" -ForegroundColor White
    Write-Host "    TTL par défaut: $defaultTTL secondes" -ForegroundColor Gray
    Write-Host "    TTL optimisé: $optimizedTTL secondes" -ForegroundColor Gray
    Write-Host "    Facteur d'ajustement: $([Math]::Round($optimizedTTL / $defaultTTL, 2))x" -ForegroundColor Gray
    Write-Host ""
}

# === Démonstration 7: Performance et ressources ===
Show-SectionTitle "Performance et ressources"

# Mesurer le temps d'accès avec et sans cache prédictif
$testKey = "PerformanceTest:123"

# Sans préchargement
$cache.PreloadEnabled = $false
$startTime = Get-Date
$result = Get-PSCacheItem -Cache $cache.BaseCache -Key $testKey -GenerateValue {
    Invoke-ExpensiveOperation -Key $testKey -DurationMs 1000
}
$endTime = Get-Date
$withoutPreloadTime = ($endTime - $startTime).TotalMilliseconds

# Avec préchargement
$cache.PreloadEnabled = $true
Optimize-PredictiveCache -Cache $cache

# Précharger la clé
$cache.TriggerPreload()

# Mesurer le temps d'accès
$startTime = Get-Date
$result = Get-PSCacheItem -Cache $cache.BaseCache -Key $testKey -GenerateValue {
    Invoke-ExpensiveOperation -Key $testKey -DurationMs 1000
}
$endTime = Get-Date
$withPreloadTime = ($endTime - $startTime).TotalMilliseconds

Write-Host "Comparaison des performances:" -ForegroundColor Green
Write-Host "  Temps d'accès sans préchargement: $([Math]::Round($withoutPreloadTime, 2)) ms" -ForegroundColor White
Write-Host "  Temps d'accès avec préchargement: $([Math]::Round($withPreloadTime, 2)) ms" -ForegroundColor White
Write-Host "  Amélioration: $([Math]::Round(($withoutPreloadTime - $withPreloadTime) / $withoutPreloadTime * 100, 2))%" -ForegroundColor White

# === Démonstration 8: Nettoyage et finalisation ===
Show-SectionTitle "Nettoyage et finalisation"

# Obtenir les statistiques finales
$stats = Get-PredictiveCacheStatistics -Cache $cache

Write-Host "Statistiques finales du cache prédictif:" -ForegroundColor Green
Write-Host "  Hits de base: $($stats.BaseCache.Hits)" -ForegroundColor White
Write-Host "  Misses de base: $($stats.BaseCache.Misses)" -ForegroundColor White
Write-Host "  Hits de prédiction: $($stats.PredictionHits)" -ForegroundColor White
Write-Host "  Misses de prédiction: $($stats.PredictionMisses)" -ForegroundColor White
Write-Host "  Précision des prédictions: $([Math]::Round($stats.PredictionAccuracy * 100, 2))%" -ForegroundColor White
Write-Host "  Éléments préchargés: $($stats.PreloadedItems)" -ForegroundColor White
Write-Host "  Ajustements de TTL: $($stats.TTLAdjustments)" -ForegroundColor White

Write-Host "`nDémonstration terminée!" -ForegroundColor Green
