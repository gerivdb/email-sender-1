# FunctionTest.ps1
# Script de test utilisant des fonctions pour les filtres
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

# Fonction pour filtrer par type
function Select-ByType {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [Parameter(Mandatory = $true)]
        [string[]]$IncludeTypes
    )
    
    process {
        if ($IncludeTypes -contains $Document.type) {
            return $Document
        }
    }
}

# Fonction pour filtrer par date
function Select-ByDate {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $true)]
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

# Fonction pour filtrer par métadonnées
function Select-ByMetadata {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [hashtable]$Document,
        
        [Parameter(Mandatory = $true)]
        [string]$Field,
        
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    process {
        if ($Document.ContainsKey($Field) -and $Document[$Field] -eq $Value) {
            return $Document
        }
    }
}

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par type
Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow
$filteredDocuments = $documents | Select-ByType -IncludeTypes @("document", "video")
Write-Host "Documents filtrés par type (document, video): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Tester le filtre par date
Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow
$startDate = [DateTime]::Parse("2024-01-01T00:00:00Z")
$endDate = [DateTime]::Parse("2024-12-31T23:59:59Z")
$filteredDocuments = $documents | Select-ByDate -Field "created_at" -StartDate $startDate -EndDate $endDate
Write-Host "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Créé le: $($doc.created_at))"
}

# Tester le filtre par métadonnées
Write-Host "`nTest du filtre par métadonnées:" -ForegroundColor Yellow
$filteredDocuments = $documents | Select-ByMetadata -Field "language" -Value "fr"
Write-Host "Documents filtrés par métadonnées (langue = fr): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Langue: $($doc.language))"
}

# Tester la combinaison de filtres
Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow
$filteredDocuments = $documents | 
    Select-ByType -IncludeTypes @("document", "video") | 
    Select-ByDate -Field "created_at" -StartDate $startDate -EndDate $endDate | 
    Select-ByMetadata -Field "language" -Value "fr"
Write-Host "Documents filtrés par combinaison de filtres: $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at), Langue: $($doc.language))"
}

