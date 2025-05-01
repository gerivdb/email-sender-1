<#
.SYNOPSIS
    Tests unitaires pour le module AugmentIntegration.

.DESCRIPTION
    Ce script contient des tests unitaires pour le module AugmentIntegration,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-AugmentIntegration.ps1"
    # Exécute les tests unitaires pour le module AugmentIntegration

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

# Importer le module à tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "AugmentIntegration.psm1"

# Déterminer le chemin du projet
$projectRoot = $moduleRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "AugmentIntegration Module Tests" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force
        
        # Créer des mocks pour les dépendances
        Mock -CommandName Start-Process -MockWith { return [PSCustomObject]@{ Id = 12345 } }
        Mock -CommandName Invoke-RestMethod -MockWith { return [PSCustomObject]@{ status = "success" } }
        
        # Créer des fichiers temporaires pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        $testMemoriesPath = Join-Path -Path $testDir -ChildPath "memories.json"
        $testMemoriesContent = @{
            version = "2.0.0"
            lastUpdated = (Get-Date).ToString("o")
            sections = @(
                @{
                    name = "TEST"
                    content = "Test content"
                }
            )
        } | ConvertTo-Json -Depth 10
        $testMemoriesContent | Out-File -FilePath $testMemoriesPath -Encoding UTF8
        
        $testLogPath = Join-Path -Path $testDir -ChildPath "augment.log"
        $testLogContent = @"
