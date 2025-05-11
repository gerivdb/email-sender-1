# BasicTest.ps1
# Script de test basique pour les filtres de recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Créer des documents de test sous forme de hashtables simples
$documents = @(
    @{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        content = "Ce rapport présente les résultats financiers de l'année 2024."
        created_at = "2024-01-15T10:30:00Z"
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        content = "Logo officiel de l'entreprise en haute résolution"
        created_at = "2023-05-10T09:15:00Z"
    }
)

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par type
Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow

# Filtrer les documents de type "document"
$filteredDocuments = $documents | Where-Object { $_.type -eq "document" }

Write-Host "Documents de type 'document': $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title)"
}

# Tester le filtre par date
Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow

# Filtrer les documents créés en 2024
$filteredDocuments = @()
foreach ($doc in $documents) {
    $dateStr = $doc.created_at
    if ($dateStr) {
        $date = [DateTime]::Parse($dateStr)
        if ($date.Year -eq 2024) {
            $filteredDocuments += $doc
        }
    }
}

Write-Host "Documents créés en 2024: $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Créé le: $($doc.created_at))"
}

# Tester la combinaison de filtres
Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow

# Filtrer les documents de type "document" créés en 2024
$filteredDocuments = @()
foreach ($doc in $documents) {
    if ($doc.type -eq "document") {
        $dateStr = $doc.created_at
        if ($dateStr) {
            $date = [DateTime]::Parse($dateStr)
            if ($date.Year -eq 2024) {
                $filteredDocuments += $doc
            }
        }
    }
}

Write-Host "Documents de type 'document' créés en 2024: $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at))"
}
