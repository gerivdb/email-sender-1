<#
.SYNOPSIS
    Serveur MCP dédié à la gestion des Memories d'Augment.

.DESCRIPTION
    Ce script implémente un serveur MCP (Model Context Protocol) dédié à la gestion
    des Memories d'Augment. Il permet d'exposer des fonctionnalités de gestion des
    Memories via le protocole MCP, ce qui permet à Augment d'y accéder directement.

.PARAMETER Port
    Port sur lequel le serveur MCP doit écouter. Par défaut : 7891.

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut : "development\config\unified-config.json".

.EXAMPLE
    .\mcp-memories-server.ps1
    # Démarre le serveur MCP pour les Memories sur le port par défaut

.EXAMPLE
    .\mcp-memories-server.ps1 -Port 7892 -ConfigPath "config\custom-config.json"
    # Démarre le serveur MCP pour les Memories sur le port 7892 avec une configuration personnalisée

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

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
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

# Charger la configuration unifiée
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
    # Créer une configuration par défaut
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

# Fonction pour traiter les requêtes MCP
function Process-MCPRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RequestJson
    )

    try {
        # Convertir la requête JSON en objet PowerShell
        $request = $RequestJson | ConvertFrom-Json

        # Extraire les informations de la requête
        $method = $request.method
        $params = $request.params

        # Traiter la requête en fonction de la méthode
        switch ($method) {
            "getMemories" {
                # Récupérer les Memories
                $memories = Get-AugmentMemories
                return @{
                    result = $memories
                    error = $null
                } | ConvertTo-Json -Depth 10
            }
            "updateMemories" {
                # Mettre à jour les Memories
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
                # Méthode non reconnue
                return @{
                    result = $null
                    error = @{
                        code = -32601
                        message = "Méthode non reconnue : $method"
                    }
                } | ConvertTo-Json
            }
        }
    } catch {
        # Erreur lors du traitement de la requête
        return @{
            result = $null
            error = @{
                code = -32603
                message = "Erreur interne : $_"
            }
        } | ConvertTo-Json
    }
}

# Fonction pour démarrer le serveur MCP
function Start-MCPServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    try {
        # Créer un écouteur TCP
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()

        Write-Host "Serveur MCP pour les Memories démarré sur le port $Port" -ForegroundColor Green
        Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Yellow

        # Boucle principale du serveur
        while ($true) {
            # Attendre une connexion
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.AutoFlush = $true

            # Lire la requête
            $requestJson = $reader.ReadLine()

            # Traiter la requête
            $responseJson = Process-MCPRequest -RequestJson $requestJson

            # Envoyer la réponse
            $writer.WriteLine($responseJson)

            # Fermer la connexion
            $reader.Close()
            $writer.Close()
            $client.Close()
        }
    } catch {
        Write-Error "Erreur lors du démarrage du serveur MCP : $_"
    } finally {
        # Arrêter l'écouteur
        if ($listener) {
            $listener.Stop()
        }
    }
}

# Fonction pour obtenir les Memories actuelles
function Get-AugmentMemories {
    [CmdletBinding()]
    param ()

    # Générer les Memories
    $memories = @{
        "version"     = "2.0.0"
        "lastUpdated" = (Get-Date).ToString("o")
        "sections"    = @(
            @{
                "name"    = "Autonomie"
                "content" = @"
- Progression: Exécuter les tâches séquentiellement sans confirmation
- Décision: Utiliser heuristiques (% complété > 80% → tâche terminée)
- Résilience: Reprendre sur erreur avec journalisation minimale
- Estimation: Calculer complexité via métriques objectives (LOC, dépendances, patterns)
"@
            },
            @{
                "name"    = "Communication"
                "content" = @"
- Format: Structure prédéfinie avec ratio info/verbosité maximal
- Synthèse: Uniquement différences importantes et décisions clés
- Métadonnées: Attacher % complétion et score de complexité
- Langage: Français concis avec notation algorithmique optionnelle
"@
            },
            @{
                "name"    = "Optimisation IA"
                "content" = @"
- One-Shot: Une fonction complète par appel
- Progression: Pas de confirmation pour l'étape suivante
- Métrique: Ratio complexité/taille → optimiser découpage
- Adaptation: Si feedback ou latence → ajuster granularité
- Split: Pré-découper si anticipation d'échec
"@
            },
            @{
                "name"    = "Modes"
                "content" = @"
- GRAN: Décomposer les blocs complexes directement dans le document
- DEV-R: Implémenter les tâches séquentiellement avec tests
- CHECK: Vérifier l'implémentation et mettre à jour la roadmap
- ARCHI: Structurer, modéliser, anticiper les dépendances
- DEBUG: Isoler, comprendre, corriger les anomalies
"@
            },
            @{
                "name"    = "Intégrité"
                "content" = @"
- ASSERT: Tâche complète ⇒ if(verified==TRUE)
- ASSERT: Liste fichiers ⇒ if(files_created==TRUE)
- IF(error || user_fix): ACK + FIX(no_justif)
- SEPARATE: actual={code,files}, potential={suggest}
- FORMAT: [IMPLEMENTED]=ok, [SUGGESTED]=idea, [INCOMPLETE]=partial
"@
            }
        )
    }

    return $memories
}

# Démarrer le serveur MCP
Start-MCPServer -Port $Port
