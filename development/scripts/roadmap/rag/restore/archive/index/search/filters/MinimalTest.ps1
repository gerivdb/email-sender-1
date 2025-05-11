# MinimalTest.ps1
# Script de test minimal pour les filtres de recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Créer des documents de test sous forme de hashtables simples
$documents = @(
    @{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        created_at = "2024-01-15T10:30:00Z"
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        created_at = "2023-05-10T09:15:00Z"
    },
    @{
        id = "doc3"
        type = "video"
        title = "Présentation du produit"
        created_at = "2024-03-05T13:20:00Z"
    }
)

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par type
Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow

# Définir les types à inclure
$includeTypes = @("document", "video")

# Filtrer les documents par type
$filteredDocuments = $documents | Where-Object { $includeTypes -contains $_.type }

Write-Host "Documents filtrés par type (document, video): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par date
Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow

# Définir la plage de dates
$startDate = [DateTime]::Parse("2024-01-01T00:00:00Z")
$endDate = [DateTime]::Parse("2024-12-31T23:59:59Z")

# Filtrer les documents par date
$filteredDocuments = @()
foreach ($doc in $documents) {
    $dateStr = $doc.created_at
    if ($dateStr) {
        $date = [DateTime]::Parse($dateStr)
        if ($date -ge $startDate -and $date -le $endDate) {
            $filteredDocuments += $doc
        }
    }
}

Write-Host "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Créé le: $($doc.created_at))"
}

# Tester la combinaison de filtres
Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow

# Filtrer les documents par type et date
$filteredDocuments = @()
foreach ($doc in $documents) {
    if ($includeTypes -contains $doc.type) {
        $dateStr = $doc.created_at
        if ($dateStr) {
            $date = [DateTime]::Parse($dateStr)
            if ($date -ge $startDate -and $date -le $endDate) {
                $filteredDocuments += $doc
            }
        }
    }
}

Write-Host "Documents filtrés par type et date (document/video créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at))"
}
