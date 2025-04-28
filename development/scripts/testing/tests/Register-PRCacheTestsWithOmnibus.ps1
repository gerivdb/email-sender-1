#Requires -Version 5.1
<#
.SYNOPSIS
    Enregistre les tests du systÃ¨me de cache avec TestOmnibus.
.DESCRIPTION
    Ce script enregistre tous les tests unitaires, d'intÃ©gration et de performance
    du systÃ¨me de cache d'analyse des pull requests avec TestOmnibus.
.PARAMETER TestOmnibusPath
    Le chemin vers le rÃ©pertoire de TestOmnibus.
    Par dÃ©faut: "scripts\tests\TestOmnibus"
.EXAMPLE
    .\Register-PRCacheTestsWithOmnibus.ps1
    Enregistre les tests avec TestOmnibus en utilisant le chemin par dÃ©faut.
.EXAMPLE
    .\Register-PRCacheTestsWithOmnibus.ps1 -TestOmnibusPath "D:\Tests\TestOmnibus"
    Enregistre les tests avec TestOmnibus en utilisant un chemin personnalisÃ©.
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

# VÃ©rifier que le rÃ©pertoire TestOmnibus existe
if (-not (Test-Path -Path $TestOmnibusPath)) {
    throw "RÃ©pertoire TestOmnibus non trouvÃ©: $TestOmnibusPath"
}

# Chemin du module TestOmnibus
$testOmnibusModule = Join-Path -Path $TestOmnibusPath -ChildPath "TestOmnibus.psm1"

# VÃ©rifier que le module TestOmnibus existe
if (-not (Test-Path -Path $testOmnibusModule)) {
    throw "Module TestOmnibus non trouvÃ©: $testOmnibusModule"
}

# Importer le module TestOmnibus
Import-Module $testOmnibusModule -Force

# Chemin des tests du systÃ¨me de cache
$cacheTestsPath = $PSScriptRoot

# VÃ©rifier que le rÃ©pertoire des tests existe
if (-not (Test-Path -Path $cacheTestsPath)) {
    throw "RÃ©pertoire des tests du systÃ¨me de cache non trouvÃ©: $cacheTestsPath"
}

# Fichiers de test Ã  enregistrer
$testFiles = @(
    "PRAnalysisCache.Tests.ps1",
    "Initialize-PRCachePersistence.Tests.ps1",
    "Test-PRCacheValidity.Tests.ps1",
    "Update-PRCacheSelectively.Tests.ps1",
    "Get-PRCacheStatistics.Tests.ps1",
    "PRCacheSystem.Integration.Tests.ps1",
    "PRCache.Performance.Tests.ps1"
)

# VÃ©rifier que tous les fichiers de test existent
foreach ($testFile in $testFiles) {
    $testFilePath = Join-Path -Path $cacheTestsPath -ChildPath $testFile
    if (-not (Test-Path -Path $testFilePath)) {
        Write-Warning "Fichier de test non trouvÃ©: $testFilePath"
    }
}

# Enregistrer les tests avec TestOmnibus
Write-Host "Enregistrement des tests du systÃ¨me de cache avec TestOmnibus..." -ForegroundColor Cyan

# CrÃ©er la configuration des tests
$testConfig = @{
    Name = "PRCacheSystem"
    Description = "Tests du systÃ¨me de cache d'analyse des pull requests"
    Category = "PR-Analysis"
    Tags = @("Cache", "Performance", "Integration")
    Priority = "High"
    TestFiles = @()
}

# Ajouter les fichiers de test Ã  la configuration
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

# Afficher le rÃ©sultat
if ($result.Success) {
    Write-Host "Tests enregistrÃ©s avec succÃ¨s!" -ForegroundColor Green
    Write-Host "ID de la suite de tests: $($result.SuiteId)" -ForegroundColor White
    Write-Host "Nombre de tests enregistrÃ©s: $($result.TestCount)" -ForegroundColor White
} else {
    Write-Host "Ã‰chec de l'enregistrement des tests: $($result.Error)" -ForegroundColor Red
}

# Retourner le rÃ©sultat
return $result
