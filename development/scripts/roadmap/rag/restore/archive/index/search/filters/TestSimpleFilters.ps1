# TestSimpleFilters.ps1
# Script de test pour le module de filtres simplifie
# Version: 1.0
# Date: 2025-05-15

# Importer le module de filtres
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$filtersPath = Join-Path -Path $scriptPath -ChildPath "SimpleFilterModule.ps1"

if (Test-Path -Path $filtersPath) {
    . $filtersPath
} else {
    Write-Error "Le fichier SimpleFilterModule.ps1 est introuvable."
    exit 1
}

# Creer des documents de test
$documents = @(
    [PSCustomObject]@{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        created_at = "2024-01-15T10:30:00Z"
        language = "fr"
    },
    [PSCustomObject]@{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        created_at = "2023-05-10T09:15:00Z"
        language = "en"
    },
    [PSCustomObject]@{
        id = "doc3"
        type = "video"
        title = "Presentation du produit"
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
$filteredDocuments = $documents | Filter-ByType -IncludeTypes @("document", "video")
Write-Output "Documents filtres par type (document, video): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par date
Write-Output "`nTest du filtre par date:"
$startDate = [DateTime]::Parse("2024-01-01T00:00:00Z")
$endDate = [DateTime]::Parse("2024-12-31T23:59:59Z")
$filteredDocuments = $documents | Filter-ByDate -Field "created_at" -StartDate $startDate -EndDate $endDate
Write-Output "Documents filtres par date (crees en 2024): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Cree le: $($doc.created_at))"
}

# Tester le filtre par metadonnees
Write-Output "`nTest du filtre par metadonnees:"
$filteredDocuments = $documents | Filter-ByMetadata -Field "language" -Value "fr"
Write-Output "Documents filtres par metadonnees (langue = fr): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Langue: $($doc.language))"
}

# Tester la combinaison de filtres
Write-Output "`nTest de la combinaison de filtres:"
$filteredDocuments = $documents | 
    Filter-ByType -IncludeTypes @("document", "video") | 
    Filter-ByDate -Field "created_at" -StartDate $startDate -EndDate $endDate | 
    Filter-ByMetadata -Field "language" -Value "fr"
Write-Output "Documents filtres par combinaison de filtres: $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Cree le: $($doc.created_at), Langue: $($doc.language))"
}
