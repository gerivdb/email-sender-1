# SimpleTest.ps1
# Script de test simple pour les filtres de recherche avancée
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

# Créer des documents de test
$documents = @()

# Document 1: Document texte
$doc1 = [IndexDocument]::new("doc1")
$doc1.Content["type"] = "document"
$doc1.Content["title"] = "Rapport annuel 2024"
$doc1.Content["content"] = "Ce rapport présente les résultats financiers de l'année 2024."
$doc1.Content["created_at"] = "2024-01-15T10:30:00Z"
$documents += $doc1

# Document 2: Image
$doc2 = [IndexDocument]::new("doc2")
$doc2.Content["type"] = "image"
$doc2.Content["title"] = "Logo de l'entreprise"
$doc2.Content["created_at"] = "2023-05-10T09:15:00Z"
$documents += $doc2

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]))"
}

# Tester le filtre par type
Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow

# Filtrer les documents de type "document"
$filteredDocuments = $documents | Where-Object { $_.Content["type"] -eq "document" }

Write-Host "Documents de type 'document': $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.Id): $($doc.Content["title"])"
}

# Tester le filtre par date
Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow

# Filtrer les documents créés en 2024
$filteredDocuments = @()
foreach ($doc in $documents) {
    $dateStr = $doc.Content["created_at"]
    if ($dateStr) {
        $date = [DateTime]::Parse($dateStr)
        if ($date.Year -eq 2024) {
            $filteredDocuments += $doc
        }
    }
}

Write-Host "Documents créés en 2024: $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Créé le: $($doc.Content["created_at"]))"
}

# Tester la combinaison de filtres
Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow

# Filtrer les documents de type "document" créés en 2024
$filteredDocuments = @()
foreach ($doc in $documents) {
    if ($doc.Content["type"] -eq "document") {
        $dateStr = $doc.Content["created_at"]
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
    Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]), Créé le: $($doc.Content["created_at"]))"
}
