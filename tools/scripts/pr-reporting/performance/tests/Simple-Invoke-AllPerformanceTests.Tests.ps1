#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le script Invoke-AllPerformanceTests.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiés pour le script Invoke-AllPerformanceTests.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Invoke-AllPerformanceTests.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Invoke-AllPerformanceTests.ps1 non trouvé à l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Invoke-AllPerformanceTests Tests Simplifiés" {
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
        It "Le script contient le paramètre OutputDir" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputDir.*\)"
        }
        
        It "Le script contient le paramètre DataSize" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$DataSize.*\)"
        }
        
        It "Le script contient le paramètre Iterations" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Iterations.*\)"
        }
        
        It "Le script contient le paramètre Duration" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Duration.*\)"
        }
        
        It "Le script contient le paramètre Concurrency" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Concurrency.*\)"
        }
        
        It "Le script contient le paramètre GenerateReport" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$GenerateReport.*\)"
        }
    }
    
    Context "Vérification des appels de scripts" {
        It "Le script appelle Invoke-PRPerformanceBenchmark.ps1" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "Invoke-PRPerformanceBenchmark\.ps1"
        }
        
        It "Le script appelle Start-PRLoadTest.ps1" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "Start-PRLoadTest\.ps1"
        }
        
        It "Le script appelle Compare-PRPerformanceResults.ps1" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "Compare-PRPerformanceResults\.ps1"
        }
    }
}
