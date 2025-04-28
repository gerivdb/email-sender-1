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
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script Ã  tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Compare-PRPerformanceResults.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Compare-PRPerformanceResults.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Compare-PRPerformanceResults Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceComparisonTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er des fichiers de rÃ©sultats de test
        $script:result1Path = Join-Path -Path $script:testDir -ChildPath "result1.json"
        $script:result2Path = Join-Path -Path $script:testDir -ChildPath "result2.json"
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "comparison_results.html"

        # CrÃ©er des donnÃ©es de test pour les rÃ©sultats 1
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

        # CrÃ©er des donnÃ©es de test pour les rÃ©sultats 2
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

        # Enregistrer les fichiers de rÃ©sultats
        $result1 | ConvertTo-Json -Depth 10 | Set-Content -Path $script:result1Path -Encoding UTF8
        $result2 | ConvertTo-Json -Depth 10 | Set-Content -Path $script:result2Path -Encoding UTF8

        # CrÃ©er un mock pour les modules
        Mock Import-Module { } -ModuleName $scriptToTest

        # CrÃ©er un mock pour les fonctions de visualisation
        Mock New-PRBarChart { return "<div class='pr-bar-chart'>Bar Chart</div>" } -ModuleName $scriptToTest
        Mock New-PRPieChart { return "<div class='pr-pie-chart'>Pie Chart</div>" } -ModuleName $scriptToTest
        Mock New-PRLineChart { return "<div class='pr-line-chart'>Line Chart</div>" } -ModuleName $scriptToTest

        # CrÃ©er un mock pour les fonctions de rapport
        Mock Register-PRReportTemplate { } -ModuleName $scriptToTest
        Mock New-PRReport { return "HTML Report" } -ModuleName $scriptToTest
    }

    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre ResultsPath" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre Labels" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre OutputPath" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre IncludeRawData" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -IncludeRawData -WhatIf } | Should -Not -Throw
        }

        It "VÃ©rifie que ResultsPath et Labels ont la mÃªme longueur" {
            { . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1") -OutputPath $script:outputPath } | Should -Throw
        }
    }

    Context "Chargement des rÃ©sultats" {
        It "Charge correctement les rÃ©sultats" {
            # ExÃ©cuter le script
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf

            # VÃ©rifier que les fonctions de visualisation ont Ã©tÃ© appelÃ©es
            Should -Invoke New-PRBarChart -ModuleName $scriptToTest

            # VÃ©rifier que les fonctions de rapport ont Ã©tÃ© appelÃ©es
            Should -Invoke Register-PRReportTemplate -ModuleName $scriptToTest
            Should -Invoke New-PRReport -ModuleName $scriptToTest
        }
    }

    Context "Comparaison des rÃ©sultats" {
        It "Compare correctement les rÃ©sultats" {
            # ExÃ©cuter le script
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -WhatIf

            # VÃ©rifier que les fonctions de visualisation ont Ã©tÃ© appelÃ©es
            Should -Invoke New-PRBarChart -ModuleName $scriptToTest -Times 2
        }

        It "Inclut les donnÃ©es brutes si demandÃ©" {
            # ExÃ©cuter le script avec l'option IncludeRawData
            . $scriptToTest -ResultsPath @($script:result1Path, $script:result2Path) -Labels @("Result1", "Result2") -OutputPath $script:outputPath -IncludeRawData -WhatIf

            # VÃ©rifier que les fonctions de rapport ont Ã©tÃ© appelÃ©es avec les donnÃ©es brutes
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
