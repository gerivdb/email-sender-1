# Script de vectorisation pour RAG
param(
    [Parameter(Mandatory=$true)]
    [string]$DocumentPath,
    [string]$CollectionName = "documents",
    [string]$QdrantUrl = "http://localhost:6333"
)

function Create-Collection {
    param([string]$Name)
    
    $config = @{
        vectors = @{
            size = 384
            distance = "Cosine"
        }
    } | ConvertTo-Json -Depth 3
    
    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$Name" -Method PUT -ContentType "application/json" -Body $config
        Write-Host "✓ Collection '$Name' créée" -ForegroundColor Green
    } catch {
        Write-Host "! Collection '$Name' existe déjà" -ForegroundColor Yellow
    }
}

function Get-TextChunks {
    param([string]$Text, [int]$ChunkSize = 500)
    
    $chunks = @()
    $words = $Text -split '\s+'
    
    for ($i = 0; $i -lt $words.Length; $i += $ChunkSize) {
        $end = [Math]::Min($i + $ChunkSize, $words.Length)
        $chunk = $words[$i..($end-1)] -join ' '
        if ($chunk.Trim()) {
            $chunks += $chunk.Trim()
        }
    }
    return $chunks
}

function Get-EmbeddingVector {
    param([string]$Text)
    
    # Simulation d'embeddings - remplacer par un vrai service
    $vector = @()
    for ($i = 0; $i -lt 384; $i++) {
        $vector += [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6)
    }
    return $vector
}

# Script principal
Write-Host "=== VECTORISATION RAG ===" -ForegroundColor Green
Write-Host "Document: $DocumentPath" -ForegroundColor Cyan
Write-Host "Collection: $CollectionName" -ForegroundColor Cyan

if (-not (Test-Path $DocumentPath)) {
    Write-Error "Document non trouvé: $DocumentPath"
    exit 1
}

# Création de la collection
Create-Collection -Name $CollectionName

# Lecture et découpage du document
$content = Get-Content $DocumentPath -Raw -Encoding UTF8
$chunks = Get-TextChunks -Text $content

Write-Host "Document découpé en $($chunks.Count) fragments" -ForegroundColor Yellow

# Vectorisation et indexation
$pointId = 1
foreach ($chunk in $chunks) {
    $vector = Get-EmbeddingVector -Text $chunk
    
    $point = @{
        points = @(
            @{
                id = $pointId
                payload = @{
                    content = $chunk
                    source = $DocumentPath
                    chunk_id = $pointId
                }
                vector = $vector
            }
        )
    } | ConvertTo-Json -Depth 5
    
    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points" -Method PUT -ContentType "application/json" -Body $point
        Write-Host "✓ Fragment $pointId indexé" -ForegroundColor Green
    } catch {
        Write-Warning "Erreur indexation fragment $pointId"
    }
    
    $pointId++
}

Write-Host "✓ Vectorisation terminée - $($chunks.Count) fragments indexés" -ForegroundColor Green
