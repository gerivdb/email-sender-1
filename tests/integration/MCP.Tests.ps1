#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour les serveurs MCP.
.DESCRIPTION
    Ce script contient des tests d'intégration pour vérifier que les serveurs MCP
    fonctionnent correctement et peuvent être utilisés par les modules PowerShell.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-21
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Importer les modules à tester
$mcpManagerPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPManager.psm1"
$mcpClientPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier que les modules existent
if (-not (Test-Path -Path $mcpManagerPath)) {
    throw "Le module MCPManager.psm1 n'existe pas à l'emplacement spécifié: $mcpManagerPath"
}

if (-not (Test-Path -Path $mcpClientPath)) {
    throw "Le module MCPClient.psm1 n'existe pas à l'emplacement spécifié: $mcpClientPath"
}

# Importer les modules
Import-Module $mcpManagerPath -Force
Import-Module $mcpClientPath -Force

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\test_reports\MCP.Tests.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Variables globales pour les tests
$script:serverProcess = $null
$script:serverPort = 8000
$script:serverUrl = "http://localhost:$script:serverPort"

# Définir les tests
Describe "MCP Integration Tests" {
    BeforeAll {
        # Démarrer un serveur MCP local pour les tests
        Write-Host "Démarrage d'un serveur MCP local pour les tests..." -ForegroundColor Cyan
        
        $script:serverProcess = Start-MCPServer -ServerType "local" -Port $script:serverPort -Wait:$false
        
        # Attendre que le serveur soit prêt
        Write-Host "Attente du démarrage du serveur MCP..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Initialiser la connexion au serveur MCP
        Initialize-MCPConnection -ServerUrl $script:serverUrl
    }
    
    AfterAll {
        # Arrêter le serveur MCP
        if ($script:serverProcess) {
            Write-Host "Arrêt du serveur MCP..." -ForegroundColor Yellow
            Stop-MCPServer -ServerType "local" -Port $script:serverPort
            Write-Host "Serveur MCP arrêté" -ForegroundColor Green
        }
    }
    
    Context "MCPManager" {
        It "Devrait détecter les serveurs MCP" {
            $servers = Find-MCPServers
            $servers | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait créer une configuration MCP" {
            $configPath = Join-Path -Path $env:TEMP -ChildPath "mcp-config-test.json"
            $result = New-MCPConfiguration -OutputPath $configPath -Force
            $result | Should -Be $true
            Test-Path -Path $configPath | Should -Be $true
            
            # Nettoyer
            if (Test-Path -Path $configPath) {
                Remove-Item -Path $configPath -Force
            }
        }
    }
    
    Context "MCPClient" {
        It "Devrait se connecter au serveur MCP" {
            $result = Initialize-MCPConnection -ServerUrl $script:serverUrl
            $result | Should -Be $true
            
            $config = Get-MCPClientConfiguration
            $config.ServerUrl | Should -Be $script:serverUrl
        }
        
        It "Devrait récupérer la liste des outils disponibles" {
            $tools = Get-MCPTools
            $tools | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait exécuter un outil MCP" {
            # Vérifier que l'outil 'add' est disponible
            $tools = Get-MCPTools
            $addTool = $tools | Where-Object { $_.name -eq "add" }
            
            if ($addTool) {
                $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
                $result | Should -Not -BeNullOrEmpty
                $result | Should -Be 5
            } else {
                Set-ItResult -Skipped -Because "L'outil 'add' n'est pas disponible sur ce serveur MCP"
            }
        }
    }
    
    Context "Intégration MCPManager et MCPClient" {
        It "Devrait démarrer un serveur MCP et s'y connecter" {
            # Arrêter le serveur existant
            if ($script:serverProcess) {
                Stop-MCPServer -ServerType "local" -Port $script:serverPort
            }
            
            # Démarrer un nouveau serveur sur un port différent
            $newPort = 8001
            $newServerUrl = "http://localhost:$newPort"
            
            $newServerProcess = Start-MCPServer -ServerType "local" -Port $newPort -Wait:$false
            
            # Attendre que le serveur soit prêt
            Start-Sleep -Seconds 5
            
            # Initialiser la connexion au nouveau serveur
            $result = Initialize-MCPConnection -ServerUrl $newServerUrl
            $result | Should -Be $true
            
            # Vérifier que la connexion est établie
            $config = Get-MCPClientConfiguration
            $config.ServerUrl | Should -Be $newServerUrl
            
            # Récupérer la liste des outils
            $tools = Get-MCPTools
            $tools | Should -Not -BeNullOrEmpty
            
            # Arrêter le nouveau serveur
            Stop-MCPServer -ServerType "local" -Port $newPort
            
            # Redémarrer le serveur original
            $script:serverProcess = Start-MCPServer -ServerType "local" -Port $script:serverPort -Wait:$false
            
            # Attendre que le serveur soit prêt
            Start-Sleep -Seconds 5
            
            # Réinitialiser la connexion au serveur original
            Initialize-MCPConnection -ServerUrl $script:serverUrl
        }
    }
    
    Context "Performances" {
        It "Devrait mettre en cache les résultats des outils" {
            # Activer le cache
            Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 60
            
            # Exécuter l'outil une première fois
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 5; b = 7 }
            $stopwatch1.Stop()
            $time1 = $stopwatch1.ElapsedMilliseconds
            
            $result1 | Should -Be 12
            
            # Exécuter l'outil une deuxième fois (devrait utiliser le cache)
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 5; b = 7 }
            $stopwatch2.Stop()
            $time2 = $stopwatch2.ElapsedMilliseconds
            
            $result2 | Should -Be 12
            
            # Le deuxième appel devrait être plus rapide
            Write-Host "Premier appel: $time1 ms, Deuxième appel: $time2 ms" -ForegroundColor Cyan
            
            # Nettoyer le cache
            Clear-MCPCache -Force
        }
        
        It "Devrait exécuter plusieurs outils en parallèle" {
            # Définir les outils à exécuter en parallèle
            $toolNames = @("add", "add")
            $parametersList = @(
                @{ a = 1; b = 2 },
                @{ a = 3; b = 4 }
            )
            
            # Exécuter les outils en parallèle
            $stopwatch1 = [System.Diagnostics.Stopwatch]::StartNew()
            $results = Invoke-MCPToolParallel -ToolNames $toolNames -ParametersList $parametersList
            $stopwatch1.Stop()
            $timeParallel = $stopwatch1.ElapsedMilliseconds
            
            # Exécuter les outils en séquentiel
            $stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()
            $result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 1; b = 2 }
            $result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 3; b = 4 }
            $stopwatch2.Stop()
            $timeSequential = $stopwatch2.ElapsedMilliseconds
            
            # Vérifier les résultats
            $results.Count | Should -Be 2
            $results[0] | Should -Be 3
            $results[1] | Should -Be 7
            
            # L'exécution parallèle devrait être plus rapide
            Write-Host "Exécution parallèle: $timeParallel ms, Exécution séquentielle: $timeSequential ms" -ForegroundColor Cyan
        }
    }
}

# Exécuter les tests
Invoke-Pester -Configuration $pesterConfig
