# SimpleCombinerTest.ps1
# Script de test simple pour le combinateur de filtres
# Version: 1.0
# Date: 2025-05-15

# Créer des documents de test sous forme de hashtables simples
$documents = @(
    @{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        created_at = "2024-01-15T10:30:00Z"
        language = "fr"
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        created_at = "2023-05-10T09:15:00Z"
        language = "en"
    },
    @{
        id = "doc3"
        type = "video"
        title = "Présentation du produit"
        created_at = "2024-03-05T13:20:00Z"
        language = "fr"
    }
)

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester la combinaison de filtres
Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow

# Filtrer les documents de type "document" créés en 2024 en français
$filteredDocuments = @()
foreach ($doc in $documents) {
    # Filtre par type
    if ($doc.type -eq "document") {
        # Filtre par date
        $dateStr = $doc.created_at
        if ($dateStr) {
            $date = [DateTime]::Parse($dateStr)
            if ($date.Year -eq 2024) {
                # Filtre par langue
                if ($doc.language -eq "fr") {
                    $filteredDocuments += $doc
                }
            }
        }
    }
}

Write-Host "Documents filtrés (document, 2024, fr): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at), Langue: $($doc.language))"
}

# Tester la combinaison de filtres avec OR
Write-Host "`nTest de la combinaison de filtres avec OR:" -ForegroundColor Yellow

# Filtrer les documents de type "document" OU créés en 2024
$filteredDocuments = @()
foreach ($doc in $documents) {
    # Filtre par type OU par date
    $isDocument = $doc.type -eq "document"
    
    $isCreatedIn2024 = $false
    $dateStr = $doc.created_at
    if ($dateStr) {
        $date = [DateTime]::Parse($dateStr)
        $isCreatedIn2024 = $date.Year -eq 2024
    }
    
    if ($isDocument -or $isCreatedIn2024) {
        $filteredDocuments += $doc
    }
}

Write-Host "Documents filtrés (document OU 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at))"
}
