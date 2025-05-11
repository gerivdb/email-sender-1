# AsciiFilterTest.ps1
# Script de test pour les filtres utilisant uniquement des caracteres ASCII
# Version: 1.0
# Date: 2025-05-15

# Creer des documents de test
$documents = @(
    @{
        id = "doc1"
        type = "document"
        title = "Rapport annuel 2024"
        description = "Presentation des resultats financiers"
        created_at = "2024-01-15T10:30:00Z"
        language = "fr"
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        description = "Logo officiel en haute resolution"
        created_at = "2023-05-10T09:15:00Z"
        language = "en"
    },
    @{
        id = "doc3"
        type = "video"
        title = "Presentation du produit"
        description = "Demonstration des fonctionnalites"
        created_at = "2024-03-05T13:20:00Z"
        language = "fr"
    }
)

# Afficher les documents
Write-Output "Documents de test:"
foreach ($doc in $documents) {
    Write-Output "  - $($doc.id): $($doc.title) (Type: $($doc.type), Description: $($doc.description))"
}

# Fonction pour filtrer par type
function Filter-ByType {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [string[]]$IncludeTypes
    )
    
    process {
        if ($IncludeTypes -contains $Document.type) {
            return $Document
        }
    }
}

# Fonction pour filtrer par date
function Filter-ByDate {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [string]$Field,
        
        [DateTime]$StartDate,
        
        [DateTime]$EndDate
    )
    
    process {
        if ($Document.ContainsKey($Field)) {
            $dateStr = $Document[$Field]
            if ($dateStr) {
                $date = [DateTime]::Parse($dateStr)
                if ($date -ge $StartDate -and $date -le $EndDate) {
                    return $Document
                }
            }
        }
    }
}

# Fonction pour filtrer par metadonnees
function Filter-ByMetadata {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [string]$Field,
        
        [object]$Value
    )
    
    process {
        if ($Document.ContainsKey($Field) -and $Document[$Field] -eq $Value) {
            return $Document
        }
    }
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
