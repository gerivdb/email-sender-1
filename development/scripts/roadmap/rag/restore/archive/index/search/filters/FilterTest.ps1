# FilterTest.ps1
# Script de test pour les filtres de recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Définir la classe IndexDocument pour les tests
class IndexDocument {
    # ID du document
    [string]$Id
    
    # Contenu du document
    [hashtable]$Content
    
    # Métadonnées du document
    [hashtable]$Metadata
    
    # Constructeur par défaut
    IndexDocument() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Content = @{}
        $this.Metadata = @{}
    }
    
    # Constructeur avec ID
    IndexDocument([string]$id) {
        $this.Id = $id
        $this.Content = @{}
        $this.Metadata = @{}
    }
}

# Définir la classe TypeFilter pour les tests
class TypeFilter {
    # Types de points à inclure
    [string[]]$IncludeTypes
    
    # Types de points à exclure
    [string[]]$ExcludeTypes
    
    # Constructeur par défaut
    TypeFilter() {
        $this.IncludeTypes = @()
        $this.ExcludeTypes = @()
    }
    
    # Constructeur avec types à inclure
    TypeFilter([string[]]$includeTypes) {
        $this.IncludeTypes = $includeTypes
        $this.ExcludeTypes = @()
    }
    
    # Constructeur complet
    TypeFilter([string[]]$includeTypes, [string[]]$excludeTypes) {
        $this.IncludeTypes = $includeTypes
        $this.ExcludeTypes = $excludeTypes
    }
    
    # Méthode pour vérifier si un document correspond au filtre
    [bool] Matches([IndexDocument]$document) {
        # Vérifier si le document a un type
        if (-not $document.Content.ContainsKey("type")) {
            # Si aucun type n'est spécifié, le document ne correspond pas
            return $false
        }
        
        $documentType = $document.Content["type"]
        
        # Vérifier si le type est exclu
        if ($this.ExcludeTypes.Count -gt 0 -and $this.ExcludeTypes -contains $documentType) {
            return $false
        }
        
        # Vérifier si le type est inclus
        if ($this.IncludeTypes.Count -gt 0) {
            return $this.IncludeTypes -contains $documentType
        }
        
        # Si aucun type n'est spécifié à inclure, tous les types non exclus sont inclus
        return $true
    }
}

# Définir la classe DateFilter pour les tests
class DateFilter {
    # Champ de date à filtrer
    [string]$Field
    
    # Date de début
    [DateTime]$StartDate
    
    # Date de fin
    [DateTime]$EndDate
    
    # Constructeur par défaut
    DateFilter() {
        $this.Field = "created_at"
        $this.StartDate = [DateTime]::MinValue
        $this.EndDate = [DateTime]::MaxValue
    }
    
    # Constructeur avec champ
    DateFilter([string]$field) {
        $this.Field = $field
        $this.StartDate = [DateTime]::MinValue
        $this.EndDate = [DateTime]::MaxValue
    }
    
    # Constructeur avec champ et dates
    DateFilter([string]$field, [DateTime]$startDate, [DateTime]$endDate) {
        $this.Field = $field
        $this.StartDate = $startDate
        $this.EndDate = $endDate
    }
    
    # Méthode pour vérifier si un document correspond au filtre
    [bool] Matches([IndexDocument]$document) {
        # Vérifier si le document a le champ de date
        if (-not $document.Content.ContainsKey($this.Field)) {
            return $false
        }
        
        # Récupérer la valeur du champ
        $dateValue = $document.Content[$this.Field]
        
        # Vérifier si la valeur est une date
        if ($null -eq $dateValue) {
            return $false
        }
        
        # Convertir la valeur en date
        $date = $null
        
        if ($dateValue -is [DateTime]) {
            $date = $dateValue
        } elseif ($dateValue -is [string]) {
            try {
                $date = [DateTime]::Parse($dateValue)
            } catch {
                return $false
            }
        } else {
            return $false
        }
        
        # Vérifier si la date est dans la plage
        return $date -ge $this.StartDate -and $date -le $this.EndDate
    }
}

