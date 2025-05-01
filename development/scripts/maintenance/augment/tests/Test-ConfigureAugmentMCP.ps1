<#
.SYNOPSIS
    Tests unitaires pour le script de configuration d'Augment MCP.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de configuration d'Augment MCP,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-ConfigureAugmentMCP.ps1"
    # Exécute les tests unitaires pour le script de configuration d'Augment MCP

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "configure-augment-mcp.ps1"

# Déterminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Configure Augment MCP Tests" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Créer un fichier de configuration temporaire
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
        
        # Créer un répertoire .augment temporaire
        $testAugmentDir = Join-Path -Path $testDir -ChildPath ".augment"
        New-Item -Path $testAugmentDir -ItemType Directory -Force | Out-Null
        
        # Créer un répertoire .vscode temporaire
        $testVscodeDir = Join-Path -Path $testDir -ChildPath ".vscode"
        New-Item -Path $testVscodeDir -ItemType Directory -Force | Out-Null
        
        # Créer un fichier settings.json temporaire
        $testSettingsPath = Join-Path -Path $testVscodeDir -ChildPath "settings.json"
        $testSettingsContent = @{
            "editor.formatOnSave" = $true
        } | ConvertTo-Json -Depth 10
        $testSettingsContent | Out-File -FilePath $testSettingsPath -Encoding UTF8
        
        # Définir des variables globales pour les tests
        $Global:TestConfigPath = $testConfigPath
        $Global:TestAugmentDir = $testAugmentDir
        $Global:TestVscodeDir = $testVscodeDir
        $Global:TestSettingsPath = $testSettingsPath
        
        # Mock pour les fonctions système
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
            # Vérifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour éviter d'exécuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exécute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Créer le répertoire .augment s'il n'existe pas.*?# Démarrer les serveurs MCP si demandé", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # Exécuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Script Execution" {
        It "Should configure Augment MCP" {
            # Mock supplémentaires pour l'exécution du script
            Mock -CommandName New-Item -MockWith { return [PSCustomObject]@{ FullName = "$Path" } }
            
            # Exécuter le script avec des paramètres spécifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                StartServers = $false
            }
            
            # Exécuter le script
            & $scriptPath @params
            
            # Vérifier que les fonctions ont été appelées
            Should -Invoke -CommandName New-Item -Times 1 -ParameterFilter { $Path -like "*\.augment" }
            Should -Invoke -CommandName Out-File -Times 3 -ParameterFilter { $FilePath -like "*\.augment\*" -or $FilePath -like "*\.vscode\*" }
            Should -Invoke -CommandName & -Times 0 -ParameterFilter { $args[0] -like "*optimize-augment-memories.ps1" }
        }
        
        It "Should start MCP servers if requested" {
            # Exécuter le script avec des paramètres spécifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                StartServers = $true
            }
            
            # Exécuter le script
            & $scriptPath @params
            
            # Vérifier que les fonctions ont été appelées
            Should -Invoke -CommandName Start-Process -Times 2
        }
    }
}
