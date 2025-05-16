﻿# Search-RoadmapVectors.ps1
# Script pour rechercher des informations dans les roadmaps vectorisées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",

    [Parameter(Mandatory = $false)]
    [int]$Limit = 10,

    [Parameter(Mandatory = $false)]
    [double]$ScoreThreshold = 0.7,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "Markdown", "HTML")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeContext,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeVectors,

    [Parameter(Mandatory = $false)]
    [switch]$OpenInBrowser
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"

# Importer les fonctions utilitaires
. (Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1")
. (Join-Path -Path $utilsPath -ChildPath "Format-Output.ps1")

# Fonction pour vérifier si Qdrant est accessible
function Test-QdrantConnection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get -ErrorAction Stop
        Write-Log "Connexion à Qdrant établie" -Level Success
        return $true
    } catch {
        Write-Log "Impossible de se connecter à Qdrant: $_" -Level Error
        return $false
    }
}

# Fonction pour vérifier si la collection existe
function Test-QdrantCollection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get -ErrorAction Stop
        Write-Log "Collection '$CollectionName' trouvée" -Level Success
        return $true
    } catch {
        Write-Log "Collection '$CollectionName' non trouvée" -Level Warning
        return $false
    }
}

# Fonction pour générer des embeddings avec l'API OpenRouter
function Get-OpenRouterEmbeddings {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $env:OPENROUTER_API_KEY,

        [Parameter(Mandatory = $false)]
        [string]$Model = "qwen/qwen3-235b-a22b"
    )

    if (-not $ApiKey) {
        Write-Log "Clé API OpenRouter non trouvée. Définissez la variable d'environnement OPENROUTER_API_KEY" -Level Error
        return $null
    }

    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $ApiKey"
        "HTTP-Referer"  = "https://augment.dev"
        "X-Title"       = "Roadmap Vector Search"
    }

    $body = @{
        input = $Text
        model = $Model
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/embeddings" -Method Post -Headers $headers -Body $body -ErrorAction Stop
        return $response.data[0].embedding
    } catch {
        Write-Log "Erreur lors de la génération des embeddings: $_" -Level Error
        return $null
    }
}

# Fonction pour rechercher dans Qdrant
function Search-Qdrant {
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $true)]
        [string]$CollectionName,

        [Parameter(Mandatory = $true)]
        [array]$Vector,

        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,

        [Parameter(Mandatory = $false)]
        [double]$ScoreThreshold = 0.7
    )

    $body = @{
        vector          = $Vector
        limit           = $Limit
        score_threshold = $ScoreThreshold
        with_payload    = $true
        with_vectors    = $IncludeVectors.IsPresent
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points/search" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        return $response
    } catch {
        Write-Log "Erreur lors de la recherche dans Qdrant: $_" -Level Error
        return $null
    }
}

# Fonction pour formater les résultats en texte
function Format-ResultsAsText {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext
    )

    $output = @()
    $output += "=== RÉSULTATS DE RECHERCHE ==="
    $output += "Requête: $Query"
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Nombre de résultats: $($Results.result.Count)"
    $output += ""

    foreach ($result in $Results.result) {
        $score = [math]::Round($result.score, 4)
        $task = $result.payload

        $output += "--- RÉSULTAT (Score: $score) ---"
        $output += "ID: $($task.id)"
        $output += "Description: $($task.description)"
        $output += "Statut: $($task.status)"

        if ($IncludeContext) {
            $output += "Contexte: $($task.context)"
            $output += "Chemin: $($task.path)"
            $output += "Fichier: $($task.roadmap_path)"
            $output += "Ligne: $($task.line_number)"

            if ($task.parent_id) {
                $output += "Parent: $($task.parent_id)"
            }
        }

        $output += ""
    }

    return $output -join "`n"
}

# Fonction pour formater les résultats en JSON
function Format-ResultsAsJson {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVectors
    )

    $jsonObject = @{
        query        = $Query
        timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        result_count = $Results.result.Count
        results      = @()
    }

    foreach ($result in $Results.result) {
        $resultObject = @{
            score = $result.score
            task  = @{
                id          = $result.payload.id
                description = $result.payload.description
                status      = $result.payload.status
            }
        }

        if ($IncludeContext) {
            $resultObject.task.context = $result.payload.context
            $resultObject.task.path = $result.payload.path
            $resultObject.task.roadmap_path = $result.payload.roadmap_path
            $resultObject.task.line_number = $result.payload.line_number

            if ($result.payload.parent_id) {
                $resultObject.task.parent_id = $result.payload.parent_id
            }
        }

        if ($IncludeVectors -and $result.vector) {
            $resultObject.vector = $result.vector
        }

        $jsonObject.results += $resultObject
    }

    return $jsonObject | ConvertTo-Json -Depth 10
}

# Fonction pour formater les résultats en Markdown
function Format-ResultsAsMarkdown {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext
    )

    $output = @()
    $output += "# Résultats de recherche"
    $output += "**Requête:** $Query"
    $output += "**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "**Nombre de résultats:** $($Results.result.Count)"
    $output += ""

    foreach ($result in $Results.result) {
        $score = [math]::Round($result.score, 4)
        $task = $result.payload

        $output += "## Résultat (Score: $score)"
        $output += "- **ID:** $($task.id)"
        $output += "- **Description:** $($task.description)"
        $output += "- **Statut:** $($task.status)"

        if ($IncludeContext) {
            $output += ""
            $output += "### Contexte"
            $output += "- **Contexte:** $($task.context)"
            $output += "- **Chemin:** $($task.path)"
            $output += "- **Fichier:** $($task.roadmap_path)"
            $output += "- **Ligne:** $($task.line_number)"

            if ($task.parent_id) {
                $output += "- **Parent:** $($task.parent_id)"
            }
        }

        $output += ""
    }

    return $output -join "`n"
}

