# Invoke-RoadmapRAG.ps1
# Script principal pour le systÃ¨me RAG (Retrieval-Augmented Generation) de gestion de roadmap

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "Initialize", "Convert", "Store", "Index",
        "Search", "Filter", "UpdateStatus",
        "ViewActive", "ViewCompleted", "ViewPriority",
        "Help"
    )]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},

    [Parameter(Mandatory = $false)]
    [ValidateSet("Qdrant", "Chroma")]
    [string]$VectorDb = "Qdrant"
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Fonction pour afficher l'aide
function Show-Help {
    Write-Host @"
SystÃ¨me RAG (Retrieval-Augmented Generation) pour la gestion de roadmap
=======================================================================

SYNTAXE:
    .\Invoke-RoadmapRAG.ps1 -Action <Action> [-Parameters <Hashtable>] [-VectorDb <Qdrant|Chroma>]

ACTIONS:
    Initialize      : Initialise le systÃ¨me RAG (crÃ©e les dossiers nÃ©cessaires)
    Convert         : Convertit les tÃ¢ches de la roadmap en vecteurs
    Store           : Stocke les vecteurs dans une base vectorielle (Qdrant ou Chroma)
    Index           : Indexe les tÃ¢ches par identifiant, statut, date, etc.
    Search          : Recherche sÃ©mantique des tÃ¢ches par contenu
    Filter          : Filtre les tÃ¢ches selon diffÃ©rents critÃ¨res
    UpdateStatus    : Met Ã  jour le statut d'une tÃ¢che avec historique
    ViewActive      : GÃ©nÃ¨re une vue de la roadmap active
    ViewCompleted   : GÃ©nÃ¨re une vue des tÃ¢ches rÃ©cemment terminÃ©es
    ViewPriority    : GÃ©nÃ¨re une vue des prochaines Ã©tapes prioritaires
    Help            : Affiche cette aide

EXEMPLES:
    # Initialiser le systÃ¨me
    .\Invoke-RoadmapRAG.ps1 -Action Initialize

    # Convertir les tÃ¢ches en vecteurs
    .\Invoke-RoadmapRAG.ps1 -Action Convert -Parameters @{
        RoadmapPath = "projet\roadmaps\active\roadmap_active.md"
        OutputPath = "projet\roadmaps\vectors\task_vectors.json"
        Force = $true
    }

    # Rechercher des tÃ¢ches par contenu
    .\Invoke-RoadmapRAG.ps1 -Action Search -Parameters @{
        Query = "ImplÃ©mentation des fonctionnalitÃ©s de base"
        MaxResults = 5
        OutputFormat = "markdown"
    }

    # Mettre Ã  jour le statut d'une tÃ¢che
    .\Invoke-RoadmapRAG.ps1 -Action UpdateStatus -Parameters @{
        TaskId = "1.1.2.1"
        Status = "Complete"
        Comment = "FonctionnalitÃ© terminÃ©e et testÃ©e"
        UpdateRoadmap = $true
    }

    # GÃ©nÃ©rer une vue des prochaines Ã©tapes prioritaires
    .\Invoke-RoadmapRAG.ps1 -Action ViewPriority -Parameters @{
        MaxTasks = 10
        PriorityMethod = "Auto"
        OutputFormat = "html"
        OutputPath = "projet\roadmaps\views\priority_tasks.html"
    }

Pour plus d'informations sur les paramÃ¨tres disponibles pour chaque action,
consultez les scripts individuels dans le dossier development\scripts\roadmap\.
"@
}

