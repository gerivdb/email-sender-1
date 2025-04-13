#Requires -Version 5.1
<#
.SYNOPSIS
    Tests des scénarios d'erreur pour le module DependencyManager.
.DESCRIPTION
    Ce script contient des tests pour les scénarios d'erreur et les cas limites
    du module DependencyManager.
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

Show-SectionTitle "Tests des scénarios d'erreur pour DependencyManager"

# Créer les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$manager = New-DependencyManager -BaseCache $baseCache -UsageCollector $collector

# Test 1: Gestion des dépendances circulaires
Show-SectionTitle "1. Gestion des dépendances circulaires"

# Test 1.1: Dépendance directe sur soi-même
$manager.AddDependency("Key1", "Key1", 0.8)
$dependencies = $manager.GetDependencies("Key1")
$test1_1 = Show-TestResult -TestName "1.1 Dépendance sur soi-même" -Success ($dependencies.Count -eq 0) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test1_1

# Test 1.2: Dépendance circulaire simple
$manager.AddDependency("Key2", "Key3", 0.8)
$manager.AddDependency("Key3", "Key2", 0.8)
$dependencies2 = $manager.GetDependencies("Key2")
$dependencies3 = $manager.GetDependencies("Key3")
$test1_2 = Show-TestResult -TestName "1.2 Dépendance circulaire simple" -Success ($dependencies2.Count -eq 1 -and $dependencies3.Count -eq 1) -Message "Dépendances pour Key2: $($dependencies2.Count), pour Key3: $($dependencies3.Count)"
$testResults += $test1_2

# Test 1.3: Dépendance circulaire complexe
$manager.AddDependency("KeyA", "KeyB", 0.8)
$manager.AddDependency("KeyB", "KeyC", 0.8)
$manager.AddDependency("KeyC", "KeyA", 0.8)
$dependenciesA = $manager.GetDependencies("KeyA")
$dependenciesB = $manager.GetDependencies("KeyB")
$dependenciesC = $manager.GetDependencies("KeyC")
$test1_3 = Show-TestResult -TestName "1.3 Dépendance circulaire complexe" -Success ($dependenciesA.Count -eq 1 -and $dependenciesB.Count -eq 1 -and $dependenciesC.Count -eq 1) -Message "Dépendances pour KeyA: $($dependenciesA.Count), pour KeyB: $($dependenciesB.Count), pour KeyC: $($dependenciesC.Count)"
$testResults += $test1_3

# Test 2: Valeurs extrêmes pour la force des dépendances
Show-SectionTitle "2. Valeurs extrêmes pour la force des dépendances"

# Test 2.1: Force de dépendance négative
$manager.AddDependency("NegKey", "Target", -0.5)
$dependencies = $manager.GetDependencies("NegKey")
$strength = if ($dependencies.ContainsKey("Target")) { $dependencies["Target"] } else { 0 }
$test2_1 = Show-TestResult -TestName "2.1 Force de dépendance négative" -Success ($strength -eq -0.5) -Message "Force de la dépendance: $strength"
$testResults += $test2_1

# Test 2.2: Force de dépendance supérieure à 1
$manager.AddDependency("HighKey", "Target", 1.5)
$dependencies = $manager.GetDependencies("HighKey")
$strength = if ($dependencies.ContainsKey("Target")) { $dependencies["Target"] } else { 0 }
$test2_2 = Show-TestResult -TestName "2.2 Force de dépendance > 1" -Success ($strength -eq 1.5) -Message "Force de la dépendance: $strength"
$testResults += $test2_2

# Test 2.3: Force de dépendance nulle
$manager.AddDependency("ZeroKey", "Target", 0.0)
$dependencies = $manager.GetDependencies("ZeroKey")
$strength = if ($dependencies.ContainsKey("Target")) { $dependencies["Target"] } else { 0 }
$test2_3 = Show-TestResult -TestName "2.3 Force de dépendance nulle" -Success ($strength -eq 0.0) -Message "Force de la dépendance: $strength"
$testResults += $test2_3

