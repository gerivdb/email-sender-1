#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module FileContentIndexer.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module FileContentIndexer
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du module à tester
$moduleToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\FileContentIndexer.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $moduleToTest)) {
    throw "Module FileContentIndexer non trouvé à l'emplacement: $moduleToTest"
}

# Importer le module à tester
Import-Module $moduleToTest -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "FileContentIndexerTests_$(Get-Random)"
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
$psScriptContent = @'
function Test-Function {
    param(
        [string]$Parameter1,
        [int]$Parameter2 = 0
    )
    
    $result = $Parameter1 + $Parameter2
    return $result
}

$testVariable = "Test Value"

Import-Module MyModule

# Test comment
foreach ($item in $collection) {
    Write-Output $item
}
'@

$pythonScriptContent = @'
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name
    
    def test_method(self, param1):
        return f"Hello, {param1}!"

def test_function(param1, param2=0):
    result = param1 + param2
    return result

# Test comment
for item in collection:
    print(item)
'@

$testPsScript = New-TestFile -Path "test_script.ps1" -Content $psScriptContent
$testPyScript = New-TestFile -Path "test_script.py" -Content $pythonScriptContent
$testTxtFile = New-TestFile -Path "test_file.txt" -Content "This is a test file."

# Tests Pester
Describe "FileContentIndexer Module Tests" {
    BeforeAll {
        # Créer un indexeur pour les tests
        $script:indexer = New-FileContentIndexer -IndexPath $testDir -PersistIndices $true
    }
    
    Context "New-FileContentIndexer" {
        It "Crée un nouvel indexeur" {
            $indexer | Should -Not -BeNullOrEmpty
            $indexer.GetType().Name | Should -Be "FileContentIndexer"
        }
        
        It "Initialise correctement les propriétés" {
            $indexer.FileIndices | Should -Not -BeNullOrEmpty
            $indexer.SymbolMap | Should -Not -BeNullOrEmpty
            $indexer.IndexPath | Should -Be $testDir
            $indexer.PersistIndices | Should -Be $true
        }
    }
    
    Context "New-FileIndex" {
        It "Indexe un fichier PowerShell" {
            $index = New-FileIndex -Indexer $indexer -FilePath $testPsScript
            $index | Should -Not -BeNullOrEmpty
            $index.FilePath | Should -Be $testPsScript
            $index.FileHash | Should -Not -BeNullOrEmpty
            $index.Functions.Count | Should -BeGreaterThan 0
            $index.Functions[0].Name | Should -Be "Test-Function"
            $index.Variables.Count | Should -BeGreaterThan 0
            $index.Imports.Count | Should -BeGreaterThan 0
            $index.Imports[0].Name | Should -Be "MyModule"
        }
        
        It "Indexe un fichier Python" {
            $index = New-FileIndex -Indexer $indexer -FilePath $testPyScript
            $index | Should -Not -BeNullOrEmpty
            $index.FilePath | Should -Be $testPyScript
            $index.FileHash | Should -Not -BeNullOrEmpty
            $index.Functions.Count | Should -BeGreaterThan 0
            $index.Functions[0].Name | Should -Be "test_function"
            $index.Classes.Count | Should -BeGreaterThan 0
            $index.Classes[0].Name | Should -Be "TestClass"
            $index.Imports.Count | Should -BeGreaterThan 0
        }
        
        It "Indexe un fichier texte" {
            $index = New-FileIndex -Indexer $indexer -FilePath $testTxtFile
            $index | Should -Not -BeNullOrEmpty
            $index.FilePath | Should -Be $testTxtFile
            $index.FileHash | Should -Not -BeNullOrEmpty
            $index.LineCount | Should -Be 1
        }
        
        It "Retourne null pour un fichier inexistant" {
            $result = New-FileIndex -Indexer $indexer -FilePath "fichier_inexistant.txt" -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }
    
    Context "Search-FileIndex" {
        BeforeAll {
            # S'assurer que les fichiers sont indexés
            New-FileIndex -Indexer $indexer -FilePath $testPsScript | Out-Null
            New-FileIndex -Indexer $indexer -FilePath $testPyScript | Out-Null
        }
        
        It "Recherche un symbole existant" {
            $results = Search-FileIndex -Indexer $indexer -Query "Test-Function"
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results[0].FilePath | Should -Be $testPsScript
            $results[0].MatchType | Should -Be "Symbol"
        }
        
        It "Recherche un mot existant" {
            $results = Search-FileIndex -Indexer $indexer -Query "test"
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
        }
        
        It "Filtre par type de fichier" {
            $results = Search-FileIndex -Indexer $indexer -Query "test" -FileTypes @(".py")
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object { $_.FilePath | Should -BeLike "*.py" }
        }
        
        It "Retourne un tableau vide pour une recherche sans résultat" {
            $results = Search-FileIndex -Indexer $indexer -Query "MotInexistant123456789"
            $results | Should -BeOfType [array]
            $results.Count | Should -Be 0
        }
    }
    
    Context "Compare-FileVersions" {
        It "Compare deux versions d'un fichier PowerShell" {
            $oldContent = $psScriptContent
            $newContent = $psScriptContent.Replace("Test-Function", "New-TestFunction").Replace("$testVariable", "$newVariable")
            
            $comparison = Compare-FileVersions -Indexer $indexer -FilePath $testPsScript -OldContent $oldContent -NewContent $newContent
            $comparison | Should -Not -BeNullOrEmpty
            $comparison.FilePath | Should -Be $testPsScript
            $comparison.SignificantChanges | Should -Be $true
            $comparison.AddedFunctions.Count | Should -BeGreaterThan 0
            $comparison.RemovedFunctions.Count | Should -BeGreaterThan 0
        }
        
        It "Compare deux versions identiques" {
            $comparison = Compare-FileVersions -Indexer $indexer -FilePath $testPsScript -OldContent $psScriptContent -NewContent $psScriptContent
            $comparison | Should -Not -BeNullOrEmpty
            $comparison.FilePath | Should -Be $testPsScript
            $comparison.SignificantChanges | Should -Be $false
            $comparison.AddedFunctions.Count | Should -Be 0
            $comparison.RemovedFunctions.Count | Should -Be 0
            $comparison.ModifiedFunctions.Count | Should -Be 0
            $comparison.ChangeRatio | Should -Be 0
        }
        
        It "Compare avec des modifications mineures" {
            $oldContent = $psScriptContent
            $newContent = $psScriptContent.Replace("Test comment", "Updated comment")
            
            $comparison = Compare-FileVersions -Indexer $indexer -FilePath $testPsScript -OldContent $oldContent -NewContent $newContent
            $comparison | Should -Not -BeNullOrEmpty
            $comparison.FilePath | Should -Be $testPsScript
            $comparison.SignificantChanges | Should -Be $false
            $comparison.AddedFunctions.Count | Should -Be 0
            $comparison.RemovedFunctions.Count | Should -Be 0
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
