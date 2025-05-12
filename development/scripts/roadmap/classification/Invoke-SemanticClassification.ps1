# Invoke-SemanticClassification.ps1
# Module pour la classification par similarité sémantique
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour la classification des tâches par similarité sémantique.

.DESCRIPTION
    Ce module fournit des fonctions pour la classification des tâches par similarité sémantique,
    en utilisant des modèles d'embeddings vectoriels et des algorithmes de clustering.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Verbose "Module Parse-Roadmap.ps1 chargé."
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

# Fonction principale pour la classification par similarité sémantique
function Invoke-SemanticClassification {
    <#
    .SYNOPSIS
        Classifie les tâches d'une roadmap par similarité sémantique.

    .DESCRIPTION
        Cette fonction classifie les tâches d'une roadmap par similarité sémantique,
        en utilisant des modèles d'embeddings vectoriels et des algorithmes de clustering.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats de la classification.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER EmbeddingModel
        Le modèle d'embedding à utiliser.
        Par défaut, "openai/text-embedding-ada-002".

    .PARAMETER ClusteringAlgorithm
        L'algorithme de clustering à utiliser.
        Par défaut, "kmeans".

    .PARAMETER NumberOfClusters
        Le nombre de clusters à créer.
        Par défaut, 0 (déterminé automatiquement).

    .PARAMETER MinimumSimilarity
        La similarité minimale pour considérer deux tâches comme similaires.
        Par défaut, 0.7 (70%).

    .PARAMETER QdrantEndpoint
        L'endpoint Qdrant à utiliser pour la recherche vectorielle.
        Par défaut, "http://localhost:6333".

    .PARAMETER QdrantCollection
        La collection Qdrant à utiliser.
        Par défaut, "roadmap-tasks".

    .EXAMPLE
        Invoke-SemanticClassification -RoadmapPath "C:\Roadmaps\roadmap.md" -NumberOfClusters 10 -MinimumSimilarity 0.8
        Classifie les tâches d'une roadmap en 10 clusters avec une similarité minimale de 80%.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string]$EmbeddingModel = "openai/text-embedding-ada-002",

        [Parameter(Mandatory = $false)]
        [ValidateSet("kmeans", "hierarchical", "dbscan", "optics")]
        [string]$ClusteringAlgorithm = "kmeans",

        [Parameter(Mandatory = $false)]
        [int]$NumberOfClusters = 0,

        [Parameter(Mandatory = $false)]
        [double]$MinimumSimilarity = 0.7,

        [Parameter(Mandatory = $false)]
        [string]$QdrantEndpoint = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$QdrantCollection = "roadmap-tasks"
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }

        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "SemanticClassification"
        }

        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }

        # Générer un identifiant unique pour cette exécution
        $executionId = [Guid]::NewGuid().ToString()
        $executionPath = Join-Path -Path $OutputPath -ChildPath $executionId

        # Créer le dossier d'exécution
        if (-not (Test-Path $executionPath)) {
            New-Item -Path $executionPath -ItemType Directory -Force | Out-Null
        }

        # Analyser la roadmap pour extraire les tâches
        Write-Verbose "Extraction des tâches de la roadmap..."
        $roadmapContent = Get-Content -Path $RoadmapPath
        $parsedRoadmap = Parse-RoadmapContent -Content $roadmapContent
        $tasks = $parsedRoadmap.Tasks

        Write-Verbose "Nombre total de tâches: $($tasks.Count)"

        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            RoadmapPath         = $RoadmapPath
            OutputPath          = $executionPath
            EmbeddingModel      = $EmbeddingModel
            ClusteringAlgorithm = $ClusteringAlgorithm
            NumberOfClusters    = $NumberOfClusters
            MinimumSimilarity   = $MinimumSimilarity
            QdrantEndpoint      = $QdrantEndpoint
            QdrantCollection    = $QdrantCollection
            StartTime           = Get-Date
            Tasks               = $tasks
            TaskEmbeddings      = @{}
            Clusters            = @()
            SimilarityMatrix    = @{}
        }

        # Générer les embeddings pour chaque tâche
        Write-Verbose "Génération des embeddings pour les tâches..."
        $taskEmbeddings = Get-TaskEmbeddings -Tasks $tasks -EmbeddingModel $EmbeddingModel
        $config.TaskEmbeddings = $taskEmbeddings

        # Calculer la matrice de similarité
        Write-Verbose "Calcul de la matrice de similarité..."
        $similarityMatrix = Get-SimilarityMatrix -TaskEmbeddings $taskEmbeddings -MinimumSimilarity $MinimumSimilarity
        $config.SimilarityMatrix = $similarityMatrix

        # Déterminer le nombre de clusters si non spécifié
        if ($NumberOfClusters -le 0) {
            $NumberOfClusters = Get-OptimalClusterCount -SimilarityMatrix $similarityMatrix -Tasks $tasks
            $config.NumberOfClusters = $NumberOfClusters
            Write-Verbose "Nombre optimal de clusters déterminé: $NumberOfClusters"
        }

        # Appliquer l'algorithme de clustering
        Write-Verbose "Application de l'algorithme de clustering: $ClusteringAlgorithm..."
        $clusters = switch ($ClusteringAlgorithm) {
            "kmeans" { Invoke-KMeansClustering -TaskEmbeddings $taskEmbeddings -NumberOfClusters $NumberOfClusters }
            "hierarchical" { Invoke-HierarchicalClustering -SimilarityMatrix $similarityMatrix -NumberOfClusters $NumberOfClusters }
            "dbscan" { Invoke-DBSCANClustering -TaskEmbeddings $taskEmbeddings -MinimumSimilarity $MinimumSimilarity }
            "optics" { Invoke-OPTICSClustering -TaskEmbeddings $taskEmbeddings -MinimumSimilarity $MinimumSimilarity }
        }
        $config.Clusters = $clusters

        # Générer les étiquettes pour chaque cluster
        Write-Verbose "Génération des étiquettes pour les clusters..."
        $labeledClusters = Get-ClusterLabels -Clusters $clusters -Tasks $tasks

        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $executionPath -ChildPath "classification-result.json"
        $labeledClusters | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8

        # Générer un rapport HTML
        $reportFilePath = Join-Path -Path $executionPath -ChildPath "classification-report.html"
        $report = Get-ClassificationReport -LabeledClusters $labeledClusters -Config $config
        $report | Out-File -FilePath $reportFilePath -Encoding UTF8

        # Indexer les résultats dans Qdrant si disponible
        $qdrantAvailable = Test-QdrantConnection -QdrantEndpoint $QdrantEndpoint

        if ($qdrantAvailable) {
            Write-Verbose "Indexation des résultats dans Qdrant..."
            $qdrantResult = Add-TasksToQdrant -TaskEmbeddings $taskEmbeddings -Clusters $labeledClusters -QdrantEndpoint $QdrantEndpoint -QdrantCollection $QdrantCollection

            if ($qdrantResult) {
                Write-Verbose "Indexation dans Qdrant réussie."
            } else {
                Write-Warning "Échec de l'indexation dans Qdrant."
            }
        } else {
            Write-Warning "Qdrant n'est pas disponible. Les résultats ne seront pas indexés."
        }

        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Config          = $config
            LabeledClusters = $labeledClusters
            ResultFilePath  = $resultFilePath
            ReportFilePath  = $reportFilePath
            QdrantAvailable = $qdrantAvailable
            ExecutionTime   = (Get-Date) - $config.StartTime
        }

        return $result
    } catch {
        Write-Error "Échec de la classification par similarité sémantique: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour générer les embeddings des tâches
function Get-TaskEmbeddings {
    <#
    .SYNOPSIS
        Génère les embeddings vectoriels pour les tâches.

    .DESCRIPTION
        Cette fonction génère les embeddings vectoriels pour les tâches,
        en utilisant un modèle d'embedding spécifié.

    .PARAMETER Tasks
        Les tâches pour lesquelles générer les embeddings.

    .PARAMETER EmbeddingModel
        Le modèle d'embedding à utiliser.
        Par défaut, "openai/text-embedding-ada-002".

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$EmbeddingModel = "openai/text-embedding-ada-002"
    )

    try {
        $embeddings = @{}

        # Vérifier si OpenAI est disponible
        $openaiAvailable = $false

        try {
            # Vérifier si la variable d'environnement OPENAI_API_KEY est définie
            $openaiApiKey = $env:OPENAI_API_KEY

            if (-not [string]::IsNullOrEmpty($openaiApiKey)) {
                $openaiAvailable = $true
            }
        } catch {
            $openaiAvailable = $false
        }

        if ($openaiAvailable) {
            # Utiliser l'API OpenAI pour générer les embeddings
            foreach ($task in $Tasks) {
                $taskText = "$($task.Id): $($task.Title)"

                if ($task.PSObject.Properties.Name.Contains("Description") -and -not [string]::IsNullOrEmpty($task.Description)) {
                    $taskText += " - $($task.Description)"
                }

                $headers = @{
                    "Content-Type"  = "application/json"
                    "Authorization" = "Bearer $openaiApiKey"
                }

                $body = @{
                    model = $EmbeddingModel
                    input = $taskText
                } | ConvertTo-Json

                $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/embeddings" -Method Post -Headers $headers -Body $body

                $embedding = $response.data[0].embedding
                $embeddings[$task.Id] = $embedding
            }
        } else {
            # Utiliser une méthode alternative pour générer des embeddings simulés
            Write-Warning "OpenAI API n'est pas disponible. Utilisation d'embeddings simulés."

            foreach ($task in $Tasks) {
                # Générer un embedding simulé basé sur le hachage du texte de la tâche
                $taskText = "$($task.Id): $($task.Title)"

                if ($task.PSObject.Properties.Name.Contains("Description") -and -not [string]::IsNullOrEmpty($task.Description)) {
                    $taskText += " - $($task.Description)"
                }

                $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($taskText))

                # Convertir le hachage en un vecteur d'embedding simulé (dimension 1536 pour ada-002)
                $embedding = New-Object double[] 1536

                for ($i = 0; $i -lt 1536; $i++) {
                    $hashIndex = $i % $hash.Length
                    $embedding[$i] = ($hash[$hashIndex] / 255.0) * 2 - 1  # Normaliser entre -1 et 1
                }

                $embeddings[$task.Id] = $embedding
            }
        }

        return $embeddings
    } catch {
        Write-Error "Échec de la génération des embeddings: $($_.Exception.Message)"
        return @{}
    }
}

