<#
.SYNOPSIS
    Tests unitaires pour le script d'installation du module d'intégration.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script d'installation du module d'intégration,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-InstallAugmentIntegration.ps1"
    # Exécute les tests unitaires pour le script d'installation du module d'intégration

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Déterminer le chemin du script à tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Install-AugmentIntegration.ps1"

# Déterminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Install Augment Integration Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "modules"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Créer un répertoire pour le module
        $testModuleDir = Join-Path -Path $testDir -ChildPath "AugmentIntegration"
        New-Item -Path $testModuleDir -ItemType Directory -Force | Out-Null
        
        # Définir des variables globales pour les tests
        $Global:TestModuleDir = $testModuleDir
        
        # Mock pour les fonctions système
        Mock -CommandName New-ModuleManifest -MockWith { return $true }
        Mock -CommandName Copy-Item -MockWith { return $true }
        Mock -CommandName Join-Path -MockWith { return "$Global:TestModuleDir\$($args[1])" }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Get-Content -MockWith { return "# Module content" }
        Mock -CommandName Out-File -MockWith { return $true }
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestModuleDir -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # Vérifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour éviter d'exécuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exécute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Copier le module et les fichiers associés.*?# Retourner le code de sortie", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # Exécuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Script Execution" {
        It "Should install the module" {
            # Mock supplémentaires pour l'exécution du script
            Mock -CommandName Split-Path -MockWith { return $scriptRoot }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -eq "AugmentIntegration.psm1" } -MockWith { return "$scriptRoot\AugmentIntegration.psm1" }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -like "development\scripts\maintenance\augment\*" } -MockWith { return "$scriptRoot\$ChildPath" }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -eq "Documents\WindowsPowerShell\Modules" } -MockWith { return $Global:TestModuleDir }
            
            # Exécuter le script avec des paramètres spécifiques
            $params = @{
                Force = $true
            }
            
            # Exécuter le script
            & $scriptPath @params
            
            # Vérifier que les fonctions ont été appelées
            Should -Invoke -CommandName Copy-Item -Times 1 -ParameterFilter { $Destination -like "*AugmentIntegration*" }
            Should -Invoke -CommandName New-ModuleManifest -Times 1
            Should -Invoke -CommandName Out-File -Times 1 -ParameterFilter { $FilePath -like "*Example.ps1" }
        }
    }
}