# Fonction pour formater les résultats en HTML
function Format-ResultsAsHtml {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Results,

        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultats de recherche - $Query</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
        h1 { color: #2c3e50; }
        h2 { color: #3498db; margin-top: 20px; }
        h3 { color: #7f8c8d; }
        .result { margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .score { color: #e74c3c; font-weight: bold; }
        .completed { color: #27ae60; }
        .incomplete { color: #e67e22; }
        .context { margin-top: 10px; padding: 10px; background-color: #f9f9f9; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Résultats de recherche</h1>
    <p><strong>Requête:</strong> $Query</p>
    <p><strong>Date:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    <p><strong>Nombre de résultats:</strong> $($Results.result.Count)</p>

"@

    foreach ($result in $Results.result) {
        $score = [math]::Round($result.score, 4)
        $task = $result.payload
        $statusClass = $task.status -eq "Completed" ? "completed" : "incomplete"

        $html += @"
    <div class="result">
        <h2>Résultat <span class="score">(Score: $score)</span></h2>
        <p><strong>ID:</strong> $($task.id)</p>
        <p><strong>Description:</strong> $($task.description)</p>
        <p><strong>Statut:</strong> <span class="$statusClass">$($task.status)</span></p>

"@

        if ($IncludeContext) {
            $html += @"
        <div class="context">
            <h3>Contexte</h3>
            <p><strong>Contexte:</strong> $($task.context)</p>
            <p><strong>Chemin:</strong> $($task.path)</p>
            <p><strong>Fichier:</strong> $($task.roadmap_path)</p>
            <p><strong>Ligne:</strong> $($task.line_number)</p>
"@

            if ($task.parent_id) {
                $html += @"
            <p><strong>Parent:</strong> $($task.parent_id)</p>
"@
            }

            $html += @"
        </div>
"@
        }

        $html += @"
    </div>
"@
    }

    $html += @"
</body>
</html>
"@

    return $html
}

# Fonction principale
function Search-RoadmapVectors {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Query,

        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl,

        [Parameter(Mandatory = $false)]
        [string]$CollectionName,

        [Parameter(Mandatory = $false)]
        [int]$Limit,

        [Parameter(Mandatory = $false)]
        [double]$ScoreThreshold,

        [Parameter(Mandatory = $false)]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeContext,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeVectors,

        [Parameter(Mandatory = $false)]
        [switch]$OpenInBrowser
    )

    # Vérifier la connexion à Qdrant
    if (-not (Test-QdrantConnection -QdrantUrl $QdrantUrl)) {
        return $false
    }

    # Vérifier si la collection existe
    if (-not (Test-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName)) {
        return $false
    }

    # Générer l'embedding pour la requête
    Write-Log "Génération de l'embedding pour la requête: $Query" -Level Info
    $embedding = Get-OpenRouterEmbeddings -Text $Query

    if (-not $embedding) {
        return $false
    }

    # Rechercher dans Qdrant
    Write-Log "Recherche dans Qdrant..." -Level Info
    $results = Search-Qdrant -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Vector $embedding -Limit $Limit -ScoreThreshold $ScoreThreshold

    if (-not $results) {
        return $false
    }

    Write-Log "Recherche terminée. $($results.result.Count) résultats trouvés." -Level Success

    # Formater les résultats
    $formattedResults = switch ($OutputFormat) {
        "Text" { Format-ResultsAsText -Results $results -Query $Query -IncludeContext:$IncludeContext }
        "JSON" { Format-ResultsAsJson -Results $results -Query $Query -IncludeContext:$IncludeContext -IncludeVectors:$IncludeVectors }
        "Markdown" { Format-ResultsAsMarkdown -Results $results -Query $Query -IncludeContext:$IncludeContext }
        "HTML" { Format-ResultsAsHtml -Results $results -Query $Query -IncludeContext:$IncludeContext }
        default { Format-ResultsAsText -Results $results -Query $Query -IncludeContext:$IncludeContext }
    }

    # Enregistrer ou afficher les résultats
    if ($OutputPath) {
        $formattedResults | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Résultats enregistrés dans: $OutputPath" -Level Success

        # Ouvrir dans le navigateur si demandé et si le format est HTML
        if ($OpenInBrowser -and $OutputFormat -eq "HTML") {
            Start-Process $OutputPath
        }
    } else {
        Write-Output $formattedResults
    }

    return $results
}

# Exécution principale
try {
    $results = Search-RoadmapVectors -Query $Query -QdrantUrl $QdrantUrl -CollectionName $CollectionName `
        -Limit $Limit -ScoreThreshold $ScoreThreshold -OutputFormat $OutputFormat `
        -OutputPath $OutputPath -IncludeContext:$IncludeContext -IncludeVectors:$IncludeVectors `
        -OpenInBrowser:$OpenInBrowser

    if ($results) {
        exit 0
    } else {
        exit 1
    }
} catch {
    Write-Log "Erreur lors de la recherche: $_" -Level Error
    exit 2
}
