﻿# Fix-RoadmapVectorization.ps1
# Script pour corriger les problèmes de vectorisation des tâches de roadmap dans Qdrant

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapDir = "projet\roadmaps\plans\consolidated",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [string]$ModelEndpoint = "https://api.openrouter.ai/api/v1/embeddings",

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = $env:OPENROUTER_API_KEY,

    [Parameter(Mandatory = $false)]
    [string]$ModelName = "qwen/qwen2-7b",

    [Parameter(Mandatory = $false)]
    [int]$VectorDimension = 1536,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "..\utils\Common-Utils.ps1"
$diagnosticPath = Join-Path -Path $scriptPath -ChildPath "Diagnostic-RoadmapVectorization.ps1"

if (Test-Path -Path $utilsPath) {
    . $utilsPath
} else {
    Write-Error "Le fichier d'utilitaires communs est introuvable: $utilsPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour analyser un fichier Markdown et extraire les tâches
function Get-MarkdownTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Extraire les tâches avec regex améliorée pour capturer différents formats
        $taskPattern = '- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
        $matches = [regex]::Matches($content, $taskPattern)

        $tasks = @()
        foreach ($match in $matches) {
            $status = $match.Groups[1].Value
            $taskId = $match.Groups[2].Value
            $description = $match.Groups[3].Value.Trim()

            # Déterminer le niveau d'indentation
            $indentLevel = ($taskId -split '\.').Count

            # Déterminer l'ID parent
            $parentId = if ($indentLevel -gt 1) {
                $parts = $taskId -split '\.'
                $parts[0..($parts.Count - 2)] -join '.'
            } else {
                ""
            }

            # Extraire la section (en cherchant le dernier titre avant la tâche)
            $sectionPattern = '##\s+(.*?)(?:\r?\n)'
            $sections = [regex]::Matches($content, $sectionPattern)
            $section = "Non spécifié"

            foreach ($sec in $sections) {
                if ($sec.Index -lt $match.Index) {
                    $section = $sec.Groups[1].Value.Trim()
                } else {
                    break
                }
            }

            # Extraire les métadonnées supplémentaires (MVP, priorité, etc.)
            $isMVP = $description -match '\bMVP\b'
            $priorityMatch = [regex]::Match($description, '\b(P[0-3])\b')
            $priority = if ($priorityMatch.Success) { $priorityMatch.Groups[1].Value } else { "P3" }

            # Estimer le temps (si présent dans la description)
            $timeMatch = [regex]::Match($description, '\b(\d+[hj])\b')
            $estimatedTime = if ($timeMatch.Success) { $timeMatch.Groups[1].Value } else { "" }

            # Déterminer la catégorie
            $category = "non_categorise"
            if ($description -match '\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b') {
                $category = $Matches[1]
            }

            $tasks += [PSCustomObject]@{
                TaskId = $taskId
                Description = $description
                Status = if ($status -match '[xX]') { "completed" } else { "pending" }
                IndentLevel = $indentLevel
                ParentId = $parentId
                Section = $section
                FilePath = $FilePath
                IsMVP = $isMVP
                Priority = $priority
                EstimatedTime = $estimatedTime
                Category = $category
                LastUpdated = (Get-Date).ToString("o")
            }
        }

        return $tasks
    } catch {
        Write-Log "Erreur lors de l'analyse du fichier $FilePath : $_" -Level Error
        return @()
    }
}

# Fonction pour vérifier l'état de Qdrant
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        return $true
    } catch {
        Write-Log "Erreur de connexion à Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour vérifier si une collection existe
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
        return $collections | Where-Object { $_.name -eq $CollectionName }
    } catch {
        Write-Log "Erreur lors de la vérification de la collection: $_" -Level Error
        return $null
    }
}

# Fonction pour créer une collection Qdrant
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $false)]
        [int]$VectorSize = 1536
    )

    try {
        $body = @{
            vectors = @{
                size = $VectorSize
                distance = "Cosine"
            }
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Put -Body $body -ContentType "application/json"
        return $response.result
    } catch {
        Write-Log "Erreur lors de la création de la collection: $_" -Level Error
        return $null
    }
}

