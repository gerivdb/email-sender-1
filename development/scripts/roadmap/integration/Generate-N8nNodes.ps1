# Generate-N8nNodes.ps1
# Script pour générer les nodes personnalisés pour n8n
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère les nodes personnalisés pour n8n.

.DESCRIPTION
    Ce script génère les nodes personnalisés pour n8n, permettant d'intégrer
    les fonctionnalités de roadmap dans les workflows n8n.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer un node n8n
function New-N8nNode {
    <#
    .SYNOPSIS
        Génère un node personnalisé pour n8n.

    .DESCRIPTION
        Cette fonction génère un node personnalisé pour n8n, en créant les fichiers
        nécessaires dans le dossier des nodes personnalisés de n8n.

    .PARAMETER Name
        Le nom du node.

    .PARAMETER DisplayName
        Le nom d'affichage du node.

    .PARAMETER Description
        La description du node.

    .PARAMETER Icon
        L'icône du node.

    .PARAMETER Category
        La catégorie du node.

    .PARAMETER Version
        La version du node.

    .PARAMETER Inputs
        Les entrées du node.

    .PARAMETER Outputs
        Les sorties du node.

    .PARAMETER Operations
        Les opérations du node.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les fichiers du node.

    .EXAMPLE
        New-N8nNode -Name "roadmap" -DisplayName "Roadmap" -Description "Manipule des roadmaps" -OutputPath "C:\n8n\custom"
        Génère un node personnalisé pour n8n.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Icon = "file-text",

        [Parameter(Mandatory = $false)]
        [string]$Category = "Roadmap",

        [Parameter(Mandatory = $false)]
        [string]$Version = "1.0",

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Inputs,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Outputs,

        [Parameter(Mandatory = $true)]
        [PSObject[]]$Operations,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Créer le dossier du node
    $nodePath = Join-Path -Path $OutputPath -ChildPath $Name
    if (-not (Test-Path $nodePath)) {
        New-Item -Path $nodePath -ItemType Directory -Force | Out-Null
    }

    # Générer le fichier de description du node (node.json)
    $nodeJson = @{
        name        = $Name
        displayName = $DisplayName
        description = $Description
        icon        = $Icon
        group       = @($Category)
        version     = [int]($Version -replace "\D", "")
        defaults    = @{
            name = $DisplayName
        }
        inputs      = $Inputs | ForEach-Object { @{ name = $_.Name; type = $_.Type; required = $_.Required; default = $_.Default; description = $_.Description } }
        outputs     = $Outputs | ForEach-Object { @{ name = $_.Name; type = $_.Type; description = $_.Description } }
        properties  = @(
            @{
                displayName = "Operation"
                name        = "operation"
                type        = "options"
                options     = $Operations | ForEach-Object { @{ name = $_.DisplayName; value = $_.Name; description = $_.Description } }
                default     = $Operations[0].Name
                required    = $true
                description = "L'opération à effectuer"
            }
        )
    }

    # Ajouter les propriétés spécifiques à chaque opération
    foreach ($operation in $Operations) {
        if ($null -ne $operation.Properties -and $operation.Properties.Count -gt 0) {
            foreach ($property in $operation.Properties) {
                $nodeJson.properties += @{
                    displayName    = $property.DisplayName
                    name           = $property.Name
                    type           = $property.Type
                    default        = $property.Default
                    required       = $property.Required
                    description    = $property.Description
                    displayOptions = @{
                        show = @{
                            operation = @($operation.Name)
                        }
                    }
                }

                if ($null -ne $property.Options -and $property.Options.Count -gt 0) {
                    $nodeJson.properties[-1].options = $property.Options | ForEach-Object { @{ name = $_.Name; value = $_.Value; description = $_.Description } }
                }
            }
        }
    }

    # Convertir en JSON et sauvegarder
    $nodeJsonPath = Join-Path -Path $nodePath -ChildPath "node.json"
    $nodeJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $nodeJsonPath -Encoding utf8

    # Générer le fichier d'implémentation du node (*.node.ts)
    $nodeTs = @"
import { IExecuteFunctions } from 'n8n-core';
import { INodeExecutionData, INodeType, INodeTypeDescription } from 'n8n-workflow';
import axios from 'axios';

export class $DisplayName implements INodeType {
	description: INodeTypeDescription = {
		displayName: '$DisplayName',
		name: '$Name',
		icon: '$Icon',
		group: ['$Category'],
		version: $([int]($Version -replace "\D", "")),
		description: '$Description',
		defaults: {
			name: '$DisplayName',
		},
		inputs: [$(($Inputs | ForEach-Object { "{ name: '$($_.Name)', type: '$($_.Type)', required: $(if ($_.Required) { "true" } else { "false" }), default: $(if ($null -ne $_.Default) { "'$($_.Default)'" } else { "undefined" }), description: '$($_.Description)' }" }) -join ", ")],
		outputs: [$(($Outputs | ForEach-Object { "{ name: '$($_.Name)', type: '$($_.Type)', description: '$($_.Description)' }" }) -join ", ")],
		properties: [
			{
				displayName: 'Operation',
				name: 'operation',
				type: 'options',
				options: [
$(($Operations | ForEach-Object { "					{ name: '$($_.DisplayName)', value: '$($_.Name)', description: '$($_.Description)' }," }) -join "`n")
				],
				default: '$(if ($Operations.Count -gt 0) { $Operations[0].Name } else { "" })',
				required: true,
				description: 'L\'opération à effectuer',
			},
$(($Operations | ForEach-Object {
    $operation = $_
    if ($null -ne $operation.Properties -and $operation.Properties.Count -gt 0) {
        ($operation.Properties | ForEach-Object {
            $property = $_
            $result = @"
			{
				displayName: '$($property.DisplayName)',
				name: '$($property.Name)',
				type: '$($property.Type)',
				default: $(if ($null -ne $property.Default) { if ($property.Type -eq "string") { "'$($property.Default)'" } else { $property.Default } } else { "undefined" }),
				required: $(if ($property.Required) { "true" } else { "false" }),
				description: '$($property.Description)',
				displayOptions: {
					show: {
						operation: ['$($operation.Name)'],
					},
				},
"@
            if ($null -ne $property.Options -and $property.Options.Count -gt 0) {
                $result += @"
				options: [
$(($property.Options | ForEach-Object { "					{ name: '$($_.Name)', value: '$($_.Value)', description: '$($_.Description)' }," }) -join "`n")
				],
"@
            }
            $result += @"
			},
"@
            $result
        }) -join "`n"
    }
}) -join "`n")
		],
	};

	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
		const items = this.getInputData();
		const returnData: INodeExecutionData[] = [];
		const operation = this.getNodeParameter('operation', 0) as string;
		const apiUrl = 'http://localhost:3000/api/roadmap';

		for (let i = 0; i < items.length; i++) {
			try {
				if (operation === 'list') {
					// Lister toutes les roadmaps
					const response = await axios.get(`\${apiUrl}/roadmaps`);
					returnData.push({ json: response.data });
				} else if (operation === 'get') {
					// Obtenir une roadmap spécifique
					const name = this.getNodeParameter('name', i) as string;
					const response = await axios.get(`\${apiUrl}/roadmaps/\${name}`);
					returnData.push({ json: response.data });
				} else if (operation === 'create') {
					// Créer une nouvelle roadmap
					const title = this.getNodeParameter('title', i) as string;
					const description = this.getNodeParameter('description', i) as string;
					const author = this.getNodeParameter('author', i) as string;
					const tags = (this.getNodeParameter('tags', i) as string).split(',').map(tag => tag.trim());
					const modelName = this.getNodeParameter('modelName', i) as string;
					const thematicContext = this.getNodeParameter('thematicContext', i) as string;

					const response = await axios.post(`\${apiUrl}/roadmaps`, {
						title,
						description,
						author,
						tags,
						modelName,
						thematicContext,
					});
					returnData.push({ json: response.data });
				} else if (operation === 'update') {
					// Mettre à jour une roadmap
					const name = this.getNodeParameter('name', i) as string;
					const taskUpdates = JSON.parse(this.getNodeParameter('taskUpdates', i) as string);

					const response = await axios.put(`\${apiUrl}/roadmaps/\${name}`, {
						taskUpdates,
					});
					returnData.push({ json: response.data });
				} else if (operation === 'delete') {
					// Supprimer une roadmap
					const name = this.getNodeParameter('name', i) as string;
					const response = await axios.delete(`\${apiUrl}/roadmaps/\${name}`);
					returnData.push({ json: response.data });
				} else if (operation === 'analyze') {
					// Analyser une roadmap
					const name = this.getNodeParameter('name', i) as string;
					const response = await axios.get(`\${apiUrl}/analyze/\${name}`);
					returnData.push({ json: response.data });
				} else if (operation === 'listModels') {
					// Lister tous les modèles
					const response = await axios.get(`\${apiUrl}/models`);
					returnData.push({ json: response.data });
				} else if (operation === 'createModel') {
					// Créer un nouveau modèle
					const modelName = this.getNodeParameter('modelName', i) as string;
					const roadmapNames = (this.getNodeParameter('roadmapNames', i) as string).split(',').map(name => name.trim());

					const response = await axios.post(`\${apiUrl}/models`, {
						modelName,
						roadmapNames,
					});
					returnData.push({ json: response.data });
				}
			} catch (error) {
				if (this.continueOnFail()) {
					returnData.push({ json: { error: error.message } });
					continue;
				}
				throw error;
			}
		}

		return [returnData];
	}
}
"@

    # Sauvegarder le fichier TypeScript
    $nodeTsPath = Join-Path -Path $nodePath -ChildPath "$Name.node.ts"
    $nodeTs | Out-File -FilePath $nodeTsPath -Encoding utf8

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Name        = $Name
        DisplayName = $DisplayName
        Path        = $nodePath
        JsonPath    = $nodeJsonPath
        TsPath      = $nodeTsPath
    }

    return $result
}

