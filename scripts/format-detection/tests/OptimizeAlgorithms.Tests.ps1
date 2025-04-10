#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script d'optimisation des algorithmes de détection.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement du script
    d'optimisation des algorithmes de détection. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\OptimizeAlgorithms.Tests.ps1
    Exécute les tests unitaires pour le script d'optimisation des algorithmes de détection.

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
$optimizeAlgorithmsScript = "$PSScriptRoot\Optimize-DetectionAlgorithms.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $optimizeAlgorithmsScript)) {
    Write-Error "Le script '$optimizeAlgorithmsScript' est manquant."
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "OptimizeAlgorithmsTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

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

# Créer un rapport de précision de test
$accuracyReportContent = @"
{
    "Metrics": {
        "TotalFiles": 10,
        "CorrectDetections": 8,
        "AmbiguousCases": 3,
        "ResolvedAmbiguousCases": 2,
        "Accuracy": 80,
        "AmbiguousResolutionRate": 66.67,
        "FormatMetrics": {
            "JSON": {
                "TruePositives": 3,
                "FalseNegatives": 1,
                "FalsePositives": 0,
                "Precision": 100,
                "Recall": 75,
                "F1Score": 85.71
            },
            "XML": {
                "TruePositives": 2,
                "FalseNegatives": 0,
                "FalsePositives": 1,
                "Precision": 66.67,
                "Recall": 100,
                "F1Score": 80
            },
            "TEXT": {
                "TruePositives": 3,
                "FalseNegatives": 1,
                "FalsePositives": 1,
                "Precision": 75,
                "Recall": 75,
                "F1Score": 75
            }
        },
        "FormatCounts": {
            "JSON": 4,
            "XML": 2,
            "TEXT": 4
        },
        "GlobalPrecision": 80,
        "GlobalRecall": 80,
        "GlobalF1Score": 80
    },
    "DetailedResults": [
        {
            "FilePath": "sample.json",
            "ExpectedFormat": "JSON",
            "DetectedFormat": "JSON",
            "ConfidenceScore": 95,
            "IsCorrect": true,
            "IsAmbiguous": false
        },
        {
            "FilePath": "sample.xml",
            "ExpectedFormat": "XML",
            "DetectedFormat": "XML",
            "ConfidenceScore": 90,
            "IsCorrect": true,
            "IsAmbiguous": false
        },
        {
            "FilePath": "sample.txt",
            "ExpectedFormat": "TEXT",
            "DetectedFormat": "TEXT",
            "ConfidenceScore": 85,
            "IsCorrect": true,
            "IsAmbiguous": true
        },
        {
            "FilePath": "sample_truncated_50.json",
            "ExpectedFormat": "JSON",
            "DetectedFormat": "TEXT",
            "ConfidenceScore": 60,
            "IsCorrect": false,
            "IsAmbiguous": true
        },
        {
            "FilePath": "sample_corrupted_10.xml",
            "ExpectedFormat": "XML",
            "DetectedFormat": "XML",
            "ConfidenceScore": 70,
            "IsCorrect": true,
            "IsAmbiguous": true
        },
        {
            "FilePath": "sample_incorrect_header.json",
            "ExpectedFormat": "JSON",
            "DetectedFormat": "JSON",
            "ConfidenceScore": 80,
            "IsCorrect": true,
            "IsAmbiguous": false
        },
        {
            "FilePath": "sample_incorrect_extension.txt",
            "ExpectedFormat": "TEXT",
            "DetectedFormat": "TEXT",
            "ConfidenceScore": 75,
            "IsCorrect": true,
            "IsAmbiguous": false
        },
        {
            "FilePath": "json_txt_hybrid.txt",
            "ExpectedFormat": "JSON",
            "DetectedFormat": "JSON",
            "ConfidenceScore": 65,
            "IsCorrect": true,
            "IsAmbiguous": false
        },
        {
            "FilePath": "xml_html_hybrid.txt",
            "ExpectedFormat": "XML",
            "DetectedFormat": "JSON",
            "ConfidenceScore": 55,
            "IsCorrect": false,
            "IsAmbiguous": true
        },
        {
            "FilePath": "sample_corrupted_20.txt",
            "ExpectedFormat": "TEXT",
            "DetectedFormat": "XML",
            "ConfidenceScore": 50,
            "IsCorrect": false,
            "IsAmbiguous": true
        }
    ]
}
"@

$accuracyReportPath = New-TestFile -FileName "DetectionAccuracy.json" -Content $accuracyReportContent -Directory $testTempDir

