#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le script Invoke-PRPerformanceBenchmark.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiés pour le script Invoke-PRPerformanceBenchmark.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Invoke-PRPerformanceBenchmark.ps1 non trouvé à l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Invoke-PRPerformanceBenchmark Tests Simplifiés" {
    Context "Vérification de la structure du script" {
        It "Le script existe" {
            Test-Path -Path $scriptPath | Should -Be $true
        }
        
        It "Le script est un fichier PowerShell valide" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            { [ScriptBlock]::Create($scriptContent) } | Should -Not -Throw
        }
    }
    
    Context "Vérification des paramètres" {
        It "Le script contient le paramètre ModuleName" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ModuleName.*\)"
        }
        
        It "Le script contient le paramètre FunctionName" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$FunctionName.*\)"
        }
        
        It "Le script contient le paramètre Iterations" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Iterations.*\)"
        }
        
        It "Le script contient le paramètre OutputPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputPath.*\)"
        }
    }
    
    Context "Vérification des fonctions internes" {
        It "Le script contient une fonction pour générer des données de test" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-TestData"
        }
        
        It "Le script contient une fonction pour exécuter les benchmarks" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+Invoke-Benchmark"
        }
    }
}
