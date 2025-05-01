<#
.SYNOPSIS
    Tests unitaires pour le script de démarrage des serveurs MCP.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de démarrage des serveurs MCP,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-StartMCPServers.ps1"
    # Exécute les tests unitaires pour le script de démarrage des serveurs MCP

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "start-mcp-servers.ps1"

# Déterminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Start MCP Servers Tests" {
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
        
        # Créer un répertoire de logs temporaire
        $testLogsDir = Join-Path -Path $testDir -ChildPath "logs\mcp"
        New-Item -Path $testLogsDir -ItemType Directory -Force | Out-Null
        
        # Définir des variables globales pour les tests
        $Global:TestConfigPath = $testConfigPath
        $Global:TestLogsDir = $testLogsDir
        
        # Mock pour les fonctions système
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Diagnostics.ProcessStartInfo" } -MockWith {
            return [PSCustomObject]@{
                FileName = "powershell"
                Arguments = ""
                WorkingDirectory = ""
                RedirectStandardOutput = $false
                RedirectStandardError = $false
                UseShellExecute = $true
                CreateNoWindow = $false
            }
        }
        
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Diagnostics.Process" } -MockWith {
            return [PSCustomObject]@{
                StartInfo = $null
                Start = { return $true }
                Id = 12345
                HasExited = $false
                StandardOutput = [PSCustomObject]@{
                    ReadToEndAsync = { return [PSCustomObject]@{ Result = "Output" } }
                }
                StandardError = [PSCustomObject]@{
                    ReadToEndAsync = { return [PSCustomObject]@{ Result = "Error" } }
                }
            }
        }
        
        Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "System.Net.Sockets.TcpClient" } -MockWith {
            throw "Connection refused"
        }
        
        Mock -CommandName Start-Sleep -MockWith { return $null }
        Mock -CommandName Out-File -MockWith { return $true }
        Mock -CommandName Test-Path -MockWith { return $true }
        Mock -CommandName Get-Content -MockWith { return $testConfigContent }
        Mock -CommandName ConvertFrom-Json -MockWith { 
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
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestConfigPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestLogsDir -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # Vérifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour éviter d'exécuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exécute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Créer le répertoire des logs s'il n'existe pas.*?# Créer un script d'arrêt", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # Exécuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Start-MCPServer Function" {
        It "Should start a MCP server" {
            # Définir la fonction Start-MCPServer pour le test
            function Start-MCPServer {
                param (
                    [string]$Name,
                    [int]$Port,
                    [string]$ScriptPath,
                    [string]$LogPath
                )
                
                # Vérifier si le script existe
                if (-not (Test-Path -Path $ScriptPath)) {
                    return $false
                }
                
                # Vérifier si le port est disponible
                try {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $tcpClient.Connect("127.0.0.1", $Port)
                    $tcpClient.Close()
                    return $false
                } catch {
                    # Le port est disponible
                }
                
                # Démarrer le serveur MCP
                try {
                    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $startInfo.FileName = "powershell"
                    $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Port $Port"
                    $startInfo.WorkingDirectory = $projectRoot
                    $startInfo.RedirectStandardOutput = $true
                    $startInfo.RedirectStandardError = $true
                    $startInfo.UseShellExecute = $false
                    $startInfo.CreateNoWindow = $true
                    
                    $process = New-Object System.Diagnostics.Process
                    $process.StartInfo = $startInfo
                    $process.Start() | Out-Null
                    
                    # Attendre que le processus démarre
                    Start-Sleep -Seconds 2
                    
                    # Vérifier si le processus est toujours en cours d'exécution
                    if ($process.HasExited) {
                        return $false
                    }
                    
                    # Enregistrer le PID du processus
                    $pid = $process.Id
                    $pidFile = Join-Path -Path $LogPath -ChildPath "$Name.pid"
                    $pid | Out-File -FilePath $pidFile -Encoding UTF8
                    
                    return $true
                } catch {
                    return $false
                }
            }
            
            # Tester la fonction
            $result = Start-MCPServer -Name "test" -Port 7891 -ScriptPath "$scriptRoot\mcp-memories-server.ps1" -LogPath $Global:TestLogsDir
            $result | Should -Be $true
        }
    }
    
    Context "Script Execution" {
        It "Should start all MCP servers" {
            # Mock supplémentaires pour l'exécution du script
            Mock -CommandName Start-MCPServer -MockWith { return $true }
            
            # Exécuter le script avec des paramètres spécifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                LogPath = $Global:TestLogsDir
            }
            
            # Exécuter le script
            & $scriptPath @params
            
            # Vérifier que les fonctions ont été appelées
            Should -Invoke -CommandName Start-MCPServer -Times 2
            Should -Invoke -CommandName Out-File -Times 1 -ParameterFilter { $FilePath -like "*stop-mcp-servers.ps1" }
        }
    }
}
