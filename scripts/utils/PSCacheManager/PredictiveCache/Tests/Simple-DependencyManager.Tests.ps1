#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour le module DependencyManager.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour le module DependencyManager
    du système de cache prédictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulés
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# Créer un chemin temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
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

Show-SectionTitle "Tests simplifiés pour DependencyManager"

# Créer les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$usageCollector = [UsageCollector]::new($testDatabasePath, "TestCache")

# Ajouter des données de test au UsageCollector
$usageCollector.RecordAccess("Key1", $true)
$usageCollector.RecordAccess("Key2", $true)
$usageCollector.RecordAccess("Key3", $true)

# Test 1: Création d'un gestionnaire de dépendances
Show-SectionTitle "1. Création d'un gestionnaire de dépendances"

# Test 1.1: Création directe
$manager = [DependencyManager]::new($baseCache, $usageCollector)
$test1_1 = Show-TestResult -TestName "1.1 Création directe" -Success ($null -ne $manager) -Message "Gestionnaire créé: $($manager.GetType().Name)"
$testResults += $test1_1

# Test 1.2: Création via la fonction
$managerFromFunction = New-DependencyManager -BaseCache $baseCache -UsageCollector $usageCollector
$test1_2 = Show-TestResult -TestName "1.2 Création via la fonction" -Success ($null -ne $managerFromFunction) -Message "Gestionnaire créé: $($managerFromFunction.GetType().Name)"
$testResults += $test1_2

# Test 2: Ajout et récupération de dépendances
Show-SectionTitle "2. Ajout et récupération de dépendances"

# Test 2.1: Ajout d'une dépendance
$manager.AddDependency("Source1", "Target1", 0.8)
$dependencies = $manager.GetDependencies("Source1")
$test2_1 = Show-TestResult -TestName "2.1 Ajout d'une dépendance" -Success ($dependencies.Count -eq 1) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test2_1

# Test 2.2: Vérification de la force de la dépendance
$strength = $dependencies["Target1"]
$test2_2 = Show-TestResult -TestName "2.2 Vérification de la force" -Success ($strength -eq 0.8) -Message "Force de la dépendance: $strength"
$testResults += $test2_2

# Test 2.3: Ajout de plusieurs dépendances
$manager.AddDependency("Source2", "Target1", 0.5)
$manager.AddDependency("Source2", "Target2", 0.7)
$dependencies = $manager.GetDependencies("Source2")
$test2_3 = Show-TestResult -TestName "2.3 Ajout de plusieurs dépendances" -Success ($dependencies.Count -eq 2) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test2_3

# Test 3: Suppression de dépendances
Show-SectionTitle "3. Suppression de dépendances"

# Test 3.1: Suppression d'une dépendance
$result = $manager.RemoveDependency("Source2", "Target1")
$dependencies = $manager.GetDependencies("Source2")
$test3_1 = Show-TestResult -TestName "3.1 Suppression d'une dépendance" -Success ($result -and $dependencies.Count -eq 1) -Message "Nombre de dépendances restantes: $($dependencies.Count)"
$testResults += $test3_1

# Test 3.2: Suppression d'une dépendance inexistante
$result = $manager.RemoveDependency("Source2", "NonExistent")
$test3_2 = Show-TestResult -TestName "3.2 Suppression d'une dépendance inexistante" -Success ($result -eq $false) -Message "Résultat: $result"
$testResults += $test3_2

# Test 4: Configuration du gestionnaire
Show-SectionTitle "4. Configuration du gestionnaire"

# Test 4.1: Configuration via la fonction
$result = Set-DependencyManagerOptions -DependencyManager $manager -AutoDetectDependencies $false -MaxDependenciesPerKey 5 -MinDependencyStrength 0.2
$test4_1 = Show-TestResult -TestName "4.1 Configuration via la fonction" -Success $result -Message "AutoDetect=$($manager.AutoDetectDependencies), MaxDependencies=$($manager.MaxDependenciesPerKey), MinStrength=$($manager.MinDependencyStrength)"
$testResults += $test4_1

# Test 5: Ajout de dépendances via la fonction
Show-SectionTitle "5. Ajout de dépendances via la fonction"

# Test 5.1: Ajout d'une dépendance via la fonction
$result = Add-CacheDependency -DependencyManager $manager -SourceKey "Source3" -TargetKey "Target3" -Strength 0.9
$dependencies = $manager.GetDependencies("Source3")
$test5_1 = Show-TestResult -TestName "5.1 Ajout d'une dépendance via la fonction" -Success ($result -and $dependencies.Count -eq 1) -Message "Nombre de dépendances: $($dependencies.Count)"
$testResults += $test5_1

# Test 6: Suppression de dépendances via la fonction
Show-SectionTitle "6. Suppression de dépendances via la fonction"

# Test 6.1: Suppression d'une dépendance via la fonction
$result = Remove-CacheDependency -DependencyManager $manager -SourceKey "Source3" -TargetKey "Target3"
$dependencies = $manager.GetDependencies("Source3")
$test6_1 = Show-TestResult -TestName "6.1 Suppression d'une dépendance via la fonction" -Success ($result -and $dependencies.Count -eq 0) -Message "Nombre de dépendances restantes: $($dependencies.Count)"
$testResults += $test6_1

# Test 7: Statistiques des dépendances
Show-SectionTitle "7. Statistiques des dépendances"

# Test 7.1: Obtention des statistiques
$stats = $manager.GetDependencyStatistics()
$test7_1 = Show-TestResult -TestName "7.1 Obtention des statistiques" -Success ($null -ne $stats) -Message "TotalSources=$($stats.TotalSources), TotalTargets=$($stats.TotalTargets), TotalDependencies=$($stats.TotalDependencies)"
$testResults += $test7_1

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
