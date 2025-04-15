#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Invoke-AllPerformanceTests.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Invoke-AllPerformanceTests.ps1
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

# Chemin du script à tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-AllPerformanceTests.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Invoke-AllPerformanceTests.ps1 non trouvé à l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Invoke-AllPerformanceTests Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRAllPerformanceTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # Créer un répertoire de sortie
        $script:outputDir = Join-Path -Path $script:testDir -ChildPath "performance_results"
        New-Item -Path $script:outputDir -ItemType Directory -Force | Out-Null

        # Créer un mock pour les scripts de test de performance
        Mock Invoke-Expression { } -ModuleName $scriptToTest

        # Créer un mock pour les scripts de test de performance
        $benchmarkScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"
        $loadTestScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PRLoadTest.ps1"
        $comparisonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Compare-PRPerformanceResults.ps1"

        Mock Test-Path { return $true } -ModuleName $scriptToTest -ParameterFilter { $Path -eq $benchmarkScript -or $Path -eq $loadTestScript -or $Path -eq $comparisonScript }

        # Créer des mocks pour les appels de scripts
        Mock Invoke-Expression { return "Benchmark results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Invoke-PRPerformanceBenchmark.ps1*" }
        Mock Invoke-Expression { return "Load test results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Start-PRLoadTest.ps1*" }
        Mock Invoke-Expression { return "Comparison results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Compare-PRPerformanceResults.ps1*" }
    }

    Context "Validation des paramètres" {
        It "Accepte le paramètre OutputDir" {
            { . $scriptToTest -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre DataSize" {
            { . $scriptToTest -DataSize "Small" -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre Iterations" {
            { . $scriptToTest -Iterations 3 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre Duration" {
            { . $scriptToTest -Duration 10 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre Concurrency" {
            { . $scriptToTest -Concurrency 2 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre GenerateReport" {
            { . $scriptToTest -GenerateReport -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
    }

    Context "Exécution des tests de performance" {
        It "Exécute tous les tests de performance" {
            # Créer un mock pour le fichier de résumé
            $summaryContent = @"
# Résumé des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des données: Small
- Itérations de benchmark: 1
- Durée des tests de charge: 1 secondes
- Concurrence des tests de charge: 1

## Fichiers générés

- [Résultats de benchmark](benchmark_results.json)
- [Résultats de test de charge](load_test_results.json)
"@

            # Créer un mock pour Get-Content
            Mock Get-Content { return $summaryContent } -ModuleName $scriptToTest

            # Créer un mock pour Get-ChildItem
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name     = "performance_summary_test.md"
                        FullName = Join-Path -Path $script:outputDir -ChildPath "performance_summary_test.md"
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Filter -eq "performance_summary_*.md" }

            # Exécuter le script
            . $scriptToTest -OutputDir $script:outputDir -DataSize "Small" -Iterations 1 -Duration 1 -Concurrency 1 -WhatIf

            # Vérifier que les mocks ont été appelés
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Invoke-PRPerformanceBenchmark.ps1*" }
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Start-PRLoadTest.ps1*" }
        }

        It "Génère un rapport de comparaison si demandé" {
            # Créer un mock pour le fichier de résumé
            $summaryContent = @"
# Résumé des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des données: Small
- Itérations de benchmark: 1
- Durée des tests de charge: 1 secondes
- Concurrence des tests de charge: 1

## Fichiers générés

- [Résultats de benchmark](benchmark_results.json)
- [Résultats de test de charge](load_test_results.json)
- [Rapport de comparaison](performance_comparison.html)
"@

            # Créer un mock pour Get-Content
            Mock Get-Content { return $summaryContent } -ModuleName $scriptToTest

            # Créer un mock pour Get-ChildItem pour les fichiers de résumé
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name     = "performance_summary_test.md"
                        FullName = Join-Path -Path $script:outputDir -ChildPath "performance_summary_test.md"
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Filter -eq "performance_summary_*.md" }

            # Créer un mock pour Get-ChildItem pour les fichiers de benchmark
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name          = "benchmark_results_previous.json"
                        FullName      = Join-Path -Path $script:outputDir -ChildPath "benchmark_results_previous.json"
                        LastWriteTime = (Get-Date).AddDays(-1)
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Path -eq $script:outputDir -and $Filter -eq "benchmark_results_*.json" }

            # Exécuter le script avec l'option GenerateReport
            . $scriptToTest -OutputDir $script:outputDir -DataSize "Small" -Iterations 1 -Duration 1 -Concurrency 1 -GenerateReport -WhatIf

            # Vérifier que les mocks ont été appelés
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Invoke-PRPerformanceBenchmark.ps1*" }
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Start-PRLoadTest.ps1*" }
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Compare-PRPerformanceResults.ps1*" }
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
