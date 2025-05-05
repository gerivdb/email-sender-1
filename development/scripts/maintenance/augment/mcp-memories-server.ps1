<#
.SYNOPSIS
    Serveur MCP dÃ©diÃ© Ã  la gestion des Memories d'Augment.

.DESCRIPTION
    Ce script implÃ©mente un serveur MCP (Model Context Protocol) dÃ©diÃ© Ã  la gestion
    des Memories d'Augment. Il permet d'exposer des fonctionnalitÃ©s de gestion des
    Memories via le protocole MCP, ce qui permet Ã  Augment d'y accÃ©der directement.

.PARAMETER Port
    Port sur lequel le serveur MCP doit Ã©couter. Par dÃ©faut : 7891.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut : "development\config\unified-config.json".

.EXAMPLE
    .\mcp-memories-server.ps1
    # DÃ©marre le serveur MCP pour les Memories sur le port par dÃ©faut

.EXAMPLE
    .\mcp-memories-server.ps1 -Port 7892 -ConfigPath "config\custom-config.json"
    # DÃ©marre le serveur MCP pour les Memories sur le port 7892 avec une configuration personnalisÃ©e

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$Port = 7891,

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

# Importer le module AugmentMemoriesManager
$memoriesManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentMemoriesManager.ps1"
if (Test-Path -Path $memoriesManagerPath) {
    . $memoriesManagerPath
} else {
    Write-Error "Module AugmentMemoriesManager introuvable : $memoriesManagerPath"
    exit 1
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
        Augment = [PSCustomObject]@{
            Memories = [PSCustomObject]@{
                Enabled = $true
                UpdateFrequency = "Daily"
                MaxSizeKB = 5
                AutoSegmentation = $true
                VSCodeWorkspaceId = "224ad75ce65ce8cf2efd9efc61d3c988"
            }
        }
    }
}

# Fonction pour traiter les requÃªtes MCP
function Process-MCPRequest {
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
            "getMemories" {
                # RÃ©cupÃ©rer les Memories
                $memories = Get-AugmentMemories
                return @{
                    result = $memories
                    error = $null
                } | ConvertTo-Json -Depth 10
            }
            "updateMemories" {
                # Mettre Ã  jour les Memories
                $content = $params.content
                $result = Update-AugmentMemories -Content $content
                return @{
                    result = $result
                    error = $null
                } | ConvertTo-Json
            }
            "splitInput" {
                # Diviser un input en segments
                $input = $params.input
                $maxSize = if ($params.maxSize) { $params.maxSize } else { 3000 }
                $segments = Split-LargeInput -Input $input -MaxSize $maxSize
                return @{
                    result = @{
                        segments = $segments
                        count = $segments.Count
                    }
                    error = $null
                } | ConvertTo-Json -Depth 10
            }
            "exportToVSCode" {
                # Exporter les Memories vers VS Code
                $workspaceId = if ($params.workspaceId) { $params.workspaceId } else { $config.Augment.Memories.VSCodeWorkspaceId }
                $result = Export-MemoriesToVSCode -WorkspaceId $workspaceId
                return @{
                    result = $result
                    error = $null
                } | ConvertTo-Json
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

        Write-Host "Serveur MCP pour les Memories dÃ©marrÃ© sur le port $Port" -ForegroundColor Green
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
            $responseJson = Process-MCPRequest -RequestJson $requestJson

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

# Fonction pour obtenir les Memories actuelles
function Get-AugmentMemories {
    [CmdletBinding()]
    param ()

    # GÃ©nÃ©rer les Memories
    $memories = @{
        "version"     = "2.0.0"
        "lastUpdated" = (Get-Date).ToString("o")
        "sections"    = @(
            @{
                "name"    = "Autonomie"
                "content" = @"
- Progression: ExÃ©cuter les tÃ¢ches sÃ©quentiellement sans confirmation
- DÃ©cision: Utiliser heuristiques (% complÃ©tÃ© > 80% â†’ tÃ¢che terminÃ©e)
- RÃ©silience: Reprendre sur erreur avec journalisation minimale
- Estimation: Calculer complexitÃ© via mÃ©triques objectives (LOC, dÃ©pendances, patterns)
"@
            },
            @{
                "name"    = "Communication"
                "content" = @"
- Format: Structure prÃ©dÃ©finie avec ratio info/verbositÃ© maximal
- SynthÃ¨se: Uniquement diffÃ©rences importantes et dÃ©cisions clÃ©s
- MÃ©tadonnÃ©es: Attacher % complÃ©tion et score de complexitÃ©
- Langage: FranÃ§ais concis avec notation algorithmique optionnelle
"@
            },
            @{
                "name"    = "Optimisation IA"
                "content" = @"
- One-Shot: Une fonction complÃ¨te par appel
- Progression: Pas de confirmation pour l'Ã©tape suivante
- MÃ©trique: Ratio complexitÃ©/taille â†’ optimiser dÃ©coupage
- Adaptation: Si feedback ou latence â†’ ajuster granularitÃ©
- Split: PrÃ©-dÃ©couper si anticipation d'Ã©chec
"@
            },
            @{
                "name"    = "Modes"
                "content" = @"
- GRAN: DÃ©composer les blocs complexes directement dans le document
- DEV-R: ImplÃ©menter les tÃ¢ches sÃ©quentiellement avec tests
- CHECK: VÃ©rifier l'implÃ©mentation et mettre Ã  jour la roadmap
- ARCHI: Structurer, modÃ©liser, anticiper les dÃ©pendances
- DEBUG: Isoler, comprendre, corriger les anomalies
"@
            },
            @{
                "name"    = "IntÃ©gritÃ©"
                "content" = @"
- ASSERT: TÃ¢che complÃ¨te â‡’ if(verified==TRUE)
- ASSERT: Liste fichiers â‡’ if(files_created==TRUE)
- IF(error || user_fix): ACK + FIX(no_justif)
- SEPARATE: actual={code,files}, potential={suggest}
- FORMAT: [IMPLEMENTED]=ok, [SUGGESTED]=idea, [INCOMPLETE]=partial
"@
            }
        )
    }

    return $memories
}

# DÃ©marrer le serveur MCP
Start-MCPServer -Port $Port
