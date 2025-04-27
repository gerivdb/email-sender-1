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
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script Ã  tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-AllPerformanceTests.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Invoke-AllPerformanceTests.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Invoke-AllPerformanceTests Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRAllPerformanceTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un rÃ©pertoire de sortie
        $script:outputDir = Join-Path -Path $script:testDir -ChildPath "performance_results"
        New-Item -Path $script:outputDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un mock pour les scripts de test de performance
        Mock Invoke-Expression { } -ModuleName $scriptToTest

        # CrÃ©er un mock pour les scripts de test de performance
        $benchmarkScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"
        $loadTestScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PRLoadTest.ps1"
        $comparisonScript = Join-Path -Path $PSScriptRoot -ChildPath "..\Compare-PRPerformanceResults.ps1"

        Mock Test-Path { return $true } -ModuleName $scriptToTest -ParameterFilter { $Path -eq $benchmarkScript -or $Path -eq $loadTestScript -or $Path -eq $comparisonScript }

        # CrÃ©er des mocks pour les appels de scripts
        Mock Invoke-Expression { return "Benchmark results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Invoke-PRPerformanceBenchmark.ps1*" }
        Mock Invoke-Expression { return "Load test results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Start-PRLoadTest.ps1*" }
        Mock Invoke-Expression { return "Comparison results" } -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Compare-PRPerformanceResults.ps1*" }
    }

    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre OutputDir" {
            { . $scriptToTest -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre DataSize" {
            { . $scriptToTest -DataSize "Small" -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre Iterations" {
            { . $scriptToTest -Iterations 3 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre Duration" {
            { . $scriptToTest -Duration 10 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre Concurrency" {
            { . $scriptToTest -Concurrency 2 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre GenerateReport" {
            { . $scriptToTest -GenerateReport -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
    }

    Context "ExÃ©cution des tests de performance" {
        It "ExÃ©cute tous les tests de performance" {
            # CrÃ©er un mock pour le fichier de rÃ©sumÃ©
            $summaryContent = @"
# RÃ©sumÃ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des donnÃ©es: Small
- ItÃ©rations de benchmark: 1
- DurÃ©e des tests de charge: 1 secondes
- Concurrence des tests de charge: 1

## Fichiers gÃ©nÃ©rÃ©s

- [RÃ©sultats de benchmark](benchmark_results.json)
- [RÃ©sultats de test de charge](load_test_results.json)
"@

            # CrÃ©er un mock pour Get-Content
            Mock Get-Content { return $summaryContent } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Get-ChildItem
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name     = "performance_summary_test.md"
                        FullName = Join-Path -Path $script:outputDir -ChildPath "performance_summary_test.md"
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Filter -eq "performance_summary_*.md" }

            # ExÃ©cuter le script
            . $scriptToTest -OutputDir $script:outputDir -DataSize "Small" -Iterations 1 -Duration 1 -Concurrency 1 -WhatIf

            # VÃ©rifier que les mocks ont Ã©tÃ© appelÃ©s
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Invoke-PRPerformanceBenchmark.ps1*" }
            Should -Invoke Invoke-Expression -ModuleName $scriptToTest -ParameterFilter { $Command -like "*Start-PRLoadTest.ps1*" }
        }

        It "GÃ©nÃ¨re un rapport de comparaison si demandÃ©" {
            # CrÃ©er un mock pour le fichier de rÃ©sumÃ©
            $summaryContent = @"
# RÃ©sumÃ© des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Taille des donnÃ©es: Small
- ItÃ©rations de benchmark: 1
- DurÃ©e des tests de charge: 1 secondes
- Concurrence des tests de charge: 1

## Fichiers gÃ©nÃ©rÃ©s

- [RÃ©sultats de benchmark](benchmark_results.json)
- [RÃ©sultats de test de charge](load_test_results.json)
- [Rapport de comparaison](performance_comparison.html)
"@

            # CrÃ©er un mock pour Get-Content
            Mock Get-Content { return $summaryContent } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Get-ChildItem pour les fichiers de rÃ©sumÃ©
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name     = "performance_summary_test.md"
                        FullName = Join-Path -Path $script:outputDir -ChildPath "performance_summary_test.md"
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Filter -eq "performance_summary_*.md" }

            # CrÃ©er un mock pour Get-ChildItem pour les fichiers de benchmark
            Mock Get-ChildItem {
                return @(
                    [PSCustomObject]@{
                        Name          = "benchmark_results_previous.json"
                        FullName      = Join-Path -Path $script:outputDir -ChildPath "benchmark_results_previous.json"
                        LastWriteTime = (Get-Date).AddDays(-1)
                    }
                )
            } -ModuleName $scriptToTest -ParameterFilter { $Path -eq $script:outputDir -and $Filter -eq "benchmark_results_*.json" }

            # ExÃ©cuter le script avec l'option GenerateReport
            . $scriptToTest -OutputDir $script:outputDir -DataSize "Small" -Iterations 1 -Duration 1 -Concurrency 1 -GenerateReport -WhatIf

            # VÃ©rifier que les mocks ont Ã©tÃ© appelÃ©s
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
