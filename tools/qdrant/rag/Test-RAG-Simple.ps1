# Test simple du système RAG
param([string]$QdrantUrl = "http://localhost:6333")

Write-Host "=== TEST SYSTÈME RAG ===" -ForegroundColor Green

# Test connexion QDrant
Write-Host "Test connexion QDrant..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$QdrantUrl/" -Method GET -TimeoutSec 5
    Write-Host "✓ QDrant opérationnel" -ForegroundColor Green
} catch {
    Write-Error "✗ QDrant non accessible sur $QdrantUrl"
    Write-Host "Assurez-vous que QDrant est démarré avec: .\Start-QdrantStandalone.ps1 -Action Start" -ForegroundColor Yellow
    exit 1
}

# Création collection test
Write-Host "Création collection test..." -ForegroundColor Yellow
$collectionConfig = @{
    vectors = @{
        size = 384
        distance = "Cosine"
    }
} | ConvertTo-Json -Depth 3

try {
    Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag" -Method PUT -ContentType "application/json" -Body $collectionConfig
    Write-Host "✓ Collection 'test_rag' créée" -ForegroundColor Green
} catch {
    Write-Host "! Collection existe ou erreur création" -ForegroundColor Yellow
}

# Ajout document test
Write-Host "Ajout document test..." -ForegroundColor Yellow
$vector = @()
for ($i = 0; $i -lt 384; $i++) { $vector += [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6) }

$testPoint = @{
    points = @(
        @{
            id = 1
            payload = @{
                title = "Test RAG"
                content = "Ceci est un document de test pour le système RAG avec QDrant."
            }
            vector = $vector
        }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag/points" -Method PUT -ContentType "application/json" -Body $testPoint
    Write-Host "✓ Document test ajouté" -ForegroundColor Green
} catch {
    Write-Warning "Erreur ajout document: $($_.Exception.Message)"
}

# Test recherche
Write-Host "Test recherche..." -ForegroundColor Yellow
$searchQuery = @{
    vector = $vector
    limit = 1
    with_payload = $true
} | ConvertTo-Json -Depth 3

try {
    $result = Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag/points/search" -Method POST -ContentType "application/json" -Body $searchQuery
    Write-Host "✓ Recherche réussie - $($result.result.Count) résultat(s)" -ForegroundColor Green
    if ($result.result.Count -gt 0) {
        Write-Host "  Titre: $($result.result[0].payload.title)" -ForegroundColor Cyan
        Write-Host "  Score: $([Math]::Round($result.result[0].score, 3))" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Erreur recherche: $($_.Exception.Message)"
}

Write-Host "`n✓ Test RAG terminé avec succès!" -ForegroundColor Green
Write-Host "Le système est prêt pour indexer vos documents." -ForegroundColor Yellow
