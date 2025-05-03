# Invoke-RoadmapRAG.ps1
# Script principal pour le système RAG (Retrieval-Augmented Generation) de gestion de roadmap

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

# Fonction pour écrire des messages de log
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
Système RAG (Retrieval-Augmented Generation) pour la gestion de roadmap
=======================================================================

SYNTAXE:
    .\Invoke-RoadmapRAG.ps1 -Action <Action> [-Parameters <Hashtable>] [-VectorDb <Qdrant|Chroma>]

ACTIONS:
    Initialize      : Initialise le système RAG (crée les dossiers nécessaires)
    Convert         : Convertit les tâches de la roadmap en vecteurs
    Store           : Stocke les vecteurs dans une base vectorielle (Qdrant ou Chroma)
    Index           : Indexe les tâches par identifiant, statut, date, etc.
    Search          : Recherche sémantique des tâches par contenu
    Filter          : Filtre les tâches selon différents critères
    UpdateStatus    : Met à jour le statut d'une tâche avec historique
    ViewActive      : Génère une vue de la roadmap active
    ViewCompleted   : Génère une vue des tâches récemment terminées
    ViewPriority    : Génère une vue des prochaines étapes prioritaires
    Help            : Affiche cette aide

EXEMPLES:
    # Initialiser le système
    .\Invoke-RoadmapRAG.ps1 -Action Initialize

    # Convertir les tâches en vecteurs
    .\Invoke-RoadmapRAG.ps1 -Action Convert -Parameters @{
        RoadmapPath = "projet\roadmaps\active\roadmap_active.md"
        OutputPath = "projet\roadmaps\vectors\task_vectors.json"
        Force = $true
    }

    # Rechercher des tâches par contenu
    .\Invoke-RoadmapRAG.ps1 -Action Search -Parameters @{
        Query = "Implémentation des fonctionnalités de base"
        MaxResults = 5
        OutputFormat = "markdown"
    }

    # Mettre à jour le statut d'une tâche
    .\Invoke-RoadmapRAG.ps1 -Action UpdateStatus -Parameters @{
        TaskId = "1.1.2.1"
        Status = "Complete"
        Comment = "Fonctionnalité terminée et testée"
        UpdateRoadmap = $true
    }

    # Générer une vue des prochaines étapes prioritaires
    .\Invoke-RoadmapRAG.ps1 -Action ViewPriority -Parameters @{
        MaxTasks = 10
        PriorityMethod = "Auto"
        OutputFormat = "html"
        OutputPath = "projet\roadmaps\views\priority_tasks.html"
    }

Pour plus d'informations sur les paramètres disponibles pour chaque action,
consultez les scripts individuels dans le dossier development\scripts\roadmap\.
"@
}

# Fonction pour initialiser le système RAG
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

    # Définir les dossiers à créer
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

    # Créer les dossiers
    foreach ($folder in $folders) {
        if (-not (Test-Path -Path $folder) -or $Force) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Log "Dossier créé: $folder" -Level Success
        } else {
            Write-Log "Le dossier $folder existe déjà." -Level Info
        }
    }

    # Créer un fichier de configuration de priorité par défaut
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
                    description = "Le parent est terminé"
                },
                @{
                    rule        = "HasAssignee"
                    score       = 30
                    description = "La tâche est assignée"
                },
                @{
                    rule        = "InProgress"
                    score       = 40
                    description = "La tâche est en cours"
                }
            )
        }

        $priorityConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $priorityConfigPath -Encoding UTF8
        Write-Log "Fichier de configuration de priorité créé: $priorityConfigPath" -Level Success
    }

    # Si Qdrant est sélectionné et StartQdrantContainer est activé, démarrer le conteneur Docker
    if ($VectorDb -eq "Qdrant" -and $StartQdrantContainer) {
        Write-Log "Démarrage du conteneur Docker pour Qdrant..." -Level Info

        $qdrantContainerScript = Join-Path -Path $PSScriptRoot -ChildPath "Start-QdrantContainer.ps1"
        if (Test-Path -Path $qdrantContainerScript) {
            $qdrantDataPath = Join-Path -Path $BasePath -ChildPath "vectors\qdrant_data"
            & $qdrantContainerScript -Action Start -DataPath $qdrantDataPath -Force:$Force

            if ($LASTEXITCODE -eq 0) {
                Write-Log "Conteneur Docker pour Qdrant démarré avec succès." -Level Success
            } else {
                Write-Log "Erreur lors du démarrage du conteneur Docker pour Qdrant." -Level Warning
                Write-Log "Vous devrez démarrer le conteneur manuellement avec la commande:" -Level Warning
                Write-Log ".\Start-QdrantContainer.ps1 -Action Start -DataPath `"$qdrantDataPath`"" -Level Warning
            }
        } else {
            Write-Log "Script de gestion du conteneur Docker pour Qdrant non trouvé: $qdrantContainerScript" -Level Warning
            Write-Log "Vous devrez démarrer le conteneur manuellement." -Level Warning
        }
    }

    Write-Log "Initialisation du système RAG terminée." -Level Success
    return $true
}

# Fonction principale
function Main {
    # Vérifier l'action demandée
    switch ($Action) {
        "Initialize" {
            # Ajouter le paramètre VectorDb aux paramètres d'initialisation
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
                Write-Log "Script non trouvé: $scriptPath" -Level Error
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
                Write-Log "Script non trouvé: $scriptPath" -Level Error
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
                Write-Log "Script non trouvé: $scriptPath" -Level Error
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
                Write-Log "Script non trouvé: $scriptPath" -Level Error
                return $false
            }
        }
        "Filter" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Filter-Tasks.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvé: $scriptPath" -Level Error
                return $false
            }
        }
        "UpdateStatus" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-TaskStatus.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvé: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewActive" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-ActiveRoadmapView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvé: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewCompleted" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-CompletedTasksView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvé: $scriptPath" -Level Error
                return $false
            }
        }
        "ViewPriority" {
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-PriorityTasksView.ps1"
            if (Test-Path -Path $scriptPath) {
                & $scriptPath @Parameters
                return $?
            } else {
                Write-Log "Script non trouvé: $scriptPath" -Level Error
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

# Exécuter la fonction principale
Main
