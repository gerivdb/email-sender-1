#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour le script Compare-PRPerformanceResults.ps1.
.DESCRIPTION
    Ce script contient des tests simplifiés pour le script Compare-PRPerformanceResults.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Compare-PRPerformanceResults.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Script Compare-PRPerformanceResults.ps1 non trouvé à l'emplacement: $scriptPath"
}

# Tests Pester
Describe "Compare-PRPerformanceResults Tests Simplifiés" {
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
        It "Le script contient le paramètre ResultsPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$ResultsPath.*\)"
        }
        
        It "Le script contient le paramètre Labels" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$Labels.*\)"
        }
        
        It "Le script contient le paramètre OutputPath" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$OutputPath.*\)"
        }
        
        It "Le script contient le paramètre IncludeRawData" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "param\s*\(.*\[Parameter.*\].*\$IncludeRawData.*\)"
        }
    }
    
    Context "Vérification des fonctions internes" {
        It "Le script contient une fonction pour charger les résultats" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+Load-Results"
        }
        
        It "Le script contient une fonction pour comparer les résultats" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+Compare-Results"
        }
        
        It "Le script contient une fonction pour générer un rapport" {
            $scriptContent = Get-Content -Path $scriptPath -Raw
            $scriptContent | Should -Match "function\s+New-ComparisonReport"
        }
    }
}