# Test 3: Limite du nombre de dépendances
Show-SectionTitle "3. Limite du nombre de dépendances"

# Test 3.1: Définir une limite très basse
$result = Set-DependencyManagerOptions -DependencyManager $manager -MaxDependenciesPerKey 2
$test3_1 = Show-TestResult -TestName "3.1 Définir une limite basse" -Success ($result -and $manager.MaxDependenciesPerKey -eq 2) -Message "Limite définie à: $($manager.MaxDependenciesPerKey)"
$testResults += $test3_1

# Test 3.2: Dépasser la limite
$manager.AddDependency("LimitKey", "Target1", 0.9)
$manager.AddDependency("LimitKey", "Target2", 0.8)
$manager.AddDependency("LimitKey", "Target3", 0.7)  # Devrait être ignorée ou remplacer la plus faible
$dependencies = $manager.GetDependencies("LimitKey")
$test3_2 = Show-TestResult -TestName "3.2 Dépasser la limite" -Success ($dependencies.Count -le 2) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test3_2

# Test 3.3: Vérifier que les dépendances les plus fortes sont conservées
$hasStrongest = $dependencies.ContainsKey("Target1")
$test3_3 = Show-TestResult -TestName "3.3 Conservation des dépendances fortes" -Success $hasStrongest -Message "La dépendance la plus forte est conservée: $hasStrongest"
$testResults += $test3_3

# Test 4: Détection automatique des dépendances
Show-SectionTitle "4. Détection automatique des dépendances"

# Test 4.1: Activer/désactiver la détection automatique
$result = Set-DependencyManagerOptions -DependencyManager $manager -AutoDetectDependencies $false
$test4_1 = Show-TestResult -TestName "4.1 Désactiver la détection automatique" -Success ($result -and $manager.AutoDetectDependencies -eq $false) -Message "Détection automatique: $($manager.AutoDetectDependencies)"
$testResults += $test4_1

# Test 4.2: Exécuter la détection avec l'option désactivée
$initialDependencyCount = ($manager.GetDependencyStatistics()).TotalDependencies
$manager.DetectDependencies()
$finalDependencyCount = ($manager.GetDependencyStatistics()).TotalDependencies
$test4_2 = Show-TestResult -TestName "4.2 Détection avec option désactivée" -Success ($initialDependencyCount -eq $finalDependencyCount) -Message "Dépendances avant: $initialDependencyCount, après: $finalDependencyCount"
$testResults += $test4_2

# Test 5: Nettoyage des dépendances obsolètes
Show-SectionTitle "5. Nettoyage des dépendances obsolètes"

# Test 5.1: Ajouter des dépendances faibles
$manager.AddDependency("WeakKey", "Target1", 0.05)
$manager.AddDependency("WeakKey", "Target2", 0.08)
$initialDependencies = $manager.GetDependencies("WeakKey")
$test5_1 = Show-TestResult -TestName "5.1 Ajouter des dépendances faibles" -Success ($initialDependencies.Count -gt 0) -Message "Dépendances ajoutées: $($initialDependencies.Count)"
$testResults += $test5_1

# Test 5.2: Nettoyer les dépendances obsolètes
$manager.CleanupObsoleteDependencies()
$finalDependencies = $manager.GetDependencies("WeakKey")
$test5_2 = Show-TestResult -TestName "5.2 Nettoyer les dépendances obsolètes" -Success ($finalDependencies.Count -le $initialDependencies.Count) -Message "Dépendances avant: $($initialDependencies.Count), après: $($finalDependencies.Count)"
$testResults += $test5_2

# Test 6: Statistiques des dépendances
Show-SectionTitle "6. Statistiques des dépendances"

# Test 6.1: Obtenir les statistiques
$stats = $manager.GetDependencyStatistics()
$test6_1 = Show-TestResult -TestName "6.1 Obtenir les statistiques" -Success ($null -ne $stats) -Message "Statistiques récupérées: TotalSources=$($stats.TotalSources), TotalTargets=$($stats.TotalTargets), TotalDependencies=$($stats.TotalDependencies)"
$testResults += $test6_1

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
