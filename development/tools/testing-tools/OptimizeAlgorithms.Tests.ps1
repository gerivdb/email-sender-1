#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script d'optimisation des algorithmes de dÃ©tection.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement du script
    d'optimisation des algorithmes de dÃ©tection. Il utilise le framework Pester pour exÃ©cuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\OptimizeAlgorithms.Tests.ps1
    ExÃ©cute les tests unitaires pour le script d'optimisation des algorithmes de dÃ©tection.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Chemins des scripts Ã  tester
$scriptRoot = Split-Path -Parent $PSScriptRoot
$optimizeAlgorithmsScript = "$PSScriptRoot\Optimize-DetectionAlgorithms.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $optimizeAlgorithmsScript)) {
    Write-Error "Le script '$optimizeAlgorithmsScript' est manquant."
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "OptimizeAlgorithmsTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
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

# CrÃ©er un rapport de prÃ©cision de test
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

# CrÃ©er un fichier de critÃ¨res de dÃ©tection de test
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

# CrÃ©er un rÃ©pertoire pour les rapports
$testReportsDir = Join-Path -Path $testTempDir -ChildPath "reports"
New-Item -Path $testReportsDir -ItemType Directory -Force | Out-Null

# Tests Pester
Describe "Script d'optimisation des algorithmes de dÃ©tection" {
    Context "Fonctions internes" {
        It "La fonction New-DirectoryIfNotExists crÃ©e un rÃ©pertoire s'il n'existe pas" {
            # CrÃ©er un chemin de test
            $testPath = Join-Path -Path $testTempDir -ChildPath "test_directory"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                New-DirectoryIfNotExists -Path $testPath
            }
            
            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $testPath -PathType Container | Should -Be $true
        }
        
        It "La fonction Get-AccuracyReport charge correctement le rapport de prÃ©cision" {
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                $report = Get-AccuracyReport -Path $accuracyReportPath
                return $report
            }
            
            # VÃ©rifier que le rapport a Ã©tÃ© chargÃ© correctement
            $report = & $scriptBlock
            $report | Should -Not -BeNullOrEmpty
            $report.Metrics | Should -Not -BeNullOrEmpty
            $report.DetailedResults | Should -Not -BeNullOrEmpty
            $report.Metrics.TotalFiles | Should -Be 10
            $report.DetailedResults.Count | Should -Be 10
        }
        
        It "La fonction Get-DetectionCriteria charge correctement les critÃ¨res de dÃ©tection" {
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $optimizeAlgorithmsScript
                $criteria = Get-DetectionCriteria -Path $criteriaPath
                return $criteria
            }
            
            # VÃ©rifier que les critÃ¨res ont Ã©tÃ© chargÃ©s correctement
            $criteria = & $scriptBlock
            $criteria | Should -Not -BeNullOrEmpty
            $criteria.JSON | Should -Not -BeNullOrEmpty
            $criteria.XML | Should -Not -BeNullOrEmpty
            $criteria.TEXT | Should -Not -BeNullOrEmpty
            $criteria.JSON.Extensions | Should -Contain ".json"
            $criteria.XML.Extensions | Should -Contain ".xml"
            $criteria.TEXT.Extensions | Should -Contain ".txt"
        }
        
        It "La fonction Get-ProblematicCases identifie correctement les cas problÃ©matiques" {
            # Charger le rapport
            $report = Get-Content -Path $accuracyReportPath -Raw | ConvertFrom-Json
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                param($report)
                . $optimizeAlgorithmsScript
                $cases = Get-ProblematicCases -Report $report
                return $cases
            }
            
            # VÃ©rifier que les cas problÃ©matiques ont Ã©tÃ© identifiÃ©s correctement
            $cases = & $scriptBlock -report $report
            $cases | Should -Not -BeNullOrEmpty
            $cases.Count | Should -Be 2
            $cases | Where-Object { $_.FilePath -eq "sample_truncated_50.json" } | Should -Not -BeNullOrEmpty
            $cases | Where-Object { $_.FilePath -eq "xml_html_hybrid.txt" } | Should -Not -BeNullOrEmpty
            $cases | Where-Object { $_.FilePath -eq "sample_corrupted_20.txt" } | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Get-CaseAnalysis analyse correctement les cas problÃ©matiques" {
            # Charger le rapport et les critÃ¨res
            $report = Get-Content -Path $accuracyReportPath -Raw | ConvertFrom-Json
            $criteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
            
            # Obtenir les cas problÃ©matiques
            $problematicCases = $report.DetailedResults | Where-Object { -not $_.IsCorrect }
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                param($cases, $criteria)
                . $optimizeAlgorithmsScript
                $analysis = Get-CaseAnalysis -ProblematicCases $cases -Criteria $criteria
                return $analysis
            }
            
            # VÃ©rifier que l'analyse a Ã©tÃ© effectuÃ©e correctement
            $analysis = & $scriptBlock -cases $problematicCases -criteria $criteria
            $analysis | Should -Not -BeNullOrEmpty
            $analysis.Keys | Should -Contain "JSON"
            $analysis.Keys | Should -Contain "TEXT"
            $analysis["JSON"].MisclassifiedAs | Should -Not -BeNullOrEmpty
            $analysis["JSON"].TotalMisclassifications | Should -BeGreaterThan 0
            $analysis["JSON"].CommonPatterns | Should -Not -BeNullOrEmpty
        }
        
        It "La fonction Optimize-Criteria optimise correctement les critÃ¨res de dÃ©tection" {
            # Charger les critÃ¨res
            $criteria = Get-Content -Path $criteriaPath -Raw | ConvertFrom-Json
            
            # CrÃ©er une analyse de test
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
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                param($criteria, $analysis)
                . $optimizeAlgorithmsScript
                $result = Optimize-Criteria -Criteria $criteria -Analysis $analysis
                return $result
            }
            
            # VÃ©rifier que les critÃ¨res ont Ã©tÃ© optimisÃ©s correctement
            $result = & $scriptBlock -criteria $criteria -analysis $analysis
            $result | Should -Not -BeNullOrEmpty
            $result.OptimizedCriteria | Should -Not -BeNullOrEmpty
            $result.OptimizationLog | Should -Not -BeNullOrEmpty
            $result.OptimizationLog.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les critÃ¨res ont Ã©tÃ© modifiÃ©s
            $originalJsonMinSize = $criteria.JSON.MinimumSize
            $optimizedJsonMinSize = $result.OptimizedCriteria.JSON.MinimumSize
            $optimizedJsonMinSize | Should -Not -Be $originalJsonMinSize
        }
    }
    
    Context "ExÃ©cution du script complet" {
        It "Le script s'exÃ©cute sans erreur avec les paramÃ¨tres par dÃ©faut" {
            # CrÃ©er un chemin de sortie pour les critÃ¨res optimisÃ©s
            $outputCriteriaPath = Join-Path -Path $testTempDir -ChildPath "OptimizedCriteria.json"
            
            # ExÃ©cuter le script avec des paramÃ¨tres minimaux
            $scriptBlock = {
                & $optimizeAlgorithmsScript -AccuracyReportPath $accuracyReportPath -CriteriaPath $criteriaPath -OutputCriteriaPath $outputCriteriaPath
            }
            
            # VÃ©rifier que le script s'exÃ©cute sans erreur
            $scriptBlock | Should -Not -Throw
            
            # VÃ©rifier que le fichier de critÃ¨res optimisÃ©s a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $outputCriteriaPath -PathType Leaf | Should -Be $true
            
            $optimizedCriteria = Get-Content -Path $outputCriteriaPath -Raw | ConvertFrom-Json
            $optimizedCriteria | Should -Not -BeNullOrEmpty
            $optimizedCriteria.JSON | Should -Not -BeNullOrEmpty
            $optimizedCriteria.XML | Should -Not -BeNullOrEmpty
            $optimizedCriteria.TEXT | Should -Not -BeNullOrEmpty
        }
        
        It "Le script gÃ©nÃ¨re un rapport HTML lorsque demandÃ©" {
            # CrÃ©er un chemin de sortie pour les critÃ¨res optimisÃ©s
            $outputCriteriaPath = Join-Path -Path $testTempDir -ChildPath "OptimizedCriteria2.json"
            $reportPath = Join-Path -Path $testReportsDir -ChildPath "OptimizationReport.html"
            
            # ExÃ©cuter le script avec l'option de rapport HTML
            & $optimizeAlgorithmsScript -AccuracyReportPath $accuracyReportPath -CriteriaPath $criteriaPath -OutputCriteriaPath $outputCriteriaPath -GenerateReport -ReportPath $reportPath
            
            # VÃ©rifier que le rapport HTML a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $reportPath -PathType Leaf | Should -Be $true
            
            $htmlContent = Get-Content -Path $reportPath -Raw
            $htmlContent | Should -Not -BeNullOrEmpty
            $htmlContent | Should -Match "<html"
            $htmlContent | Should -Match "</html>"
            $htmlContent | Should -Match "Rapport d'optimisation des algorithmes de dÃ©tection"
        }
    }
}

# Nettoyer aprÃ¨s les tests
AfterAll {
    # Supprimer le rÃ©pertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
}
