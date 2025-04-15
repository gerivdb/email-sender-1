#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-SmartPartialAnalysis.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Start-SmartPartialAnalysis
    en utilisant le framework Pester.
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-SmartPartialAnalysis.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Start-SmartPartialAnalysis non trouvé à l'emplacement: $scriptToTest"
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
$testDir = Join-Path -Path $env:TEMP -ChildPath "SmartPartialAnalysisTests_$(Get-Random)"
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

$modifiedPsScriptContent = @"
# Test PowerShell Script
Import-Module MyModule

function Test-Function {
    param(
        [string]`$param1,
        [int]`$param2 = 0
    )
    
    `$testVariable = "Modified value"
    Write-Output `$testVariable
}

function Get-TestData {
    param(
        [string]`$source
    )
    
    return "Modified data from `$source"
}

Test-Function -param1 "Test" -param2 42
Get-TestData -source "Test"
"@

$testPsScript = New-TestFile -Path "test_partial.ps1" -Content $psScriptContent

# Fonction pour tester la fonction Invoke-PartialFileAnalysis
function Test-PartialFileAnalysisFunction {
    param(
        [object]$File,
        [object]$Analyzer,
        [object]$Cache,
        [bool]$UseFileCache,
        [string]$RepoPath,
        [string]$BaseBranch,
        [string]$HeadBranch,
        [int]$Context,
        [bool]$UseIntelligentContext = $true,
        [bool]$IncludeSymbolContext = $true
    )
    
    # Charger le script à tester
    . $scriptToTest
    
    # Appeler la fonction Invoke-PartialFileAnalysis
    return Invoke-PartialFileAnalysis -File $File -Analyzer $Analyzer -Cache $Cache -UseFileCache $UseFileCache -RepoPath $RepoPath -BaseBranch $BaseBranch -HeadBranch $HeadBranch -Context $Context -UseIntelligentContext $UseIntelligentContext -IncludeSymbolContext $IncludeSymbolContext
}

# Fonction pour simuler Get-FileDiff
function Get-FileDiff {
    param(
        [string]$RepoPath,
        [string]$FilePath,
        [string]$BaseBranch,
        [string]$HeadBranch
    )
    
    # Simuler des lignes modifiées
    return @(
        [PSCustomObject]@{
            LineNumber = 10
            Content = '$testVariable = "Modified value"'
            Type = "Modified"
        },
        [PSCustomObject]@{
            LineNumber = 20
            Content = 'return "Modified data from $source"'
            Type = "Modified"
        }
    )
}

# Tests Pester
Describe "Start-SmartPartialAnalysis Tests" {
    BeforeAll {
        # Créer un analyseur pour les tests
        $script:analyzer = New-SyntaxAnalyzer
        
        # Créer un cache pour les tests
        $script:cache = New-PRAnalysisCache -MaxMemoryItems 100
        
        # Créer un objet de fichier pour les tests
        $script:fileObject = [PSCustomObject]@{
            path = "test_partial.ps1"
            sha = "123456789abcdef"
        }
    }
    
    Context "Invoke-PartialFileAnalysis avec métriques de performance" {
        It "Collecte des métriques de performance" {
            # Définir la fonction Get-FileDiff dans le scope global pour qu'elle soit accessible
            Set-Item -Path function:Global:Get-FileDiff -Value ${function:Get-FileDiff}
            
            $result = Test-PartialFileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -BaseBranch "main" -HeadBranch "feature" -Context 3
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalTimeMs | Should -BeGreaterThan 0
            $result.AnalysisTimeMs | Should -BeGreaterThan 0
            $result.DiffTimeMs | Should -BeGreaterThan 0
            $result.ContextTimeMs | Should -BeGreaterThan 0
            $result.FilterTimeMs | Should -BeGreaterThan 0
            $result.FileSize | Should -BeGreaterThan 0
        }
        
        It "Utilise le contexte intelligent" {
            # Définir la fonction Get-FileDiff dans le scope global pour qu'elle soit accessible
            Set-Item -Path function:Global:Get-FileDiff -Value ${function:Get-FileDiff}
            
            $result = Test-PartialFileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -BaseBranch "main" -HeadBranch "feature" -Context 3 -UseIntelligentContext $true
            
            $result | Should -Not -BeNullOrEmpty
            $result.ContextStrategy | Should -Be "Intelligent"
        }
        
        It "Utilise le contexte standard quand demandé" {
            # Définir la fonction Get-FileDiff dans le scope global pour qu'elle soit accessible
            Set-Item -Path function:Global:Get-FileDiff -Value ${function:Get-FileDiff}
            
            $result = Test-PartialFileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -BaseBranch "main" -HeadBranch "feature" -Context 3 -UseIntelligentContext $false
            
            $result | Should -Not -BeNullOrEmpty
            $result.ContextStrategy | Should -Be "Standard"
        }
        
        It "Utilise le cache pour améliorer les performances" {
            # Définir la fonction Get-FileDiff dans le scope global pour qu'elle soit accessible
            Set-Item -Path function:Global:Get-FileDiff -Value ${function:Get-FileDiff}
            
            # Première analyse (sans cache)
            $startTime1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = Test-PartialFileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -BaseBranch "main" -HeadBranch "feature" -Context 3
            $startTime1.Stop()
            $time1 = $startTime1.ElapsedMilliseconds
            
            # Deuxième analyse (avec cache)
            $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = Test-PartialFileAnalysisFunction -File $script:fileObject -Analyzer $script:analyzer -Cache $script:cache -UseFileCache $true -RepoPath $testDir -BaseBranch "main" -HeadBranch "feature" -Context 3
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
        
        # Supprimer la fonction globale
        if (Test-Path function:Global:Get-FileDiff) {
            Remove-Item function:Global:Get-FileDiff
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
