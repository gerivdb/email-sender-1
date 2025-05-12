# Index-TagsInQdrant.ps1
# Script pour indexer les tags dans Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "..\config\tag-formats\TagFormats.config.json",

    [Parameter(Mandatory = $false)]
    [string]$RoadmapsPath = "..\..\..\..\..\..\projet\roadmaps\plans",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tags",

    [Parameter(Mandatory = $false)]
    [int]$VectorDimension = 384,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = $scriptDir
$utilsDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "utils"

# Importer les modules
. (Join-Path -Path $metadataDir -ChildPath "Manage-TagFormats-Fixed.ps1")
. (Join-Path -Path $utilsDir -ChildPath "Write-Log.ps1")
. (Join-Path -Path $utilsDir -ChildPath "Get-OpenRouterEmbeddings.ps1")

# Fonction pour vérifier et démarrer le conteneur Docker de Qdrant
function Start-QdrantContainerIfNeeded {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$DataPath = "projet\roadmaps\vectors\qdrant_data",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le conteneur est accessible
    try {
        $testUrl = "$QdrantUrl/dashboard"
        $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue

        if ($response.StatusCode -eq 200) {
            Write-Log "Qdrant est accessible à l'URL: $QdrantUrl" -Level Success
            return $true
        }
    } catch {
        Write-Log "Qdrant n'est pas accessible à l'URL: $QdrantUrl" -Level Warning
    }

    # Vérifier si le script Start-QdrantContainer.ps1 existe
    $startScriptPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptDir)) -ChildPath "Start-QdrantContainer.ps1"
    if (-not (Test-Path -Path $startScriptPath)) {
        Write-Log "Le script Start-QdrantContainer.ps1 n'existe pas à l'emplacement: $startScriptPath" -Level Error
        return $false
    }

    # Démarrer le conteneur
    Write-Log "Démarrage du conteneur Qdrant..." -Level Info
    & $startScriptPath -Action Start -DataPath $DataPath -Force:$Force

    # Vérifier si le conteneur est maintenant accessible
    try {
        $testUrl = "$QdrantUrl/dashboard"
        $maxRetries = 5
        $retryCount = 0
        $success = $false

        while (-not $success -and $retryCount -lt $maxRetries) {
            try {
                $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $success = $true
                    Write-Log "Qdrant est maintenant accessible à l'URL: $QdrantUrl" -Level Success
                    return $true
                }
            } catch {
                $retryCount++
                Write-Log "Tentative $retryCount/$maxRetries - Qdrant n'est pas encore accessible..." -Level Warning
                Start-Sleep -Seconds 2
            }
        }

        if (-not $success) {
            Write-Log "Impossible d'accéder à Qdrant après $maxRetries tentatives" -Level Error
            return $false
        }
    } catch {
        Write-Log "Erreur lors de la vérification de l'accessibilité de Qdrant: $_" -Level Error
        return $false
    }

    return $false
}

# Fonction pour vérifier si une collection existe dans Qdrant
function Test-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        $collections = $response.result.collections

        foreach ($collection in $collections) {
            if ($collection.name -eq $CollectionName) {
                return $true
            }
        }

        return $false
    } catch {
        Write-Log "Erreur lors de la vérification de la collection Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour créer une collection dans Qdrant
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [int]$VectorDimension,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si la collection existe déjà
    if (Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName) {
        if ($Force) {
            # Supprimer la collection existante
            Write-Log "Suppression de la collection existante: $CollectionName" -Level Warning
            try {
                Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Delete | Out-Null
            } catch {
                Write-Log "Erreur lors de la suppression de la collection: $_" -Level Error
                return $false
            }
        } else {
            Write-Log "La collection $CollectionName existe déjà. Utilisez -Force pour la recréer." -Level Warning
            return $true
        }
    }

    # Créer la collection
    $body = @{
        vectors = @{
            size     = $VectorDimension
            distance = "Cosine"
        }
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Put -Body $body -ContentType "application/json" | Out-Null
        Write-Log "Collection $CollectionName créée avec succès" -Level Success
        return $true
    } catch {
        Write-Log "Erreur lors de la création de la collection: $_" -Level Error
        return $false
    }
}

# Fonction pour extraire les tags des roadmaps
function Get-RoadmapTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapsPath,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    # Charger la configuration des formats de tags
    $config = Get-TagFormatsConfig -ConfigPath $ConfigPath -CreateIfNotExists

    if (-not $config) {
        Write-Log "Impossible de charger la configuration des formats de tags" -Level Error
        return $null
    }

    # Récupérer tous les fichiers markdown dans le dossier des roadmaps
    $roadmapFiles = Get-ChildItem -Path $RoadmapsPath -Filter "*.md" -Recurse

    $allTags = @()

    foreach ($file in $roadmapFiles) {
        Write-Log "Analyse des tags dans le fichier: $($file.Name)" -Level Info

        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw

        # Extraire les tâches du contenu
        $tasks = Get-TasksFromContent -Content $content

        foreach ($task in $tasks) {
            # Extraire les tags de la tâche
            $tags = Get-TagsFromTask -Task $task -Config $config

            foreach ($tag in $tags) {
                $tagInfo = @{
                    FilePath = $file.FullName
                    FileName = $file.Name
                    TaskId   = $task.Id
                    TaskText = $task.Text
                    TagType  = $tag.Type
                    TagName  = $tag.Name
                    TagValue = $tag.Value
                    TagUnit  = $tag.Unit
                }

                $allTags += $tagInfo
            }
        }
    }

    return $allTags
}

