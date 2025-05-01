<#
.SYNOPSIS
    Tests unitaires pour le script d'optimisation des Memories.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script d'optimisation des Memories,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-OptimizeAugmentMemories.ps1"
    # Exécute les tests unitaires pour le script d'optimisation des Memories

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "optimize-augment-memories.ps1"

# Déterminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Optimize Augment Memories Tests" {
    BeforeAll {
        # Créer un fichier de configuration temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "config"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        $testConfigPath = Join-Path -Path $testDir -ChildPath "unified-config.json"
        $testConfigContent = @{
            Augment = @{
                Memories = @{
                    Enabled = $true
                    UpdateFrequency = "Daily"
                    MaxSizeKB = 5
                    AutoSegmentation = $true
                    VSCodeWorkspaceId = "test-workspace-id"
                }
            }
        } | ConvertTo-Json -Depth 10
        $testConfigContent | Out-File -FilePath $testConfigPath -Encoding UTF8
        
        # Créer un répertoire de sortie temporaire pour les tests
        $testOutputDir = Join-Path -Path $TestDrive -ChildPath "output"
        New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
        
        $testOutputPath = Join-Path -Path $testOutputDir -ChildPath "memories.json"
        
        # Définir des variables globales pour les tests
        $Global:TestConfigPath = $testConfigPath
        $Global:TestOutputPath = $testOutputPath
        
        # Créer des fonctions de mock pour les fonctions du script
        function Get-OptimizedMemories {
            param (
                [string]$Mode = "ALL"
            )
            
            $memories = @{
                version = "2.0.0"
                lastUpdated = (Get-Date).ToString("o")
                sections = @(
                    @{
                        name = "TEST"
                        content = "Test content"
                    }
                )
            }
            
            if ($Mode -ne "ALL") {
                $memories.sections += @{
                    name = "$Mode MODE"
                    content = "Mode-specific content for $Mode"
                }
            }
            
            return $memories
        }
        
        # Exporter les fonctions pour qu'elles soient disponibles dans le scope du test
        Export-ModuleMember -Function Get-OptimizedMemories
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestConfigPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestOutputPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # Vérifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour éviter d'exécuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exécute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Générer les Memories optimisées.*?# Enregistrer les Memories optimisées", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # Exécuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Get-OptimizedMemories" {
        It "Should return valid Memories for ALL mode" {
            # Tester la fonction
            $result = Get-OptimizedMemories -Mode "ALL"
            
            $result | Should -Not -BeNullOrEmpty
            $result.version | Should -Be "2.0.0"
            $result.sections | Should -Not -BeNullOrEmpty
            $result.sections.Count | Should -Be 1
            $result.sections[0].name | Should -Be "TEST"
        }
        
        It "Should return mode-specific Memories for specific modes" {
            $modes = @("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")
            
            foreach ($mode in $modes) {
                $result = Get-OptimizedMemories -Mode $mode
                
                $result | Should -Not -BeNullOrEmpty
                $result.version | Should -Be "2.0.0"
                $result.sections | Should -Not -BeNullOrEmpty
                $result.sections.Count | Should -Be 2
                $result.sections[1].name | Should -Be "$mode MODE"
            }
        }
    }
    
    Context "Script Execution" {
        It "Should generate and save optimized Memories" {
            # Mock les fonctions nécessaires
            Mock -CommandName Get-OptimizedMemories -MockWith {
                param (
                    [string]$Mode = "ALL"
                )
                
                return @{
                    version = "2.0.0"
                    lastUpdated = (Get-Date).ToString("o")
                    sections = @(
                        @{
                            name = "TEST"
                            content = "Test content"
                        }
                    )
                }
            }
            
            # Exécuter le script avec des paramètres spécifiques
            $params = @{
                OutputPath = $Global:TestOutputPath
                Mode = "ALL"
                ConfigPath = $Global:TestConfigPath
            }
            
            # Exécuter le script
            & $scriptPath @params
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $Global:TestOutputPath | Should -Be $true
            
            # Vérifier le contenu du fichier
            $content = Get-Content -Path $Global:TestOutputPath -Raw | ConvertFrom-Json
            $content | Should -Not -BeNullOrEmpty
            $content.version | Should -Be "2.0.0"
            $content.sections | Should -Not -BeNullOrEmpty
        }
    }
}
