#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le script Register-PRPerformanceTests.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiés pour le script Register-PRPerformanceTests.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Register-PRPerformanceTests.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Register-PRPerformanceTests.ps1 non trouvé à l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Register-PRPerformanceTests Tests Simplifiés" {
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
        It "Le script contient le paramètre ConfigPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ConfigPath.*\)"
        }
        
        It "Le script contient le paramètre BaselineResultsPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$BaselineResultsPath.*\)"
        }
        
        It "Le script contient le paramètre ThresholdPercent" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ThresholdPercent.*\)"
        }
        
        It "Le script contient le paramètre OutputDir" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputDir.*\)"
        }
        
        It "Le script contient le paramètre GenerateReport" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$GenerateReport.*\)"
        }
        
        It "Le script contient le paramètre FailOnRegression" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$FailOnRegression.*\)"
        }
    }
    
    Context "Vérification des fonctions internes" {
        It "Le script contient une fonction pour créer une configuration" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-Configuration"
        }
        
        It "Le script contient une fonction pour générer des scripts CI" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-CIScript"
        }
    }
}
