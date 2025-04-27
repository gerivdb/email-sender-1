#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-SignificantChanges.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Test-SignificantChanges
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script Ã  tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-SignificantChanges.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Test-SignificantChanges non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modulesToImport = @(
    "FileContentIndexer.psm1",
    "PRAnalysisCache.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    }
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "SignificantChangesTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
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

# CrÃ©er des fichiers de test
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

# Fonction pour crÃ©er un objet de version de fichier
function New-FileVersion {
    param(
        [string]$FilePath,
        [string]$BaseContent,
        [string]$HeadContent,
        [bool]$IsNewFile = $false,
        [bool]$IsDeletedFile = $false,
        [bool]$IsModifiedFile = $true
    )
    
    return [PSCustomObject]@{
        FilePath = $FilePath
        BaseContent = $BaseContent
        HeadContent = $HeadContent
        IsNewFile = $IsNewFile
        IsDeletedFile = $IsDeletedFile
        IsModifiedFile = $IsModifiedFile
    }
}

# Fonction pour tester la fonction Test-FileChanges
function Test-FileChangesFunction {
    param(
        [object]$FileVersions,
        [object]$Indexer,
        [double]$Threshold = 0.1,
        [int]$MinChanges = 5
    )
    
    # Charger le script Ã  tester
    . $scriptToTest
    
    # Appeler la fonction Test-FileChanges
    return Test-FileChanges -FileVersions $FileVersions -Indexer $Indexer -Threshold $Threshold -MinChanges $MinChanges
}

# Tests Pester
Describe "Test-SignificantChanges Tests" {
    BeforeAll {
        # CrÃ©er un indexeur pour les tests
        $script:indexer = New-FileContentIndexer -IndexPath $testDir -PersistIndices $true
        
        # Indexer les fichiers de test
        New-FileIndex -Indexer $script:indexer -FilePath $testPsScript | Out-Null
        New-FileIndex -Indexer $script:indexer -FilePath $testPyScript | Out-Null
    }
    
    Context "Test-FileChanges avec score de significativitÃ©" {
        It "Attribue un score Ã©levÃ© pour un nouveau fichier" {
            $fileVersion = New-FileVersion -FilePath $testPsScript -BaseContent "" -HeadContent $psScriptContent -IsNewFile $true -IsModifiedFile $false
            $result = Test-FileChangesFunction -FileVersions $fileVersion -Indexer $script:indexer
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsSignificant | Should -Be $true
            $result.Score | Should -Be 100
            $result.Reason | Should -Be "Nouveau fichier"
        }
        
        It "Attribue un score Ã©levÃ© pour un fichier supprimÃ©" {
            $fileVersion = New-FileVersion -FilePath $testPsScript -BaseContent $psScriptContent -HeadContent "" -IsNewFile $false -IsDeletedFile $true -IsModifiedFile $false
            $result = Test-FileChangesFunction -FileVersions $fileVersion -Indexer $script:indexer
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsSignificant | Should -Be $true
            $result.Score | Should -Be 100
            $result.Reason | Should -Be "Fichier supprimÃ©"
        }
        
        It "Attribue un score Ã©levÃ© pour des changements de fonction" {
            $newContent = $psScriptContent.Replace("Test-Function", "New-TestFunction")
            $fileVersion = New-FileVersion -FilePath $testPsScript -BaseContent $psScriptContent -HeadContent $newContent
            $result = Test-FileChangesFunction -FileVersions $fileVersion -Indexer $script:indexer
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsSignificant | Should -Be $true
            $result.Score | Should -BeGreaterThan 0
            $result.Reason | Should -Match "Fonctions"
        }
        
        It "Attribue un score faible pour des changements mineurs" {
            $newContent = $psScriptContent.Replace("# Test PowerShell Script", "# Modified PowerShell Script")
            $fileVersion = New-FileVersion -FilePath $testPsScript -BaseContent $psScriptContent -HeadContent $newContent
            $result = Test-FileChangesFunction -FileVersions $fileVersion -Indexer $script:indexer -Threshold 0.5 -MinChanges 10
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsSignificant | Should -Be $false
            $result.Score | Should -BeLessThan 50
        }
        
        It "DÃ©tecte les mots-clÃ©s importants" {
            $newContent = $psScriptContent.Replace("Test value", "Critical security fix")
            $fileVersion = New-FileVersion -FilePath $testPsScript -BaseContent $psScriptContent -HeadContent $newContent
            $result = Test-FileChangesFunction -FileVersions $fileVersion -Indexer $script:indexer
            
            $result | Should -Not -BeNullOrEmpty
            $result.IsSignificant | Should -Be $true
            $result.Score | Should -BeGreaterThan 0
            $result.Reason | Should -Match "Mot-clÃ© important"
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
