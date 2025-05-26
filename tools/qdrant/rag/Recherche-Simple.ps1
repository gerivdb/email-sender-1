# Script de recherche RAG simple
param(
    [Parameter(Mandatory=$true)]
    [string]$Query,
    [string]$Collection = "documents",
    [string]$QdrantUrl = "http://localhost:6333"
)

function Get-RandomVector {
    param([int]$Size = 384)
    $vector = @()
    for ($i = 0; $i -lt $Size; $i++) {
        $vector += [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6)
    }
    return $vector
}

Write-Host "=== RECHERCHE RAG ===" -ForegroundColor Green
Write-Host "Requete: $Query" -ForegroundColor Yellow
Write-Host "Collection: $Collection" -ForegroundColor Cyan

# Generation du vecteur de requete (simulation)
$queryVector = Get-RandomVector -Size 384

# Recherche
$searchPayload = @{
    vector = $queryVector
    limit = 3
    with_payload = $true
    with_vector = $false
} | ConvertTo-Json -Depth 10

try {
    $results = Invoke-RestMethod -Uri "$QdrantUrl/collections/$Collection/points/search" `
                                -Method POST `
                                -ContentType "application/json" `
                                -Body $searchPayload
    
    Write-Host "Resultats trouves: $($results.result.Count)" -ForegroundColor Green
    
    if ($results.result.Count -eq 0) {
        Write-Host "Aucun document trouve dans la collection $Collection" -ForegroundColor Yellow
    } else {
        for ($i = 0; $i -lt $results.result.Count; $i++) {
            $result = $results.result[$i]
            Write-Host "[$($i+1)] Score: $([Math]::Round($result.score, 4))" -ForegroundColor Blue
            
            if ($result.payload.title) {
                Write-Host "    Titre: $($result.payload.title)" -ForegroundColor White
            }
            
            if ($result.payload.content) {
                $content = $result.payload.content
                if ($content.Length -gt 150) {
                    $content = $content.Substring(0, 150) + "..."
                }
                Write-Host "    Contenu: $content" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }
} catch {
    Write-Error "Erreur lors de la recherche: $($_.Exception.Message)"
}

Write-Host "=== RECHERCHE TERMINEE ===" -ForegroundColor Green