#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Compare-PRPerformanceResults.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Compare-PRPerformanceResults.ps1
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Compare-PRPerformanceResults.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Compare-PRPerformanceResults.ps1 non trouvé à l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Compare-PRPerformanceResults Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceComparisonTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # Créer des fichiers de résultats de test
        $script:result1Path = Join-Path -Path $script:testDir -ChildPath "result1.json"
        $script:result2Path = Join-Path -Path $script:testDir -ChildPath "result2.json"
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "comparison_results.html"

        # Créer des données de test pour les résultats 1
        $result1 = @{
            Timestamp  = "2025-04-28 10:00:00"
            DataSize   = "Medium"
            Iterations = 5
            System     = @{
                PSVersion      = "5.1.19041.3031"
                OS             = "Microsoft Windows 10.0.19045"
                ProcessorCount = 8
            }
            Results    = @(
                @{
                    ModuleName   = "PRVisualization"
                    FunctionName = "New-PRBarChart"
                    Iterations   = 5
                    TotalMs      = 500
                    AverageMs    = 100
                    MinMs        = 90
                    MaxMs        = 110
                },
                @{
                    ModuleName   = "PRVisualization"
                    FunctionName = "New-PRPieChart"
                    Iterations   = 5
                    TotalMs      = 600
                    AverageMs    = 120
                    MinMs        = 110
                    MaxMs        = 130
                }
            )
        }

        # Créer des données de test pour les résultats 2
        $result2 = @{
            Timestamp  = "2025-04-29 10:00:00"
            DataSize   = "Medium"
            Iterations = 5
            System     = @{
                PSVersion      = "5.1.19041.3031"
                OS             = "Microsoft Windows 10.0.19045"
                ProcessorCount = 8
            }
            Results    = @(
                @{
                    ModuleName   = "PRVisualization"
                    FunctionName = "New-PRBarChart"
                    Iterations   = 5
                    TotalMs      = 550
                    AverageMs    = 110
                    MinMs        = 100
                    MaxMs        = 120
                },
                @{
                    ModuleName   = "PRVisualization"
                    FunctionName = "New-PRPieChart"
                    Iterations   = 5
                    TotalMs      = 540
                    AverageMs    = 108
                    MinMs        = 100
                    MaxMs        = 120
                }
            )
        }

        # Enregistrer les fichiers de résultats
        $result1 | ConvertTo-Json -Depth 10 | Set-Content -Path $script:result1Path -Encoding UTF8
        $result2 | ConvertTo-Json -Depth 10 | Set-Content -Path $script:result2Path -Encoding UTF8

        # Créer un mock pour les modules
        Mock Import-Module { } -ModuleName $scriptToTest

        # Créer un mock pour les fonctions de visualisation
        Mock New-PRBarChart { return "<div class='pr-bar-chart'>Bar Chart</div>" } -ModuleName $scriptToTest
        Mock New-PRPieChart { return "<div class='pr-pie-chart'>Pie Chart</div>" } -ModuleName $scriptToTest
        Mock New-PRLineChart { return "<div class='pr-line-chart'>Line Chart</div>" } -ModuleName $scriptToTest

        # Créer un mock pour les fonctions de rapport
        Mock Register-PRReportTemplate { } -ModuleName $scriptToTest
        Mock New-PRReport { return "HTML Report" } -ModuleName $scriptToTest
    }

    Context "Validation des paramètres" {
        It "Accepte le paramètre ResultsPath" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre Labels" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre OutputPath" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramètre IncludeRawData" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -IncludeRawData -WhatIf } | Should -Not -Throw
        }

        It "Vérifie que ResultsPath et Labels ont la même longueur" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1") -OutputPath $script:outputPath } | Should -Throw
        }
    }

    Context "Chargement des résultats" {
        It "Charge correctement les résultats" {
            # Exécuter le script
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf

            # Vérifier que les fonctions de visualisation ont été appelées
            Should -Invoke New-PRBarChart -ModuleName $scriptToTest

            # Vérifier que les fonctions de rapport ont été appelées
            Should -Invoke Register-PRReportTemplate -ModuleName $scriptToTest
            Should -Invoke New-PRReport -ModuleName $scriptToTest
        }
    }

    Context "Comparaison des résultats" {
        It "Compare correctement les résultats" {
            # Exécuter le script
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf

            # Vérifier que les fonctions de visualisation ont été appelées
            Should -Invoke New-PRBarChart -ModuleName $scriptToTest -Times 2
        }

        It "Inclut les données brutes si demandé" {
            # Exécuter le script avec l'option IncludeRawData
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -IncludeRawData -WhatIf

            # Vérifier que les fonctions de rapport ont été appelées avec les données brutes
            Should -Invoke New-PRReport -ModuleName $scriptToTest -ParameterFilter { $Data.IncludeRawData -eq $true }
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
