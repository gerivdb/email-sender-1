<#
.SYNOPSIS
    Tests unitaires pour le script d'intÃ©gration avec le MCP Manager.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script d'intÃ©gration avec le MCP Manager,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-IntegrateWithMCPManager.ps1"
    # ExÃ©cute les tests unitaires pour le script d'intÃ©gration avec le MCP Manager

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "integrate-with-mcp-manager.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Integrate With MCP Manager Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "mcp"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de configuration du MCP Manager temporaire
        $testMcpManagerPath = Join-Path -Path $testDir -ChildPath "MCPManager.psm1"
        $testMcpManagerContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des serveurs MCP (Model Context Protocol).
.DESCRIPTION
    Ce module fournit des fonctions pour dÃ©tecter, configurer et gÃ©rer les serveurs MCP
    (Model Context Protocol) pour une intÃ©gration transparente avec les outils d'IA.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-01
#>

# Variables globales
`$script:ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
`$script:MCPServersDir = Join-Path -Path `$script:ProjectRoot -ChildPath "mcp-servers"
`$script:ConfigPath = Join-Path -Path `$script:MCPServersDir -ChildPath "mcp-config.json"
`$script:DetectedServersPath = Join-Path -Path `$script:MCPServersDir -ChildPath "detected.json"

# Configuration de base
`$config = @{
    mcpServers = @{
        filesystem = @{
            command = "npx"
            args    = @("@modelcontextprotocol/server-filesystem", `$script:ProjectRoot)
        }
    }
}

# Ajouter le serveur GitHub s'il est configurÃ©
`$githubConfig = Join-Path -Path `$script:MCPServersDir -ChildPath "github\config.json"
if (Test-Path -Path `$githubConfig) {
    `$config.mcpServers.github = @{
        command = "npx"
        args    = @("@modelcontextprotocol/server-github", "--config", `$githubConfig)
    }
}

# Ajouter le serveur GCP s'il est configurÃ©
`$gcpToken = Join-Path -Path `$script:MCPServersDir -ChildPath "gcp\token.json"
if (Test-Path -Path `$gcpToken) {
    `$config.mcpServers.gcp = @{
        command = "npx"
        args    = @("gcp-mcp")
        env     = @{
            GOOGLE_APPLICATION_CREDENTIALS = `$gcpToken
        }
    }
}

# Fonction pour dÃ©tecter les serveurs MCP
function Get-MCPServers {
    [CmdletBinding()]
    param ()
    
    # Code de la fonction
}
"@
        $testMcpManagerContent | Out-File -FilePath $testMcpManagerPath -Encoding UTF8
        
        # CrÃ©er un rÃ©pertoire pour les serveurs MCP
        $testMcpServersDir = Join-Path -Path $testDir -ChildPath "mcp-servers"
        New-Item -Path $testMcpServersDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de configuration MCP temporaire
        $testMcpConfigPath = Join-Path -Path $testMcpServersDir -ChildPath "mcp-config.json"
        $testMcpConfigContent = @{
            mcpServers = @{
                filesystem = @{
                    command = "npx"
                    args = @("@modelcontextprotocol/server-filesystem", "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1")
                }
            }
        } | ConvertTo-Json -Depth 10
        $testMcpConfigContent | Out-File -FilePath $testMcpConfigPath -Encoding UTF8
        
        # CrÃ©er un script de dÃ©marrage de tous les serveurs MCP temporaire
        $testStartAllMcpServersPath = Join-Path -Path $testDir -ChildPath "start-all-mcp-servers.ps1"
        $testStartAllMcpServersContent = @"
# Chemin du rÃ©pertoire racine du projet
`$projectRoot = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\"
`$projectRoot = (Resolve-Path `$projectRoot).Path

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "      DÃ‰MARRAGE DES SERVEURS MCP POUR EMAIL_SENDER_1     " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. DÃ©marrer le serveur MCP Filesystem
Write-Host "1. DÃ©marrage du serveur MCP Filesystem..." -ForegroundColor Cyan
`$filesystemSuccess = Start-McpServer -Name "Filesystem" -Command "npx" -Arguments @("@modelcontextprotocol/server-filesystem", `$projectRoot)
"@
        $testStartAllMcpServersContent | Out-File -FilePath $testStartAllMcpServersPath -Encoding UTF8
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestMcpManagerPath = $testMcpManagerPath
        $Global:TestMcpConfigPath = $testMcpConfigPath
        $Global:TestStartAllMcpServersPath = $testStartAllMcpServersPath
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestMcpManagerPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestMcpConfigPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestStartAllMcpServersPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Lire le contenu du fichier de configuration du MCP Manager.*?# Mettre Ã  jour le script de dÃ©marrage de tous les serveurs MCP", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "MCP Manager Integration" {
        It "Should update the MCP Manager configuration" {
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                ConfigPath = $Global:TestMcpManagerPath
                Force = $true
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que le fichier a Ã©tÃ© mis Ã  jour
            $updatedContent = Get-Content -Path $Global:TestMcpManagerPath -Raw
            $updatedContent | Should -Match "augment-memories"
            $updatedContent | Should -Match "augment-mode-manager"
            $updatedContent | Should -Match "development\\scripts\\maintenance\\augment\\mcp-memories-server.ps1"
            $updatedContent | Should -Match "development\\scripts\\maintenance\\augment\\mcp-mode-manager-adapter.ps1"
        }
        
        It "Should update the MCP configuration file" {
            # VÃ©rifier que le fichier a Ã©tÃ© mis Ã  jour
            $updatedConfig = Get-Content -Path $Global:TestMcpConfigPath -Raw | ConvertFrom-Json
            $updatedConfig.mcpServers.PSObject.Properties.Name | Should -Contain "augment-memories"
            $updatedConfig.mcpServers.PSObject.Properties.Name | Should -Contain "augment-mode-manager"
            $updatedConfig.mcpServers."augment-memories".command | Should -Be "powershell"
            $updatedConfig.mcpServers."augment-mode-manager".command | Should -Be "powershell"
        }
        
        It "Should update the start-all-mcp-servers script" {
            # VÃ©rifier que le fichier a Ã©tÃ© mis Ã  jour
            $updatedContent = Get-Content -Path $Global:TestStartAllMcpServersPath -Raw
            $updatedContent | Should -Match "Augment Memories"
            $updatedContent | Should -Match "Augment Mode Manager"
            $updatedContent | Should -Match "development\\scripts\\maintenance\\augment\\mcp-memories-server.ps1"
            $updatedContent | Should -Match "development\\scripts\\maintenance\\augment\\mcp-mode-manager-adapter.ps1"
        }
    }
}