# Fonction pour initialiser le systÃ¨me RAG
function Initialize-RoadmapRAG {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = "projet\roadmaps",

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$StartQdrantContainer = $true
    )

    # DÃ©finir les dossiers Ã  crÃ©er
    $folders = @(
        "$BasePath\active",
        "$BasePath\completed",
        "$BasePath\vectors",
        "$BasePath\vectors\chroma_db",
        "$BasePath\vectors\qdrant_data",
        "$BasePath\history",
        "$BasePath\views",
        "$BasePath\config"
    )

    # CrÃ©er les dossiers
    foreach ($folder in $folders) {
        if (-not (Test-Path -Path $folder) -or $Force) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Log "Dossier crÃ©Ã©: $folder" -Level Success
        } else {
            Write-Log "Le dossier $folder existe dÃ©jÃ ." -Level Info
        }
    }

    # CrÃ©er un fichier de configuration de prioritÃ© par dÃ©faut
    $priorityConfigPath = "$BasePath\config\priority_config.json"
    if (-not (Test-Path -Path $priorityConfigPath) -or $Force) {
        $priorityConfig = @{
            taskPriorities = @{
                "1.1" = 100
                "1.2" = 90
                "1.3" = 80
                "2.1" = 70
            }
            priorityRules  = @(
                @{
                    rule        = "ParentComplete"
                    score       = 50
                    description = "Le parent est terminÃ©"
                },
                @{
                    rule        = "HasAssignee"
                    score       = 30
                    description = "La tÃ¢che est assignÃ©e"
                },
                @{
                    rule        = "InProgress"
                    score       = 40
                    description = "La tÃ¢che est en cours"
                }
            )
        }

        $priorityConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $priorityConfigPath -Encoding UTF8
        Write-Log "Fichier de configuration de prioritÃ© crÃ©Ã©: $priorityConfigPath" -Level Success
    }

    # Si Qdrant est sÃ©lectionnÃ© et StartQdrantContainer est activÃ©, dÃ©marrer le conteneur Docker
    if ($VectorDb -eq "Qdrant" -and $StartQdrantContainer) {
        Write-Log "DÃ©marrage du conteneur Docker pour Qdrant..." -Level Info

        $qdrantContainerScript = Join-Path -Path $PSScriptRoot -ChildPath "Start-QdrantContainer.ps1"
        if (Test-Path -Path $qdrantContainerScript) {
            $qdrantDataPath = Join-Path -Path $BasePath -ChildPath "vectors\qdrant_data"
            & $qdrantContainerScript -Action Start -DataPath $qdrantDataPath -Force:$Force

            if ($LASTEXITCODE -eq 0) {
                Write-Log "Conteneur Docker pour Qdrant dÃ©marrÃ© avec succÃ¨s." -Level Success
            } else {
                Write-Log "Erreur lors du dÃ©marrage du conteneur Docker pour Qdrant." -Level Warning
                Write-Log "Vous devrez dÃ©marrer le conteneur manuellement avec la commande:" -Level Warning
                Write-Log ".\Start-QdrantContainer.ps1 -Action Start -DataPath `"$qdrantDataPath`"" -Level Warning
            }
        } else {
            Write-Log "Script de gestion du conteneur Docker pour Qdrant non trouvÃ©: $qdrantContainerScript" -Level Warning
            Write-Log "Vous devrez dÃ©marrer le conteneur manuellement." -Level Warning
        }
    }

    Write-Log "Initialisation du systÃ¨me RAG terminÃ©e." -Level Success
    return $true
}

# Fonction principale
function Main {
    # VÃ©rifier l'action demandÃ©e
    switch ($Action) {
        "Initialize" {
            # Ajouter le paramÃ¨tre VectorDb aux paramÃ¨tres d'initialisation
            $initParams = $Parameters.Clone()
            $initParams["VectorDb"] = $VectorDb

            $result = Initialize-RoadmapRAG @initParams
            return $result
        }
        "Convert" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Convert-TaskToVector.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "Store" {
            if ($VectorDb -eq "Qdrant") {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Store-VectorsInQdrant.ps1"
            } else {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Store-VectorsInChroma.ps1"
            }

            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "Index" {
            if ($VectorDb -eq "Qdrant") {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Index-TaskVectorsQdrant.ps1"
            } else {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Index-TaskVectors.ps1"
            }

            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "Search" {
            if ($VectorDb -eq "Qdrant") {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Search-TasksSemanticQdrant.ps1"
            } else {
                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Search-TasksSemantic.ps1"
            }

            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "Filter" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Filter-Tasks.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "UpdateStatus" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-TaskStatus.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewActive" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-ActiveRoadmapView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewCompleted" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-CompletedTasksView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewPriority" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-PriorityTasksView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvÃ©: $scriptPath" -Level Error
                return $false
            }
        }
        "Help" {
            Show-Help
            return $true
        }
        default {
            Write-Log "Action non reconnue: $Action" -Level Error
            Show-Help
            return $false
        }
    }
}

# ExÃ©cuter la fonction principale
Main
