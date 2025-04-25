#Requires -Version 5.1
<#
.SYNOPSIS
    Tests des cas limites pour le module TTLOptimizer.
.DESCRIPTION
    Ce script contient des tests pour les cas limites et les scénarios d'erreur
    du module TTLOptimizer.
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

Show-SectionTitle "Tests des cas limites pour TTLOptimizer"

# Créer les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector

# Test 1: Valeurs extrêmes pour les paramètres TTL
Show-SectionTitle "1. Valeurs extrêmes pour les paramètres TTL"

# Test 1.1: TTL minimum négatif
# Sauvegarder la valeur originale pour référence
$script:originalMinTTL = $optimizer.MinimumTTL
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL -100
$test1_1 = Show-TestResult -TestName "1.1 TTL minimum négatif" -Success ($result -and $optimizer.MinimumTTL -eq -100) -Message "TTL minimum défini à -100 (valeur originale: $script:originalMinTTL)"
$testResults += $test1_1

# Test 1.2: TTL maximum très grand
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MaximumTTL 31536000  # 1 an en secondes
$test1_2 = Show-TestResult -TestName "1.2 TTL maximum très grand" -Success ($result -and $optimizer.MaximumTTL -eq 31536000) -Message "TTL maximum défini à 31536000 (1 an)"
$testResults += $test1_2

# Test 1.3: TTL minimum supérieur au TTL maximum
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 50000 -MaximumTTL 40000
$test1_3 = Show-TestResult -TestName "1.3 TTL minimum > TTL maximum" -Success $result -Message "TTL min=$($optimizer.MinimumTTL), TTL max=$($optimizer.MaximumTTL)"
$testResults += $test1_3

# Test 1.4: Optimisation avec TTL extrêmes
$optimizedTTL = $optimizer.OptimizeTTL("TestKey", 3600)
$test1_4 = Show-TestResult -TestName "1.4 Optimisation avec TTL extrêmes" -Success ($null -ne $optimizedTTL) -Message "TTL optimisé: $optimizedTTL"
$testResults += $test1_4

# Test 2: Poids des facteurs
Show-SectionTitle "2. Poids des facteurs"

# Test 2.1: Somme des poids différente de 1
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight 0.4 -RecencyWeight 0.4 -StabilityWeight 0.4
$test2_1 = Show-TestResult -TestName "2.1 Somme des poids différente de 1" -Success $result -Message "Poids: Fréquence=$($optimizer.FrequencyWeight), Récence=$($optimizer.RecencyWeight), Stabilité=$($optimizer.StabilityWeight)"
$testResults += $test2_1

# Test 2.2: Poids négatifs
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight -0.2 -RecencyWeight 0.6 -StabilityWeight 0.6
$test2_2 = Show-TestResult -TestName "2.2 Poids négatifs" -Success $result -Message "Poids: Fréquence=$($optimizer.FrequencyWeight), Récence=$($optimizer.RecencyWeight), Stabilité=$($optimizer.StabilityWeight)"
$testResults += $test2_2

# Test 2.3: Poids supérieurs à 1
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight 1.5 -RecencyWeight 0.3 -StabilityWeight 0.2
$test2_3 = Show-TestResult -TestName "2.3 Poids supérieurs à 1" -Success $result -Message "Poids: Fréquence=$($optimizer.FrequencyWeight), Récence=$($optimizer.RecencyWeight), Stabilité=$($optimizer.StabilityWeight)"
$testResults += $test2_3

# Test 3: Détection de patterns
Show-SectionTitle "3. Détection de patterns"

# Test 3.1: Pattern simple
$pattern = $optimizer.DetectKeyPattern("User:123")
$test3_1 = Show-TestResult -TestName "3.1 Pattern simple" -Success ($pattern -eq "User:*") -Message "Pattern détecté: $pattern"
$testResults += $test3_1

# Test 3.2: Pattern complexe
$pattern = $optimizer.DetectKeyPattern("Config:App:Setting")
$test3_2 = Show-TestResult -TestName "3.2 Pattern complexe" -Success ($null -ne $pattern) -Message "Pattern détecté: $pattern"
$testResults += $test3_2

# Test 3.3: Pattern avec date
$pattern = $optimizer.DetectKeyPattern("Data:2023-04-12:Stats")
$test3_3 = Show-TestResult -TestName "3.3 Pattern avec date" -Success ($null -ne $pattern) -Message "Pattern détecté: $pattern"
$testResults += $test3_3

# Test 3.4: Pattern non reconnu
$pattern = $optimizer.DetectKeyPattern("UnknownPattern")
$test3_4 = Show-TestResult -TestName "3.4 Pattern non reconnu" -Success ($pattern -eq "UnknownPattern") -Message "Pattern détecté: $pattern"
$testResults += $test3_4

# Test 4: Calcul des facteurs
Show-SectionTitle "4. Calcul des facteurs"

# Test 4.1: Facteur de fréquence
$frequencyFactor = $optimizer.CalculateFrequencyFactor(1000)  # Valeur très élevée
$test4_1 = Show-TestResult -TestName "4.1 Facteur de fréquence élevé" -Success ($frequencyFactor -le 1.0) -Message "Facteur de fréquence: $frequencyFactor"
$testResults += $test4_1

# Test 4.2: Facteur de récence
$lastAccess = (Get-Date).AddDays(-30)  # Accès très ancien
$recencyFactor = $optimizer.CalculateRecencyFactor($lastAccess)
$test4_2 = Show-TestResult -TestName "4.2 Facteur de récence pour accès ancien" -Success ($recencyFactor -ge 0.0 -and $recencyFactor -le 1.0) -Message "Facteur de récence: $recencyFactor"
$testResults += $test4_2

# Test 4.3: Facteur de stabilité
$stabilityFactor = $optimizer.CalculateStabilityFactor(0.0)  # Ratio de hits nul
$test4_3 = Show-TestResult -TestName "4.3 Facteur de stabilité pour ratio nul" -Success ($stabilityFactor -eq 0.0) -Message "Facteur de stabilité: $stabilityFactor"
$testResults += $test4_3

# Test 4.4: Facteur de stabilité
$stabilityFactor = $optimizer.CalculateStabilityFactor(1.0)  # Ratio de hits parfait
$test4_4 = Show-TestResult -TestName "4.4 Facteur de stabilité pour ratio parfait" -Success ($stabilityFactor -eq 1.0) -Message "Facteur de stabilité: $stabilityFactor"
$testResults += $test4_4

# Test 5: Statistiques d'optimisation
Show-SectionTitle "5. Statistiques d'optimisation"

# Test 5.1: Obtenir les statistiques
$stats = $optimizer.GetOptimizationStatistics()
$test5_1 = Show-TestResult -TestName "5.1 Obtenir les statistiques" -Success ($null -ne $stats) -Message "Statistiques récupérées: RuleCount=$($stats.RuleCount), PatternCount=$($stats.PatternCount)"
$testResults += $test5_1

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
