#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction Detect-FileFormatWithConfirmation.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement de la fonction
    Detect-FileFormatWithConfirmation du module Format-Converters. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\Detect-FileFormatWithConfirmation.Tests.ps1
    Exécute les tests unitaires pour la fonction Detect-FileFormatWithConfirmation.

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
$detectorsPath = Join-Path -Path $moduleRoot -ChildPath "Detectors"
$detectWithConfirmationPath = Join-Path -Path $detectorsPath -ChildPath "Detect-FileFormatWithConfirmation.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "DetectWithConfirmationTests_$(Get-Random)"
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

$jsonJsAmbiguousContent = @"
{
    "function": "test",
    "code": "function test() { return 'Hello World'; }"
}
"@

$jsonPath = New-TestFile -FileName "test.json" -Content $jsonContent
$jsonJsAmbiguousPath = New-TestFile -FileName "ambiguous_json_js.txt" -Content $jsonJsAmbiguousContent

# Tests Pester
Describe "Fonction Detect-FileFormatWithConfirmation" {
    BeforeAll {
        # Importer le module Format-Converters
        Import-Module $modulePath -Force
        
        # Créer des mocks pour les fonctions utilisées par Detect-FileFormatWithConfirmation
        Mock Handle-AmbiguousFormats {
            return [PSCustomObject]@{
                FilePath = $FilePath
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                MatchedCriteria = "Extension (.json), Contenu (\"\\w+\"\\s*:), Structure (\\{.*\\})"
            }
        }
        
        Mock Show-FormatDetectionResults {
            return $DetectionResult
        }
    }
    
    Context "Détection de format avec confirmation" {
        It "Détecte le format d'un fichier sans erreur" {
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }
        
        It "Utilise l'option -AutoResolve correctement" {
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath -AutoResolve
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que Handle-AmbiguousFormats a été appelé avec l'option -AutoResolve
            Assert-MockCalled Handle-AmbiguousFormats -ParameterFilter { $AutoResolve -eq $true }
        }
        
        It "Utilise l'option -ShowDetails correctement" {
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que Handle-AmbiguousFormats a été appelé avec l'option -ShowDetails
            Assert-MockCalled Handle-AmbiguousFormats -ParameterFilter { $ShowDetails -eq $true }
            
            # Vérifier que Show-FormatDetectionResults a été appelé
            Assert-MockCalled Show-FormatDetectionResults
        }
        
        It "Utilise l'option -RememberChoices correctement" {
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath -RememberChoices
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que Handle-AmbiguousFormats a été appelé avec l'option -RememberChoices
            Assert-MockCalled Handle-AmbiguousFormats -ParameterFilter { $RememberChoices -eq $true }
        }
    }
    
    Context "Exportation des résultats" {
        It "Exporte les résultats avec l'option -ExportResults" {
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath -ShowDetails -ExportResults -ExportFormat "JSON"
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que Show-FormatDetectionResults a été appelé avec les options d'exportation
            Assert-MockCalled Show-FormatDetectionResults -ParameterFilter { $ExportFormat -eq "JSON" }
        }
        
        It "Utilise le chemin de sortie spécifié avec -OutputPath" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.json"
            
            $result = Detect-FileFormatWithConfirmation -FilePath $jsonPath -ShowDetails -ExportResults -ExportFormat "JSON" -OutputPath $outputPath
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que Show-FormatDetectionResults a été appelé avec le chemin de sortie spécifié
            Assert-MockCalled Show-FormatDetectionResults -ParameterFilter { $OutputPath -eq $outputPath }
        }
    }
    
    Context "Gestion des erreurs" {
        It "Lève une erreur si le fichier n'existe pas" {
            { Detect-FileFormatWithConfirmation -FilePath "fichier_inexistant.txt" } | Should -Throw
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
