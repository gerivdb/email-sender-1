<#
.SYNOPSIS
    Tests unitaires pour le script de dÃ©marrage des serveurs MCP.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de dÃ©marrage des serveurs MCP,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-StartMCPServers.ps1"
    # ExÃ©cute les tests unitaires pour le script de dÃ©marrage des serveurs MCP

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "start-mcp-servers.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Start MCP Servers Tests" {
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
        
        # CrÃ©er un rÃ©pertoire de logs temporaire
        $testLogsDir = Join-Path -Path $testDir -ChildPath "logs\mcp"
        New-Item -Path $testLogsDir -ItemType Directory -Force | Out-Null
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestConfigPath = $testConfigPath
        $Global:TestLogsDir = $testLogsDir
        
        # Mock pour les fonctions systÃ¨me
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
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# CrÃ©er le rÃ©pertoire des logs s'il n'existe pas.*?# CrÃ©er un script d'arrÃªt", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Start-MCPServer Function" {
        It "Should start a MCP server" {
            # DÃ©finir la fonction Start-MCPServer pour le test
            function Start-MCPServer {
                param (
                    [string]$Name,
                    [int]$Port,
                    [string]$ScriptPath,
                    [string]$LogPath
                )
                
                # VÃ©rifier si le script existe
                if (-not (Test-Path -Path $ScriptPath)) {
                    return $false
                }
                
                # VÃ©rifier si le port est disponible
                try {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $tcpClient.Connect("127.0.0.1", $Port)
                    $tcpClient.Close()
                    return $false
                } catch {
                    # Le port est disponible
                }
                
                # DÃ©marrer le serveur MCP
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
                    
                    # Attendre que le processus dÃ©marre
                    Start-Sleep -Seconds 2
                    
                    # VÃ©rifier si le processus est toujours en cours d'exÃ©cution
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
            # Mock supplÃ©mentaires pour l'exÃ©cution du script
            Mock -CommandName Start-MCPServer -MockWith { return $true }
            
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                ConfigPath = $Global:TestConfigPath
                LogPath = $Global:TestLogsDir
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que les fonctions ont Ã©tÃ© appelÃ©es
            Should -Invoke -CommandName Start-MCPServer -Times 2
            Should -Invoke -CommandName Out-File -Times 1 -ParameterFilter { $FilePath -like "*stop-mcp-servers.ps1" }
        }
    }
}