# Créer un fichier de critères de détection de test
$criteriaContent = @"
{
    "JSON": {
        "Extensions": [".json"],
        "HeaderPatterns": ["^\\s*\\{"],
        "ContentPatterns": ["\"\\w+\"\\s*:", "\\{\\s*\"\\w+\""],
        "StructurePatterns": ["\\{.*\\}"],
        "BinarySignatures": [],
        "MinimumSize": 2,
        "RequireHeader": false,
        "RequiredPatternCount": 1,
        "ExtensionWeight": 30,
        "HeaderWeight": 25,
        "ContentWeight": 30,
        "StructureWeight": 15,
        "Priority": 10
    },
    "XML": {
        "Extensions": [".xml", ".svg", ".xhtml"],
        "HeaderPatterns": ["^\\s*<\\?xml", "^\\s*<!DOCTYPE"],
        "ContentPatterns": ["<\\w+[^>]*>", "</\\w+>"],
        "StructurePatterns": ["<[^>]+>[^<]*</[^>]+>"],
        "BinarySignatures": [],
        "MinimumSize": 5,
        "RequireHeader": false,
        "RequiredPatternCount": 1,
        "ExtensionWeight": 30,
        "HeaderWeight": 25,
        "ContentWeight": 30,
        "StructureWeight": 15,
        "Priority": 10
    },
    "TEXT": {
        "Extensions": [".txt", ".text", ".log"],
        "HeaderPatterns": [],
        "ContentPatterns": ["^[\\w\\s\\p{P}]+$", "^[\\r\\n\\t\\w\\s\\p{P}]+$"],
        "StructurePatterns": [],
        "BinarySignatures": [],
        "MinimumSize": 1,
        "RequireHeader": false,
        "RequiredPatternCount": 1,
        "ExtensionWeight": 20,
        "HeaderWeight": 0,
        "ContentWeight": 70,
        "StructureWeight": 10,
        "Priority": 5
    }
}
"@

$criteriaPath = New-TestFile -FileName "FormatDetectionCriteria.json" -Content $criteriaContent -Directory $testTempDir

# Créer un répertoire pour les rapports
$testReportsDir = Join-Path -Path $testTempDir -ChildPath "reports"
New-Item -Path $testReportsDir -ItemType Directory -Force | Out-Null

