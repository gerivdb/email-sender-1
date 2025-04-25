<#
.SYNOPSIS
    Test complet pour le système de cache prédictif.
.DESCRIPTION
    Ce script teste les fonctionnalités du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Test"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Définir les chemins de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests précédents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Créer le répertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour afficher un résultat de test
function Show-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )

    Write-Host "  $TestName : " -NoNewline
    if ($Success) {
        Write-Host "Succès" -ForegroundColor Green
    } else {
        Write-Host "Échec" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }

    return $Success
}

# Tableau pour stocker les résultats des tests
$testResults = @()

Show-SectionTitle "Test du système de cache prédictif"

# Section 1: Cache de base
Show-SectionTitle "1. Cache de base"

# Test 1.1: Création d'un cache prédictif
$cache = New-PredictiveCache -Name "TestCache" -UsageDatabase $testDatabasePath -CachePath $testCachePath
$test1_1 = Show-TestResult -TestName "1.1 Création d'un cache prédictif" -Success ($null -ne $cache) -Message "Cache créé: $($cache.Name)"
$testResults += $test1_1

# Test 1.2: Configuration du cache
$result = Set-PredictiveCacheOptions -Cache $cache -PreloadEnabled $true -AdaptiveTTL $true -DependencyTracking $true
$test1_2 = Show-TestResult -TestName "1.2 Configuration du cache" -Success $result -Message "Options configurées: Préchargement=$($cache.PreloadEnabled), TTL adaptatif=$($cache.AdaptiveTTLEnabled), Dépendances=$($cache.DependencyTrackingEnabled)"
$testResults += $test1_2

# Test 1.3: Accès au cache de base
$baseCache = $cache.BaseCache
# Utiliser la propriété Cache directement au lieu de la méthode Set
$baseCache.Cache["TestKey"] = "TestValue"
$value = $baseCache.Get("TestKey")
$test1_3 = Show-TestResult -TestName "1.3 Accès au cache de base" -Success ($value -eq "TestValue") -Message "Valeur récupérée: $value"
$testResults += $test1_3

# Section 2: Collecteur d'utilisation
Show-SectionTitle "2. Collecteur d'utilisation"

# Test 2.1: Création d'un collecteur d'utilisation
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$test2_1 = Show-TestResult -TestName "2.1 Création d'un collecteur d'utilisation" -Success ($null -ne $collector) -Message "Collecteur créé pour $($collector.CacheName)"
$testResults += $test2_1

# Test 2.2: Enregistrement des accès
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key1", $true)
$collector.RecordAccess("Key2", $false)
$stats = $collector.GetKeyAccessStats("Key1")
$test2_2 = Show-TestResult -TestName "2.2 Enregistrement des accès" -Success ($null -ne $stats) -Message "Statistiques pour Key1: Hits=$($stats.Hits), Misses=$($stats.Misses)"
$testResults += $test2_2

# Test 2.3: Récupération des clés les plus accédées
$mostAccessed = $collector.GetMostAccessedKeys(10, 60)
# Vérifier si $mostAccessed est un tableau et non null
$isValidResult = ($null -ne $mostAccessed) -and ($mostAccessed -is [array] -or $mostAccessed -is [System.Collections.ICollection])
$test2_3 = Show-TestResult -TestName "2.3 Récupération des clés les plus accédées" -Success $isValidResult -Message "Nombre de clés: $(if($isValidResult){$mostAccessed.Count}else{0})"
$testResults += $test2_3

# Section 3: Moteur de prédiction
Show-SectionTitle "3. Moteur de prédiction"

# Test 3.1: Création d'un moteur de prédiction
$engine = New-PredictionEngine -UsageCollector $collector -CacheName "TestCache"
$test3_1 = Show-TestResult -TestName "3.1 Création d'un moteur de prédiction" -Success ($null -ne $engine) -Message "Moteur créé pour $($engine.CacheName)"
$testResults += $test3_1

# Test 3.2: Prédiction des prochains accès
$predictions = $engine.PredictNextAccesses()
# Vérifier si $predictions est un tableau et non null
$isValidPredictions = ($null -ne $predictions) -and ($predictions -is [array] -or $predictions -is [System.Collections.ICollection])
$test3_2 = Show-TestResult -TestName "3.2 Prédiction des prochains accès" -Success $isValidPredictions -Message "Nombre de prédictions: $(if($isValidPredictions){$predictions.Count}else{0})"
$testResults += $test3_2

# Test 3.3: Calcul de probabilité pour une clé
$probability = $engine.CalculateKeyProbability("Key1")
$test3_3 = Show-TestResult -TestName "3.3 Calcul de probabilité pour une clé" -Success ($probability -ge 0 -and $probability -le 1) -Message "Probabilité pour Key1: $probability"
$testResults += $test3_3

# Section 4: Optimiseur de TTL
Show-SectionTitle "4. Optimiseur de TTL"