# Fonction pour calculer la matrice de similarité
function Get-SimilarityMatrix {
    <#
    .SYNOPSIS
        Calcule la matrice de similarité entre les tâches.

    .DESCRIPTION
        Cette fonction calcule la matrice de similarité entre les tâches,
        en utilisant la similarité cosinus entre leurs embeddings.

    .PARAMETER TaskEmbeddings
        Les embeddings des tâches.

    .PARAMETER MinimumSimilarity
        La similarité minimale pour considérer deux tâches comme similaires.
        Par défaut, 0.7 (70%).

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$TaskEmbeddings,

        [Parameter(Mandatory = $false)]
        [double]$MinimumSimilarity = 0.7
    )

    try {
        $similarityMatrix = @{}

        # Calculer la similarité cosinus entre chaque paire de tâches
        foreach ($taskId1 in $TaskEmbeddings.Keys) {
            $similarityMatrix[$taskId1] = @{}

            foreach ($taskId2 in $TaskEmbeddings.Keys) {
                if ($taskId1 -eq $taskId2) {
                    # La similarité d'une tâche avec elle-même est 1
                    $similarityMatrix[$taskId1][$taskId2] = 1.0
                } else {
                    # Calculer la similarité cosinus
                    $embedding1 = $TaskEmbeddings[$taskId1]
                    $embedding2 = $TaskEmbeddings[$taskId2]

                    $similarity = Get-CosineSimilarity -Vector1 $embedding1 -Vector2 $embedding2

                    # Ne stocker que les similarités supérieures au seuil
                    if ($similarity -ge $MinimumSimilarity) {
                        $similarityMatrix[$taskId1][$taskId2] = $similarity
                    }
                }
            }
        }

        return $similarityMatrix
    } catch {
        Write-Error "Échec du calcul de la matrice de similarité: $($_.Exception.Message)"
        return @{}
    }
}

