#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script de mesure de la précision de détection.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement du script
    de mesure de la précision de détection. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\DetectionAccuracy.Tests.ps1
    Exécute les tests unitaires pour le script de mesure de la précision de détection.

.NOTES
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

# Chemins des scripts à tester
$scriptRoot = Split-Path -Parent $PSScriptRoot
$measureAccuracyScript = "$PSScriptRoot\Measure-DetectionAccuracy.ps1"
$formatDetectionScript = "$scriptRoot\analysis\Improved-FormatDetection.ps1"
$ambiguousHandlingScript = "$scriptRoot\analysis\Handle-AmbiguousFormats.ps1"

# Vérifier si les scripts nécessaires existent
$missingScripts = @()

if (-not (Test-Path -Path $measureAccuracyScript)) {
    $missingScripts += $measureAccuracyScript
}

if (-not (Test-Path -Path $formatDetectionScript)) {
    $missingScripts += $formatDetectionScript
}

if (-not (Test-Path -Path $ambiguousHandlingScript)) {
    $missingScripts += $ambiguousHandlingScript
}

if ($missingScripts.Count -gt 0) {
    Write-Error "Les scripts suivants sont manquants :`n$($missingScripts -join "`n")"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "DetectionAccuracyTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer un répertoire de test pour les échantillons
$testSamplesDir = Join-Path -Path $testTempDir -ChildPath "samples"
New-Item -Path $testSamplesDir -ItemType Directory -Force | Out-Null
New-Item -Path $testSamplesDir -ChildPath "formats" -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory
    )
    
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# Créer des fichiers d'exemple pour les tests
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

$textContent = @"
This is a test file.
It contains plain text.
"@

$jsonPath = New-TestFile -FileName "sample.json" -Content $jsonContent -Directory (Join-Path -Path $testSamplesDir -ChildPath "formats")
$xmlPath = New-TestFile -FileName "sample.xml" -Content $xmlContent -Directory (Join-Path -Path $testSamplesDir -ChildPath "formats")
$textPath = New-TestFile -FileName "sample.txt" -Content $textContent -Directory (Join-Path -Path $testSamplesDir -ChildPath "formats")

# Créer un fichier de formats attendus
$expectedFormatsContent = @"
{
    "sample.json": "JSON",
    "sample.xml": "XML",
    "sample.txt": "TEXT"
}
"@

$expectedFormatsPath = New-TestFile -FileName "ExpectedFormats.json" -Content $expectedFormatsContent -Directory $testSamplesDir

# Créer un répertoire pour les rapports
$testReportsDir = Join-Path -Path $testTempDir -ChildPath "reports"
New-Item -Path $testReportsDir -ItemType Directory -Force | Out-Null

# Tests Pester
Describe "Script de mesure de la précision de détection" {
    Context "Fonctions internes" {
        It "La fonction New-DirectoryIfNotExists crée un répertoire s'il n'existe pas" {
            # Créer un chemin de test
            $testPath = Join-Path -Path $testTempDir -ChildPath "test_directory"
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $measureAccuracyScript
                New-DirectoryIfNotExists -Path $testPath
            }
            
            # Vérifier que le répertoire a été créé
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $testPath -PathType Container | Should -Be $true
        }
        
        It "La fonction Get-ExpectedFormats charge correctement les formats attendus" {
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $measureAccuracyScript
                $formats = Get-ExpectedFormats -Path $expectedFormatsPath
                return $formats
            }
            
            # Vérifier que les formats ont été chargés correctement
            $formats = & $scriptBlock
            $formats | Should -Not -BeNullOrEmpty
            $formats["sample.json"] | Should -Be "JSON"
            $formats["sample.xml"] | Should -Be "XML"
            $formats["sample.txt"] | Should -Be "TEXT"
        }
        
        It "La fonction Get-DetectionMetrics calcule correctement les métriques" {
            # Créer des résultats de test
            $testResults = @(
                [PSCustomObject]@{
                    FilePath = "sample.json"
                    ExpectedFormat = "JSON"
                    DetectedFormat = "JSON"
                    ConfidenceScore = 95
                    IsCorrect = $true
                    IsAmbiguous = $false
                },
                [PSCustomObject]@{
                    FilePath = "sample.xml"
                    ExpectedFormat = "XML"
                    DetectedFormat = "XML"
                    ConfidenceScore = 90
                    IsCorrect = $true
                    IsAmbiguous = $false
                },
                [PSCustomObject]@{
                    FilePath = "sample.txt"
                    ExpectedFormat = "TEXT"
                    DetectedFormat = "TEXT"
                    ConfidenceScore = 85
                    IsCorrect = $true
                    IsAmbiguous = $true
                },
                [PSCustomObject]@{
                    FilePath = "sample_error.json"
                    ExpectedFormat = "JSON"
                    DetectedFormat = "TEXT"
                    ConfidenceScore = 60
                    IsCorrect = $false
                    IsAmbiguous = $true
                }
            )
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $measureAccuracyScript
                $metrics = Get-DetectionMetrics -Results $testResults
                return $metrics
            }
            
            # Vérifier que les métriques ont été calculées correctement
            $metrics = & $scriptBlock
            $metrics | Should -Not -BeNullOrEmpty
            $metrics.TotalFiles | Should -Be 4
            $metrics.CorrectDetections | Should -Be 3
            $metrics.Accuracy | Should -Be 75
            $metrics.AmbiguousCases | Should -Be 2
            $metrics.ResolvedAmbiguousCases | Should -Be 1
            $metrics.AmbiguousResolutionRate | Should -Be 50
        }
        
        It "La fonction Export-ResultsToJson exporte correctement les résultats" {
            # Créer des résultats et métriques de test
            $testResults = @(
                [PSCustomObject]@{
                    FilePath = "sample.json"
                    ExpectedFormat = "JSON"
                    DetectedFormat = "JSON"
                    ConfidenceScore = 95
                    IsCorrect = $true
                    IsAmbiguous = $false
                }
            )
            
            $testMetrics = @{
                TotalFiles = 1
                CorrectDetections = 1
                Accuracy = 100
                AmbiguousCases = 0
                ResolvedAmbiguousCases = 0
                AmbiguousResolutionRate = 0
                GlobalPrecision = 100
                GlobalRecall = 100
                GlobalF1Score = 100
                FormatMetrics = @{}
                FormatCounts = @{}
            }
            
            # Créer un chemin de sortie
            $outputPath = Join-Path -Path $testTempDir -ChildPath "test_results.json"
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $measureAccuracyScript
                Export-ResultsToJson -Metrics $testMetrics -DetailedResults $testResults -OutputPath $outputPath
            }
            
            # Vérifier que les résultats ont été exportés correctement
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            
            $exportedContent = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent.Metrics.TotalFiles | Should -Be 1
            $exportedContent.Metrics.Accuracy | Should -Be 100
            $exportedContent.DetailedResults.Count | Should -Be 1
            $exportedContent.DetailedResults[0].FilePath | Should -Be "sample.json"
        }
    }
    
    Context "Exécution du script complet" {
        It "Le script s'exécute sans erreur avec les paramètres par défaut" {
            # Exécuter le script avec des paramètres minimaux
            $scriptBlock = {
                & $measureAccuracyScript -TestDirectory $testSamplesDir -ExpectedFormatsPath $expectedFormatsPath -OutputDirectory $testReportsDir
            }
            
            # Vérifier que le script s'exécute sans erreur
            $scriptBlock | Should -Not -Throw
        }
        
        It "Le script génère un rapport JSON" {
            # Exécuter le script
            & $measureAccuracyScript -TestDirectory $testSamplesDir -ExpectedFormatsPath $expectedFormatsPath -OutputDirectory $testReportsDir
            
            # Vérifier que le rapport JSON a été créé
            $jsonReportPath = Join-Path -Path $testReportsDir -ChildPath "DetectionAccuracy.json"
            Test-Path -Path $jsonReportPath -PathType Leaf | Should -Be $true
            
            $reportContent = Get-Content -Path $jsonReportPath -Raw | ConvertFrom-Json
            $reportContent | Should -Not -BeNullOrEmpty
            $reportContent.Metrics | Should -Not -BeNullOrEmpty
            $reportContent.DetailedResults | Should -Not -BeNullOrEmpty
        }
        
        It "Le script génère un rapport HTML lorsque demandé" {
            # Exécuter le script avec l'option de rapport HTML
            & $measureAccuracyScript -TestDirectory $testSamplesDir -ExpectedFormatsPath $expectedFormatsPath -OutputDirectory $testReportsDir -GenerateHtmlReport
            
            # Vérifier que le rapport HTML a été créé
            $htmlReportPath = Join-Path -Path $testReportsDir -ChildPath "DetectionAccuracy.html"
            Test-Path -Path $htmlReportPath -PathType Leaf | Should -Be $true
            
            $htmlContent = Get-Content -Path $htmlReportPath -Raw
            $htmlContent | Should -Not -BeNullOrEmpty
            $htmlContent | Should -Match "<html"
            $htmlContent | Should -Match "</html>"
            $htmlContent | Should -Match "Rapport de précision de détection de format"
        }
    }
}

# Nettoyer après les tests
AfterAll {
    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
}