# Fonction pour générer tous les nodes n8n pour les roadmaps
function New-N8nRoadmapNodes {
    <#
    .SYNOPSIS
        Génère tous les nodes n8n pour les roadmaps.

    .DESCRIPTION
        Cette fonction génère tous les nodes n8n pour les roadmaps,
        en créant les fichiers nécessaires dans le dossier des nodes personnalisés de n8n.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les fichiers des nodes.

    .EXAMPLE
        New-N8nRoadmapNodes -OutputPath "C:\n8n\custom"
        Génère tous les nodes n8n pour les roadmaps.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Vérifier que le dossier de sortie existe
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    # Définir les nodes à générer
    $nodes = @(
        # Node pour les roadmaps
        @{
            Name        = "roadmap"
            DisplayName = "Roadmap"
            Description = "Manipule des roadmaps"
            Icon        = "file-text"
            Category    = "Roadmap"
            Version     = "1.0"
            Inputs      = @(
                @{
                    Name        = "default"
                    Type        = "collection"
                    Required    = $false
                    Default     = $null
                    Description = "Données d'entrée"
                }
            )
            Outputs     = @(
                @{
                    Name        = "default"
                    Type        = "collection"
                    Description = "Données de sortie"
                }
            )
            Operations  = @(
                @{
                    Name        = "list"
                    DisplayName = "List Roadmaps"
                    Description = "Liste toutes les roadmaps disponibles"
                    Properties  = @()
                },
                @{
                    Name        = "get"
                    DisplayName = "Get Roadmap"
                    Description = "Obtient une roadmap spécifique"
                    Properties  = @(
                        @{
                            DisplayName = "Name"
                            Name        = "name"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le nom de la roadmap à obtenir"
                            Options     = $null
                        }
                    )
                },
                @{
                    Name        = "create"
                    DisplayName = "Create Roadmap"
                    Description = "Crée une nouvelle roadmap"
                    Properties  = @(
                        @{
                            DisplayName = "Title"
                            Name        = "title"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le titre de la roadmap"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Description"
                            Name        = "description"
                            Type        = "string"
                            Default     = ""
                            Required    = $false
                            Description = "La description de la roadmap"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Author"
                            Name        = "author"
                            Type        = "string"
                            Default     = "Équipe de développement"
                            Required    = $false
                            Description = "L'auteur de la roadmap"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Tags"
                            Name        = "tags"
                            Type        = "string"
                            Default     = ""
                            Required    = $false
                            Description = "Les tags de la roadmap (séparés par des virgules)"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Model Name"
                            Name        = "modelName"
                            Type        = "string"
                            Default     = ""
                            Required    = $false
                            Description = "Le nom du modèle statistique à utiliser pour générer la roadmap"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Thematic Context"
                            Name        = "thematicContext"
                            Type        = "string"
                            Default     = ""
                            Required    = $false
                            Description = "Le contexte thématique pour la génération des noms de tâches"
                            Options     = $null
                        }
                    )
                },
                @{
                    Name        = "update"
                    DisplayName = "Update Roadmap"
                    Description = "Met à jour une roadmap existante"
                    Properties  = @(
                        @{
                            DisplayName = "Name"
                            Name        = "name"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le nom de la roadmap à mettre à jour"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Task Updates"
                            Name        = "taskUpdates"
                            Type        = "string"
                            Default     = "{}"
                            Required    = $true
                            Description = "Les mises à jour de statut des tâches (JSON)"
                            Options     = $null
                        }
                    )
                },
                @{
                    Name        = "delete"
                    DisplayName = "Delete Roadmap"
                    Description = "Supprime une roadmap"
                    Properties  = @(
                        @{
                            DisplayName = "Name"
                            Name        = "name"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le nom de la roadmap à supprimer"
                            Options     = $null
                        }
                    )
                },
                @{
                    Name        = "analyze"
                    DisplayName = "Analyze Roadmap"
                    Description = "Analyse une roadmap"
                    Properties  = @(
                        @{
                            DisplayName = "Name"
                            Name        = "name"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le nom de la roadmap à analyser"
                            Options     = $null
                        }
                    )
                },
                @{
                    Name        = "listModels"
                    DisplayName = "List Models"
                    Description = "Liste tous les modèles statistiques disponibles"
                    Properties  = @()
                },
                @{
                    Name        = "createModel"
                    DisplayName = "Create Model"
                    Description = "Crée un nouveau modèle statistique"
                    Properties  = @(
                        @{
                            DisplayName = "Model Name"
                            Name        = "modelName"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Le nom du modèle à créer"
                            Options     = $null
                        },
                        @{
                            DisplayName = "Roadmap Names"
                            Name        = "roadmapNames"
                            Type        = "string"
                            Default     = $null
                            Required    = $true
                            Description = "Les noms des roadmaps à utiliser pour créer le modèle (séparés par des virgules)"
                            Options     = $null
                        }
                    )
                }
            )
        }
    )

    # Générer les nodes
    $results = @()
    foreach ($node in $nodes) {
        $result = New-N8nNode @node -OutputPath $OutputPath
        $results += $result
    }

    return $results
}

