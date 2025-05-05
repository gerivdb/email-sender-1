<#
.SYNOPSIS
    Tests unitaires pour le script de configuration d'Augment MCP.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de configuration d'Augment MCP,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-ConfigureAugmentMCP.ps1"
    # ExÃ©cute les tests unitaires pour le script de configuration d'Augment MCP

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "configure-augment-mcp.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Configure Augment MCP Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de configuration temporaire
        $testConfigPath = Join-Path -Path $testDir -ChildPath "unified-config.json"
        $testConfigContent = @{
            Augment = @{
                MCP = @{
                    Enabled = $true
                    Servers = @(
                        @{
                            Name = "memories"
                            Port = 7891
                            ScriptPath = "development\scripts\maintenance\augment\mcp-memories-server.ps1"
                        },
                        @{
                            Name = "mode-manager"
                            Port = 7892
                            ScriptPath = "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
                        }
                    )
                }
            }
        } | ConvertTo-Json -Depth 10
        $testConfigContent | Out-File -FilePath $testConfigPath -Encoding UTF8
        
        # CrÃ©er un rÃ©pertoire .augment temporaire
        $testAugmentDir = Join-Path -Path $testDir -ChildPath ".augment"
        New-Item -Path $testAugmentDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un rÃ©pertoire .vscode temporaire
        $testVscodeDir = Join-Path -Path $testDir -ChildPath ".vscode"
        New-Item -Path $testVscodeDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier settings.json temporaire
        $testSettingsPath = Join-Path -Path $testVscodeDir -ChildPath "settings.json"
        $testSettingsContent = @{
            "editor.formatOnSave" = $true
        } | ConvertTo-Json -Depth 10
        $testSettingsContent | Out-File -FilePath $testSettingsPath -Encoding UTF8
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestConfigPath = $testConfigPath
        $Global:TestAugmentDir = $testAugmentDir
        $Global:TestVscodeDir = $testVscodeDir
        $Global:TestSettingsPath = $testSettingsPath
        
        # Mock pour les fonctions systÃ¨me
        Mock -CommandName Start-Process -MockWith { return [PSCustomObject]@{ Id = 12345 } }
        Mock -CommandName Join-Path -MockWith { 
            if ($ChildPath -eq "development\scripts\maintenance\augment\optimize-augment-memories.ps1") {
                return "$scriptRoot\optimize-augment-memories.ps1"
            } else {
                return "$Path\$ChildPath"
            }
        }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Get-Content -MockWith { 
            if ($Path -eq $Global:TestSettingsPath) {
                return $testSettingsContent
            } else {
                return $testConfigContent
            }
        }
        Mock -CommandName Out-File -MockWith { return $true }
        Mock -CommandName ConvertFrom-Json -MockWith { 
            if ($InputObject -eq $testSettingsContent) {
                return @{
                    "editor.formatOnSave" = $true
                }
            } else {
                return @{
                    Augment = @{
                        MCP = @{
                            Enabled = $true
                            Servers = @(
                                @{
                                    Name = "memories"
                                    Port = 7891
                                    ScriptPath = "development\scripts\maintenance\augment\mcp-memories-server.ps1"
                                },
                                @{
                                    Name = "mode-manager"
                                    Port = 7892
                                    ScriptPath = "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
                                }
                            )
                        }
                    }
                }
            }
        }
        Mock -CommandName ConvertTo-Json -MockWith { return $InputObject | ConvertTo-Json -Depth 10 }
        Mock -CommandName & -MockWith { return $true }
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestConfigPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestAugmentDir -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestVscodeDir -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestSettingsPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# CrÃ©er le rÃ©pertoire .augment s'il n'existe pas.*?# DÃ©marrer les serveurs MCP si demandÃ©", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Script Execution" {
        It "Should configure Augment MCP" {
            # Mock supplÃ©mentaires pour l'exÃ©cution du script
            Mock -CommandName New-Item -MockWith { return [PSCustomObject]@{ FullName = "$Path" } }
            
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                StartServers = $false
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que les fonctions ont Ã©tÃ© appelÃ©es
            Should -Invoke -CommandName New-Item -Times 1 -ParameterFilter { $Path -like "*\.augment" }
            Should -Invoke -CommandName Out-File -Times 3 -ParameterFilter { $FilePath -like "*\.augment\*" -or $FilePath -like "*\.vscode\*" }
            Should -Invoke -CommandName & -Times 0 -ParameterFilter { $args[0] -like "*optimize-augment-memories.ps1" }
        }
        
        It "Should start MCP servers if requested" {
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                StartServers = $true
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que les fonctions ont Ã©tÃ© appelÃ©es
            Should -Invoke -CommandName Start-Process -Times 2
        }
    }
}
