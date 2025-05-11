# TestSearchFilters.ps1
# Script de test pour le module de filtres de recherche avancee
# Version: 1.0
# Date: 2025-05-15

# Importer le module de filtres
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$filtersPath = Join-Path -Path $scriptPath -ChildPath "SearchFilters.ps1"

if (Test-Path -Path $filtersPath) {
    . $filtersPath
} else {
    Write-Error "Le fichier SearchFilters.ps1 est introuvable."
    exit 1
}

# Creer des documents de test
$documents = @(
    [PSCustomObject]@{
        id         = "doc1"
        type       = "document"
        title      = "Rapport annuel 2024"
        content    = "Ce rapport presente les resultats financiers de l'annee 2024."
        created_at = "2024-01-15T10:30:00Z"
        updated_at = "2024-02-20T14:45:00Z"
        author     = "Jean Dupont"
        tags       = @("rapport", "finance", "2024")
        status     = "published"
        priority   = 1
        language   = "fr"
    },
    [PSCustomObject]@{
        id         = "doc2"
        type       = "image"
        title      = "Logo de l'entreprise"
        content    = "Logo officiel de l'entreprise en haute resolution"
        created_at = "2023-05-10T09:15:00Z"
        updated_at = "2023-05-10T09:15:00Z"
        author     = "Marie Martin"
        tags       = @("logo", "image", "branding")
        status     = "published"
        priority   = 2
        language   = "en"
    },
    [PSCustomObject]@{
        id         = "doc3"
        type       = "video"
        title      = "Presentation du produit"
        content    = "Video de presentation du nouveau produit"
        created_at = "2024-03-05T13:20:00Z"
        updated_at = "2024-03-10T11:30:00Z"
        author     = "Pierre Durand"
        tags       = @("video", "produit", "presentation")
        status     = "draft"
        priority   = 3
        language   = "fr"
    },
    [PSCustomObject]@{
        id         = "doc4"
        type       = "pdf"
        title      = "Manuel d'utilisation"
        content    = "Manuel d'utilisation du logiciel"
        created_at = "2023-11-20T08:45:00Z"
        updated_at = "2024-01-05T16:10:00Z"
        author     = "Sophie Lefebvre"
        tags       = @("manuel", "documentation", "pdf")
        status     = "published"
        priority   = 1
        language   = "fr"
    },
    [PSCustomObject]@{
        id         = "doc5"
        type       = "email"
        title      = "Invitation a la reunion"
        content    = "Vous etes invite a la reunion du comite qui aura lieu le 15 mai 2024."
        created_at = "2024-05-01T09:30:00Z"
        updated_at = "2024-05-01T09:30:00Z"
        author     = "Paul Dubois"
        tags       = @("email", "invitation", "reunion")
        status     = "sent"
        priority   = 2
        language   = "fr"
    }
)

# Afficher les documents
Write-Output "Documents de test:"
foreach ($doc in $documents) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par type
Write-Output "`nTest du filtre par type:"
$filteredDocuments = $documents | Filter-ByType -IncludeTypes @("document", "pdf", "email")
Write-Output "Documents filtres par type (document, pdf, email): $($filteredDocuments.Count)"
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

# Tester le filtre par texte
Write-Output "`nTest du filtre par texte:"
$filteredDocuments = $documents | Filter-ByText -Field "content" -Text "rapport" -SearchType "CONTAINS"
Write-Output "Documents filtres par texte (contenu contenant 'rapport'): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Contenu: $($doc.content))"
}

# Tester la recherche floue
Write-Output "`nTest de la recherche floue:"
$filteredDocuments = $documents | Filter-ByText -Field "content" -Text "raport" -SearchType "FUZZY"
Write-Output "Documents filtres par recherche floue (contenu similaire a 'raport'): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Contenu: $($doc.content))"
}

# Tester la combinaison de filtres
Write-Output "`nTest de la combinaison de filtres:"

# Creer les filtres
$typeFilter = { param($doc) $doc | Filter-ByType -IncludeTypes @("document", "pdf", "email") }
$dateFilter = { param($doc) $doc | Filter-ByDate -Field "created_at" -StartDate $startDate -EndDate $endDate }
$languageFilter = { param($doc) $doc | Filter-ByMetadata -Field "language" -Value "fr" }

# Combiner les filtres avec AND
$filteredDocuments = $documents | Merge-Filters -Filters @($typeFilter, $dateFilter, $languageFilter) -LogicalOperator "AND"
Write-Output "Documents filtres par combinaison de filtres (AND): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Cree le: $($doc.created_at), Langue: $($doc.language))"
}

# Combiner les filtres avec OR
$filteredDocuments = $documents | Merge-Filters -Filters @($typeFilter, $dateFilter) -LogicalOperator "OR"
Write-Output "`nDocuments filtres par combinaison de filtres (OR): $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Cree le: $($doc.created_at))"
}

# Tester des cas particuliers
Write-Output "`nTest de cas particuliers:"

# Filtre par priorite (valeur numerique)
$filteredDocuments = $documents | Filter-ByMetadata -Field "priority" -Operator "LE" -Value 2
Write-Output "Documents avec priorite <= 2: $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Priorite: $($doc.priority))"
}

# Filtre par tags (tableau)
$filteredDocuments = $documents | Filter-ByMetadata -Field "tags" -Operator "CONTAINS" -Value "documentation"
Write-Output "`nDocuments avec tag 'documentation': $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title) (Tags: $($doc.tags -join ', '))"
}

# Filtre par expression reguliere
$filteredDocuments = $documents | Filter-ByText -Field "title" -Text "^[RP]" -SearchType "MATCHES"
Write-Output "`nDocuments avec titre commencant par R ou P: $($filteredDocuments.Count)"
foreach ($doc in $filteredDocuments) {
    Write-Output "  - $($doc.id): $($doc.title)"
}

Write-Output "`nTous les tests sont termines."