# Fonction principale pour générer tous les nodes n8n
function Invoke-N8nNodesGeneration {
    <#
    .SYNOPSIS
        Génère tous les nodes n8n pour les roadmaps.

    .DESCRIPTION
        Cette fonction génère tous les nodes n8n pour les roadmaps,
        en créant les fichiers nécessaires dans le dossier des nodes personnalisés de n8n.

    .PARAMETER N8nPath
        Le chemin vers l'installation de n8n.

    .PARAMETER CustomNodesPath
        Le chemin vers le dossier des nodes personnalisés de n8n.
        Si non spécifié, utilise le dossier "custom" dans le dossier de n8n.

    .EXAMPLE
        Invoke-N8nNodesGeneration -N8nPath "C:\n8n"
        Génère tous les nodes n8n pour les roadmaps.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nPath,

        [Parameter(Mandatory = $false)]
        [string]$CustomNodesPath
    )

    # Vérifier que le dossier de n8n existe
    if (-not (Test-Path $N8nPath)) {
        Write-Error "Le dossier de n8n n'existe pas: $N8nPath"
        return $null
    }

    # Définir le chemin des nodes personnalisés
    if ([string]::IsNullOrEmpty($CustomNodesPath)) {
        $CustomNodesPath = Join-Path -Path $N8nPath -ChildPath "custom"
    }

    # Vérifier que le dossier des nodes personnalisés existe
    if (-not (Test-Path $CustomNodesPath)) {
        New-Item -Path $CustomNodesPath -ItemType Directory -Force | Out-Null
    }

    # Générer les nodes
    $nodes = New-N8nRoadmapNodes -OutputPath $CustomNodesPath

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        N8nPath         = $N8nPath
        CustomNodesPath = $CustomNodesPath
        Nodes           = $nodes
    }

    return $result
}

# Les fonctions sont automatiquement disponibles après le sourcing du script
