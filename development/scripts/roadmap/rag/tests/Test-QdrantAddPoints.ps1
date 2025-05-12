# Test-QdrantAddPoints.ps1
# Script de test pour ajouter des points à Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "test_collection_simple",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier si Qdrant est accessible
try {
    Write-Host "Tentative de connexion à Qdrant à l'URL: $QdrantUrl" -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
    Write-Host "Connexion réussie!" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la connexion à Qdrant: $_" -ForegroundColor Red
    exit 1
}

# Vérifier si la collection existe déjà
try {
    $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get

    if ($Force) {
        # Supprimer la collection existante
        Write-Host "Suppression de la collection existante: $CollectionName" -ForegroundColor Yellow
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Delete | Out-Null
    } else {
        Write-Host "La collection $CollectionName existe déjà" -ForegroundColor Yellow
        exit 0
    }
} catch {
    # La collection n'existe pas, c'est normal
}

# Créer la collection
$vectorDimension = 4  # Utiliser une petite dimension pour simplifier
$body = @{
    vectors = @{
        size     = $vectorDimension
        distance = "Cosine"
    }
} | ConvertTo-Json

try {
    Write-Host "Création de la collection: $CollectionName" -ForegroundColor Cyan
    Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Put -Body $body -ContentType "application/json" | Out-Null
    Write-Host "Collection créée avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de la création de la collection: $_" -ForegroundColor Red
    exit 1
}

# Créer des vecteurs de test très simples
$vector1 = @(1.0, 0.0, 0.0, 0.0)
$vector2 = @(0.0, 1.0, 0.0, 0.0)
$vector3 = @(0.0, 0.0, 1.0, 0.0)
$vector4 = @(0.0, 0.0, 0.0, 1.0)

# Ajouter des points à la collection
$points = @(
    @{
        id      = 1
        vector  = $vector1
        payload = @{
            name     = "Point 1"
            category = "Test"
            tags     = @("tag1", "tag2")
        }
    },
    @{
        id      = 2
        vector  = $vector2
        payload = @{
            name     = "Point 2"
            category = "Test"
            tags     = @("tag2", "tag3")
        }
    },
    @{
        id      = 3
        vector  = $vector3
        payload = @{
            name     = "Point 3"
            category = "Test"
            tags     = @("tag1", "tag3")
        }
    },
    @{
        id      = 4
        vector  = $vector4
        payload = @{
            name     = "Point 4"
            category = "Test"
            tags     = @("tag4")
        }
    }
)

$body = @{
    points = $points
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Ajout de points à la collection" -ForegroundColor Cyan
    Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points" -Method Put -Body $body -ContentType "application/json" | Out-Null
    Write-Host "Points ajoutés avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'ajout des points: $_" -ForegroundColor Red
    exit 1
}

# Rechercher des points similaires à vector1
$searchBody = @{
    vector       = $vector1
    limit        = 3
    with_payload = $true
    with_vectors = $false
} | ConvertTo-Json

try {
    Write-Host "Recherche de points similaires à vector1" -ForegroundColor Cyan
    $searchResponse = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points/search" -Method Post -Body $searchBody -ContentType "application/json"

    Write-Host "Résultats trouvés: $($searchResponse.result.Count)" -ForegroundColor Green

    foreach ($result in $searchResponse.result) {
        Write-Host "  ID: $($result.id), Score: $($result.score)" -ForegroundColor Cyan
        Write-Host "  Payload: $($result.payload | ConvertTo-Json -Compress)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Erreur lors de la recherche: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Test terminé avec succès" -ForegroundColor Green
