# Test-QdrantSimple.ps1
# Script de test simple pour l'intégration avec Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "test_collection",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour vérifier si Qdrant est accessible
function Test-QdrantConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        Write-Host "Qdrant est accessible à l'URL: $QdrantUrl" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de la connexion à Qdrant: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour créer une collection
function New-QdrantCollection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [int]$VectorDimension = 384,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si la collection existe déjà
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Get
        
        if ($Force) {
            # Supprimer la collection existante
            Write-Host "Suppression de la collection existante: $CollectionName" -ForegroundColor Yellow
            Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Delete | Out-Null
        } else {
            Write-Host "La collection $CollectionName existe déjà" -ForegroundColor Yellow
            return $true
        }
    } catch {
        # La collection n'existe pas, c'est normal
    }
    
    # Créer la collection
    $body = @{
        vectors = @{
            size = $VectorDimension
            distance = "Cosine"
        }
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method Put -Body $body -ContentType "application/json" | Out-Null
        Write-Host "Collection $CollectionName créée avec succès" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de la création de la collection: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour ajouter un point à la collection
function Add-QdrantPoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [string]$PointId,
        
        [Parameter(Mandatory = $true)]
        [float[]]$Vector,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Payload
    )
    
    # Créer le corps de la requête
    $body = @{
        points = @(
            @{
                id = $PointId
                vector = $Vector
                payload = $Payload
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points" -Method Put -Body $body -ContentType "application/json" | Out-Null
        Write-Host "Point $PointId ajouté avec succès à la collection $CollectionName" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Erreur lors de l'ajout du point: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour rechercher des points dans la collection
function Search-QdrantPoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $true)]
        [float[]]$Vector,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 10,
        
        [Parameter(Mandatory = $false)]
        [float]$ScoreThreshold = 0.7
    )
    
    # Créer le corps de la requête
    $body = @{
        vector = $Vector
        limit = $Limit
        with_payload = $true
        with_vectors = $false
        score_threshold = $ScoreThreshold
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName/points/search" -Method Post -Body $body -ContentType "application/json"
        
        if ($response.result.Count -eq 0) {
            Write-Host "Aucun résultat trouvé" -ForegroundColor Yellow
        } else {
            Write-Host "Résultats trouvés: $($response.result.Count)" -ForegroundColor Green
            
            foreach ($result in $response.result) {
                Write-Host "  ID: $($result.id), Score: $($result.score)" -ForegroundColor Cyan
                Write-Host "  Payload: $($result.payload | ConvertTo-Json -Compress)" -ForegroundColor Gray
            }
        }
        
        return $response.result
    } catch {
        Write-Host "Erreur lors de la recherche: $_" -ForegroundColor Red
        return $null
    }
}

# Fonction principale
function Main {
    # Vérifier la connexion à Qdrant
    if (-not (Test-QdrantConnection -QdrantUrl $QdrantUrl)) {
        Write-Host "Impossible de se connecter à Qdrant. Le script ne peut pas continuer." -ForegroundColor Red
        return
    }
    
    # Créer une collection de test
    if (-not (New-QdrantCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force)) {
        Write-Host "Impossible de créer la collection. Le script ne peut pas continuer." -ForegroundColor Red
        return
    }
    
    # Créer des vecteurs de test
    $vector1 = 1..384 | ForEach-Object { [math]::Sin($_) }
    $vector2 = 1..384 | ForEach-Object { [math]::Cos($_) }
    $vector3 = 1..384 | ForEach-Object { [math]::Tan($_) % 1 }
    
    # Ajouter des points à la collection
    Add-QdrantPoint -QdrantUrl $QdrantUrl -CollectionName $CollectionName -PointId "point1" -Vector $vector1 -Payload @{ name = "Point 1"; category = "Test"; tags = @("tag1", "tag2") }
    Add-QdrantPoint -QdrantUrl $QdrantUrl -CollectionName $CollectionName -PointId "point2" -Vector $vector2 -Payload @{ name = "Point 2"; category = "Test"; tags = @("tag2", "tag3") }
    Add-QdrantPoint -QdrantUrl $QdrantUrl -CollectionName $CollectionName -PointId "point3" -Vector $vector3 -Payload @{ name = "Point 3"; category = "Test"; tags = @("tag1", "tag3") }
    
    # Rechercher des points similaires
    Write-Host "Recherche de points similaires à point1..." -ForegroundColor Cyan
    Search-QdrantPoints -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Vector $vector1 -Limit 3 -ScoreThreshold 0.5
    
    Write-Host "Recherche de points similaires à point2..." -ForegroundColor Cyan
    Search-QdrantPoints -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Vector $vector2 -Limit 3 -ScoreThreshold 0.5
    
    Write-Host "Recherche de points similaires à point3..." -ForegroundColor Cyan
    Search-QdrantPoints -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Vector $vector3 -Limit 3 -ScoreThreshold 0.5
    
    Write-Host "Test terminé avec succès" -ForegroundColor Green
}

# Exécuter la fonction principale
Main
