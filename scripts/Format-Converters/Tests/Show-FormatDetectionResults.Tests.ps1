#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction Show-FormatDetectionResults.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement de la fonction
    Show-FormatDetectionResults du module Format-Converters. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\Show-FormatDetectionResults.Tests.ps1
    Exécute les tests unitaires pour la fonction Show-FormatDetectionResults.

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
$showResultsPath = Join-Path -Path $detectorsPath -ChildPath "Show-FormatDetectionResults.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "ShowResultsTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer un résultat de détection de test
$testDetectionResult = [PSCustomObject]@{
    FilePath = "test.json"
    Size = 1024
    IsBinary = $false
    DetectedFormat = "JSON"
    ConfidenceScore = 95
    MatchedCriteria = "Extension (.json), Contenu (\"\\w+\"\\s*:), Structure (\\{.*\\})"
    AllFormats = @(
        [PSCustomObject]@{
            Format = "JSON"
            Score = 95
            Priority = 10
            MatchedCriteria = @("Extension (.json)", "Contenu (\"\\w+\"\\s*:)", "Structure (\\{.*\\})")
        },
        [PSCustomObject]@{
            Format = "JAVASCRIPT"
            Score = 65
            Priority = 9
            MatchedCriteria = @("Contenu (var\\s+\\w+\\s*=)")
        },
        [PSCustomObject]@{
            Format = "TEXT"
            Score = 50
            Priority = 5
            MatchedCriteria = @("Extension (.txt)")
        }
    )
}

# Tests Pester
Describe "Fonction Show-FormatDetectionResults" {
    BeforeAll {
        # Importer le module Format-Converters
        Import-Module $modulePath -Force
    }
    
    Context "Affichage des résultats" {
        It "Affiche les résultats de base sans erreur" {
            { Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult } | Should -Not -Throw
        }
        
        It "Affiche tous les formats détectés avec l'option -ShowAllFormats" {
            { Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ShowAllFormats } | Should -Not -Throw
        }
    }
    
    Context "Exportation des résultats" {
        It "Exporte les résultats au format JSON" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.json"
            
            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "JSON" -OutputPath $outputPath
            
            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent.DetectedFormat | Should -Be "JSON"
        }
        
        It "Exporte les résultats au format CSV" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.csv"
            
            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "CSV" -OutputPath $outputPath
            
            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Import-Csv -Path $outputPath
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent[0].Format | Should -Be "JSON"
        }
        
        It "Exporte les résultats au format HTML" {
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.html"
            
            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "HTML" -OutputPath $outputPath
            
            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            $exportedContent = Get-Content -Path $outputPath -Raw
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent | Should -Match "<html"
            $exportedContent | Should -Match "JSON"
        }
        
        It "Génère un nom de fichier par défaut si OutputPath n'est pas spécifié" {
            # Mock de la fonction Set-Content pour éviter d'écrire réellement le fichier
            Mock Set-Content { }
            
            Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $testDetectionResult -ExportFormat "JSON"
            
            # Vérifier que Set-Content a été appelé avec un chemin qui contient "detection.json"
            Assert-MockCalled Set-Content -ParameterFilter { $Path -like "*detection.json" }
        }
    }
    
    Context "Gestion des cas particuliers" {
        It "Gère correctement un résultat sans format détecté" {
            $noFormatResult = [PSCustomObject]@{
                FilePath = "test.bin"
                Size = 1024
                IsBinary = $true
                DetectedFormat = $null
                ConfidenceScore = 0
                MatchedCriteria = ""
            }
            
            { Show-FormatDetectionResults -FilePath "test.bin" -DetectionResult $noFormatResult } | Should -Not -Throw
        }
        
        It "Gère correctement un résultat sans AllFormats" {
            $noAllFormatsResult = [PSCustomObject]@{
                FilePath = "test.json"
                Size = 1024
                IsBinary = $false
                DetectedFormat = "JSON"
                ConfidenceScore = 95
                MatchedCriteria = "Extension (.json), Contenu (\"\\w+\"\\s*:), Structure (\\{.*\\})"
            }
            
            { Show-FormatDetectionResults -FilePath "test.json" -DetectionResult $noAllFormatsResult -ShowAllFormats } | Should -Not -Throw
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
