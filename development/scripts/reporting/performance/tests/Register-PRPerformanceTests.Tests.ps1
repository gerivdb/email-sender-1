#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Register-PRPerformanceTests.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Register-PRPerformanceTests.ps1
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Register-PRPerformanceTests.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Register-PRPerformanceTests.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Register-PRPerformanceTests Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceRegisterTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er des fichiers de configuration et de rÃ©sultats de test
        $script:configPath = Join-Path -Path $script:testDir -ChildPath "performance_tests_config.json"
        $script:baselineResultsPath = Join-Path -Path $script:testDir -ChildPath "baseline_results.json"
        $script:outputDir = Join-Path -Path $script:testDir -ChildPath "performance_results"
        
        # CrÃ©er un rÃ©pertoire de sortie
        New-Item -Path $script:outputDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er des donnÃ©es de test pour les rÃ©sultats de rÃ©fÃ©rence
        $baselineResults = @{
            Timestamp = "2025-04-28 10:00:00"
            DataSize = "Medium"
            Iterations = 5
            System = @{
                PSVersion = "5.1.19041.3031"
                OS = "Microsoft Windows 10.0.19045"
                ProcessorCount = 8
            }
            Results = @(
                @{
                    ModuleName = "PRVisualization"
                    FunctionName = "New-PRBarChart"
                    Iterations = 5
                    TotalMs = 500
                    AverageMs = 100
                    MinMs = 90
                    MaxMs = 110
                },
                @{
                    ModuleName = "PRVisualization"
                    FunctionName = "New-PRPieChart"
                    Iterations = 5
                    TotalMs = 600
                    AverageMs = 120
                    MinMs = 110
                    MaxMs = 130
                }
            )
        }
        
        # Enregistrer le fichier de rÃ©sultats de rÃ©fÃ©rence
        $baselineResults | ConvertTo-Json -Depth 10 | Set-Content -Path $script:baselineResultsPath -Encoding UTF8
        
        # CrÃ©er un mock pour les scripts de test de performance
        Mock Invoke-Expression { } -ModuleName $scriptToTest
    }
    
    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre ConfigPath" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre BaselineResultsPath" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre ThresholdPercent" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -ThresholdPercent 5 -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre OutputDir" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre GenerateReport" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir -GenerateReport -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre FailOnRegression" {
            { & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir -FailOnRegression -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "CrÃ©ation de configuration" {
        It "CrÃ©e un fichier de configuration par dÃ©faut si non existant" {
            # ExÃ©cuter le script
            & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir
            
            # VÃ©rifier que le fichier de configuration a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:configPath | Should -Be $true
            
            # VÃ©rifier que le fichier de configuration contient des donnÃ©es valides
            $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.Benchmark | Should -Not -BeNullOrEmpty
            $config.LoadTest | Should -Not -BeNullOrEmpty
            $config.Regression | Should -Not -BeNullOrEmpty
            $config.Comparison | Should -Not -BeNullOrEmpty
            $config.CI | Should -Not -BeNullOrEmpty
        }
        
        It "Met Ã  jour la configuration existante avec les paramÃ¨tres spÃ©cifiÃ©s" {
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -ThresholdPercent 5 -OutputDir $script:outputDir -GenerateReport -FailOnRegression
            
            # VÃ©rifier que le fichier de configuration a Ã©tÃ© mis Ã  jour
            $config = Get-Content -Path $script:configPath -Raw | ConvertFrom-Json
            $config | Should -Not -BeNullOrEmpty
            $config.Regression.ThresholdPercent | Should -Be 5
            $config.CI.BaselineResultsPath | Should -Be $script:baselineResultsPath
            $config.CI.OutputDir | Should -Be $script:outputDir
            $config.Comparison.GenerateReport | Should -Be $true
            $config.CI.FailOnRegression | Should -Be $true
        }
    }
    
    Context "GÃ©nÃ©ration de scripts CI" {
        It "GÃ©nÃ¨re un script CI" {
            # ExÃ©cuter le script
            & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir
            
            # VÃ©rifier que le script CI a Ã©tÃ© crÃ©Ã©
            $ciScriptPath = Join-Path -Path $script:outputDir -ChildPath "Run-PRPerformanceTests.ps1"
            Test-Path -Path $ciScriptPath | Should -Be $true
            
            # VÃ©rifier que le script CI contient des donnÃ©es valides
            $ciScript = Get-Content -Path $ciScriptPath -Raw
            $ciScript | Should -Not -BeNullOrEmpty
            $ciScript | Should -BeLike "*Register-PRPerformanceTests.ps1*"
        }
        
        It "GÃ©nÃ¨re une configuration Azure DevOps" {
            # ExÃ©cuter le script
            & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir
            
            # VÃ©rifier que la configuration Azure DevOps a Ã©tÃ© crÃ©Ã©e
            $azureDevOpsConfigPath = Join-Path -Path $script:outputDir -ChildPath "azure-pipelines-performance.yml"
            Test-Path -Path $azureDevOpsConfigPath | Should -Be $true
            
            # VÃ©rifier que la configuration Azure DevOps contient des donnÃ©es valides
            $azureDevOpsConfig = Get-Content -Path $azureDevOpsConfigPath -Raw
            $azureDevOpsConfig | Should -Not -BeNullOrEmpty
            $azureDevOpsConfig | Should -BeLike "*Run-PRPerformanceTests.ps1*"
        }
        
        It "GÃ©nÃ¨re une configuration GitHub Actions" {
            # ExÃ©cuter le script
            & $scriptToTest -ConfigPath $script:configPath -BaselineResultsPath $script:baselineResultsPath -OutputDir $script:outputDir
            
            # VÃ©rifier que la configuration GitHub Actions a Ã©tÃ© crÃ©Ã©e
            $githubActionsConfigPath = Join-Path -Path $script:outputDir -ChildPath "github-actions-performance.yml"
            Test-Path -Path $githubActionsConfigPath | Should -Be $true
            
            # VÃ©rifier que la configuration GitHub Actions contient des donnÃ©es valides
            $githubActionsConfig = Get-Content -Path $githubActionsConfigPath -Raw
            $githubActionsConfig | Should -Not -BeNullOrEmpty
            $githubActionsConfig | Should -BeLike "*Run-PRPerformanceTests.ps1*"
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
