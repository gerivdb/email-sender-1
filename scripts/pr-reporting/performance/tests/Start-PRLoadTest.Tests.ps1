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
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script à tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-PRLoadTest.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Start-PRLoadTest.ps1 non trouvé à l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Start-PRLoadTest Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRLoadTestTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
        
        # Créer un fichier de sortie temporaire
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "load_test_results.json"
        
        # Créer un mock pour les modules
        Mock Import-Module { } -ModuleName $scriptToTest
        
        # Créer un mock pour les fonctions
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
        
        # Créer un mock pour l'exécution des fonctions
        Mock Test-Function1 { return "Test result 1" } -ModuleName $scriptToTest
        Mock Test-Function2 { return "Test result 2" } -ModuleName $scriptToTest
        
        # Créer un mock pour Start-Job
        Mock Start-Job { 
            return [PSCustomObject]@{
                Id = 1
                Name = "Job1"
                State = "Completed"
            }
        } -ModuleName $scriptToTest
        
        # Créer un mock pour Receive-Job
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
        
        # Créer un mock pour Remove-Job
        Mock Remove-Job { } -ModuleName $scriptToTest
        
        # Créer un mock pour Get-Process
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
    
    Context "Validation des paramètres" {
        It "Accepte le paramètre ModuleName" {
            { & $scriptToTest -ModuleName "PRVisualization" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre FunctionName" {
            { & $scriptToTest -FunctionName "New-PRBarChart" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre Duration" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre Concurrency" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre DataSize" {
            { & $scriptToTest -DataSize "Small" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre OutputPath" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre MonitorInterval" {
            { & $scriptToTest -Duration 1 -Concurrency 1 -MonitorInterval 2 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Génération de données de test" {
        It "Génère des données de test de taille Small" {
            # Exécuter la fonction New-TestData avec la taille Small
            $testData = & $scriptToTest -DataSize "Small" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "Génère des données de test de taille Medium" {
            # Exécuter la fonction New-TestData avec la taille Medium
            $testData = & $scriptToTest -DataSize "Medium" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "Génère des données de test de taille Large" {
            # Exécuter la fonction New-TestData avec la taille Large
            $testData = & $scriptToTest -DataSize "Large" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "Génère des données de test de taille ExtraLarge" {
            # Exécuter la fonction New-TestData avec la taille ExtraLarge
            $testData = & $scriptToTest -DataSize "ExtraLarge" -Duration 1 -Concurrency 1 -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Exécution des tests de charge" {
        It "Exécute les tests de charge pour toutes les fonctions" {
            # Exécuter le script avec une durée et une concurrence minimales
            & $scriptToTest -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.Duration | Should -Be 1
            $results.Concurrency | Should -Be 1
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Exécute les tests de charge pour un module spécifique" {
            # Exécuter le script avec un module spécifique
            & $scriptToTest -ModuleName "PRVisualization" -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.Duration | Should -Be 1
            $results.Concurrency | Should -Be 1
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Exécute les tests de charge pour une fonction spécifique" {
            # Exécuter le script avec une fonction spécifique
            & $scriptToTest -FunctionName "New-PRBarChart" -Duration 1 -Concurrency 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
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