# Fonction pour déterminer le nombre optimal de clusters
function Get-OptimalClusterCount {
    <#
    .SYNOPSIS
        Détermine le nombre optimal de clusters pour les tâches.

    .DESCRIPTION
        Cette fonction détermine le nombre optimal de clusters pour les tâches,
        en utilisant la méthode du coude ou la méthode de la silhouette.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .PARAMETER Tasks
        Les tâches à classifier.

    .PARAMETER MaxClusters
        Le nombre maximum de clusters à considérer.
        Par défaut, 20 clusters.

    .PARAMETER Method
        La méthode à utiliser pour déterminer le nombre optimal de clusters.
        Par défaut, "elbow" (méthode du coude).

    .OUTPUTS
        Int
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix,

        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [int]$MaxClusters = 20,

        [Parameter(Mandatory = $false)]
        [ValidateSet("elbow", "silhouette")]
        [string]$Method = "elbow"
    )

    try {
        # Limiter le nombre maximum de clusters au nombre de tâches
        $MaxClusters = [Math]::Min($MaxClusters, $Tasks.Count)

        # Méthode du coude
        if ($Method -eq "elbow") {
            # Calculer l'inertie pour différents nombres de clusters
            $inertias = @{}

            for ($k = 2; $k -le $MaxClusters; $k++) {
                # Exécuter K-means avec k clusters
                $clusters = Invoke-KMeansClustering -TaskEmbeddings $TaskEmbeddings -NumberOfClusters $k -MaxIterations 10

                # Calculer l'inertie (somme des distances au carré)
                $inertia = 0

                foreach ($cluster in $clusters.Values) {
                    $centroid = $cluster.Centroid

                    foreach ($taskId in $cluster.TaskIds) {
                        $embedding = $TaskEmbeddings[$taskId]
                        $distance = 1 - (Get-CosineSimilarity -Vector1 $embedding -Vector2 $centroid)
                        $inertia += [Math]::Pow($distance, 2)
                    }
                }

                $inertias[$k] = $inertia
            }

            # Trouver le coude (point d'inflexion)
            $optimalK = 2
            $maxCurvature = 0

            for ($k = 3; $k -lt $MaxClusters; $k++) {
                $prev = $inertias[$k - 1]
                $curr = $inertias[$k]
                $next = $inertias[$k + 1]

                # Calculer la courbure approximative
                $curvature = ($prev - 2 * $curr + $next)

                if ($curvature -gt $maxCurvature) {
                    $maxCurvature = $curvature
                    $optimalK = $k
                }
            }

            return $optimalK
        }
        # Méthode de la silhouette
        elseif ($Method -eq "silhouette") {
            # Calculer le score de silhouette pour différents nombres de clusters
            $silhouetteScores = @{}

            for ($k = 2; $k -le $MaxClusters; $k++) {
                # Exécuter K-means avec k clusters
                $clusters = Invoke-KMeansClustering -TaskEmbeddings $TaskEmbeddings -NumberOfClusters $k -MaxIterations 10

                # Calculer le score de silhouette
                $silhouetteScore = Get-SilhouetteScore -Clusters $clusters -SimilarityMatrix $SimilarityMatrix
                $silhouetteScores[$k] = $silhouetteScore
            }

            # Trouver le nombre de clusters avec le meilleur score de silhouette
            $optimalK = 2
            $maxScore = $silhouetteScores[2]

            for ($k = 3; $k -le $MaxClusters; $k++) {
                if ($silhouetteScores[$k] -gt $maxScore) {
                    $maxScore = $silhouetteScores[$k]
                    $optimalK = $k
                }
            }

            return $optimalK
        }

        # Par défaut, retourner un nombre basé sur la taille du jeu de données
        $defaultK = [Math]::Max(2, [Math]::Min(10, [Math]::Ceiling($Tasks.Count / 20)))
        return $defaultK
    } catch {
        Write-Error "Échec de la détermination du nombre optimal de clusters: $($_.Exception.Message)"
        return 5  # Valeur par défaut
    }
}

