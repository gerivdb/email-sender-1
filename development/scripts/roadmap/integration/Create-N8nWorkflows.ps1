# Create-N8nWorkflows.ps1
# Script pour créer les workflows n8n pour l'automatisation des roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Crée les workflows n8n pour l'automatisation des roadmaps.

.DESCRIPTION
    Ce script crée les workflows n8n pour l'automatisation des roadmaps,
    permettant d'automatiser la génération, l'analyse et la gestion des roadmaps.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour créer un workflow n8n
function New-N8nWorkflow {
    <#
    .SYNOPSIS
        Crée un workflow n8n.

    .DESCRIPTION
        Cette fonction crée un workflow n8n, en générant le fichier JSON
        correspondant et en l'important dans n8n.

    .PARAMETER Name
        Le nom du workflow.

    .PARAMETER Description
        La description du workflow.

    .PARAMETER Nodes
        Les nodes du workflow.

    .PARAMETER Connections
        Les connexions entre les nodes du workflow.

    .PARAMETER Tags
        Les tags du workflow.

    .PARAMETER OutputPath
        Le chemin où sauvegarder le fichier JSON du workflow.

    .PARAMETER ImportToN8n
        Indique si le workflow doit être importé dans n8n.

    .PARAMETER N8nUrl
        L'URL de l'instance n8n.

    .PARAMETER N8nApiKey
        La clé API de l'instance n8n.

    .EXAMPLE
        New-N8nWorkflow -Name "Generate Roadmap" -Description "Génère une roadmap" -Nodes $nodes -Connections $connections -OutputPath "C:\Workflows"
        Crée un workflow n8n et le sauvegarde dans le dossier spécifié.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description = "",

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Nodes,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Connections,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$ImportToN8n,

        [Parameter(Mandatory = $false)]
        [string]$N8nUrl = "http://localhost:5678",

        [Parameter(Mandatory = $false)]
        [string]$N8nApiKey = ""
    )

    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Générer le workflow
    $workflow = @{
        name        = $Name
        nodes       = $Nodes
        connections = @{
            Main = $Connections
        }
        active      = $true
        settings    = @{
            saveManualExecutions = $true
            callerPolicy         = "workflowsFromSameOwner"
        }
        tags        = $Tags
        id          = [guid]::NewGuid().ToString()
        meta        = @{
            instanceId = [guid]::NewGuid().ToString()
        }
    }

    if (-not [string]::IsNullOrEmpty($Description)) {
        $workflow.description = $Description
    }

    # Convertir en JSON et sauvegarder
    $workflowJson = $workflow | ConvertTo-Json -Depth 10
    $workflowPath = Join-Path -Path $OutputPath -ChildPath "$($Name -replace "\s+", "_").json"
    $workflowJson | Out-File -FilePath $workflowPath -Encoding utf8

    # Importer dans n8n si demandé
    if ($ImportToN8n) {
        if ([string]::IsNullOrEmpty($N8nApiKey)) {
            Write-Warning "Aucune clé API n8n spécifiée. L'importation automatique n'est pas possible."
        } else {
            try {
                $headers = @{
                    "X-N8N-API-KEY" = $N8nApiKey
                    "Content-Type"  = "application/json"
                }

                $importUrl = "$N8nUrl/rest/workflows"
                $response = Invoke-RestMethod -Uri $importUrl -Method Post -Headers $headers -Body $workflowJson

                Write-Host "Workflow importé avec succès dans n8n. ID: $($response.id)"
            } catch {
                Write-Error "Erreur lors de l'importation du workflow dans n8n: $_"
            }
        }
    }

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Name     = $Name
        Path     = $workflowPath
        Workflow = $workflow
    }

    return $result
}

# Fonction pour créer un node n8n
function New-N8nWorkflowNode {
    <#
    .SYNOPSIS
        Crée un node pour un workflow n8n.

    .DESCRIPTION
        Cette fonction crée un node pour un workflow n8n, en générant
        l'objet JSON correspondant.

    .PARAMETER Name
        Le nom du node.

    .PARAMETER Type
        Le type du node.

    .PARAMETER Position
        La position du node dans le workflow.

    .PARAMETER Parameters
        Les paramètres du node.

    .EXAMPLE
        New-N8nWorkflowNode -Name "Start" -Type "n8n-nodes-base.start" -Position @{x = 100; y = 100}
        Crée un node de type "start" pour un workflow n8n.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [hashtable]$Position,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Générer le node
    $node = @{
        id         = [guid]::NewGuid().ToString()
        name       = $Name
        type       = $Type
        position   = @($Position.x, $Position.y)
        parameters = $Parameters
    }

    return $node
}