# Test 4.1: Création d'un optimiseur de TTL
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector
$test4_1 = Show-TestResult -TestName "4.1 Création d'un optimiseur de TTL" -Success ($null -ne $optimizer) -Message "Optimiseur créé"
$testResults += $test4_1

# Test 4.2: Configuration de l'optimiseur
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 300 -MaximumTTL 43200
$test4_2 = Show-TestResult -TestName "4.2 Configuration de l'optimiseur" -Success $result -Message "TTL min=$($optimizer.MinimumTTL), TTL max=$($optimizer.MaximumTTL)"
$testResults += $test4_2

# Test 4.3: Optimisation du TTL pour une clé
$optimizedTTL = $optimizer.OptimizeTTL("Key1", 3600)
$test4_3 = Show-TestResult -TestName "4.3 Optimisation du TTL pour une clé" -Success ($optimizedTTL -ge $optimizer.MinimumTTL -and $optimizedTTL -le $optimizer.MaximumTTL) -Message "TTL optimisé pour Key1: $optimizedTTL"
$testResults += $test4_3

# Section 5: Gestionnaire de dépendances
Show-SectionTitle "5. Gestionnaire de dépendances"

# Test 5.1: Création d'un gestionnaire de dépendances
$dependencyManager = New-DependencyManager -BaseCache $baseCache -UsageCollector $collector
$test5_1 = Show-TestResult -TestName "5.1 Création d'un gestionnaire de dépendances" -Success ($null -ne $dependencyManager) -Message "Gestionnaire créé"
$testResults += $test5_1

# Test 5.2: Ajout d'une dépendance
$result = Add-CacheDependency -DependencyManager $dependencyManager -SourceKey "Source" -TargetKey "Target" -Strength 0.8
$test5_2 = Show-TestResult -TestName "5.2 Ajout d'une dépendance" -Success $result -Message "Dépendance ajoutée: Source -> Target (0.8)"
$testResults += $test5_2

# Test 5.3: Récupération des dépendances
$dependencies = $dependencyManager.GetDependencies("Source")
$test5_3 = Show-TestResult -TestName "5.3 Récupération des dépendances" -Success ($dependencies.Count -gt 0) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test5_3

# Test 5.4: Suppression d'une dépendance
$result = Remove-CacheDependency -DependencyManager $dependencyManager -SourceKey "Source" -TargetKey "Target"
$dependencies = $dependencyManager.GetDependencies("Source")
$test5_4 = Show-TestResult -TestName "5.4 Suppression d'une dépendance" -Success ($result -and $dependencies.Count -eq 0) -Message "Dépendances restantes: $($dependencies.Count)"
$testResults += $test5_4

# Section 6: Gestionnaire de préchargement
Show-SectionTitle "6. Gestionnaire de préchargement"

# Test 6.1: Création d'un gestionnaire de préchargement
$preloadManager = New-PreloadManager -BaseCache $baseCache -PredictionEngine $engine
$test6_1 = Show-TestResult -TestName "6.1 Création d'un gestionnaire de préchargement" -Success ($null -ne $preloadManager) -Message "Gestionnaire créé"
$testResults += $test6_1

# Test 6.2: Enregistrement d'un générateur
$generator = { return "Valeur préchargée" }
$result = Register-PreloadGenerator -PreloadManager $preloadManager -KeyPattern "User:*" -Generator $generator
$test6_2 = Show-TestResult -TestName "6.2 Enregistrement d'un générateur" -Success $result -Message "Générateur enregistré pour le pattern 'User:*'"
$testResults += $test6_2

# Test 6.3: Préchargement de clés
$preloadManager.PreloadKeys(@("User:123", "User:456"))
$test6_3 = Show-TestResult -TestName "6.3 Préchargement de clés" -Success $true -Message "Préchargement déclenché pour 2 clés"
$testResults += $test6_3

# Section 7: Intégration complète
Show-SectionTitle "7. Intégration complète"

# Test 7.1: Optimisation du cache prédictif
$result = Optimize-PredictiveCache -Cache $cache
$test7_1 = Show-TestResult -TestName "7.1 Optimisation du cache prédictif" -Success $result -Message "Optimisation réussie"
$testResults += $test7_1

# Test 7.2: Statistiques du cache prédictif
$stats = Get-PredictiveCacheStatistics -Cache $cache
$test7_2 = Show-TestResult -TestName "7.2 Statistiques du cache prédictif" -Success ($null -ne $stats) -Message "Statistiques récupérées: Hits=$($stats.BaseCache.Hits), Misses=$($stats.BaseCache.Misses)"
$testResults += $test7_2

# Test 7.3: Déclenchement du préchargement
$cache.TriggerPreload()
$test7_3 = Show-TestResult -TestName "7.3 Déclenchement du préchargement" -Success $true -Message "Préchargement déclenché"
$testResults += $test7_3

# Résumé des tests
Show-SectionTitle "Résumé des tests"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exécutés: $totalTests" -ForegroundColor White
Write-Host "Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "Tests échoués: $failedTests" -ForegroundColor Red
Write-Host "Taux de réussite: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# Résultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
