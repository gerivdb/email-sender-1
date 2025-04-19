#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour le module MCPClient.
.DESCRIPTION
    Ce script contient les tests d'intégration pour le module MCPClient.
    Il vérifie que le module peut se connecter à un serveur MCP réel et exécuter des opérations.
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

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module MCPClient.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Configuration de Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Output.Verbosity = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\test_reports\MCPClient.Integration.Tests.xml"
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $modulePath
$pesterConfig.CodeCoverage.OutputPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\test_reports\MCPClient.Integration.Coverage.xml"
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'

# Variables globales pour les tests
$script:serverProcess = $null
$script:serverPort = 8000
$script:serverUrl = "http://localhost:$script:serverPort"

# Définir les tests
Describe "MCPClient Integration Tests" {
    BeforeAll {
        # Démarrer le serveur MCP de test
        $serverScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\scripts\python\minimal_mcp_server.py"
        
        if (-not (Test-Path -Path $serverScriptPath)) {
            throw "Le script du serveur MCP de test n'existe pas à l'emplacement spécifié: $serverScriptPath"
        }
        
        Write-Host "Démarrage du serveur MCP de test sur $script:serverUrl..." -ForegroundColor Cyan
        
        # Vérifier si Python est installé
        try {
            $pythonVersion = python --version
            Write-Host "Python détecté: $pythonVersion" -ForegroundColor Green
        } catch {
            throw "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.8 ou supérieur."
        }
        
        # Vérifier si le package mcp est installé
        try {
            python -c "import mcp" 2>$null
            Write-Host "Package mcp détecté" -ForegroundColor Green
        } catch {
            Write-Warning "Le package mcp n'est pas installé. Installation en cours..."
            python -m pip install mcp
        }
        
        # Démarrer le serveur MCP en arrière-plan
        $script:serverProcess = Start-Process -FilePath "python" -ArgumentList $serverScriptPath -PassThru -NoNewWindow
        
        # Attendre que le serveur soit prêt
        Write-Host "Attente du démarrage du serveur MCP..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Vérifier que le serveur est en cours d'exécution
        if ($script:serverProcess.HasExited) {
            throw "Le serveur MCP de test n'a pas pu démarrer. Vérifiez les logs pour plus d'informations."
        }
        
        Write-Host "Serveur MCP de test démarré avec le PID $($script:serverProcess.Id)" -ForegroundColor Green
        
        # Initialiser la connexion au serveur MCP
        Initialize-MCPConnection -ServerUrl $script:serverUrl
    }
    
    AfterAll {
        # Arrêter le serveur MCP de test
        if ($script:serverProcess -and -not $script:serverProcess.HasExited) {
            Write-Host "Arrêt du serveur MCP de test..." -ForegroundColor Yellow
            Stop-Process -Id $script:serverProcess.Id -Force
            Write-Host "Serveur MCP de test arrêté" -ForegroundColor Green
        }
    }
    
    Context "Connexion au serveur MCP" {
        It "Devrait se connecter au serveur MCP" {
            $result = Initialize-MCPConnection -ServerUrl $script:serverUrl
            $result | Should -Be $true
            
            $config = Get-MCPClientConfiguration
            $config.ServerUrl | Should -Be $script:serverUrl
        }
    }
    
    Context "Récupération des outils disponibles" {
        It "Devrait récupérer la liste des outils disponibles" {
            $tools = Get-MCPTools
            $tools | Should -Not -BeNullOrEmpty
            
            # Vérifier que l'outil 'add' est disponible
            $addTool = $tools | Where-Object { $_.name -eq "add" }
            $addTool | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Exécution d'outils" {
        It "Devrait exécuter l'outil 'add' correctement" {
            $result = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be 5
        }
        
        It "Devrait exécuter l'outil 'get_hello' correctement" {
            $result = Invoke-MCPTool -ToolName "get_hello" -Parameters @{}
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Be "Hello from MCP Server!"
        }
    }
    
    Context "Mise en cache" {
        It "Devrait mettre en cache les résultats des outils" {
            # Activer le cache
            Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 60
            
            # Exécuter l'outil une première fois
            $result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 5; b = 7 }
            $result1 | Should -Be 12
            
            # Exécuter l'outil une deuxième fois (devrait utiliser le cache)
            $result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 5; b = 7 }
            $result2 | Should -Be 12
            
            # Vérifier que le cache contient l'entrée
            $config = Get-MCPClientConfiguration
            $config.CacheEnabled | Should -Be $true
            
            # Nettoyer le cache
            Clear-MCPCache -Force
        }
        
        It "Devrait ignorer le cache avec l'option NoCache" {
            # Activer le cache
            Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 60
            
            # Exécuter l'outil une première fois
            $result1 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 8; b = 9 }
            $result1 | Should -Be 17
            
            # Exécuter l'outil une deuxième fois avec NoCache
            $result2 = Invoke-MCPTool -ToolName "add" -Parameters @{ a = 8; b = 9 } -NoCache
            $result2 | Should -Be 17
            
            # Nettoyer le cache
            Clear-MCPCache -Force
        }
    }
    
    Context "Traitement parallèle" {
        It "Devrait exécuter plusieurs outils en parallèle" {
            # Définir les outils à exécuter en parallèle
            $toolNames = @("add", "add", "get_hello")
            $parametersList = @(
                @{ a = 1; b = 2 },
                @{ a = 3; b = 4 },
                @{}
            )
            
            # Exécuter les outils en parallèle
            $results = Invoke-MCPToolParallel -ToolNames $toolNames -ParametersList $parametersList
            
            # Vérifier les résultats
            $results.Count | Should -Be 3
            $results[0] | Should -Be 3
            $results[1] | Should -Be 7
            $results[2] | Should -Be "Hello from MCP Server!"
        }
    }
    
    Context "Traitement par lots" {
        It "Devrait traiter des données par lots" {
            # Créer des objets d'entrée
            $inputObjects = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    A = $_
                    B = $_ * 2
                }
            }
            
            # Définir le script block pour traiter chaque lot
            $scriptBlock = {
                param($batch)
                
                $results = @()
                foreach ($item in $batch) {
                    $result = Invoke-MCPTool -ToolName "add" -Parameters @{
                        a = $item.A
                        b = $item.B
                    }
                    
                    $results += [PSCustomObject]@{
                        Input = $item
                        Output = $result
                    }
                }
                
                return $results
            }
            
            # Traiter les objets par lots
            $results = Invoke-MCPBatch -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize 2
            
            # Vérifier les résultats
            $results.Count | Should -Be 5
            $results[0].Output | Should -Be 3  # 1 + 2
            $results[1].Output | Should -Be 6  # 2 + 4
            $results[2].Output | Should -Be 9  # 3 + 6
            $results[3].Output | Should -Be 12 # 4 + 8
            $results[4].Output | Should -Be 15 # 5 + 10
        }
    }
}

# Exécuter les tests
Invoke-Pester -Configuration $pesterConfig
