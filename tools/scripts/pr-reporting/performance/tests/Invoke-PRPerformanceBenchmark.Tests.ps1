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
    Write-Warning "Le module Pester n'est pas installé. Installation recommandée: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script à tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Invoke-PRPerformanceBenchmark.ps1 non trouvé à l'emplacement: $scriptToTest"
}

# Tests Pester
Describe "Invoke-PRPerformanceBenchmark Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testDir = Join-Path -Path $env:TEMP -ChildPath "PRPerformanceBenchmarkTests_$(Get-Random)"
        New-Item -Path $script:testDir -ItemType Directory -Force | Out-Null
        
        # Créer un fichier de sortie temporaire
        $script:outputPath = Join-Path -Path $script:testDir -ChildPath "benchmark_results.json"
        
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
    }
    
    Context "Validation des paramètres" {
        It "Accepte le paramètre ModuleName" {
            { & $scriptToTest -ModuleName "PRVisualization" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre FunctionName" {
            { & $scriptToTest -FunctionName "New-PRBarChart" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre Iterations" {
            { & $scriptToTest -Iterations 3 -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre DataSize" {
            { & $scriptToTest -DataSize "Small" -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre OutputPath" {
            { & $scriptToTest -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
        
        It "Accepte le paramètre IncludeDetails" {
            { & $scriptToTest -IncludeDetails -OutputPath $script:outputPath -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Génération de données de test" {
        It "Génère des données de test de taille Small" {
            # Exécuter la fonction New-TestData avec la taille Small
            $testData = & $scriptToTest -DataSize "Small" -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "Génère des données de test de taille Medium" {
            # Exécuter la fonction New-TestData avec la taille Medium
            $testData = & $scriptToTest -DataSize "Medium" -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
        
        It "Génère des données de test de taille Large" {
            # Exécuter la fonction New-TestData avec la taille Large
            $testData = & $scriptToTest -DataSize "Large" -OutputPath $script:outputPath -WhatIf
            
            # Vérifier que les données ont été générées
            $testData | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Exécution des benchmarks" {
        It "Exécute les benchmarks pour toutes les fonctions" {
            # Exécuter le script avec un petit nombre d'itérations
            & $scriptToTest -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Exécute les benchmarks pour un module spécifique" {
            # Exécuter le script avec un module spécifique
            & $scriptToTest -ModuleName "PRVisualization" -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Exécute les benchmarks pour une fonction spécifique" {
            # Exécuter le script avec une fonction spécifique
            & $scriptToTest -FunctionName "New-PRBarChart" -Iterations 1 -DataSize "Small" -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des données valides
            $results = Get-Content -Path $script:outputPath -Raw | ConvertFrom-Json
            $results | Should -Not -BeNullOrEmpty
            $results.Results | Should -Not -BeNullOrEmpty
            $results.Timestamp | Should -Not -BeNullOrEmpty
            $results.DataSize | Should -Be "Small"
            $results.System | Should -Not -BeNullOrEmpty
        }
        
        It "Inclut les détails des itérations si demandé" {
            # Exécuter le script avec l'option IncludeDetails
            & $scriptToTest -Iterations 2 -DataSize "Small" -IncludeDetails -OutputPath $script:outputPath
            
            # Vérifier que le fichier de résultats a été créé
            Test-Path -Path $script:outputPath | Should -Be $true
            
            # Vérifier que le fichier de résultats contient des détails d'itération
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