# Fonction pour extraire les tâches du contenu
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $tasks = @()

    # Expression régulière pour extraire les tâches avec leur ID et leur texte
    $taskRegex = '- \[([ x])\] \*\*([^*]+)\*\* (.+?)(?=\n- \[|$)'

    $taskMatches = [regex]::Matches($Content, $taskRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    foreach ($match in $taskMatches) {
        $status = $match.Groups[1].Value -eq 'x'
        $id = $match.Groups[2].Value.Trim()
        $text = $match.Groups[3].Value.Trim()

        $task = @{
            Id     = $id
            Text   = $text
            Status = $status
        }

        $tasks += $task
    }

    return $tasks
}

# Fonction pour extraire les tags d'une tâche
function Get-TagsFromTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Task,

        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    $tags = @()

    # Parcourir tous les types de tags dans la configuration
    foreach ($tagType in $Config.tag_formats.PSObject.Properties.Name) {
        $tagTypeConfig = $Config.tag_formats.$tagType

        # Parcourir tous les formats pour ce type de tag
        foreach ($format in $tagTypeConfig.formats) {
            $pattern = $format.pattern

            # Rechercher les correspondances dans le texte de la tâche
            $tagMatches = [regex]::Matches($Task.Text, $pattern)

            foreach ($match in $tagMatches) {
                $value = $null

                # Extraire la valeur si un groupe de capture est spécifié
                if ($format.value_group -gt 0 -and $match.Groups.Count -gt $format.value_group) {
                    $value = $match.Groups[$format.value_group].Value
                }

                $tag = @{
                    Type      = $tagType
                    Name      = $format.name
                    Value     = $value
                    Unit      = $format.unit
                    FullMatch = $match.Value
                }

                $tags += $tag
            }
        }
    }

    return $tags
}

# Fonction principale
function Main {
    # Vérifier et démarrer le conteneur Docker de Qdrant si nécessaire
    if (-not (Start-QdrantContainerIfNeeded -QdrantUrl $QdrantUrl -Force:$Force)) {
        Write-Log "Impossible d'assurer que le conteneur Docker de Qdrant est en cours d'exécution. Le script ne peut pas continuer." -Level Error
        return
    }

    # Créer la collection Qdrant si elle n'existe pas
    if (-not (New-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VectorDimension $VectorDimension -Force:$Force)) {
        Write-Log "Impossible de créer la collection Qdrant. Le script ne peut pas continuer." -Level Error
        return
    }

    # Extraire les tags des roadmaps
    $tags = Get-RoadmapTags -RoadmapsPath $RoadmapsPath -ConfigPath $ConfigPath

    if (-not $tags -or $tags.Count -eq 0) {
        Write-Log "Aucun tag trouvé dans les roadmaps" -Level Warning
        return
    }

    Write-Log "Nombre de tags trouvés: $($tags.Count)" -Level Info

    # Indexer les tags dans Qdrant
    $indexedCount = 0

    # Compteur pour les IDs des tags
    $tagIdCounter = 1

    foreach ($tag in $tags) {
        # Générer un ID unique pour le tag
        $tagId = $tagIdCounter
        $tagIdCounter++

        # Créer le texte pour l'embedding
        $tagText = "Type: $($tag.TagType), Name: $($tag.TagName), Value: $($tag.TagValue), Unit: $($tag.TagUnit), Task: $($tag.TaskText)"

        # Générer l'embedding pour le tag
        $embedding = Get-OpenRouterEmbeddings -Text $tagText -TestMode

        # Redimensionner l'embedding à la dimension spécifiée
        if ($embedding.Count -ne $VectorDimension) {
            Write-Log "Redimensionnement de l'embedding de $($embedding.Count) à $VectorDimension dimensions" -Level Warning

            if ($embedding.Count -gt $VectorDimension) {
                # Tronquer l'embedding
                $embedding = $embedding[0..($VectorDimension - 1)]
            } else {
                # Étendre l'embedding avec des zéros
                $embedding = $embedding + (New-Object float[] ($VectorDimension - $embedding.Count))
            }
        }

        if (-not $embedding) {
            Write-Log "Impossible de générer l'embedding pour le tag: $tagText" -Level Warning
            continue
        }

        # Créer le payload pour Qdrant
        $payload = @{
            file_path = $tag.FilePath
            file_name = $tag.FileName
            task_id   = $tag.TaskId
            task_text = $tag.TaskText
            tag_type  = $tag.TagType
            tag_name  = $tag.TagName
            tag_value = $tag.TagValue
            tag_unit  = $tag.TagUnit
            tag_text  = $tagText
        }

        # Ajouter le tag à Qdrant
        $body = @{
            points = @(
                @{
                    id      = $tagId
                    vector  = $embedding
                    payload = $payload
                }
            )
        } | ConvertTo-Json -Depth 10

        try {
            Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points" -Method Put -Body $body -ContentType "application/json" | Out-Null
            $indexedCount++

            if ($indexedCount % 10 -eq 0) {
                Write-Log "Progression: $indexedCount/$($tags.Count) tags indexés" -Level Info
            }
        } catch {
            Write-Log "Erreur lors de l'indexation du tag dans Qdrant: $_" -Level Error
        }
    }

    Write-Log "Indexation terminée. $indexedCount/$($tags.Count) tags indexés avec succès." -Level Success
}

# Exécuter la fonction principale
Main