# Fonction pour créer une connexion entre deux nodes
function New-N8nWorkflowConnection {
    <#
    .SYNOPSIS
        Crée une connexion entre deux nodes d'un workflow n8n.

    .DESCRIPTION
        Cette fonction crée une connexion entre deux nodes d'un workflow n8n,
        en générant l'objet JSON correspondant.

    .PARAMETER SourceNode
        Le node source.

    .PARAMETER TargetNode
        Le node cible.

    .PARAMETER SourceOutput
        L'index de sortie du node source.

    .PARAMETER TargetInput
        L'index d'entrée du node cible.

    .EXAMPLE
        New-N8nWorkflowConnection -SourceNode $node1 -TargetNode $node2 -SourceOutput 0 -TargetInput 0
        Crée une connexion entre deux nodes d'un workflow n8n.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$SourceNode,

        [Parameter(Mandatory = $true)]
        [PSObject]$TargetNode,

        [Parameter(Mandatory = $false)]
        [int]$SourceOutput = 0,

        [Parameter(Mandatory = $false)]
        [int]$TargetInput = 0
    )

    # Générer la connexion
    $connection = @{
        node        = $SourceNode.id
        type        = "main"
        index       = $SourceOutput
        target      = $TargetNode.id
        targetType  = "main"
        targetIndex = $TargetInput
    }

    return $connection
}