# Fonction pour implémenter l'algorithme de clustering K-means
function Invoke-KMeansClustering {
    <#
    .SYNOPSIS
        Implémente l'algorithme de clustering K-means pour les tâches.

    .DESCRIPTION
        Cette fonction implémente l'algorithme de clustering K-means pour les tâches,
        en utilisant la similarité cosinus comme mesure de distance.

    .PARAMETER TaskEmbeddings
        Les embeddings des tâches.

    .PARAMETER NumberOfClusters
        Le nombre de clusters à créer.

    .PARAMETER MaxIterations
        Le nombre maximum d'itérations de l'algorithme.
        Par défaut, 100 itérations.

    .PARAMETER Tolerance
        La tolérance pour la convergence de l'algorithme.
        Par défaut, 0.001.

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$TaskEmbeddings,

        [Parameter(Mandatory = $true)]
        [int]$NumberOfClusters,

        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 100,

        [Parameter(Mandatory = $false)]
        [double]$Tolerance = 0.001
    )

    try {
        # Initialiser les clusters avec des centroïdes aléatoires
        $clusters = @{}
        $taskIds = $TaskEmbeddings.Keys
        $dimension = $TaskEmbeddings[$taskIds[0]].Length

        # Sélectionner des tâches aléatoires comme centroïdes initiaux
        $centroidTaskIds = $taskIds | Get-Random -Count $NumberOfClusters

        for ($i = 0; $i -lt $NumberOfClusters; $i++) {
            $clusterId = $i + 1
            $centroidTaskId = $centroidTaskIds[$i]

            $clusters[$clusterId] = [PSCustomObject]@{
                ClusterId = $clusterId
                Centroid  = $TaskEmbeddings[$centroidTaskId]
                TaskIds   = @()
            }
        }

        # Itérer jusqu'à convergence ou nombre maximum d'itérations
        $converged = $false
        $iteration = 0

        while (-not $converged -and $iteration -lt $MaxIterations) {
            $iteration++

            # Réinitialiser les tâches dans chaque cluster
            foreach ($clusterId in $clusters.Keys) {
                $clusters[$clusterId].TaskIds = @()
            }

            # Assigner chaque tâche au cluster le plus proche
            foreach ($taskId in $taskIds) {
                $embedding = $TaskEmbeddings[$taskId]
                $bestClusterId = 0
                $bestSimilarity = -1

                foreach ($clusterId in $clusters.Keys) {
                    $centroid = $clusters[$clusterId].Centroid
                    $similarity = Get-CosineSimilarity -Vector1 $embedding -Vector2 $centroid

                    if ($similarity -gt $bestSimilarity) {
                        $bestSimilarity = $similarity
                        $bestClusterId = $clusterId
                    }
                }

                $clusters[$bestClusterId].TaskIds += $taskId
            }

            # Mettre à jour les centroïdes et vérifier la convergence
            $maxCentroidChange = 0

            foreach ($clusterId in $clusters.Keys) {
                $cluster = $clusters[$clusterId]

                # Si le cluster est vide, garder le centroïde actuel
                if ($cluster.TaskIds.Count -eq 0) {
                    continue
                }

                # Calculer le nouveau centroïde
                $newCentroid = New-Object double[] $dimension

                foreach ($taskId in $cluster.TaskIds) {
                    $embedding = $TaskEmbeddings[$taskId]

                    for ($i = 0; $i -lt $dimension; $i++) {
                        $newCentroid[$i] += $embedding[$i]
                    }
                }

                for ($i = 0; $i -lt $dimension; $i++) {
                    $newCentroid[$i] /= $cluster.TaskIds.Count
                }

                # Calculer le changement du centroïde
                $centroidChange = 1 - (Get-CosineSimilarity -Vector1 $cluster.Centroid -Vector2 $newCentroid)
                $maxCentroidChange = [Math]::Max($maxCentroidChange, $centroidChange)

                # Mettre à jour le centroïde
                $cluster.Centroid = $newCentroid
            }

            # Vérifier la convergence
            $converged = $maxCentroidChange -lt $Tolerance
        }

        return $clusters
    } catch {
        Write-Error "Échec du clustering K-means: $($_.Exception.Message)"
        return @{}
    }
}

# Fonction pour implémenter l'algorithme de clustering hiérarchique
function Invoke-HierarchicalClustering {
    <#
    .SYNOPSIS
        Implémente l'algorithme de clustering hiérarchique pour les tâches.

    .DESCRIPTION
        Cette fonction implémente l'algorithme de clustering hiérarchique pour les tâches,
        en utilisant la similarité cosinus comme mesure de distance.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .PARAMETER NumberOfClusters
        Le nombre de clusters à créer.

    .PARAMETER LinkageMethod
        La méthode de liaison à utiliser.
        Par défaut, "average" (liaison moyenne).

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix,

        [Parameter(Mandatory = $true)]
        [int]$NumberOfClusters,

        [Parameter(Mandatory = $false)]
        [ValidateSet("single", "complete", "average", "ward")]
        [string]$LinkageMethod = "average"
    )

    try {
        # Initialiser chaque tâche comme un cluster séparé
        $clusters = @{}
        $taskIds = $SimilarityMatrix.Keys

        foreach ($taskId in $taskIds) {
            $clusters[$taskId] = [PSCustomObject]@{
                ClusterId = $taskId
                TaskIds   = @($taskId)
            }
        }

        # Fusionner les clusters jusqu'à atteindre le nombre souhaité
        while ($clusters.Count -gt $NumberOfClusters) {
            # Trouver les deux clusters les plus similaires
            $bestPair = $null
            $bestSimilarity = -1

            foreach ($clusterId1 in $clusters.Keys) {
                foreach ($clusterId2 in $clusters.Keys) {
                    if ($clusterId1 -eq $clusterId2) {
                        continue
                    }

                    # Calculer la similarité entre les clusters selon la méthode de liaison
                    $similarity = switch ($LinkageMethod) {
                        "single" { Get-SingleLinkageSimilarity -Cluster1 $clusters[$clusterId1] -Cluster2 $clusters[$clusterId2] -SimilarityMatrix $SimilarityMatrix }
                        "complete" { Get-CompleteLinkageSimilarity -Cluster1 $clusters[$clusterId1] -Cluster2 $clusters[$clusterId2] -SimilarityMatrix $SimilarityMatrix }
                        "average" { Get-AverageLinkageSimilarity -Cluster1 $clusters[$clusterId1] -Cluster2 $clusters[$clusterId2] -SimilarityMatrix $SimilarityMatrix }
                        "ward" { Get-WardLinkageSimilarity -Cluster1 $clusters[$clusterId1] -Cluster2 $clusters[$clusterId2] -SimilarityMatrix $SimilarityMatrix }
                    }

                    if ($similarity -gt $bestSimilarity) {
                        $bestSimilarity = $similarity
                        $bestPair = @($clusterId1, $clusterId2)
                    }
                }
            }

            # Fusionner les deux clusters
            $clusterId1 = $bestPair[0]
            $clusterId2 = $bestPair[1]
            $newClusterId = "$clusterId1-$clusterId2"

            $clusters[$newClusterId] = [PSCustomObject]@{
                ClusterId = $newClusterId
                TaskIds   = $clusters[$clusterId1].TaskIds + $clusters[$clusterId2].TaskIds
            }

            # Supprimer les clusters fusionnés
            $clusters.Remove($clusterId1)
            $clusters.Remove($clusterId2)
        }

        # Renommer les clusters avec des identifiants numériques
        $result = @{}
        $clusterIndex = 1

        foreach ($clusterId in $clusters.Keys) {
            $result[$clusterIndex] = [PSCustomObject]@{
                ClusterId = $clusterIndex
                TaskIds   = $clusters[$clusterId].TaskIds
            }

            $clusterIndex++
        }

        return $result
    } catch {
        Write-Error "Échec du clustering hiérarchique: $($_.Exception.Message)"
        return @{}
    }
}

