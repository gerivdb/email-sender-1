# Test-QdrantConnection.ps1
# Script de test très simple pour vérifier la connexion à Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333"
)

# Vérifier si Qdrant est accessible
try {
    Write-Host "Tentative de connexion à Qdrant à l'URL: $QdrantUrl" -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
    Write-Host "Connexion réussie!" -ForegroundColor Green
    Write-Host "Nombre de collections: $($response.result.collections.Count)" -ForegroundColor Cyan
    
    # Afficher les collections existantes
    if ($response.result.collections.Count -gt 0) {
        Write-Host "Collections existantes:" -ForegroundColor Cyan
        foreach ($collection in $response.result.collections) {
            Write-Host "  - $($collection.name)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Aucune collection existante" -ForegroundColor Yellow
    }
    
    # Vérifier l'état du serveur
    $statusResponse = Invoke-RestMethod -Uri "$QdrantUrl/telemetry" -Method Get
    Write-Host "Version de Qdrant: $($statusResponse.result.version)" -ForegroundColor Cyan
    Write-Host "Uptime: $($statusResponse.result.uptime) secondes" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur lors de la connexion à Qdrant: $_" -ForegroundColor Red
}
