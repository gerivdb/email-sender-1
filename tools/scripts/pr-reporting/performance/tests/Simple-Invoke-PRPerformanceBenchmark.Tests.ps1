#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour le script Invoke-PRPerformanceBenchmark.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiÃ©s pour le script Invoke-PRPerformanceBenchmark.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-PRPerformanceBenchmark.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Invoke-PRPerformanceBenchmark.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Invoke-PRPerformanceBenchmark Tests SimplifiÃ©s" {
    Context "VÃ©rification de la structure du script" {
        It "Le script existe" {
            Test-Path -Path $scriptPath | Should -Be $true
        }
        
        It "Le script est un fichier PowerShell valide" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            { [ScriptBlock]::Create($scriptContent) } | Should -Not -Throw
        }
    }
    
    Context "VÃ©rification des paramÃ¨tres" {
        It "Le script contient le paramÃ¨tre ModuleName" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ModuleName.*\)"
        }
        
        It "Le script contient le paramÃ¨tre FunctionName" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$FunctionName.*\)"
        }
        
        It "Le script contient le paramÃ¨tre Iterations" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Iterations.*\)"
        }
        
        It "Le script contient le paramÃ¨tre OutputPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputPath.*\)"
        }
    }
    
    Context "VÃ©rification des fonctions internes" {
        It "Le script contient une fonction pour gÃ©nÃ©rer des donnÃ©es de test" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-TestData"
        }
        
        It "Le script contient une fonction pour exÃ©cuter les benchmarks" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+Invoke-Benchmark"
        }
    }
}
