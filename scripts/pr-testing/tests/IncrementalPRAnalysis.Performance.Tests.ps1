#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctionnalités de performance du script Start-IncrementalPRAnalysis.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalités de performance
    du script Start-IncrementalPRAnalysis en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script à tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-IncrementalPRAnalysis.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Start-IncrementalPRAnalysis non trouvé à l'emplacement: $scriptToTest"
}

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modulesToImport = @(
    "FileContentIndexer.psm1",
    "SyntaxAnalyzer.psm1",
    "PRAnalysisCache.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    }
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "IncrementalPRAnalysisPerformanceTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $fullPath = Join-Path -Path $testDir -ChildPath $Path
    $directory = Split-Path -Path $fullPath -Parent
    
    if (-not (Test-Path -Path $directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }
    
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    return $fullPath
}

# Créer des fichiers de test
$psScriptContent = @"
# Test PowerShell Script
Import-Module MyModule

function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )
    
    `$testVariable = "Test value"
    Write-Output `$testVariable
}

function Get-TestData {
    param(
        [string]`$source
    )
    
    return "Data from `$source"
}

Test-Function -param1 "Test" -param2 42
Get-TestData -source "Test"
"@

$testPsScript = New-TestFile -Path "test_incremental.ps1" -Content $psScriptContent

# Fonction pour tester la fonction Invoke-FileAnalysis
function Test-FileAnalysisFunction {
    param(
        [object]$File,
        [object]$Analyzer,
        [object]$Cache,
        [bool]$UseFileCache,
        [string]$RepoPath,
        [bool]$CollectPerformanceMetrics = $true,
        [bool]$UseParallelAnalysis = $false,
        [int]$SignificanceScore = 0
    )
    
    # Charger le script à tester
    . $scriptToTest
    
    # Appeler la fonction Invoke-FileAnalysis
    return Invoke-FileAnalysis -File $File -Analyzer $Analyzer -Cache $Cache -UseFileCache $UseFileCache -RepoPath $RepoPath -CollectPerformanceMetrics $CollectPerformanceMetrics -UseParallelAnalysis $UseParallelAnalysis -SignificanceScore $SignificanceScore
}

# Tests Pester
Describe "Start-IncrementalPRAnalysis Performance Tests" {
    BeforeAll {
        # Créer un analyseur pour les tests
        $script:analyzer = New-SyntaxAnalyzer
        
        # Créer un cache pour les tests
        $script:cache = New-PRAnalysisCache -MaxMemoryItems 100
        
        # Créer un objet de fichier pour les tests
        $script:fileObject = [PSCustomObject]@{
            path = "test_incremental.ps1"
            sha = "123456789abcdef"
            additions = 10
            deletions = 5
        }
    }
    
    Context "Invoke-FileAnalysis avec métriques de performance" {
        It "Collecte des métriques de performance" {
            $result = Test-FileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -CollectPerformanceMetrics $true
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalTimeMs | Should -BeGreaterThan 0
            $result.AnalysisTimeMs | Should -BeGreaterThan 0
            $result.FileSize | Should -BeGreaterThan 0
            $result.FileExtension | Should -Be ".ps1"
        }
        
        It "Utilise l'analyse parallèle pour les grands fichiers" {
            # Créer un grand fichier
            $largeContent = $psScriptContent * 10
            $largeFile = New-TestFile -Path "large_file.ps1" -Content $largeContent
            
            # Créer un objet de fichier pour le grand fichier
            $largeFileObject = [PSCustomObject]@{
                path = "large_file.ps1"
                sha = "987654321fedcba"
                additions = 100
                deletions = 50
            }
            
            $result = Test-FileAnalysisFunction -File $largeFileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -UseParallelAnalysis $true
            
            $result | Should -Not -BeNullOrEmpty
            $result.FileSize | Should -BeGreaterThan 0
        }
        
        It "Utilise le score de significativité" {
            $result = Test-FileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -SignificanceScore 75
            
            $result | Should -Not -BeNullOrEmpty
            $result.SignificanceScore | Should -Be 75
        }
        
        It "Groupe les problèmes par type et sévérité" {
            $result = Test-FileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -CollectPerformanceMetrics $true
            
            $result | Should -Not -BeNullOrEmpty
            $result.IssuesByType | Should -Not -BeNullOrEmpty
            $result.IssuesBySeverity | Should -Not -BeNullOrEmpty
        }
        
        It "Utilise le cache pour améliorer les performances" {
            # Première analyse (sans cache)
            $startTime1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = Test-FileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir
            $startTime1.Stop()
            $time1 = $startTime1.ElapsedMilliseconds
            
            # Deuxième analyse (avec cache)
            $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = Test-FileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir
            $startTime2.Stop()
            $time2 = $startTime2.ElapsedMilliseconds
            
            # La deuxième analyse devrait être plus rapide
            $time2 | Should -BeLessThan $time1
            $result2.FromCache | Should -Be $true
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
