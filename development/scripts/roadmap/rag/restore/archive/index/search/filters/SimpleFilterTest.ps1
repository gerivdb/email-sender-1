# SimpleFilterTest.ps1
# Script de test très simple pour les filtres
# Version: 1.0
# Date: 2025-05-15

# Créer des documents de test
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
Write-Output "Documents de test:"
foreach ($doc in $documents) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par type
Write-Output "`nTest du filtre par type:"
$filteredDocuments = @()
foreach ($doc in $documents) {
    if ($doc.type -eq "document" -or $doc.type -eq "video") {
        $filteredDocuments += $doc
    }
}
Write-Output "Documents filtrés par type (document, video): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par date
Write-Output "`nTest du filtre par date:"
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
Write-Output "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Créé le: $($doc.created_at))"
}

# Tester le filtre par métadonnées
Write-Output "`nTest du filtre par métadonnées:"
$filteredDocuments = @()
foreach ($doc in $documents) {
    if ($doc.language -eq "fr") {
        $filteredDocuments += $doc
    }
}
Write-Output "Documents filtrés par métadonnées (langue = fr): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Langue: $($doc.language))"
}

# Tester la combinaison de filtres
Write-Output "`nTest de la combinaison de filtres:"
$filteredDocuments = @()
foreach ($doc in $documents) {
    if (($doc.type -eq "document" -or $doc.type -eq "video") -and
        ($doc.created_at -and [DateTime]::Parse($doc.created_at).Year -eq 2024) -and
        ($doc.language -eq "fr")) {
        $filteredDocuments += $doc
    }
}
Write-Output "Documents filtrés par combinaison de filtres: $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at), Langue: $($doc.language))"
}
