#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Invoke-PRPerformanceBenchmark.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Invoke-PRPerformanceBenchmark.ps1
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Invoke-PRPerformanceBenchmark.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Invoke-PRPerformanceBenchmark Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceBenchmarkTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de sortie temporaire
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "benchmark_results.json"
        
        # CrÃ©er un mock pour les modules
        Mock Import-Module { } -ModuleName $scriptToTest
        
        # CrÃ©er un mock pour les fonctions
        Mock Get-Command { 
            return @(
                [PSCustomObject]@{
                    Name = "Test-Function1"
                    CommandType = "Function"
                },
                [PSCustomObject]@{
                    Name = "Test-Function2"
                    CommandType = "Function"
                }
            )
        } -ModuleName $scriptToTest
        
        # CrÃ©er un mock pour l'exÃ©cution des fonctions
        Mock Test-Function1 { return "Test result 1" } -ModuleName $scriptToTest
        Mock Test-Function2 { return "Test result 2" } -ModuleName $scriptToTest
    }
    
    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre ModuleName" {
            { & $scriptToTest -ModuleName "PRVisualization" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre FunctionName" {
            { & $scriptToTest -FunctionName "New-PRBarChart" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre Iterations" {
            { & $scriptToTest -Iterations 3 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre DataSize" {
            { & $scriptToTest -DataSize "Small" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre OutputPath" {
            { & $scriptToTest -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre IncludeDetails" {
            { & $scriptToTest -IncludeDetails -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "GÃ©nÃ©ration de donnÃ©es de test" {
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Small" {
            # ExÃ©cuter la fonction New-TestData avec la taille Small
            $testData = & $scriptToTest -DataSize "Small" -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Medium" {
            # ExÃ©cuter la fonction New-TestData avec la taille Medium
            $testData = & $scriptToTest -DataSize "Medium" -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Large" {
            # ExÃ©cuter la fonction New-TestData avec la taille Large
            $testData = & $scriptToTest -DataSize "Large" -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "ExÃ©cution des benchmarks" {
        It "ExÃ©cute les benchmarks pour toutes les fonctions" {
            # ExÃ©cuter le script avec un petit nombre d'itÃ©rations
            & $scriptToTest -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "ExÃ©cute les benchmarks pour un module spÃ©cifique" {
            # ExÃ©cuter le script avec un module spÃ©cifique
            & $scriptToTest -ModuleName "PRVisualization" -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "ExÃ©cute les benchmarks pour une fonction spÃ©cifique" {
            # ExÃ©cuter le script avec une fonction spÃ©cifique
            & $scriptToTest -FunctionName "New-PRBarChart" -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Inclut les dÃ©tails des itÃ©rations si demandÃ©" {
            # ExÃ©cuter le script avec l'option IncludeDetails
            & $scriptToTest -Iterations 2 -DataSize "Small" -IncludeDetails -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des dÃ©tails d'itÃ©ration
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Results[0].Details | Should -Not -BeNullOrEmpty
            $results.Results[0].Details.Count | Should -Be 2
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
