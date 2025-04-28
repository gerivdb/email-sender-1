#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-PRLoadTest.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Start-PRLoadTest.ps1
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
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PRLoadTest.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Start-PRLoadTest.ps1 non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Start-PRLoadTest Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRLoadTestTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de sortie temporaire
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "load_test_results.json"
        
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
        
        # CrÃ©er un mock pour Start-Job
        Mock Start-Job { 
            return [PSCustomObject]@{
                Id = 1
                Name = "Job1"
                State = "Completed"
            }
        } -ModuleName $scriptToTest
        
        # CrÃ©er un mock pour Receive-Job
        Mock Receive-Job { 
            return @(
                [PSCustomObject]@{
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                    CPU = 10
                    WorkingSet = 100MB
                    PrivateMemory = 50MB
                    Handles = 100
                    Threads = 10
                }
            )
        } -ModuleName $scriptToTest
        
        # CrÃ©er un mock pour Remove-Job
        Mock Remove-Job { } -ModuleName $scriptToTest
        
        # CrÃ©er un mock pour Get-Process
        Mock Get-Process { 
            return [PSCustomObject]@{
                Id = $PID
                Name = "powershell"
                CPU = 10
                WorkingSet64 = 100MB
                PrivateMemorySize64 = 50MB
                HandleCount = 100
                Threads = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            }
        } -ModuleName $scriptToTest
    }
    
    Context "Validation des paramÃ¨tres" {
        It "Accepte le paramÃ¨tre ModuleName" {
            { & $scriptToTest -ModuleName "PRVisualization" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre FunctionName" {
            { & $scriptToTest -FunctionName "New-PRBarChart" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre Duration" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre Concurrency" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre DataSize" {
            { & $scriptToTest -DataSize "Small" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre OutputPath" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramÃ¨tre MonitorInterval" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -MonitorInterval 2 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "GÃ©nÃ©ration de donnÃ©es de test" {
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Small" {
            # ExÃ©cuter la fonction New-TestData avec la taille Small
            $testData = & $scriptToTest -DataSize "Small" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Medium" {
            # ExÃ©cuter la fonction New-TestData avec la taille Medium
            $testData = & $scriptToTest -DataSize "Medium" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "GÃ©nÃ¨re des donnÃ©es de test de taille Large" {
            # ExÃ©cuter la fonction New-TestData avec la taille Large
            $testData = & $scriptToTest -DataSize "Large" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "GÃ©nÃ¨re des donnÃ©es de test de taille ExtraLarge" {
            # ExÃ©cuter la fonction New-TestData avec la taille ExtraLarge
            $testData = & $scriptToTest -DataSize "ExtraLarge" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # VÃ©rifier que les donnÃ©es ont Ã©tÃ© gÃ©nÃ©rÃ©es
            $testData | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "ExÃ©cution des tests de charge" {
        It "ExÃ©cute les tests de charge pour toutes les fonctions" {
            # ExÃ©cuter le script avec une durÃ©e et une concurrence minimales
            & $scriptToTest -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.Duration | Should -Be 1
            $results.Concurrency | Should -Be 1
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "ExÃ©cute les tests de charge pour un module spÃ©cifique" {
            # ExÃ©cuter le script avec un module spÃ©cifique
            & $scriptToTest -ModuleName "PRVisualization" -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.Duration | Should -Be 1
            $results.Concurrency | Should -Be 1
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "ExÃ©cute les tests de charge pour une fonction spÃ©cifique" {
            # ExÃ©cuter le script avec une fonction spÃ©cifique
            & $scriptToTest -FunctionName "New-PRBarChart" -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # VÃ©rifier que le fichier de rÃ©sultats a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # VÃ©rifier que le fichier de rÃ©sultats contient des donnÃ©es valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.Duration | Should -Be 1
            $results.Concurrency | Should -Be 1
            $results.System | Should -Not -BeNullOrEmpty
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $script:testDir) {
            Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
