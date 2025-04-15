#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour les fonctionnalités incrémentales du module FileContentIndexer.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctionnalités d'indexation incrémentale
    et parallèle du module FileContentIndexer en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
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
$testDir = Join-Path -Path $env:TEMP -ChildPath "FileContentIndexerIncrementalTests_$(Get-Random)"
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

Test-Function -param1 "Test" -param2 42
"@

$pyScriptContent = @"
# Test Python Script
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name

    def test_method(self):
        print(f"Hello, {self.name}!")

def test_function(param1, param2=0):
    test_variable = "Test value"
    print(test_variable)

if __name__ == "__main__":
    test_function("Test", 42)
    obj = TestClass("World")
    obj.test_method()
"@

$testPsScript = New-TestFile -Path "test.ps1" -Content $psScriptContent
$testPyScript = New-TestFile -Path "test.py" -Content $pyScriptContent

# Tests Pester
Describe "FileContentIndexer Incremental Tests" {
    BeforeAll {
        # Créer un indexeur pour les tests
        $script:indexer = New-FileContentIndexer -IndexPath $testDir -PersistIndices $true -MaxConcurrentIndexing 4 -EnableIncrementalIndexing $true
    }

    Context "Constructeur avec paramètres supplémentaires" {
        It "Crée un indexeur avec les paramètres supplémentaires" {
            $indexer | Should -Not -BeNullOrEmpty
            $indexer.GetType().Name | Should -Be "FileContentIndexer"
            $indexer.MaxConcurrentIndexing | Should -Be 4
            $indexer.EnableIncrementalIndexing | Should -Be $true
        }
    }

    Context "Indexation parallèle" {
        It "Indexe plusieurs fichiers en parallèle" {
            $files = @($testPsScript, $testPyScript)
            $results = New-ParallelFileIndices -Indexer $indexer -FilePaths $files

            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2
            $results.ContainsKey($testPsScript) | Should -Be $true
            $results.ContainsKey($testPyScript) | Should -Be $true
            $results[$testPsScript] | Should -Not -BeNullOrEmpty
            $results[$testPyScript] | Should -Not -BeNullOrEmpty
        }
    }

    Context "Indexation incrémentale" {
        It "Indexe un fichier de manière incrémentale" {
            # Indexer le fichier original
            New-FileIndex -Indexer $indexer -FilePath $testPsScript | Out-Null

            # Modifier le contenu
            $oldContent = $psScriptContent
            $newContent = $psScriptContent.Replace("Test-Function", "New-TestFunction").Replace("$testVariable", "$newVariable")

            # Indexer de manière incrémentale
            $incrementalIndex = New-IncrementalFileIndex -Indexer $indexer -FilePath $testPsScript -OldContent $oldContent -NewContent $newContent

            $incrementalIndex | Should -Not -BeNullOrEmpty
            $incrementalIndex.FilePath | Should -Be $testPsScript
            $incrementalIndex.IsPartialIndex | Should -Be $true
            $incrementalIndex.ChangedFunctions.Count | Should -BeGreaterThan 0
            $incrementalIndex.ChangedFunctions | Should -Contain "New-TestFunction"
        }

        It "Détecte correctement les lignes modifiées" {
            # Indexer le fichier original
            New-FileIndex -Indexer $indexer -FilePath $testPsScript | Out-Null

            # Modifier le contenu (juste un commentaire)
            $oldContent = $psScriptContent
            $newContent = $psScriptContent.Replace("# Test PowerShell Script", "# Modified PowerShell Script")

            # Indexer de manière incrémentale
            $incrementalIndex = New-IncrementalFileIndex -Indexer $indexer -FilePath $testPsScript -OldContent $oldContent -NewContent $newContent

            $incrementalIndex | Should -Not -BeNullOrEmpty
            $incrementalIndex.ChangedLines.Count | Should -BeGreaterThan 0
            $incrementalIndex.ChangedLines | Should -Contain 1  # La première ligne a été modifiée
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
