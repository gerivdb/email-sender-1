# Test simple du systeme RAG
param(
    [string]$QdrantUrl = "http://localhost:6333"
)

Write-Host "=== TEST SYSTEME RAG ===" -ForegroundColor Green

# Verification QDrant
Write-Host "Verification de QDrant..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$QdrantUrl/" -Method GET
    Write-Host "QDrant operationnel - Version: $($status.version)" -ForegroundColor Green
} catch {
    Write-Error "QDrant non accessible"
    exit 1
}

# Test de recherche sur une collection existante
Write-Host "Test de recherche..." -ForegroundColor Yellow
try {
    $collections = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method GET
    Write-Host "Collections disponibles: $($collections.result.collections.Count)" -ForegroundColor Cyan
    
    foreach ($collection in $collections.result.collections) {
        Write-Host "  - $($collection.name)" -ForegroundColor White
    }
} catch {
    Write-Warning "Erreur lors de la recuperation des collections"
}

Write-Host "=== TEST TERMINE ===" -ForegroundColor Green