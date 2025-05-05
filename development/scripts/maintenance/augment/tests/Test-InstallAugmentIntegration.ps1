<#
.SYNOPSIS
    Tests unitaires pour le script d'installation du module d'intÃ©gration.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script d'installation du module d'intÃ©gration,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-InstallAugmentIntegration.ps1"
    # ExÃ©cute les tests unitaires pour le script d'installation du module d'intÃ©gration

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©terminer le chemin du script Ã  tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Install-AugmentIntegration.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Install Augment Integration Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "modules"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un rÃ©pertoire pour le module
        $testModuleDir = Join-Path -Path $testDir -ChildPath "AugmentIntegration"
        New-Item -Path $testModuleDir -ItemType Directory -Force | Out-Null
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestModuleDir = $testModuleDir
        
        # Mock pour les fonctions systÃ¨me
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
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Copier le module et les fichiers associÃ©s.*?# Retourner le code de sortie", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Script Execution" {
        It "Should install the module" {
            # Mock supplÃ©mentaires pour l'exÃ©cution du script
            Mock -CommandName Split-Path -MockWith { return $scriptRoot }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -eq "AugmentIntegration.psm1" } -MockWith { return "$scriptRoot\AugmentIntegration.psm1" }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -like "development\scripts\maintenance\augment\*" } -MockWith { return "$scriptRoot\$ChildPath" }
            Mock -CommandName Join-Path -ParameterFilter { $ChildPath -eq "Documents\WindowsPowerShell\Modules" } -MockWith { return $Global:TestModuleDir }
            
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                Force = $true
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que les fonctions ont Ã©tÃ© appelÃ©es
            Should -Invoke -CommandName Copy-Item -Times 1 -ParameterFilter { $Destination -like "*AugmentIntegration*" }
            Should -Invoke -CommandName New-ModuleManifest -Times 1
            Should -Invoke -CommandName Out-File -Times 1 -ParameterFilter { $FilePath -like "*Example.ps1" }
        }
    }
}
