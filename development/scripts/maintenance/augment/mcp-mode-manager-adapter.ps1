<#
.SYNOPSIS
    Adaptateur MCP pour le gestionnaire de modes.

.DESCRIPTION
    Ce script implÃ©mente un adaptateur MCP (Model Context Protocol) pour le gestionnaire de modes,
    permettant Ã  Augment d'interagir directement avec le gestionnaire de modes via le protocole MCP.

.PARAMETER Port
    Port sur lequel le serveur MCP doit Ã©couter. Par dÃ©faut : 7892.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\mcp-mode-manager-adapter.ps1
    # DÃ©marre l'adaptateur MCP pour le gestionnaire de modes sur le port par dÃ©faut

.EXAMPLE
    .\mcp-mode-manager-adapter.ps1 -Port 7893 -ConfigPath "config\custom-config.json"
    # DÃ©marre l'adaptateur MCP pour le gestionnaire de modes sur le port 7893 avec une configuration personnalisÃ©e

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$Port = 7892,

    [Parameter()]
    [string]$ConfigPath = "development\config\unified-config.json"
)

# DÃ©terminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de dÃ©terminer le chemin du projet."
        exit 1
    }
}

# Chemin vers le gestionnaire de modes
$modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\managers\mode-manager\scripts\mode-manager.ps1"
if (-not (Test-Path -Path $modeManagerPath)) {
    # Essayer un chemin alternatif
    $modeManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\mode-manager\mode-manager.ps1"
    if (-not (Test-Path -Path $modeManagerPath)) {
        Write-Error "Gestionnaire de modes introuvable."
        exit 1
    }
}

# Charger la configuration unifiÃ©e
$configPath = Join-Path -Path $projectRoot -ChildPath $ConfigPath
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        exit 1
    }
} else {
    Write-Warning "Le fichier de configuration est introuvable : $configPath"
    # CrÃ©er une configuration par dÃ©faut
    $config = [PSCustomObject]@{
        Modes = [PSCustomObject]@{
            Archi = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\archi-mode.ps1"
            }
            Check = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\check.ps1"
            }
            CBreak = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\c-break-mode.ps1"
            }
            Debug = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\debug\debug-mode.ps1"
            }
            DevR = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\dev-r\dev-r-mode.ps1"
            }
            Gran = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\gran-mode.ps1"
            }
            Opti = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\opti-mode.ps1"
            }
            Predic = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\predic-mode.ps1"
            }
            Review = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\review-mode.ps1"
            }
            Test = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\test\test-mode.ps1"
            }
        }
    }
}

# Fonction pour exÃ©cuter le gestionnaire de modes
function Invoke-ModeManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Construire les paramÃ¨tres pour le gestionnaire de modes
    $params = @{
        Mode = $Mode
    }

    if ($FilePath) {
        $params.FilePath = $FilePath
    }

    if ($TaskIdentifier) {
        $params.TaskIdentifier = $TaskIdentifier
    }

    if ($ConfigPath) {
        $params.ConfigPath = $ConfigPath
    }

    if ($Force) {
        $params.Force = $true
    }

    # ExÃ©cuter le gestionnaire de modes
    & $modeManagerPath @params
    return $LASTEXITCODE -eq 0
}

# Fonction pour obtenir la liste des modes disponibles
function Get-AvailableModes {
    [CmdletBinding()]
    param ()

    $modes = @{
        "ARCHI" = "Structurer, modÃ©liser, anticiper les dÃ©pendances"
        "CHECK" = "VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches"
        "C-BREAK" = "DÃ©tecter et rÃ©soudre les dÃ©pendances circulaires"
        "DEBUG" = "Isoler, comprendre, corriger les anomalies"
        "DEV-R" = "ImplÃ©menter ce qui est dans la roadmap"
        "GRAN" = "DÃ©composer les blocs complexes"
        "OPTI" = "RÃ©duire complexitÃ©, taille ou temps d'exÃ©cution"
        "PREDIC" = "Anticiper performances, dÃ©tecter anomalies, analyser tendances"
        "REVIEW" = "VÃ©rifier lisibilitÃ©, standards, documentation"
        "TEST" = "Maximiser couverture et fiabilitÃ©"
    }

    return $modes
}

