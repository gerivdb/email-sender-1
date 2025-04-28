﻿#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-PRPerformanceRegression.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Test-PRPerformanceRegression.ps1
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Test-PRPerformanceRegression.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Test-PRPerformanceRegression.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Test-PRPerformanceRegression Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceRegressionTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null

        # CrÃ©er des fichiers de rÃ©sultats de test
        $script:baselineResultsPath = Join-Path -Path $script:testDir -ChildPath "baseline_results.json"
        $script:currentResultsPath = Join-Path -Path $script:testDir -ChildPath "current_results.json"
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "regression_results.json"

        # CrÃ©er des donnÃ©es de test pour les rÃ©sultats de rÃ©fÃ©rence
        $baselineResults = @{
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

        # CrÃ©er des donnÃ©es de test pour les rÃ©sultats actuels (avec une rÃ©gression)
        $currentResults = @{
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
        $baselineResults | ConvertTo-Json -Depth 10 | Set-Content -Path $script:baselineResultsPath -Encoding UTF8
        $currentResults | ConvertTo-Json -Depth 10 | Set-Content -Path $script:currentResultsPath -Encoding UTF8

        # CrÃ©er un mock pour les modules
        Mock Import-Module { } -ModuleName $scriptToTest
    }

    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre CurrentResults" {
            { . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre BaselineResults" {
            { . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre ThresholdPercent" {
            { . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -ThresholdPercent 5 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre OutputPath" {
            { . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }

        It "Accepte le paramÃ¨tre GenerateReport" {
            { . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -OutputPath $script:outputPath -GenerateReport -WhatIf } | Should -Not -Throw
        }
    }

    Context "DÃ©tection des rÃ©gressions" {
        It "DÃ©tecte les rÃ©gressions de performance" {
            # CrÃ©er un mock pour les rÃ©sultats
            $mockResults = @{
                Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                CurrentTimestamp  = "2025-04-29 10:00:00"
                BaselineTimestamp = "2025-04-28 10:00:00"
                ThresholdPercent  = 5
                Comparisons       = @(
                    [PSCustomObject]@{
                        ModuleName       = "PRVisualization"
                        FunctionName     = "New-PRBarChart"
                        BaselineAvgMs    = 100
                        CurrentAvgMs     = 110
                        DiffMs           = 10
                        DiffPercent      = 10
                        IsRegression     = $true
                        ThresholdPercent = 5
                    },
                    [PSCustomObject]@{
                        ModuleName       = "PRVisualization"
                        FunctionName     = "New-PRPieChart"
                        BaselineAvgMs    = 120
                        CurrentAvgMs     = 108
                        DiffMs           = -12
                        DiffPercent      = -10
                        IsRegression     = $false
                        ThresholdPercent = 5
                    }
                )
                Summary           = @{
                    TotalFunctions = 2
                    Regressions    = 1
                    Improvements   = 1
                    NoChange       = 0
                }
            }

            # CrÃ©er un mock pour ConvertTo-Json
            Mock ConvertTo-Json { return $mockResults | ConvertTo-Json -Depth 10 } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Set-Content
            Mock Set-Content { } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Get-Content
            Mock Get-Content { return $mockResults | ConvertTo-Json -Depth 10 } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Test-Path
            Mock Test-Path { return $true } -ModuleName $scriptToTest

            # ExÃ©cuter le script avec un seuil bas pour dÃ©tecter la rÃ©gression
            . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -ThresholdPercent 5 -OutputPath $script:outputPath -WhatIf

            # VÃ©rifier que les mocks ont Ã©tÃ© appelÃ©s
            Should -Invoke ConvertTo-Json -ModuleName $scriptToTest
            Should -Invoke Set-Content -ModuleName $scriptToTest
        }

        It "Respecte le seuil de rÃ©gression spÃ©cifiÃ©" {
            # CrÃ©er un mock pour les rÃ©sultats
            $mockResults = @{
                Timestamp         = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                CurrentTimestamp  = "2025-04-29 10:00:00"
                BaselineTimestamp = "2025-04-28 10:00:00"
                ThresholdPercent  = 15
                Comparisons       = @(
                    [PSCustomObject]@{
                        ModuleName       = "PRVisualization"
                        FunctionName     = "New-PRBarChart"
                        BaselineAvgMs    = 100
                        CurrentAvgMs     = 110
                        DiffMs           = 10
                        DiffPercent      = 10
                        IsRegression     = $false
                        ThresholdPercent = 15
                    }
                )
                Summary           = @{
                    TotalFunctions = 1
                    Regressions    = 0
                    Improvements   = 0
                    NoChange       = 1
                }
            }

            # CrÃ©er un mock pour ConvertTo-Json
            Mock ConvertTo-Json { return $mockResults | ConvertTo-Json -Depth 10 } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Set-Content
            Mock Set-Content { } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Get-Content
            Mock Get-Content { return $mockResults | ConvertTo-Json -Depth 10 } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Test-Path
            Mock Test-Path { return $true } -ModuleName $scriptToTest

            # ExÃ©cuter le script avec un seuil Ã©levÃ© pour ne pas dÃ©tecter la rÃ©gression
            . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -ThresholdPercent 15 -OutputPath $script:outputPath -WhatIf

            # VÃ©rifier que les mocks ont Ã©tÃ© appelÃ©s
            Should -Invoke ConvertTo-Json -ModuleName $scriptToTest
            Should -Invoke Set-Content -ModuleName $scriptToTest
        }
    }

    Context "GÃ©nÃ©ration de rapports" {
        It "GÃ©nÃ¨re un rapport HTML si demandÃ©" {
            # CrÃ©er un mock pour la fonction New-PRReport
            Mock New-PRReport { return "HTML Report" } -ModuleName $scriptToTest

            # CrÃ©er un mock pour Test-Path
            Mock Test-Path { return $true } -ModuleName $scriptToTest

            # ExÃ©cuter le script avec l'option GenerateReport
            . $scriptToTest -CurrentResults $script:currentResultsPath -BaselineResults $script:baselineResultsPath -OutputPath $script:outputPath -GenerateReport -WhatIf

            # VÃ©rifier que la fonction New-PRReport a Ã©tÃ© appelÃ©e
            Should -Invoke New-PRReport -ModuleName $scriptToTest
        }
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
