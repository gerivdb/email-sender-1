# Script de recherche RAG avec QDrant
# Permet de rechercher des documents similaires et générer des réponses

param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [int]$MaxResults = 5,
    [string]$CollectionName = "documents",
    [string]$QdrantUrl = "http://localhost:6333"
)

function Get-EmbeddingVector {
    param([string]$Text)
    
    # Simulation d'embeddings - à remplacer par un vrai service
    $vector = @()
    for ($i = 0; $i -lt 384; $i++) {
        $vector += [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6)
    }
    return $vector
}

function Search-SimilarDocuments {
    param(
        [array]$QueryVector,
        [int]$Limit,
        [string]$Collection
    )
    
    $searchPayload = @{
        vector = $QueryVector
        limit = $Limit
        with_payload = $true
        with_vector = $false
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection/points/search" `
                                    -Method POST `
                                    -ContentType "application/json" `
                                    -Body $searchPayload
        
        return $response.result
    }
    catch {
        Write-Error "Erreur lors de la recherche: $($_.Exception.Message)"
        return @()
    }
}

function Format-SearchResults {
    param([array]$Results)
    
    Write-Host "`n=== RÉSULTATS DE RECHERCHE RAG ===" -ForegroundColor Green
    Write-Host "Requête: $Query" -ForegroundColor Yellow
    Write-Host "Nombre de résultats: $($Results.Count)`n" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Results.Count; $i++) {
        $result = $Results[$i]
        Write-Host "[$($i+1)] Score de similarité: $([Math]::Round($result.score, 4))" -ForegroundColor Blue
        
        if ($result.payload.title) {
            Write-Host "    Titre: $($result.payload.title)" -ForegroundColor White
        }
        
        if ($result.payload.content) {
            $content = $result.payload.content
            if ($content.Length -gt 200) {
                $content = $content.Substring(0, 200) + "..."
            }
            Write-Host "    Contenu: $content" -ForegroundColor Gray
        }
        
        if ($result.payload.source) {
            Write-Host "    Source: $($result.payload.source)" -ForegroundColor DarkGreen
        }
        
        Write-Host ""
    }
}

function Generate-RAGResponse {
    param(
        [string]$Query,
        [array]$Context
    )
    
    Write-Host "=== GÉNÉRATION DE RÉPONSE RAG ===" -ForegroundColor Green
    Write-Host "Question: $Query`n" -ForegroundColor Yellow
    
    $contextText = ""
    foreach ($doc in $Context) {
        if ($doc.payload.content) {
            $contextText += $doc.payload.content + "`n`n"
        }
    }
    
    Write-Host "Contexte trouvé ($($Context.Count) documents):" -ForegroundColor Cyan
    Write-Host $contextText.Substring(0, [Math]::Min(500, $contextText.Length)) + "..." -ForegroundColor Gray
    
    # Ici vous pourriez intégrer un LLM (OpenAI, Azure OpenAI, etc.)
    Write-Host "`n[RÉPONSE SIMULÉE]" -ForegroundColor Magenta
    Write-Host "Basé sur les documents trouvés, voici une réponse générée à partir du contexte..." -ForegroundColor White
    
    return "Réponse générée à partir du contexte RAG"
}

# Script principal
Write-Host "Démarrage de la recherche RAG..." -ForegroundColor Green

# Vérification que QDrant est accessible
try {
    $status = Invoke-RestMethod -Uri "$QdrantUrl/" -Method GET
    Write-Host "✓ QDrant accessible" -ForegroundColor Green
}
catch {
    Write-Error "QDrant n'est pas accessible sur $QdrantUrl"
    exit 1
}

# Génération du vecteur de requête
Write-Host "Génération de l'embedding pour la requête..." -ForegroundColor Yellow
$queryVector = Get-EmbeddingVector -Text $Query

# Recherche de documents similaires
Write-Host "Recherche de documents similaires..." -ForegroundColor Yellow
$searchResults = Search-SimilarDocuments -QueryVector $queryVector -Limit $MaxResults -Collection $CollectionName

if ($searchResults.Count -eq 0) {
    Write-Warning "Aucun document trouvé pour la requête: $Query"
    exit 0
}

# Affichage des résultats
Format-SearchResults -Results $searchResults

# Génération de la réponse RAG
$ragResponse = Generate-RAGResponse -Query $Query -Context $searchResults

Write-Host "`n=== RECHERCHE RAG TERMINÉE ===" -ForegroundColor Green