# Fonction pour calculer la similarité cosinus
function Get-CosineSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité cosinus entre deux vecteurs.

    .DESCRIPTION
        Cette fonction calcule la similarité cosinus entre deux vecteurs,
        qui est une mesure de similarité entre -1 et 1.

    .PARAMETER Vector1
        Le premier vecteur.

    .PARAMETER Vector2
        Le deuxième vecteur.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Vector1,

        [Parameter(Mandatory = $true)]
        [double[]]$Vector2
    )

    try {
        # Vérifier que les vecteurs ont la même dimension
        if ($Vector1.Length -ne $Vector2.Length) {
            Write-Error "Les vecteurs doivent avoir la même dimension."
            return 0
        }

        # Calculer le produit scalaire
        $dotProduct = 0
        for ($i = 0; $i -lt $Vector1.Length; $i++) {
            $dotProduct += $Vector1[$i] * $Vector2[$i]
        }

        # Calculer les normes
        $norm1 = 0
        $norm2 = 0

        for ($i = 0; $i -lt $Vector1.Length; $i++) {
            $norm1 += [Math]::Pow($Vector1[$i], 2)
            $norm2 += [Math]::Pow($Vector2[$i], 2)
        }

        $norm1 = [Math]::Sqrt($norm1)
        $norm2 = [Math]::Sqrt($norm2)

        # Calculer la similarité cosinus
        if ($norm1 -eq 0 -or $norm2 -eq 0) {
            return 0
        }

        $similarity = $dotProduct / ($norm1 * $norm2)

        # Normaliser entre 0 et 1 (la similarité cosinus est entre -1 et 1)
        $similarity = ($similarity + 1) / 2

        return $similarity
    } catch {
        Write-Error "Échec du calcul de la similarité cosinus: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité de liaison simple
function Get-SingleLinkageSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité de liaison simple entre deux clusters.

    .DESCRIPTION
        Cette fonction calcule la similarité de liaison simple entre deux clusters,
        qui est la similarité maximale entre toutes les paires de tâches des deux clusters.

    .PARAMETER Cluster1
        Le premier cluster.

    .PARAMETER Cluster2
        Le deuxième cluster.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster1,

        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster2,

        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix
    )

    try {
        $maxSimilarity = 0

        foreach ($taskId1 in $Cluster1.TaskIds) {
            foreach ($taskId2 in $Cluster2.TaskIds) {
                if ($SimilarityMatrix.ContainsKey($taskId1) -and $SimilarityMatrix[$taskId1].ContainsKey($taskId2)) {
                    $similarity = $SimilarityMatrix[$taskId1][$taskId2]
                    $maxSimilarity = [Math]::Max($maxSimilarity, $similarity)
                }
            }
        }

        return $maxSimilarity
    } catch {
        Write-Error "Échec du calcul de la similarité de liaison simple: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité de liaison complète
function Get-CompleteLinkageSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité de liaison complète entre deux clusters.

    .DESCRIPTION
        Cette fonction calcule la similarité de liaison complète entre deux clusters,
        qui est la similarité minimale entre toutes les paires de tâches des deux clusters.

    .PARAMETER Cluster1
        Le premier cluster.

    .PARAMETER Cluster2
        Le deuxième cluster.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster1,

        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster2,

        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix
    )

    try {
        $minSimilarity = 1

        foreach ($taskId1 in $Cluster1.TaskIds) {
            foreach ($taskId2 in $Cluster2.TaskIds) {
                if ($SimilarityMatrix.ContainsKey($taskId1) -and $SimilarityMatrix[$taskId1].ContainsKey($taskId2)) {
                    $similarity = $SimilarityMatrix[$taskId1][$taskId2]
                    $minSimilarity = [Math]::Min($minSimilarity, $similarity)
                } else {
                    $minSimilarity = 0
                }
            }
        }

        return $minSimilarity
    } catch {
        Write-Error "Échec du calcul de la similarité de liaison complète: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité de liaison moyenne
function Get-AverageLinkageSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité de liaison moyenne entre deux clusters.

    .DESCRIPTION
        Cette fonction calcule la similarité de liaison moyenne entre deux clusters,
        qui est la moyenne des similarités entre toutes les paires de tâches des deux clusters.

    .PARAMETER Cluster1
        Le premier cluster.

    .PARAMETER Cluster2
        Le deuxième cluster.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster1,

        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster2,

        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix
    )

    try {
        $totalSimilarity = 0
        $pairCount = 0

        foreach ($taskId1 in $Cluster1.TaskIds) {
            foreach ($taskId2 in $Cluster2.TaskIds) {
                if ($SimilarityMatrix.ContainsKey($taskId1) -and $SimilarityMatrix[$taskId1].ContainsKey($taskId2)) {
                    $similarity = $SimilarityMatrix[$taskId1][$taskId2]
                    $totalSimilarity += $similarity
                    $pairCount++
                }
            }
        }

        if ($pairCount -eq 0) {
            return 0
        }

        return $totalSimilarity / $pairCount
    } catch {
        Write-Error "Échec du calcul de la similarité de liaison moyenne: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité de liaison de Ward
function Get-WardLinkageSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité de liaison de Ward entre deux clusters.

    .DESCRIPTION
        Cette fonction calcule la similarité de liaison de Ward entre deux clusters,
        qui est basée sur l'augmentation de la variance intra-cluster après fusion.

    .PARAMETER Cluster1
        Le premier cluster.

    .PARAMETER Cluster2
        Le deuxième cluster.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster1,

        [Parameter(Mandatory = $true)]
        [PSObject]$Cluster2,

        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix
    )

    try {
        # Calculer la similarité moyenne entre les clusters
        $averageSimilarity = Get-AverageLinkageSimilarity -Cluster1 $Cluster1 -Cluster2 $Cluster2 -SimilarityMatrix $SimilarityMatrix

        # Calculer la taille des clusters
        $n1 = $Cluster1.TaskIds.Count
        $n2 = $Cluster2.TaskIds.Count

        # Calculer la similarité de Ward (approximation basée sur la similarité)
        $wardSimilarity = $averageSimilarity * ($n1 * $n2) / ($n1 + $n2)

        return $wardSimilarity
    } catch {
        Write-Error "Échec du calcul de la similarité de liaison de Ward: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer le score de silhouette
function Get-SilhouetteScore {
    <#
    .SYNOPSIS
        Calcule le score de silhouette pour un ensemble de clusters.

    .DESCRIPTION
        Cette fonction calcule le score de silhouette pour un ensemble de clusters,
        qui est une mesure de la qualité du clustering.

    .PARAMETER Clusters
        Les clusters pour lesquels calculer le score de silhouette.

    .PARAMETER SimilarityMatrix
        La matrice de similarité entre les tâches.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$Clusters,

        [Parameter(Mandatory = $true)]
        [Hashtable]$SimilarityMatrix
    )

    try {
        $silhouetteScores = @()

        # Pour chaque tâche
        foreach ($clusterId in $Clusters.Keys) {
            $cluster = $Clusters[$clusterId]

            foreach ($taskId in $cluster.TaskIds) {
                # Calculer la cohésion (similarité moyenne avec les autres tâches du même cluster)
                $cohesion = 0
                $cohesionCount = 0

                foreach ($otherTaskId in $cluster.TaskIds) {
                    if ($taskId -ne $otherTaskId) {
                        if ($SimilarityMatrix.ContainsKey($taskId) -and $SimilarityMatrix[$taskId].ContainsKey($otherTaskId)) {
                            $similarity = $SimilarityMatrix[$taskId][$otherTaskId]
                            $cohesion += $similarity
                            $cohesionCount++
                        }
                    }
                }

                if ($cohesionCount -eq 0) {
                    $cohesion = 0
                } else {
                    $cohesion /= $cohesionCount
                }

                # Calculer la séparation (similarité moyenne avec les tâches des autres clusters)
                $bestSeparation = 0

                foreach ($otherClusterId in $Clusters.Keys) {
                    if ($otherClusterId -ne $clusterId) {
                        $otherCluster = $Clusters[$otherClusterId]
                        $separation = 0
                        $separationCount = 0

                        foreach ($otherTaskId in $otherCluster.TaskIds) {
                            if ($SimilarityMatrix.ContainsKey($taskId) -and $SimilarityMatrix[$taskId].ContainsKey($otherTaskId)) {
                                $similarity = $SimilarityMatrix[$taskId][$otherTaskId]
                                $separation += $similarity
                                $separationCount++
                            }
                        }

                        if ($separationCount -gt 0) {
                            $separation /= $separationCount

                            if ($separation -gt $bestSeparation) {
                                $bestSeparation = $separation
                            }
                        }
                    }
                }

                # Calculer le score de silhouette
                if ($cohesion -eq 0 -and $bestSeparation -eq 0) {
                    $silhouetteScore = 0
                } else {
                    $silhouetteScore = ($bestSeparation - $cohesion) / [Math]::Max($cohesion, $bestSeparation)
                }

                $silhouetteScores += $silhouetteScore
            }
        }

        # Calculer le score de silhouette moyen
        if ($silhouetteScores.Count -eq 0) {
            return 0
        }

        return ($silhouetteScores | Measure-Object -Average).Average
    } catch {
        Write-Error "Échec du calcul du score de silhouette: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour générer les étiquettes des clusters
function Get-ClusterLabels {
    <#
    .SYNOPSIS
        Génère les étiquettes pour les clusters.

    .DESCRIPTION
        Cette fonction génère les étiquettes pour les clusters,
        en utilisant les termes les plus fréquents dans les tâches de chaque cluster.

    .PARAMETER Clusters
        Les clusters pour lesquels générer les étiquettes.

    .PARAMETER Tasks
        Les tâches à classifier.

    .PARAMETER MaxTerms
        Le nombre maximum de termes à inclure dans l'étiquette.
        Par défaut, 5 termes.

    .OUTPUTS
        PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$Clusters,

        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [int]$MaxTerms = 5
    )

    try {
        $labeledClusters = @()

        # Créer un dictionnaire pour accéder rapidement aux tâches par ID
        $taskDict = @{}
        foreach ($task in $Tasks) {
            $taskDict[$task.Id] = $task
        }

        # Pour chaque cluster
        foreach ($clusterId in $Clusters.Keys) {
            $cluster = $Clusters[$clusterId]
            $clusterTasks = @()

            # Récupérer les tâches du cluster
            foreach ($taskId in $cluster.TaskIds) {
                if ($taskDict.ContainsKey($taskId)) {
                    $clusterTasks += $taskDict[$taskId]
                }
            }

            # Extraire les termes des titres et descriptions des tâches
            $terms = @{}

            foreach ($task in $clusterTasks) {
                $text = $task.Title

                if ($task.PSObject.Properties.Name.Contains("Description") -and -not [string]::IsNullOrEmpty($task.Description)) {
                    $text += " " + $task.Description
                }

                # Tokeniser le texte
                $tokens = $text -split '\W+' | Where-Object { $_.Length -gt 2 } | ForEach-Object { $_.ToLower() }

                # Compter les occurrences des termes
                foreach ($token in $tokens) {
                    if (-not $terms.ContainsKey($token)) {
                        $terms[$token] = 0
                    }

                    $terms[$token]++
                }
            }

            # Filtrer les mots vides
            $stopWords = @("the", "and", "for", "with", "this", "that", "from", "have", "has", "had", "not", "are", "were", "was", "will", "would", "should", "could", "can", "may", "might", "must", "shall")
            foreach ($stopWord in $stopWords) {
                $terms.Remove($stopWord)
            }

            # Trier les termes par fréquence
            $sortedTerms = $terms.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $MaxTerms

            # Générer l'étiquette
            $label = $sortedTerms | ForEach-Object { $_.Key } | Join-String -Separator ", "

            # Créer l'objet de cluster étiqueté
            $labeledCluster = [PSCustomObject]@{
                ClusterId = $clusterId
                Label     = $label
                TaskIds   = $cluster.TaskIds
                TaskCount = $cluster.TaskIds.Count
                TopTerms  = $sortedTerms | ForEach-Object { [PSCustomObject]@{ Term = $_.Key; Frequency = $_.Value } }
            }

            $labeledClusters += $labeledCluster
        }

        return $labeledClusters
    } catch {
        Write-Error "Échec de la génération des étiquettes des clusters: $($_.Exception.Message)"
        return @()
    }
}

# Fonction pour vérifier la connexion à Qdrant
function Test-QdrantConnection {
    <#
    .SYNOPSIS
        Vérifie la connexion à Qdrant.

    .DESCRIPTION
        Cette fonction vérifie la connexion à Qdrant,
        en envoyant une requête à l'endpoint de santé.

    .PARAMETER QdrantEndpoint
        L'endpoint Qdrant à vérifier.

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantEndpoint
    )

    try {
        $healthEndpoint = "$QdrantEndpoint/health"
        $response = Invoke-RestMethod -Uri $healthEndpoint -Method Get -ErrorAction Stop

        return $response.status -eq "ok"
    } catch {
        Write-Warning "Échec de la connexion à Qdrant: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour ajouter les tâches à Qdrant
function Add-TasksToQdrant {
    <#
    .SYNOPSIS
        Ajoute les tâches à Qdrant.

    .DESCRIPTION
        Cette fonction ajoute les tâches à Qdrant,
        en créant une collection si elle n'existe pas déjà.

    .PARAMETER TaskEmbeddings
        Les embeddings des tâches.

    .PARAMETER Clusters
        Les clusters étiquetés.

    .PARAMETER QdrantEndpoint
        L'endpoint Qdrant.

    .PARAMETER QdrantCollection
        La collection Qdrant.

    .OUTPUTS
        Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$TaskEmbeddings,

        [Parameter(Mandatory = $true)]
        [array]$Clusters,

        [Parameter(Mandatory = $true)]
        [string]$QdrantEndpoint,

        [Parameter(Mandatory = $true)]
        [string]$QdrantCollection
    )

    try {
        # Vérifier si la collection existe
        $collectionEndpoint = "$QdrantEndpoint/collections/$QdrantCollection"
        $collectionExists = $false

        try {
            $response = Invoke-RestMethod -Uri $collectionEndpoint -Method Get -ErrorAction Stop
            $collectionExists = $true
        } catch {
            $collectionExists = $false
        }

        # Créer la collection si elle n'existe pas
        if (-not $collectionExists) {
            $createCollectionEndpoint = "$QdrantEndpoint/collections/$QdrantCollection"
            $dimension = $TaskEmbeddings[$TaskEmbeddings.Keys[0]].Length

            $body = @{
                vectors = @{
                    size     = $dimension
                    distance = "Cosine"
                }
            } | ConvertTo-Json

            $response = Invoke-RestMethod -Uri $createCollectionEndpoint -Method Put -Body $body -ContentType "application/json"

            if ($response.status -ne "ok") {
                Write-Error "Échec de la création de la collection Qdrant: $($response.status)"
                return $false
            }
        }

        # Créer un dictionnaire pour accéder rapidement aux clusters par ID de tâche
        $taskClusters = @{}

        foreach ($cluster in $Clusters) {
            foreach ($taskId in $cluster.TaskIds) {
                $taskClusters[$taskId] = $cluster
            }
        }

        # Ajouter les tâches à Qdrant
        $pointsEndpoint = "$QdrantEndpoint/collections/$QdrantCollection/points"
        $batchSize = 100
        $taskIds = $TaskEmbeddings.Keys
        $totalTasks = $taskIds.Count
        $batches = [Math]::Ceiling($totalTasks / $batchSize)

        for ($i = 0; $i -lt $batches; $i++) {
            $startIndex = $i * $batchSize
            $endIndex = [Math]::Min(($i + 1) * $batchSize - 1, $totalTasks - 1)
            $batchTaskIds = $taskIds[$startIndex..$endIndex]

            $points = @()

            foreach ($taskId in $batchTaskIds) {
                $embedding = $TaskEmbeddings[$taskId]
                $cluster = $taskClusters[$taskId]

                $point = @{
                    id      = $taskId
                    vector  = $embedding
                    payload = @{
                        task_id       = $taskId
                        cluster_id    = $cluster.ClusterId
                        cluster_label = $cluster.Label
                    }
                }

                $points += $point
            }

            $body = @{
                points = $points
            } | ConvertTo-Json -Depth 10

            $response = Invoke-RestMethod -Uri $pointsEndpoint -Method Put -Body $body -ContentType "application/json"

            if ($response.status -ne "ok") {
                Write-Error "Échec de l'ajout des tâches à Qdrant: $($response.status)"
                return $false
            }
        }

        return $true
    } catch {
        Write-Error "Échec de l'ajout des tâches à Qdrant: $($_.Exception.Message)"
        return $false
    }
}

# Fonction pour générer un rapport de classification
function Get-ClassificationReport {
    <#
    .SYNOPSIS
        Génère un rapport de classification.

    .DESCRIPTION
        Cette fonction génère un rapport de classification,
        avec des visualisations et des statistiques sur les clusters.

    .PARAMETER LabeledClusters
        Les clusters étiquetés.

    .PARAMETER Config
        La configuration de la classification.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [array]$LabeledClusters,

        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    try {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de classification sémantique</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .cluster { margin-bottom: 20px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .cluster-header { background-color: #f2f2f2; padding: 10px; border-radius: 5px 5px 0 0; }
        .cluster-content { padding: 10px; }
        .term-frequency { display: inline-block; margin-right: 10px; }
        .term { font-weight: bold; }
        .frequency { color: #666; }
    </style>
</head>
<body>
    <h1>Rapport de classification sémantique</h1>

    <h2>Paramètres de classification</h2>
    <table>
        <tr>
            <th>Paramètre</th>
            <th>Valeur</th>
        </tr>
        <tr>
            <td>Fichier de roadmap</td>
            <td>$($Config.RoadmapPath)</td>
        </tr>
        <tr>
            <td>Modèle d'embedding</td>
            <td>$($Config.EmbeddingModel)</td>
        </tr>
        <tr>
            <td>Algorithme de clustering</td>
            <td>$($Config.ClusteringAlgorithm)</td>
        </tr>
        <tr>
            <td>Nombre de clusters</td>
            <td>$($Config.NumberOfClusters)</td>
        </tr>
        <tr>
            <td>Similarité minimale</td>
            <td>$($Config.MinimumSimilarity)</td>
        </tr>
        <tr>
            <td>Nombre total de tâches</td>
            <td>$($Config.Tasks.Count)</td>
        </tr>
    </table>

    <h2>Résumé des clusters</h2>
    <table>
        <tr>
            <th>ID</th>
            <th>Étiquette</th>
            <th>Nombre de tâches</th>
            <th>Termes principaux</th>
        </tr>
"@

        foreach ($cluster in $LabeledClusters) {
            $topTerms = $cluster.TopTerms | ForEach-Object { "$($_.Term) ($($_.Frequency))" } | Join-String -Separator ", "

            $html += @"
        <tr>
            <td>$($cluster.ClusterId)</td>
            <td>$($cluster.Label)</td>
            <td>$($cluster.TaskCount)</td>
            <td>$topTerms</td>
        </tr>
"@
        }

        $html += @"
    </table>

    <h2>Détails des clusters</h2>
"@

        foreach ($cluster in $LabeledClusters) {
            $html += @"
    <div class="cluster">
        <div class="cluster-header">
            <h3>Cluster $($cluster.ClusterId): $($cluster.Label)</h3>
            <div>
"@

            foreach ($term in $cluster.TopTerms) {
                $html += @"
                <div class="term-frequency">
                    <span class="term">$($term.Term)</span>
                    <span class="frequency">($($term.Frequency))</span>
                </div>
"@
            }

            $html += @"
            </div>
        </div>
        <div class="cluster-content">
            <h4>Tâches ($($cluster.TaskCount))</h4>
            <table>
                <tr>
                    <th>ID</th>
                    <th>Titre</th>
                </tr>
"@

            foreach ($taskId in $cluster.TaskIds) {
                $task = $Config.Tasks | Where-Object { $_.Id -eq $taskId }

                if ($null -ne $task) {
                    $html += @"
                <tr>
                    <td>$($task.Id)</td>
                    <td>$($task.Title)</td>
                </tr>
"@
                }
            }

            $html += @"
            </table>
        </div>
    </div>
"@
        }

        $html += @"
</body>
</html>
"@

        return $html
    } catch {
        Write-Error "Échec de la génération du rapport de classification: $($_.Exception.Message)"
        return ""
    }
}
