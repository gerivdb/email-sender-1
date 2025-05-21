﻿# Script pour vérifier l'état de Qdrant
$qdrantUrl = "http://localhost:6333"
$collectionName = "roadmap_tasks"

Write-Host "Vérification de la connexion à Qdrant..." -ForegroundColor Cyan

try {
    # Vérifier la connexion à Qdrant
    $response = Invoke-RestMethod -Uri "$qdrantUrl/collections" -Method Get
    $collections = $response.result.collections
    $collectionNames = $collections | ForEach-Object { $_.name }

    Write-Host "Collections existantes:" -ForegroundColor Green
    foreach ($coll in $collectionNames) {
        Write-Host "- $coll" -ForegroundColor White
    }

    # Vérifier si la collection existe
    if ($collectionNames -contains $collectionName) {
        Write-Host "La collection $collectionName existe." -ForegroundColor Green

        # Récupérer les informations sur la collection
        $response = Invoke-RestMethod -Uri "$qdrantUrl/collections/$collectionName" -Method Get
        $collectionInfo = $response.result

        # Vérifier si la clé vectors_count existe
        if ($collectionInfo.PSObject.Properties.Name -contains "vectors_count") {
            $vectorCount = $collectionInfo.vectors_count
        } else {
            # Essayer d'autres clés possibles
$vectorCount = if ($collectionInfo.PSObject.Properties.Name -contains "points_count") { $collectionInfo.points_count } else { 0 }
}

Write-Host "Nombre de vecteurs dans la collection: $vectorCount" -ForegroundColor Yellow
} else {
    Write-Host "La collection $collectionName n'existe pas." -ForegroundColor Red
}
} catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}