# Fonction pour créer les workflows n8n pour les roadmaps
function New-N8nRoadmapWorkflows {
    <#
    .SYNOPSIS
        Crée les workflows n8n pour les roadmaps.

    .DESCRIPTION
        Cette fonction crée les workflows n8n pour les roadmaps,
        en générant les fichiers JSON correspondants.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les fichiers JSON des workflows.

    .PARAMETER ImportToN8n
        Indique si les workflows doivent être importés dans n8n.

    .PARAMETER N8nUrl
        L'URL de l'instance n8n.

    .PARAMETER N8nApiKey
        La clé API de l'instance n8n.

    .EXAMPLE
        New-N8nRoadmapWorkflows -OutputPath "C:\Workflows"
        Crée les workflows n8n pour les roadmaps et les sauvegarde dans le dossier spécifié.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$ImportToN8n,

        [Parameter(Mandatory = $false)]
        [string]$N8nUrl = "http://localhost:5678",

        [Parameter(Mandatory = $false)]
        [string]$N8nApiKey = ""
    )

    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Définir les workflows à créer
    $workflows = @(
        # Workflow 1: Génération de roadmap
        @{
            Name        = "Generate Roadmap"
            Description = "Génère une roadmap à partir d'un modèle statistique"
            Tags        = @("roadmap", "generation")
            Nodes       = @(
                # Node 1: Déclencheur manuel
                (New-N8nWorkflowNode -Name "Manual Trigger" -Type "n8n-nodes-base.manualTrigger" -Position @{x = 100; y = 300 }),

                # Node 2: Définir les paramètres
                (New-N8nWorkflowNode -Name "Set Parameters" -Type "n8n-nodes-base.set" -Position @{x = 300; y = 300 } -Parameters @{
                    values = @{
                        parameters = @{
                            title           = "={{ $json.title || 'Nouvelle Roadmap' }}"
                            description     = "={{ $json.description || 'Roadmap générée automatiquement' }}"
                            author          = "={{ $json.author || 'Équipe de développement' }}"
                            tags            = "={{ $json.tags || 'roadmap,automatique' }}"
                            modelName       = "={{ $json.modelName || '' }}"
                            thematicContext = "={{ $json.thematicContext || 'Développement logiciel' }}"
                        }
                    }
                }),

                # Node 3: Roadmap - Créer une roadmap
                (New-N8nWorkflowNode -Name "Create Roadmap" -Type "roadmap" -Position @{x = 500; y = 300 } -Parameters @{
                    operation       = "create"
                    title           = "={{ $json.parameters.title }}"
                    description     = "={{ $json.parameters.description }}"
                    author          = "={{ $json.parameters.author }}"
                    tags            = "={{ $json.parameters.tags }}"
                    modelName       = "={{ $json.parameters.modelName }}"
                    thematicContext = "={{ $json.parameters.thematicContext }}"
                }),

                # Node 4: Afficher le résultat
                (New-N8nWorkflowNode -Name "Display Result" -Type "n8n-nodes-base.noOp" -Position @{x = 700; y = 300 })
            )
            Connections = @(
                # Connexion 1: Manual Trigger -> Set Parameters
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[0] -TargetNode $_.Nodes[1]),

                # Connexion 2: Set Parameters -> Create Roadmap
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[1] -TargetNode $_.Nodes[2]),

                # Connexion 3: Create Roadmap -> Display Result
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[2] -TargetNode $_.Nodes[3])
            )
        },

        # Workflow 2: Analyse de roadmap
        @{
            Name        = "Analyze Roadmap"
            Description = "Analyse une roadmap existante"
            Tags        = @("roadmap", "analysis")
            Nodes       = @(
                # Node 1: Déclencheur manuel
                (New-N8nWorkflowNode -Name "Manual Trigger" -Type "n8n-nodes-base.manualTrigger" -Position @{x = 100; y = 300 }),

                # Node 2: Définir les paramètres
                (New-N8nWorkflowNode -Name "Set Parameters" -Type "n8n-nodes-base.set" -Position @{x = 300; y = 300 } -Parameters @{
                    values = @{
                        parameters = @{
                            name = "={{ $json.name || '' }}"
                        }
                    }
                }),

                # Node 3: Roadmap - Analyser une roadmap
                (New-N8nWorkflowNode -Name "Analyze Roadmap" -Type "roadmap" -Position @{x = 500; y = 300 } -Parameters @{
                    operation = "analyze"
                    name      = "={{ $json.parameters.name }}"
                }),

                # Node 4: Afficher le résultat
                (New-N8nWorkflowNode -Name "Display Result" -Type "n8n-nodes-base.noOp" -Position @{x = 700; y = 300 })
            )
            Connections = @(
                # Connexion 1: Manual Trigger -> Set Parameters
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[0] -TargetNode $_.Nodes[1]),

                # Connexion 2: Set Parameters -> Analyze Roadmap
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[1] -TargetNode $_.Nodes[2]),

                # Connexion 3: Analyze Roadmap -> Display Result
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[2] -TargetNode $_.Nodes[3])
            )
        },

        # Workflow 3: Création de modèle statistique
        @{
            Name        = "Create Statistical Model"
            Description = "Crée un modèle statistique à partir de roadmaps existantes"
            Tags        = @("roadmap", "model")
            Nodes       = @(
                # Node 1: Déclencheur manuel
                (New-N8nWorkflowNode -Name "Manual Trigger" -Type "n8n-nodes-base.manualTrigger" -Position @{x = 100; y = 300 }),

                # Node 2: Définir les paramètres
                (New-N8nWorkflowNode -Name "Set Parameters" -Type "n8n-nodes-base.set" -Position @{x = 300; y = 300 } -Parameters @{
                    values = @{
                        parameters = @{
                            modelName    = "={{ $json.modelName || 'Model-' + $now }}"
                            roadmapNames = "={{ $json.roadmapNames || '' }}"
                        }
                    }
                }),

                # Node 3: Roadmap - Créer un modèle
                (New-N8nWorkflowNode -Name "Create Model" -Type "roadmap" -Position @{x = 500; y = 300 } -Parameters @{
                    operation    = "createModel"
                    modelName    = "={{ $json.parameters.modelName }}"
                    roadmapNames = "={{ $json.parameters.roadmapNames }}"
                }),

                # Node 4: Afficher le résultat
                (New-N8nWorkflowNode -Name "Display Result" -Type "n8n-nodes-base.noOp" -Position @{x = 700; y = 300 })
            )
            Connections = @(
                # Connexion 1: Manual Trigger -> Set Parameters
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[0] -TargetNode $_.Nodes[1]),

                # Connexion 2: Set Parameters -> Create Model
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[1] -TargetNode $_.Nodes[2]),

                # Connexion 3: Create Model -> Display Result
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[2] -TargetNode $_.Nodes[3])
            )
        },

        # Workflow 4: Mise à jour automatique des roadmaps
        @{
            Name        = "Auto Update Roadmaps"
            Description = "Met à jour automatiquement les roadmaps en fonction des modifications de fichiers"
            Tags        = @("roadmap", "automation")
            Nodes       = @(
                # Node 1: Déclencheur de fichier
                (New-N8nWorkflowNode -Name "File Trigger" -Type "n8n-nodes-base.fileTrigger" -Position @{x = 100; y = 300 } -Parameters @{
                    path              = "={{ $env.ROADMAPS_PATH || '/path/to/roadmaps' }}"
                    fileExtensions    = @("md")
                    ignoreHiddenFiles = $true
                    events            = @("create", "modify")
                }),

                # Node 2: Extraire le nom du fichier
                (New-N8nWorkflowNode -Name "Extract Filename" -Type "n8n-nodes-base.function" -Position @{x = 300; y = 300 } -Parameters @{
                    functionCode = @"
const filePath = $input.first().json.path;
const fileName = filePath.split('/').pop().replace('.md', '');
return [{
  json: {
    fileName,
    filePath
  }
}];
"@
                }),

                # Node 3: Roadmap - Analyser la roadmap
                (New-N8nWorkflowNode -Name "Analyze Roadmap" -Type "roadmap" -Position @{x = 500; y = 300 } -Parameters @{
                    operation = "analyze"
                    name      = "={{ $json.fileName }}"
                }),

                # Node 4: Envoyer une notification
                (New-N8nWorkflowNode -Name "Send Notification" -Type "n8n-nodes-base.noOp" -Position @{x = 700; y = 300 })
            )
            Connections = @(
                # Connexion 1: File Trigger -> Extract Filename
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[0] -TargetNode $_.Nodes[1]),

                # Connexion 2: Extract Filename -> Analyze Roadmap
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[1] -TargetNode $_.Nodes[2]),

                # Connexion 3: Analyze Roadmap -> Send Notification
                (New-N8nWorkflowConnection -SourceNode $_.Nodes[2] -TargetNode $_.Nodes[3])
            )
        }
    )

    # Créer les workflows
    $results = @()
    foreach ($workflow in $workflows) {
        # Résoudre les références dans les connexions
        $workflow.Connections = @()
        for ($i = 0; $i -lt $workflow.Nodes.Count - 1; $i++) {
            $workflow.Connections += New-N8nWorkflowConnection -SourceNode $workflow.Nodes[$i] -TargetNode $workflow.Nodes[$i + 1]
        }

        # Créer le workflow
        $result = New-N8nWorkflow -Name $workflow.Name -Description $workflow.Description -Nodes $workflow.Nodes -Connections $workflow.Connections -Tags $workflow.Tags -OutputPath $OutputPath -ImportToN8n:$ImportToN8n -N8nUrl $N8nUrl -N8nApiKey $N8nApiKey
        $results += $result
    }

    return $results
}