# Créer des documents de test
function Create-TestDocuments {
    $documents = @()
    
    # Document 1: Document texte
    $doc1 = [IndexDocument]::new("doc1")
    $doc1.Content["type"] = "document"
    $doc1.Content["title"] = "Rapport annuel 2024"
    $doc1.Content["content"] = "Ce rapport présente les résultats financiers de l'année 2024."
    $doc1.Content["created_at"] = "2024-01-15T10:30:00Z"
    $doc1.Content["updated_at"] = "2024-02-20T14:45:00Z"
    $doc1.Content["author"] = "Jean Dupont"
    $doc1.Content["tags"] = @("rapport", "finance", "2024")
    $doc1.Content["status"] = "published"
    $doc1.Content["priority"] = 1
    $doc1.Content["language"] = "fr"
    $documents += $doc1
    
    # Document 2: Image
    $doc2 = [IndexDocument]::new("doc2")
    $doc2.Content["type"] = "image"
    $doc2.Content["title"] = "Logo de l'entreprise"
    $doc2.Content["description"] = "Logo officiel de l'entreprise en haute résolution"
    $doc2.Content["created_at"] = "2023-05-10T09:15:00Z"
    $doc2.Content["updated_at"] = "2023-05-10T09:15:00Z"
    $doc2.Content["author"] = "Marie Martin"
    $doc2.Content["tags"] = @("logo", "image", "branding")
    $doc2.Content["status"] = "published"
    $doc2.Content["priority"] = 2
    $doc2.Content["language"] = "en"
    $documents += $doc2
    
    # Document 3: Vidéo
    $doc3 = [IndexDocument]::new("doc3")
    $doc3.Content["type"] = "video"
    $doc3.Content["title"] = "Présentation du produit"
    $doc3.Content["description"] = "Vidéo de présentation du nouveau produit"
    $doc3.Content["created_at"] = "2024-03-05T13:20:00Z"
    $doc3.Content["updated_at"] = "2024-03-10T11:30:00Z"
    $doc3.Content["author"] = "Pierre Durand"
    $doc3.Content["tags"] = @("vidéo", "produit", "présentation")
    $doc3.Content["status"] = "draft"
    $doc3.Content["priority"] = 3
    $doc3.Content["language"] = "fr"
    $documents += $doc3
    
    return $documents
}

# Fonction pour tester les filtres
function Test-Filters {
    # Créer des documents de test
    $documents = Create-TestDocuments
    
    Write-Host "Documents de test créés: $($documents.Count)" -ForegroundColor Green
    foreach ($doc in $documents) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]))"
    }
    
    # Tester le filtre par type
    Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow
    
    # Créer un filtre par type pour les documents et vidéos
    $typeFilter = [TypeFilter]::new(@("document", "video"))
    
    $filteredDocuments = $documents | Where-Object { $typeFilter.Matches($_) }
    
    Write-Host "Documents filtrés par type (document, video): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]))"
    }
    
    # Tester le filtre par date
    Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow
    
    # Créer un filtre par date pour les documents créés en 2024
    $dateFilter = [DateFilter]::new("created_at", [DateTime]::Parse("2024-01-01T00:00:00Z"), [DateTime]::Parse("2024-12-31T23:59:59Z"))
    
    $filteredDocuments = $documents | Where-Object { $dateFilter.Matches($_) }
    
    Write-Host "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Créé le: $($doc.Content["created_at"]))"
    }
    
    # Tester la combinaison de filtres
    Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow
    
    # Filtrer les documents de type "document" créés en 2024
    $filteredDocuments = $documents | Where-Object { $typeFilter.Matches($_) -and $dateFilter.Matches($_) }
    
    Write-Host "Documents filtrés par type et date (document/video créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]), Créé le: $($doc.Content["created_at"]))"
    }
}

# Exécuter les tests
Test-Filters
