#Requires -Version 5.1
<#
.SYNOPSIS
    Tests des cas limites pour le module TTLOptimizer.
.DESCRIPTION
    Ce script contient des tests pour les cas limites et les scÃ©narios d'erreur
    du module TTLOptimizer.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulÃ©s
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Test"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# DÃ©finir les chemins de test
$testCachePath = Join-Path -Path $testDir -ChildPath "Cache"
$testDatabasePath = Join-Path -Path $testDir -ChildPath "Usage.db"

# Nettoyer les tests prÃ©cÃ©dents
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# CrÃ©er le rÃ©pertoire du cache
New-Item -Path $testCachePath -ItemType Directory -Force | Out-Null

# Fonction pour afficher un titre de section
function Show-SectionTitle {
    param([string]$Title)

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

# Fonction pour afficher un rÃ©sultat de test
function Show-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )

    Write-Host "  $TestName : " -NoNewline
    if ($Success) {
        Write-Host "SuccÃ¨s" -ForegroundColor Green
    } else {
        Write-Host "Ã‰chec" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }

    return $Success
}

# Tableau pour stocker les rÃ©sultats des tests
$testResults = @()

Show-SectionTitle "Tests des cas limites pour TTLOptimizer"

# CrÃ©er les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$collector = New-UsageCollector -DatabasePath $testDatabasePath -CacheName "TestCache"
$optimizer = New-TTLOptimizer -BaseCache $baseCache -UsageCollector $collector

# Test 1: Valeurs extrÃªmes pour les paramÃ¨tres TTL
Show-SectionTitle "1. Valeurs extrÃªmes pour les paramÃ¨tres TTL"

# Test 1.1: TTL minimum nÃ©gatif
# Sauvegarder la valeur originale pour rÃ©fÃ©rence
$script:originalMinTTL = $optimizer.MinimumTTL
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL -100
$test1_1 = Show-TestResult -TestName "1.1 TTL minimum nÃ©gatif" -Success ($result -and $optimizer.MinimumTTL -eq -100) -Message "TTL minimum dÃ©fini Ã  -100 (valeur originale: $script:originalMinTTL)"
$testResults += $test1_1

# Test 1.2: TTL maximum trÃ¨s grand
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MaximumTTL 31536000  # 1 an en secondes
$test1_2 = Show-TestResult -TestName "1.2 TTL maximum trÃ¨s grand" -Success ($result -and $optimizer.MaximumTTL -eq 31536000) -Message "TTL maximum dÃ©fini Ã  31536000 (1 an)"
$testResults += $test1_2

# Test 1.3: TTL minimum supÃ©rieur au TTL maximum
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 50000 -MaximumTTL 40000
$test1_3 = Show-TestResult -TestName "1.3 TTL minimum > TTL maximum" -Success $result -Message "TTL min=$($optimizer.MinimumTTL), TTL max=$($optimizer.MaximumTTL)"
$testResults += $test1_3

# Test 1.4: Optimisation avec TTL extrÃªmes
$optimizedTTL = $optimizer.OptimizeTTL("TestKey", 3600)
$test1_4 = Show-TestResult -TestName "1.4 Optimisation avec TTL extrÃªmes" -Success ($null -ne $optimizedTTL) -Message "TTL optimisÃ©: $optimizedTTL"
$testResults += $test1_4

# Test 2: Poids des facteurs
Show-SectionTitle "2. Poids des facteurs"

# Test 2.1: Somme des poids diffÃ©rente de 1
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight 0.4 -RecencyWeight 0.4 -StabilityWeight 0.4
$test2_1 = Show-TestResult -TestName "2.1 Somme des poids diffÃ©rente de 1" -Success $result -Message "Poids: FrÃ©quence=$($optimizer.FrequencyWeight), RÃ©cence=$($optimizer.RecencyWeight), StabilitÃ©=$($optimizer.StabilityWeight)"
$testResults += $test2_1

# Test 2.2: Poids nÃ©gatifs
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight -0.2 -RecencyWeight 0.6 -StabilityWeight 0.6
$test2_2 = Show-TestResult -TestName "2.2 Poids nÃ©gatifs" -Success $result -Message "Poids: FrÃ©quence=$($optimizer.FrequencyWeight), RÃ©cence=$($optimizer.RecencyWeight), StabilitÃ©=$($optimizer.StabilityWeight)"
$testResults += $test2_2

# Test 2.3: Poids supÃ©rieurs Ã  1
$result = Set-TTLOptimizerParameters -TTLOptimizer $optimizer -FrequencyWeight 1.5 -RecencyWeight 0.3 -StabilityWeight 0.2
$test2_3 = Show-TestResult -TestName "2.3 Poids supÃ©rieurs Ã  1" -Success $result -Message "Poids: FrÃ©quence=$($optimizer.FrequencyWeight), RÃ©cence=$($optimizer.RecencyWeight), StabilitÃ©=$($optimizer.StabilityWeight)"
$testResults += $test2_3

