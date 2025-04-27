#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour le script Register-PRPerformanceTests.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiÃ©s pour le script Register-PRPerformanceTests.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Register-PRPerformanceTests.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Register-PRPerformanceTests.ps1 non trouvÃ© Ã  l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Register-PRPerformanceTests Tests SimplifiÃ©s" {
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
        It "Le script contient le paramÃ¨tre ConfigPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ConfigPath.*\)"
        }
        
        It "Le script contient le paramÃ¨tre BaselineResultsPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$BaselineResultsPath.*\)"
        }
        
        It "Le script contient le paramÃ¨tre ThresholdPercent" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ThresholdPercent.*\)"
        }
        
        It "Le script contient le paramÃ¨tre OutputDir" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputDir.*\)"
        }
        
        It "Le script contient le paramÃ¨tre GenerateReport" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$GenerateReport.*\)"
        }
        
        It "Le script contient le paramÃ¨tre FailOnRegression" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$FailOnRegression.*\)"
        }
    }
    
    Context "VÃ©rification des fonctions internes" {
        It "Le script contient une fonction pour crÃ©er une configuration" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-Configuration"
        }
        
        It "Le script contient une fonction pour gÃ©nÃ©rer des scripts CI" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-CIScript"
        }
    }
}