2025-06-01T10:00:00.000Z|REQUEST|{"input":"Test input","input_size":10,"mode":"GRAN"}
2025-06-01T10:00:05.000Z|RESPONSE|{"output":"Test output","output_size":11,"time_ms":5000}
"@
        $testLogContent | Out-File -FilePath $testLogPath -Encoding UTF8
        
        # Définir des variables globales pour les tests
        $Global:TestMemoriesPath = $testMemoriesPath
        $Global:TestLogPath = $testLogPath
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestMemoriesPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestLogPath -Scope Global -ErrorAction SilentlyContinue
        
        # Décharger le module
        Remove-Module -Name AugmentIntegration -ErrorAction SilentlyContinue
    }
    
    Context "Module Loading" {
        It "Should load the module without errors" {
            { Import-Module $modulePath -Force } | Should -Not -Throw
        }
        
        It "Should export the required functions" {
            $requiredFunctions = @(
                "Invoke-AugmentMode",
                "Start-AugmentMCPServers",
                "Stop-AugmentMCPServers",
                "Update-AugmentMemoriesForMode",
                "Split-AugmentInput",
                "Measure-AugmentInputSize",
                "Get-AugmentModeDescription",
                "Initialize-AugmentIntegration",
                "Analyze-AugmentPerformance"
            )
            
            foreach ($function in $requiredFunctions) {
                Get-Command -Module AugmentIntegration -Name $function -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context "Measure-AugmentInputSize" {
        It "Should correctly measure the size of an input" {
            $input = "Test input"
            $result = Measure-AugmentInputSize -Input $input
            
            $result.Bytes | Should -Be ([System.Text.Encoding]::UTF8.GetByteCount($input))
            $result.KiloBytes | Should -Be ([math]::Round(([System.Text.Encoding]::UTF8.GetByteCount($input) / 1024), 2))
            $result.IsOverLimit | Should -Be $false
            $result.IsNearLimit | Should -Be $false
        }
        
        It "Should detect inputs near the limit" {
            $input = "a" * 4100
            $result = Measure-AugmentInputSize -Input $input
            
            $result.IsNearLimit | Should -Be $true
            $result.IsOverLimit | Should -Be $false
        }
        
        It "Should detect inputs over the limit" {
            $input = "a" * 5200
            $result = Measure-AugmentInputSize -Input $input
            
            $result.IsOverLimit | Should -Be $true
        }
    }
    
    Context "Split-AugmentInput" {
        It "Should not split small inputs" {
            $input = "Small input"
            $result = Split-AugmentInput -Input $input
            
            $result.Count | Should -Be 1
            $result[0] | Should -Be $input
        }
        
        It "Should split large inputs" {
            $input = "a" * 6000
            $result = Split-AugmentInput -Input $input -MaxSize 3000
            
            $result.Count | Should -BeGreaterThan 1
            $result[0].Length | Should -BeLessOrEqual 3000
        }
    }
    
    Context "Get-AugmentModeDescription" {
        It "Should return the correct description for each mode" {
            $modes = @("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")
            
            foreach ($mode in $modes) {
                $description = Get-AugmentModeDescription -Mode $mode
                $description | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "AugmentMemoriesManager Tests" {
    BeforeAll {
        # Importer le module AugmentMemoriesManager
        $memoriesManagerPath = Join-Path -Path $moduleRoot -ChildPath "AugmentMemoriesManager.ps1"
        . $memoriesManagerPath
    }
    
    Context "Split-LargeInput" {
        It "Should not split small inputs" {
            $input = "Small input"
            $result = Split-LargeInput -Input $input
            
            $result.Count | Should -Be 1
            $result[0] | Should -Be $input
        }
        
        It "Should split large inputs" {
            $input = "a" * 6000
            $result = Split-LargeInput -Input $input -MaxSize 3000
            
            $result.Count | Should -BeGreaterThan 1
            $result[0].Length | Should -BeLessOrEqual 3000
        }
    }
    
    Context "Update-AugmentMemories" {
        It "Should update Augment Memories" {
            # Mock Export-MemoriesToVSCode
            Mock -CommandName Export-MemoriesToVSCode -MockWith { return $true }
            
            $result = Update-AugmentMemories -OutputPath $Global:TestMemoriesPath
            $result | Should -Be $true
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $Global:TestMemoriesPath | Should -Be $true
        }
    }
}

Describe "MCP Integration Tests" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force
        
        # Mock les fonctions qui interagissent avec les serveurs MCP
        Mock -CommandName Start-Process -MockWith { return [PSCustomObject]@{ Id = 12345 } }
        Mock -CommandName Invoke-RestMethod -MockWith { return [PSCustomObject]@{ status = "success" } }
    }
    
    Context "Initialize-AugmentIntegration" {
        It "Should initialize the integration without errors" {
            # Mock le script de configuration
            Mock -CommandName & -ParameterFilter { $args[0] -like "*configure-augment-mcp.ps1*" } -MockWith { return $true }
            
            { Initialize-AugmentIntegration } | Should -Not -Throw
        }
    }
    
    Context "Start-AugmentMCPServers" {
        It "Should start the MCP servers without errors" {
            # Mock le script de démarrage
            Mock -CommandName & -ParameterFilter { $args[0] -like "*start-mcp-servers.ps1*" } -MockWith { return $true }
            
            { Start-AugmentMCPServers } | Should -Not -Throw
        }
    }
    
    Context "Stop-AugmentMCPServers" {
        It "Should stop the MCP servers without errors" {
            # Mock le script d'arrêt
            Mock -CommandName & -ParameterFilter { $args[0] -like "*stop-mcp-servers.ps1*" } -MockWith { return $true }
            Mock -CommandName Test-Path -MockWith { return $true }
            
            { Stop-AugmentMCPServers } | Should -Not -Throw
        }
    }
}

Describe "Performance Analysis Tests" {
    BeforeAll {
        # Importer le module
        Import-Module $modulePath -Force
        
        # Mock le script d'analyse des performances
        Mock -CommandName & -ParameterFilter { $args[0] -like "*analyze-augment-performance.ps1*" } -MockWith { return $true }
    }
    
    Context "Analyze-AugmentPerformance" {
        It "Should analyze performance without errors" {
            { Analyze-AugmentPerformance -LogPath $Global:TestLogPath } | Should -Not -Throw
        }
    }
}
