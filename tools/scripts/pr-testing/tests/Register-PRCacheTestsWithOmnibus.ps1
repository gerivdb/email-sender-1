#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du système de cache avec TestOmnibus.
.DESCRIPTION
    Ce script enregistre tous les tests unitaires, d'intégration et de performance
    du système de cache d'analyse des pull requests avec TestOmnibus.
.PARAMETER TestOmnibusPath
    Le chemin vers le répertoire de TestOmnibus.
    Par défaut: "scripts\tests\TestOmnibus"
.EXAMPLE
    .\Register-PRCacheTestsWithOmnibus.ps1
    Enregistre les tests avec TestOmnibus en utilisant le chemin par défaut.
.EXAMPLE
    .\Register-PRCacheTestsWithOmnibus.ps1 -TestOmnibusPath "D:\Tests\TestOmnibus"
    Enregistre les tests avec TestOmnibus en utilisant un chemin personnalisé.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TestOmnibusPath = "scripts\tests\TestOmnibus"
)

# Vérifier que le répertoire TestOmnibus existe
if (-not (Test-Path -Path $TestOmnibusPath)) {
    throw "Répertoire TestOmnibus non trouvé: $TestOmnibusPath"
}

# Chemin du module TestOmnibus
$testOmnibusModule = Join-Path -Path $TestOmnibusPath -ChildPath "TestOmnibus.psm1"

# Vérifier que le module TestOmnibus existe
if (-not (Test-Path -Path $testOmnibusModule)) {
    throw "Module TestOmnibus non trouvé: $testOmnibusModule"
}

# Importer le module TestOmnibus
Import-Module $testOmnibusModule -Force

# Chemin des tests du système de cache
$cacheTestsPath = $PSScriptRoot

# Vérifier que le répertoire des tests existe
if (-not (Test-Path -Path $cacheTestsPath)) {
    throw "Répertoire des tests du système de cache non trouvé: $cacheTestsPath"
}

# Fichiers de test à enregistrer
$testFiles = @(
    "PRAnalysisCache.Tests.ps1",
    "Initialize-PRCachePersistence.Tests.ps1",
    "Test-PRCacheValidity.Tests.ps1",
    "Update-PRCacheSelectively.Tests.ps1",
    "Get-PRCacheStatistics.Tests.ps1",
    "PRCacheSystem.Integration.Tests.ps1",
    "PRCache.Performance.Tests.ps1"
)

# Vérifier que tous les fichiers de test existent
foreach ($testFile in $testFiles) {
    $testFilePath = Join-Path -Path $cacheTestsPath -ChildPath $testFile
    if (-not (Test-Path -Path $testFilePath)) {
        Write-Warning "Fichier de test non trouvé: $testFilePath"
    }
}

# Enregistrer les tests avec TestOmnibus
Write-Host "Enregistrement des tests du système de cache avec TestOmnibus..." -ForegroundColor Cyan

# Créer la configuration des tests
$testConfig = @{
    Name = "PRCacheSystem"
    Description = "Tests du système de cache d'analyse des pull requests"
    Category = "PR-Analysis"
    Tags = @("Cache", "Performance", "Integration")
    Priority = "High"
    TestFiles = @()
}

# Ajouter les fichiers de test à la configuration
foreach ($testFile in $testFiles) {
    $testFilePath = Join-Path -Path $cacheTestsPath -ChildPath $testFile
    if (Test-Path -Path $testFilePath) {
        $testType = if ($testFile -like "*Performance*") {
            "Performance"
        } elseif ($testFile -like "*Integration*") {
            "Integration"
        } else {
            "Unit"
        }
        
        $testConfig.TestFiles += @{
            Path = $testFilePath
            Type = $testType
            Enabled = $true
        }
    }
}

# Enregistrer la configuration avec TestOmnibus
$result = Register-TestSuite -Config $testConfig

# Afficher le résultat
if ($result.Success) {
    Write-Host "Tests enregistrés avec succès!" -ForegroundColor Green
    Write-Host "ID de la suite de tests: $($result.SuiteId)" -ForegroundColor White
    Write-Host "Nombre de tests enregistrés: $($result.TestCount)" -ForegroundColor White
} else {
    Write-Host "Échec de l'enregistrement des tests: $($result.Error)" -ForegroundColor Red
}

# Retourner le résultat
return $result