# Fonction pour traiter les requÃªtes MCP
function Invoke-MCPRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RequestJson
    )

    try {
        # Convertir la requÃªte JSON en objet PowerShell
        $request = $RequestJson | ConvertFrom-Json

        # Extraire les informations de la requÃªte
        $method = $request.method
        $params = $request.params

        # Traiter la requÃªte en fonction de la mÃ©thode
        switch ($method) {
            "listModes" {
                # RÃ©cupÃ©rer la liste des modes disponibles
                $modes = Get-AvailableModes
                return @{
                    result = $modes
                    error = $null
                } | ConvertTo-Json -Depth 10
            }
            "executeMode" {
                # ExÃ©cuter un mode
                $mode = $params.mode
                $filePath = $params.filePath
                $taskIdentifier = $params.taskIdentifier
                $configPath = $params.configPath
                $force = $params.force -eq $true

                $result = Invoke-ModeManager -Mode $mode -FilePath $filePath -TaskIdentifier $taskIdentifier -ConfigPath $configPath -Force:$force
                return @{
                    result = @{
                        success = $result
                        mode = $mode
                    }
                    error = $null
                } | ConvertTo-Json
            }
            "getModeConfig" {
                # RÃ©cupÃ©rer la configuration d'un mode
                $mode = $params.mode
                $modeKey = $mode -replace "-", ""
                
                if ($config.Modes.PSObject.Properties.Name -contains $modeKey) {
                    $modeConfig = $config.Modes.$modeKey
                    return @{
                        result = $modeConfig
                        error = $null
                    } | ConvertTo-Json -Depth 10
                } else {
                    return @{
                        result = $null
                        error = @{
                            code = -32602
                            message = "Mode non reconnu : $mode"
                        }
                    } | ConvertTo-Json
                }
            }
            "executeChain" {
                # ExÃ©cuter une chaÃ®ne de modes
                $chain = $params.chain
                $filePath = $params.filePath
                $taskIdentifier = $params.taskIdentifier
                $configPath = $params.configPath
                $force = $params.force -eq $true

                $modes = $chain -split ',' | ForEach-Object { $_.Trim() }
                $results = @{}

                foreach ($mode in $modes) {
                    $result = Invoke-ModeManager -Mode $mode -FilePath $filePath -TaskIdentifier $taskIdentifier -ConfigPath $configPath -Force:$force
                    $results[$mode] = $result

                    if (-not $result) {
                        break
                    }
                }

                return @{
                    result = @{
                        success = $results.Values | Where-Object { -not $_ } | Measure-Object | Select-Object -ExpandProperty Count -eq 0
                        results = $results
                    }
                    error = $null
                } | ConvertTo-Json -Depth 10
            }
            default {
                # MÃ©thode non reconnue
                return @{
                    result = $null
                    error = @{
                        code = -32601
                        message = "MÃ©thode non reconnue : $method"
                    }
                } | ConvertTo-Json
            }
        }
    } catch {
        # Erreur lors du traitement de la requÃªte
        return @{
            result = $null
            error = @{
                code = -32603
                message = "Erreur interne : $_"
            }
        } | ConvertTo-Json
    }
}

# Fonction pour dÃ©marrer le serveur MCP
function Start-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    try {
        # CrÃ©er un Ã©couteur TCP
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()

        Write-Host "Adaptateur MCP pour le gestionnaire de modes dÃ©marrÃ© sur le port $Port" -ForegroundColor Green
        Write-Host "Appuyez sur Ctrl+C pour arrÃªter le serveur" -ForegroundColor Yellow

        # Boucle principale du serveur
        while ($true) {
            # Attendre une connexion
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            # Lire la requÃªte
            $requestJson = $reader.ReadLine()

            # Traiter la requÃªte
            $responseJson = Invoke-MCPRequest -RequestJson $requestJson

            # Envoyer la rÃ©ponse
            $writer.WriteLine($responseJson)

            # Fermer la connexion
            $reader.Close()
            $writer.Close()
            $client.Close()
        }
    } catch {
        Write-Error "Erreur lors du dÃ©marrage du serveur MCP : $_"
    } finally {
        # ArrÃªter l'Ã©couteur
        if ($listener) {
            $listener.Stop()
        }
    }
}

# DÃ©marrer le serveur MCP
Start-MCPServer -Port $Port