# Fonction pour obtenir un embedding
function Get-Embedding {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $env:OPENROUTER_API_KEY,

        [Parameter(Mandatory = $false)]
        [string]$Endpoint = "https://api.openrouter.ai/api/v1/embeddings",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen2-7b"
    )

    try {
        $headers = @{
            "Content-Type" = "application/json"
            "Authorization" = "Bearer $ApiKey"
        }

        $body = @{
            model = $Model
            input = $Text
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $Endpoint -Method Post -Headers $headers -Body $body
        return $response.data[0].embedding
    } catch {
        Write-Log "Erreur lors de la génération de l'embedding: $_" -Level Error
        return $null
    }
}

# Fonction pour vectoriser les tâches
function Convert-TasksToVectors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $env:OPENROUTER_API_KEY,

        [Parameter(Mandatory = $false)]
        [string]$Endpoint = "https://api.openrouter.ai/api/v1/embeddings",

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen2-7b"
    )

    $taskVectors = @()
    $totalTasks = $Tasks.Count
    $currentTask = 0

    foreach ($task in $Tasks) {
        $currentTask++
        Write-Progress -Activity "Conversion des tâches en vecteurs" -Status "Traitement de la tâche $($task.TaskId)" -PercentComplete (($currentTask / $totalTasks) * 100)

        # Créer un texte enrichi pour l'embedding
        $enrichedText = "ID: $($task.TaskId) | Description: $($task.Description) | Section: $($task.Section) | Status: $($task.Status) | Priority: $($task.Priority) | Category: $($task.Category)"

        # Obtenir le vecteur d'embedding
        $vector = Get-Embedding -Text $enrichedText -ApiKey $ApiKey -Endpoint $Endpoint -Model $Model

        if ($null -ne $vector) {
            $taskVectors += [PSCustomObject]@{
                TaskId = $task.TaskId
                Vector = $vector
                Payload = $task
            }
        } else {
            Write-Log "Échec de la vectorisation pour la tâche $($task.TaskId)" -Level Warning
        }
    }

    Write-Progress -Activity "Conversion des tâches en vecteurs" -Completed
    return $taskVectors
}

# Fonction pour stocker les vecteurs dans Qdrant
function Add-VectorsToQdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Vectors,

        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    # Créer un script Python temporaire pour l'insertion des vecteurs
    $tempScript = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $scriptContent = @"
import json
import requests
import sys

def main():
    vectors = json.loads('''$($Vectors | ConvertTo-Json -Depth 10)''')
    qdrant_url = "$QdrantUrl"
    collection_name = "$CollectionName"

    # Préparer les points pour l'insertion
    points = []
    for i, vec in enumerate(vectors):
        point = {
            "id": i,
            "vector": vec["Vector"],
            "payload": {
                "taskId": vec["TaskId"],
                "description": vec["Payload"]["Description"],
                "status": vec["Payload"]["Status"],
                "indentLevel": vec["Payload"]["IndentLevel"],
                "parentId": vec["Payload"]["ParentId"],
                "section": vec["Payload"]["Section"],
                "isMVP": vec["Payload"]["IsMVP"],
                "priority": vec["Payload"]["Priority"],
                "estimatedTime": vec["Payload"]["EstimatedTime"],
                "category": vec["Payload"]["Category"],
                "lastUpdated": vec["Payload"]["LastUpdated"]
            }
        }
        points.append(point)

    # Insérer les points par lots de 100
    batch_size = 100
    for i in range(0, len(points), batch_size):
        batch = points[i:i+batch_size]

        try:
            response = requests.put(
                f"{qdrant_url}/collections/{collection_name}/points",
                json={"points": batch},
                headers={"Content-Type": "application/json"}
            )

            if response.status_code != 200:
                print(f"Erreur lors de l'insertion du lot {i//batch_size + 1}: {response.text}")
                sys.exit(1)

            print(f"Lot {i//batch_size + 1}/{(len(points) + batch_size - 1) // batch_size} inséré avec succès")

        except Exception as e:
            print(f"Exception lors de l'insertion du lot {i//batch_size + 1}: {str(e)}")
            sys.exit(1)

    print(f"Tous les vecteurs ({len(points)}) ont été insérés avec succès")
    return 0