# Fonction principale pour créer tous les workflows n8n
function Invoke-N8nWorkflowsCreation {
    <#
    .SYNOPSIS
        Crée tous les workflows n8n pour les roadmaps.

    .DESCRIPTION
        Cette fonction crée tous les workflows n8n pour les roadmaps,
        en générant les fichiers JSON correspondants et en les important dans n8n.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les fichiers JSON des workflows.

    .PARAMETER ImportToN8n
        Indique si les workflows doivent être importés dans n8n.

    .PARAMETER N8nUrl
        L'URL de l'instance n8n.

    .PARAMETER N8nApiKey
        La clé API de l'instance n8n.

    .EXAMPLE
        Invoke-N8nWorkflowsCreation -OutputPath "C:\Workflows" -ImportToN8n -N8nUrl "http://localhost:5678" -N8nApiKey "12345"
        Crée tous les workflows n8n pour les roadmaps et les importe dans n8n.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$ImportToN8n,

        [Parameter(Mandatory = $false)]
        [string]$N8nUrl = "http://localhost:5678",

        [Parameter(Mandatory = $false)]
        [string]$N8nApiKey = ""
    )

    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Créer les workflows
    $workflows = New-N8nRoadmapWorkflows -OutputPath $OutputPath -ImportToN8n:$ImportToN8n -N8nUrl $N8nUrl -N8nApiKey $N8nApiKey

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        OutputPath    = $OutputPath
        Workflows     = $workflows
        ImportedToN8n = $ImportToN8n
        N8nUrl        = $N8nUrl
    }

    return $result
}

# Les fonctions sont automatiquement disponibles après le sourcing du script