# Tests Pester
Describe "Script d'optimisation des algorithmes de détection" {
    Context "Fonctions internes" {
        It "La fonction New-DirectoryIfNotExists crée un répertoire s'il n'existe pas" {
            # Créer un chemin de test
            $testPath = Join-Path -Path $testTempDir -ChildPath "test_directory"
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                New-DirectoryIfNotExists -Path $testPath
            }
            
            # Vérifier que le répertoire a été créé
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $testPath -PathType Container | Should -Be $true
        }
        
        It "La fonction Get-AccuracyReport charge correctement le rapport de précision" {
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                $report = Get-AccuracyReport -Path $accuracyReportPath
                return $report
            }
            
            # Vérifier que le rapport a été chargé correctement
            $report = & $scriptBlock
            $report | Should -Not -BeNullOrEmpty
            $report.Metrics | Should -Not -BeNullOrEmpty
            $report.DetailedResults | Should -Not -BeNullOrEmpty
            $report.Metrics.TotalFiles | Should -Be 10
            $report.DetailedResults.Count | Should -Be 10
        }
        
        It "La fonction Get-DetectionCriteria charge correctement les critères de détection" {
            # Exécuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                $criteria = Get-DetectionCriteria -Path $criteriaPath
                return $criteria
            }
            
            # Vérifier que les critères ont été chargés correctement
            $criteria = & $scriptBlock
            $criteria | Should -Not -BeNullOrEmpty
            $criteria.JSON | Should -Not -BeNullOrEmpty
            $criteria.XML | Should -Not -BeNullOrEmpty
            $criteria.TEXT | Should -Not -BeNullOrEmpty
            $criteria.JSON.Extensions | Should -Contain ".json"
            $criteria.XML.Extensions | Should -Contain ".xml"
            $criteria.TEXT.Extensions | Should -Contain ".txt"
        }
        
        It "La fonction Get-ProblematicCases identifie correctement les cas problématiques" {
            # Charger le rapport
            $report = Get-Content -Path $accuracyReportPath -Raw | ConvertFrom-Json
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                param($report)
                . $optimizeAlgorithmsScript
                $cases = Get-ProblematicCases -Report $report
                return $cases
            }
            
            # Vérifier que les cas problématiques ont été identifiés correctement
            $cases = & $scriptBlock -report $report
            $cases | Should -Not -BeNullOrEmpty
            $cases.Count | Should -Be 2
            $cases | Where-Object { $_.FilePath -eq "sample_truncated_50.json" } | Should -Not -BeNullOrEmpty
            $cases | Where-Object { $_.FilePath -eq "xml_html_hybrid.txt" } | Should -Not -BeNullOrEmpty
            $cases | Where-Object { $_.FilePath -eq "sample_corrupted_20.txt" } | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Get-CaseAnalysis analyse correctement les cas problématiques" {
            # Charger le rapport et les critères
            $report = Get-Content -Path $accuracyReportPath -Raw | ConvertFrom-Json
            $criteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
            
            # Obtenir les cas problématiques
            $problematicCases = $report.DetailedResults | Where-Object { -not $_.IsCorrect }
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                param($cases, $criteria)
                . $optimizeAlgorithmsScript
                $analysis = Get-CaseAnalysis -ProblematicCases $cases -Criteria $criteria
                return $analysis
            }
            
            # Vérifier que l'analyse a été effectuée correctement
            $analysis = & $scriptBlock -cases $problematicCases -criteria $criteria
            $analysis | Should -Not -BeNullOrEmpty
            $analysis.Keys | Should -Contain "JSON"
            $analysis.Keys | Should -Contain "TEXT"
            $analysis["JSON"].MisclassifiedAs | Should -Not -BeNullOrEmpty
            $analysis["JSON"].TotalMisclassifications | Should -BeGreaterThan 0
            $analysis["JSON"].CommonPatterns | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Optimize-Criteria optimise correctement les critères de détection" {
            # Charger les critères
            $criteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
            
            # Créer une analyse de test
            $analysis = @{
                "JSON" = @{
                    MisclassifiedAs = @{
                        "TEXT" = 1
                    }
                    TotalMisclassifications = 1
                    CommonPatterns = @{
                        "truncated" = 1
                    }
                }
                "TEXT" = @{
                    MisclassifiedAs = @{
                        "XML" = 1
                    }
                    TotalMisclassifications = 1
                    CommonPatterns = @{
                        "corrupted" = 1
                    }
                }
            }
            
            # Exécuter la fonction via le script
            $scriptBlock = {
                param($criteria, $analysis)
                . $optimizeAlgorithmsScript
                $result = Optimize-Criteria -Criteria $criteria -Analysis $analysis
                return $result
            }
            
            # Vérifier que les critères ont été optimisés correctement
            $result = & $scriptBlock -criteria $criteria -analysis $analysis
            $result | Should -Not -BeNullOrEmpty
            $result.OptimizedCriteria | Should -Not -BeNullOrEmpty
            $result.OptimizationLog | Should -Not -BeNullOrEmpty
            $result.OptimizationLog.Count | Should -BeGreaterThan 0
            
            # Vérifier que les critères ont été modifiés
            $originalJsonMinSize = $criteria.JSON.MinimumSize
            $optimizedJsonMinSize = $result.OptimizedCriteria.JSON.MinimumSize
            $optimizedJsonMinSize | Should -Not -Be $originalJsonMinSize
        }
    }
    
    Context "Exécution du script complet" {
        It "Le script s'exécute sans erreur avec les paramètres par défaut" {
            # Créer un chemin de sortie pour les critères optimisés
            $outputCriteriaPath = Join-Path -Path $testTempDir -ChildPath "OptimizedCriteria.json"
            
            # Exécuter le script avec des paramètres minimaux
            $scriptBlock = {
                & $optimizeAlgorithmsScript -AccuracyReportPath $accuracyReportPath -CriteriaPath $criteriaPath -OutputCriteriaPath $outputCriteriaPath
            }
            
            # Vérifier que le script s'exécute sans erreur
            $scriptBlock | Should -Not -Throw
            
            # Vérifier que le fichier de critères optimisés a été créé
            Test-Path -Path $outputCriteriaPath -PathType Leaf | Should -Be $true
            
            $optimizedCriteria = Get-Content -Path $outputCriteriaPath -Raw | ConvertFrom-Json
            $optimizedCriteria | Should -Not -BeNullOrEmpty
            $optimizedCriteria.JSON | Should -Not -BeNullOrEmpty
            $optimizedCriteria.XML | Should -Not -BeNullOrEmpty
            $optimizedCriteria.TEXT | Should -Not -BeNullOrEmpty
        }
        
        It "Le script génère un rapport HTML lorsque demandé" {
            # Créer un chemin de sortie pour les critères optimisés
            $outputCriteriaPath = Join-Path -Path $testTempDir -ChildPath "OptimizedCriteria2.json"
            $reportPath = Join-Path -Path $testReportsDir -ChildPath "OptimizationReport.html"
            
            # Exécuter le script avec l'option de rapport HTML
            & $optimizeAlgorithmsScript -AccuracyReportPath $accuracyReportPath -CriteriaPath $criteriaPath -OutputCriteriaPath $outputCriteriaPath -GenerateReport -ReportPath $reportPath
            
            # Vérifier que le rapport HTML a été créé
            Test-Path -Path $reportPath -PathType Leaf | Should -Be $true
            
            $htmlContent = Get-Content -Path $reportPath -Raw
            $htmlContent | Should -Not -BeNullOrEmpty
            $htmlContent | Should -Match "<html"
            $htmlContent | Should -Match "</html>"
            $htmlContent | Should -Match "Rapport d'optimisation des algorithmes de détection"
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