if __name__ == "__main__":
    sys.exit(main())
"@

    $scriptContent | Set-Content -Path $tempScript -Encoding UTF8

    try {
        # Exécuter le script Python
        $result = python $tempScript

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'insertion des vecteurs dans Qdrant" -Level Error
            Write-Log $result -Level Error
            return $false
        }

        Write-Log $result -Level Info
        return $true
    } catch {
        Write-Log "Exception lors de l'exécution du script Python: $_" -Level Error
        return $false
    } finally {
        # Supprimer le script temporaire
        Remove-Item -Path $tempScript -Force
    }
}

# Fonction principale
function Start-Vectorization {
    [CmdletBinding()]
    param()

    # Vérifier la connexion à Qdrant
    Write-Log "Vérification de la connexion à Qdrant..." -Level Info
    $connected = Test-QdrantConnection -QdrantUrl $QdrantUrl

    if (-not $connected) {
        Write-Log "Impossible de se connecter à Qdrant. Vérifiez que le conteneur est en cours d'exécution." -Level Error
        return
    }

    Write-Log "Connexion à Qdrant établie." -Level Success

    # Vérifier l'existence de la collection
    Write-Log "Vérification de l'existence de la collection $CollectionName..." -Level Info
    $collection = Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($null -eq $collection) {
        Write-Log "Création de la collection $CollectionName..." -Level Info
        $result = New-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VectorSize $VectorDimension

        if ($null -eq $result) {
            Write-Log "Échec de la création de la collection." -Level Error
            return
        }

        Write-Log "Collection $CollectionName créée avec succès." -Level Success
    } elseif ($Force) {
        Write-Log "Suppression de la collection existante $CollectionName..." -Level Warning
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Delete | Out-Null

        Write-Log "Création de la collection $CollectionName..." -Level Info
        $result = New-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VectorSize $VectorDimension

        if ($null -eq $result) {
            Write-Log "Échec de la création de la collection." -Level Error
            return
        }

        Write-Log "Collection $CollectionName recréée avec succès." -Level Success
    } else {
        Write-Log "La collection $CollectionName existe déjà. Utilisez -Force pour la recréer." -Level Info
    }

    # Analyser les fichiers Markdown
    Write-Log "Analyse des fichiers Markdown dans $RoadmapDir..." -Level Info
    $files = Get-ChildItem -Path $RoadmapDir -Filter "*.md" -Recurse

    if ($files.Count -eq 0) {
        Write-Log "Aucun fichier Markdown trouvé dans $RoadmapDir" -Level Warning
        return
    }

    Write-Log "Nombre de fichiers Markdown trouvés: $($files.Count)" -Level Info

    $allTasks = @()
    foreach ($file in $files) {
        Write-Log "Analyse du fichier $($file.Name)..." -Level Info
        $tasks = Get-MarkdownTasks -FilePath $file.FullName
        Write-Log "  - $($tasks.Count) tâches trouvées" -Level Info
        $allTasks += $tasks
    }

    Write-Log "Nombre total de tâches trouvées: $($allTasks.Count)" -Level Info

    # Vectoriser les tâches
    Write-Log "Vectorisation des tâches..." -Level Info
    $taskVectors = Convert-TasksToVectors -Tasks $allTasks -ApiKey $ApiKey -Endpoint $ModelEndpoint -Model $ModelName

    Write-Log "Nombre de tâches vectorisées: $($taskVectors.Count)" -Level Info

    # Stocker les vecteurs dans Qdrant
    Write-Log "Stockage des vecteurs dans Qdrant..." -Level Info
    $result = Add-VectorsToQdrant -Vectors $taskVectors -QdrantUrl $QdrantUrl -CollectionName $CollectionName

    if ($result) {
        Write-Log "Vectorisation terminée avec succès." -Level Success
    } else {
        Write-Log "Échec de la vectorisation." -Level Error
    }
}

# Exécuter la vectorisation
Start-Vectorization
