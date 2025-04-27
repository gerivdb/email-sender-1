#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour le module DependencyManager.
.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour le module DependencyManager
    du systÃ¨me de cache prÃ©dictif.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Importer le module de types simulÃ©s
$mockTypesPath = Join-Path -Path $PSScriptRoot -ChildPath "MockTypes.psm1"
Import-Module $mockTypesPath -Force

# CrÃ©er un chemin temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSCacheManager_Tests"
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

Show-SectionTitle "Tests simplifiÃ©s pour DependencyManager"

# CrÃ©er les objets de base pour les tests
$baseCache = [CacheManager]::new("TestCache", $testCachePath)
$usageCollector = [UsageCollector]::new($testDatabasePath, "TestCache")

# Ajouter des donnÃ©es de test au UsageCollector
$usageCollector.RecordAccess("Key1", $true)
$usageCollector.RecordAccess("Key2", $true)
$usageCollector.RecordAccess("Key3", $true)

# Test 1: CrÃ©ation d'un gestionnaire de dÃ©pendances
Show-SectionTitle "1. CrÃ©ation d'un gestionnaire de dÃ©pendances"

# Test 1.1: CrÃ©ation directe
$manager = [DependencyManager]::new($baseCache, $usageCollector)
$test1_1 = Show-TestResult -TestName "1.1 CrÃ©ation directe" -Success ($null -ne $manager) -Message "Gestionnaire crÃ©Ã©: $($manager.GetType().Name)"
$testResults += $test1_1

# Test 1.2: CrÃ©ation via la fonction
$managerFromFunction = New-DependencyManager -BaseCache $baseCache -UsageCollector $usageCollector
$test1_2 = Show-TestResult -TestName "1.2 CrÃ©ation via la fonction" -Success ($null -ne $managerFromFunction) -Message "Gestionnaire crÃ©Ã©: $($managerFromFunction.GetType().Name)"
$testResults += $test1_2

# Test 2: Ajout et rÃ©cupÃ©ration de dÃ©pendances
Show-SectionTitle "2. Ajout et rÃ©cupÃ©ration de dÃ©pendances"

# Test 2.1: Ajout d'une dÃ©pendance
$manager.AddDependency("Source1", "Target1", 0.8)
$dependencies = $manager.GetDependencies("Source1")
$test2_1 = Show-TestResult -TestName "2.1 Ajout d'une dÃ©pendance" -Success ($dependencies.Count -eq 1) -Message "Nombre de dÃ©pendances: $($dependencies.Count)"
$testResults += $test2_1

# Test 2.2: VÃ©rification de la force de la dÃ©pendance
$strength = $dependencies["Target1"]
$test2_2 = Show-TestResult -TestName "2.2 VÃ©rification de la force" -Success ($strength -eq 0.8) -Message "Force de la dÃ©pendance: $strength"
$testResults += $test2_2

# Test 2.3: Ajout de plusieurs dÃ©pendances
$manager.AddDependency("Source2", "Target1", 0.5)
$manager.AddDependency("Source2", "Target2", 0.7)
$dependencies = $manager.GetDependencies("Source2")
$test2_3 = Show-TestResult -TestName "2.3 Ajout de plusieurs dÃ©pendances" -Success ($dependencies.Count -eq 2) -Message "Nombre de dÃ©pendances: $($dependencies.Count)"
$testResults += $test2_3

# Test 3: Suppression de dÃ©pendances
Show-SectionTitle "3. Suppression de dÃ©pendances"

# Test 3.1: Suppression d'une dÃ©pendance
$result = $manager.RemoveDependency("Source2", "Target1")
$dependencies = $manager.GetDependencies("Source2")
$test3_1 = Show-TestResult -TestName "3.1 Suppression d'une dÃ©pendance" -Success ($result -and $dependencies.Count -eq 1) -Message "Nombre de dÃ©pendances restantes: $($dependencies.Count)"
$testResults += $test3_1

# Test 3.2: Suppression d'une dÃ©pendance inexistante
$result = $manager.RemoveDependency("Source2", "NonExistent")
$test3_2 = Show-TestResult -TestName "3.2 Suppression d'une dÃ©pendance inexistante" -Success ($result -eq $false) -Message "RÃ©sultat: $result"
$testResults += $test3_2

# Test 4: Configuration du gestionnaire
Show-SectionTitle "4. Configuration du gestionnaire"

# Test 4.1: Configuration via la fonction
$result = Set-DependencyManagerOptions -DependencyManager $manager -AutoDetectDependencies $false -MaxDependenciesPerKey 5 -MinDependencyStrength 0.2
$test4_1 = Show-TestResult -TestName "4.1 Configuration via la fonction" -Success $result -Message "AutoDetect=$($manager.AutoDetectDependencies), MaxDependencies=$($manager.MaxDependenciesPerKey), MinStrength=$($manager.MinDependencyStrength)"
$testResults += $test4_1

# Test 5: Ajout de dÃ©pendances via la fonction
Show-SectionTitle "5. Ajout de dÃ©pendances via la fonction"

# Test 5.1: Ajout d'une dÃ©pendance via la fonction
$result = Add-CacheDependency -DependencyManager $manager -SourceKey "Source3" -TargetKey "Target3" -Strength 0.9
$dependencies = $manager.GetDependencies("Source3")
$test5_1 = Show-TestResult -TestName "5.1 Ajout d'une dÃ©pendance via la fonction" -Success ($result -and $dependencies.Count -eq 1) -Message "Nombre de dÃ©pendances: $($dependencies.Count)"
$testResults += $test5_1

# Test 6: Suppression de dÃ©pendances via la fonction
Show-SectionTitle "6. Suppression de dÃ©pendances via la fonction"

# Test 6.1: Suppression d'une dÃ©pendance via la fonction
$result = Remove-CacheDependency -DependencyManager $manager -SourceKey "Source3" -TargetKey "Target3"
$dependencies = $manager.GetDependencies("Source3")
$test6_1 = Show-TestResult -TestName "6.1 Suppression d'une dÃ©pendance via la fonction" -Success ($result -and $dependencies.Count -eq 0) -Message "Nombre de dÃ©pendances restantes: $($dependencies.Count)"
$testResults += $test6_1

# Test 7: Statistiques des dÃ©pendances
Show-SectionTitle "7. Statistiques des dÃ©pendances"

# Test 7.1: Obtention des statistiques
$stats = $manager.GetDependencyStatistics()
$test7_1 = Show-TestResult -TestName "7.1 Obtention des statistiques" -Success ($null -ne $stats) -Message "TotalSources=$($stats.TotalSources), TotalTargets=$($stats.TotalTargets), TotalDependencies=$($stats.TotalDependencies)"
$testResults += $test7_1

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