# Test 3: DÃ©tection de patterns
Show-SectionTitle "3. DÃ©tection de patterns"

# Test 3.1: Pattern simple
$pattern = $optimizer.DetectKeyPattern("User:123")
$test3_1 = Show-TestResult -TestName "3.1 Pattern simple" -Success ($pattern -eq "User:*") -Message "Pattern dÃ©tectÃ©: $pattern"
$testResults += $test3_1

# Test 3.2: Pattern complexe
$pattern = $optimizer.DetectKeyPattern("Config:App:Setting")
$test3_2 = Show-TestResult -TestName "3.2 Pattern complexe" -Success ($null -ne $pattern) -Message "Pattern dÃ©tectÃ©: $pattern"
$testResults += $test3_2

# Test 3.3: Pattern avec date
$pattern = $optimizer.DetectKeyPattern("Data:2023-04-12:Stats")
$test3_3 = Show-TestResult -TestName "3.3 Pattern avec date" -Success ($null -ne $pattern) -Message "Pattern dÃ©tectÃ©: $pattern"
$testResults += $test3_3

# Test 3.4: Pattern non reconnu
$pattern = $optimizer.DetectKeyPattern("UnknownPattern")
$test3_4 = Show-TestResult -TestName "3.4 Pattern non reconnu" -Success ($pattern -eq "UnknownPattern") -Message "Pattern dÃ©tectÃ©: $pattern"
$testResults += $test3_4

# Test 4: Calcul des facteurs
Show-SectionTitle "4. Calcul des facteurs"

# Test 4.1: Facteur de frÃ©quence
$frequencyFactor = $optimizer.CalculateFrequencyFactor(1000)  # Valeur trÃ¨s Ã©levÃ©e
$test4_1 = Show-TestResult -TestName "4.1 Facteur de frÃ©quence Ã©levÃ©" -Success ($frequencyFactor -le 1.0) -Message "Facteur de frÃ©quence: $frequencyFactor"
$testResults += $test4_1

# Test 4.2: Facteur de rÃ©cence
$lastAccess = (Get-Date).AddDays(-30)  # AccÃ¨s trÃ¨s ancien
$recencyFactor = $optimizer.CalculateRecencyFactor($lastAccess)
$test4_2 = Show-TestResult -TestName "4.2 Facteur de rÃ©cence pour accÃ¨s ancien" -Success ($recencyFactor -ge 0.0 -and $recencyFactor -le 1.0) -Message "Facteur de rÃ©cence: $recencyFactor"
$testResults += $test4_2

# Test 4.3: Facteur de stabilitÃ©
$stabilityFactor = $optimizer.CalculateStabilityFactor(0.0)  # Ratio de hits nul
$test4_3 = Show-TestResult -TestName "4.3 Facteur de stabilitÃ© pour ratio nul" -Success ($stabilityFactor -eq 0.0) -Message "Facteur de stabilitÃ©: $stabilityFactor"
$testResults += $test4_3

# Test 4.4: Facteur de stabilitÃ©
$stabilityFactor = $optimizer.CalculateStabilityFactor(1.0)  # Ratio de hits parfait
$test4_4 = Show-TestResult -TestName "4.4 Facteur de stabilitÃ© pour ratio parfait" -Success ($stabilityFactor -eq 1.0) -Message "Facteur de stabilitÃ©: $stabilityFactor"
$testResults += $test4_4

# Test 5: Statistiques d'optimisation
Show-SectionTitle "5. Statistiques d'optimisation"

# Test 5.1: Obtenir les statistiques
$stats = $optimizer.GetOptimizationStatistics()
$test5_1 = Show-TestResult -TestName "5.1 Obtenir les statistiques" -Success ($null -ne $stats) -Message "Statistiques rÃ©cupÃ©rÃ©es: RuleCount=$($stats.RuleCount), PatternCount=$($stats.PatternCount)"
$testResults += $test5_1

# RÃ©sumÃ© des tests
Show-SectionTitle "RÃ©sumÃ© des tests"

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Tests exÃ©cutÃ©s: $totalTests" -ForegroundColor White
Write-Host "Tests rÃ©ussis: $passedTests" -ForegroundColor Green
Write-Host "Tests Ã©chouÃ©s: $failedTests" -ForegroundColor Red
Write-Host "Taux de rÃ©ussite: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Cyan

# Nettoyage
Write-Host "`nNettoyage..." -ForegroundColor Cyan
if (Test-Path -Path $testCachePath) {
    Remove-Item -Path $testCachePath -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path -Path $testDatabasePath) {
    Remove-Item -Path $testDatabasePath -Force -ErrorAction SilentlyContinue
}

# RÃ©sultat final
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
