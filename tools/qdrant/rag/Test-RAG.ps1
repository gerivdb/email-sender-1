# Test du système RAG - Script de démonstration

param(
    [string]$QdrantUrl = "http://localhost:6333"
)

Write-Host "=== TEST SYSTÈME RAG ===" -ForegroundColor Green

# 1. Vérification QDrant
Write-Host "`n1. Vérification de QDrant..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$QdrantUrl/" -Method GET
    Write-Host "✓ QDrant opérationnel" -ForegroundColor Green
} catch {
    Write-Error "✗ QDrant non accessible"
    exit 1
}

# 2. Création d'une collection de test
Write-Host "`n2. Création de collection de test..." -ForegroundColor Yellow
$collectionConfig = @{
    vectors = @{
        size = 384
        distance = "Cosine"
    }
} | ConvertTo-Json -Depth 10

try {
    Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag" `
                     -Method PUT `
                     -ContentType "application/json" `
                     -Body $collectionConfig
    Write-Host "✓ Collection 'test_rag' créée" -ForegroundColor Green
} catch {
    Write-Host "! Collection existe déjà ou erreur" -ForegroundColor Yellow
}

# 3. Ajout de documents de test
Write-Host "`n3. Ajout de documents de test..." -ForegroundColor Yellow

$testDocs = @(
    @{
        id = 1
        payload = @{
            title = "Guide QDrant"
            content = "QDrant est une base de données vectorielle performante pour la recherche sémantique."
            source = "documentation"
        }
        vector = @(1..384 | ForEach-Object { [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6) })
    },
    @{
        id = 2  
        payload = @{
            title = "Système RAG"
            content = "Un système RAG combine recherche et génération pour des réponses contextualisées."
            source = "guide"
        }
        vector = @(1..384 | ForEach-Object { [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6) })
    }
)

foreach ($doc in $testDocs) {
    $docJson = $doc | ConvertTo-Json -Depth 10
    try {
        Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag/points" `
                         -Method PUT `
                         -ContentType "application/json" `
                         -Body "{ `"points`": [$docJson] }"
        Write-Host "✓ Document $($doc.id) ajouté" -ForegroundColor Green
    } catch {
        Write-Warning "Erreur ajout document $($doc.id)"
    }
}

# 4. Test de recherche
Write-Host "`n4. Test de recherche..." -ForegroundColor Yellow
$queryVector = @(1..384 | ForEach-Object { [Math]::Round((Get-Random -Minimum -1.0 -Maximum 1.0), 6) })

$searchPayload = @{
    vector = $queryVector
    limit = 2
    with_payload = $true
} | ConvertTo-Json -Depth 10

try {
    $results = Invoke-RestMethod -Uri "$QdrantUrl/collections/test_rag/points/search" `
                                -Method POST `
                                -ContentType "application/json" `
                                -Body $searchPayload
    
    Write-Host "✓ Recherche effectuée - $($results.result.Count) résultats" -ForegroundColor Green
    
    foreach ($result in $results.result) {
        Write-Host "  - $($result.payload.title) (score: $([Math]::Round($result.score, 3)))" -ForegroundColor Cyan
    }
} catch {
    Write-Warning "Erreur lors de la recherche"
}

Write-Host "`n=== TEST TERMINÉ ===" -ForegroundColor Green
Write-Host "Le système RAG est prêt à utiliser!" -ForegroundColor Yellow