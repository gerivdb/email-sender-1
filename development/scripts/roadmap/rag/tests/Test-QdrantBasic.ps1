# Test-QdrantBasic.ps1
# Script de test très basique pour Qdrant
# Version: 1.0
# Date: 2025-05-15

# Définir l'URL de Qdrant
$qdrantUrl = "http://localhost:6333"

# Vérifier si Qdrant est accessible
try {
    Write-Host "Tentative de connexion à Qdrant à l'URL: $qdrantUrl" -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "$qdrantUrl/collections" -Method Get
    Write-Host "Connexion réussie!" -ForegroundColor Green
    Write-Host "Nombre de collections: $($response.result.collections.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur lors de la connexion à Qdrant: $_" -ForegroundColor Red
    exit 1
}

# Nom de la collection de test
$collectionName = "test_collection_basic"

# Supprimer la collection si elle existe déjà
try {
    Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Delete | Out-Null
    Write-Host "Collection existante supprimée" -ForegroundColor Yellow
} catch {
    # La collection n'existe pas, c'est normal
}

# Créer une collection avec une dimension très petite
$vectorDimension = 2
$body = @{
    vectors = @{
        size = $vectorDimension
        distance = "Cosine"
    }
} | ConvertTo-Json

try {
    Write-Host "Création de la collection: $collectionName" -ForegroundColor Cyan
    Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Put -Body $body -ContentType "application/json" | Out-Null
    Write-Host "Collection créée avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la création de la collection: $_" -ForegroundColor Red
    exit 1
}

# Créer un point très simple
$pointId = 1
$vector = @(1.0, 0.0)
$payload = @{
    name = "Test Point"
    value = 42
}

$pointBody = @{
    points = @(
        @{
            id = $pointId
            vector = $vector
            payload = $payload
        }
    )
} | ConvertTo-Json -Depth 5

try {
    Write-Host "Ajout d'un point à la collection" -ForegroundColor Cyan
    Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName/points" -Method Put -Body $pointBody -ContentType "application/json" | Out-Null
    Write-Host "Point ajouté avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'ajout du point: $_" -ForegroundColor Red
    exit 1
}

# Rechercher le point
$searchBody = @{
    vector = $vector
    limit = 1
} | ConvertTo-Json

try {
    Write-Host "Recherche du point" -ForegroundColor Cyan
    $searchResponse = Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName/points/search" -Method Post -Body $searchBody -ContentType "application/json"
    
    if ($searchResponse.result.Count -gt 0) {
        Write-Host "Point trouvé!" -ForegroundColor Green
        Write-Host "ID: $($searchResponse.result[0].id)" -ForegroundColor Cyan
        Write-Host "Score: $($searchResponse.result[0].score)" -ForegroundColor Cyan
        Write-Host "Payload: $($searchResponse.result[0].payload | ConvertTo-Json -Compress)" -ForegroundColor Cyan
    } else {
        Write-Host "Aucun point trouvé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Erreur lors de la recherche du point: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Test terminé avec succès" -ForegroundColor Green
