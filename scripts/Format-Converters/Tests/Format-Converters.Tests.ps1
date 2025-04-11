#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module Format-Converters.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement du module
    Format-Converters dans son ensemble. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\Format-Converters.Tests.ps1
    Exécute les tests unitaires pour le module Format-Converters.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Chemin du module à tester
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersModuleTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory = $testTempDir
    )
    
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# Créer des fichiers de test
$jsonContent = @"
{
    "name": "Test",
    "version": "1.0.0",
    "description": "This is a test file"
}
"@

$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element>Test</element>
    <element>Example</element>
</root>
"@

$jsonPath = New-TestFile -FileName "test.json" -Content $jsonContent
$xmlPath = New-TestFile -FileName "test.xml" -Content $xmlContent

# Tests Pester
Describe "Module Format-Converters" {
    BeforeAll {
        # Importer le module Format-Converters
        Import-Module $modulePath -Force
    }
    
    Context "Structure du module" {
        It "Le module est chargé correctement" {
            Get-Module -Name Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "Le module exporte les fonctions attendues" {
            $exportedFunctions = Get-Command -Module Format-Converters
            $exportedFunctions | Should -Not -BeNullOrEmpty
            $exportedFunctions.Name | Should -Contain "Detect-FileFormat"
            $exportedFunctions.Name | Should -Contain "Convert-FileFormat"
            $exportedFunctions.Name | Should -Contain "Analyze-FileFormat"
            $exportedFunctions.Name | Should -Contain "Register-FormatConverter"
            $exportedFunctions.Name | Should -Contain "Get-RegisteredConverters"
        }
    }
    
    Context "Fonction Detect-FileFormat" {
        It "La fonction Detect-FileFormat est disponible" {
            Get-Command -Name Detect-FileFormat -Module Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Detect-FileFormat détecte correctement le format JSON" {
            $result = Detect-FileFormat -FilePath $jsonPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }
        
        It "La fonction Detect-FileFormat détecte correctement le format XML" {
            $result = Detect-FileFormat -FilePath $xmlPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "XML"
        }
    }
    
    Context "Fonction Register-FormatConverter" {
        It "La fonction Register-FormatConverter est disponible" {
            Get-Command -Name Register-FormatConverter -Module Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Register-FormatConverter enregistre correctement un convertisseur" {
            # Enregistrer un convertisseur de test
            Register-FormatConverter -Format "test" -ConverterInfo @{
                Name = "TEST"
                Description = "Test Format"
                Extensions = @(".test")
                DetectFunction = { param($FilePath) return $true }
                ImportFunction = { param($FilePath) return Get-Content -Path $FilePath -Raw }
                ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
            }
            
            # Vérifier que le convertisseur a été enregistré
            $converters = Get-RegisteredConverters
            $converters | Should -Not -BeNullOrEmpty
            $converters.Keys | Should -Contain "test"
            $converters["test"].Name | Should -Be "TEST"
        }
    }
    
    Context "Fonction Get-RegisteredConverters" {
        It "La fonction Get-RegisteredConverters est disponible" {
            Get-Command -Name Get-RegisteredConverters -Module Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Get-RegisteredConverters retourne les convertisseurs enregistrés" {
            # Enregistrer un convertisseur de test
            Register-FormatConverter -Format "test2" -ConverterInfo @{
                Name = "TEST2"
                Description = "Test Format 2"
                Extensions = @(".test2")
                DetectFunction = { param($FilePath) return $true }
                ImportFunction = { param($FilePath) return Get-Content -Path $FilePath -Raw }
                ExportFunction = { param($Data, $FilePath) $Data | Set-Content -Path $FilePath -Encoding UTF8 }
            }
            
            # Vérifier que la fonction retourne les convertisseurs
            $converters = Get-RegisteredConverters
            $converters | Should -Not -BeNullOrEmpty
            $converters.Keys | Should -Contain "test2"
            $converters["test2"].Name | Should -Be "TEST2"
        }
    }
    
    Context "Fonction Convert-FileFormat" {
        It "La fonction Convert-FileFormat est disponible" {
            Get-Command -Name Convert-FileFormat -Module Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Convert-FileFormat lève une erreur si le fichier d'entrée n'existe pas" {
            { Convert-FileFormat -InputPath "fichier_inexistant.txt" -OutputPath "sortie.txt" -OutputFormat "TEXT" } | Should -Throw
        }
        
        It "La fonction Convert-FileFormat lève une erreur si le format de sortie n'est pas pris en charge" {
            { Convert-FileFormat -InputPath $jsonPath -OutputPath "sortie.txt" -OutputFormat "FORMAT_INCONNU" } | Should -Throw
        }
    }
    
    Context "Fonction Analyze-FileFormat" {
        It "La fonction Analyze-FileFormat est disponible" {
            Get-Command -Name Analyze-FileFormat -Module Format-Converters | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Analyze-FileFormat lève une erreur si le fichier n'existe pas" {
            { Analyze-FileFormat -FilePath "fichier_inexistant.txt" } | Should -Throw
        }
    }
    
    Context "Intégration des détecteurs de format" {
        It "Le module charge correctement les détecteurs de format" {
            # Vérifier que les détecteurs sont chargés en détectant différents formats
            $jsonResult = Detect-FileFormat -FilePath $jsonPath
            $xmlResult = Detect-FileFormat -FilePath $xmlPath
            
            $jsonResult.DetectedFormat | Should -Be "JSON"
            $xmlResult.DetectedFormat | Should -Be "XML"
        }
    }
}

# Nettoyer après les tests
AfterAll {
    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
    
    # Décharger le module
    Remove-Module -Name Format-Converters -ErrorAction SilentlyContinue
}
