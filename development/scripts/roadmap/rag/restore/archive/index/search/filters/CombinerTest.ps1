# CombinerTest.ps1
# Script de test pour le combinateur de filtres
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
        status = "published"
        priority = 1
        language = "fr"
        tags = @("rapport", "finance", "2024")
    },
    @{
        id = "doc2"
        type = "image"
        title = "Logo de l'entreprise"
        content = "Logo officiel de l'entreprise en haute résolution"
        created_at = "2023-05-10T09:15:00Z"
        status = "published"
        priority = 2
        language = "en"
        tags = @("logo", "image", "branding")
    },
    @{
        id = "doc3"
        type = "video"
        title = "Présentation du produit"
        content = "Vidéo de présentation du nouveau produit"
        created_at = "2024-03-05T13:20:00Z"
        status = "draft"
        priority = 3
        language = "fr"
        tags = @("vidéo", "produit", "présentation")
    },
    @{
        id = "doc4"
        type = "pdf"
        title = "Manuel d'utilisation"
        content = "Manuel d'utilisation du logiciel"
        created_at = "2023-11-20T08:45:00Z"
        status = "published"
        priority = 1
        language = "fr"
        tags = @("manuel", "documentation", "pdf")
    },
    @{
        id = "doc5"
        type = "email"
        title = "Invitation à la réunion"
        content = "Vous êtes invité à la réunion du comité qui aura lieu le 15 mai 2024."
        created_at = "2024-05-01T09:30:00Z"
        status = "sent"
        priority = 2
        language = "fr"
        tags = @("email", "invitation", "réunion")
    }
)

# Afficher les documents
Write-Host "Documents de test:" -ForegroundColor Green
foreach ($doc in $documents) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

# Définir les filtres
$typeFilter = @{
    includeTypes = @("document", "pdf", "email")
    excludeTypes = @()
    matches = {
        param($doc)
        if ($this.includeTypes.Count -gt 0) {
            return $this.includeTypes -contains $doc.type
        }
        if ($this.excludeTypes.Count -gt 0) {
            return -not ($this.excludeTypes -contains $doc.type)
        }
        return $true
    }
}

$dateFilter = @{
    field = "created_at"
    startDate = [DateTime]::Parse("2024-01-01T00:00:00Z")
    endDate = [DateTime]::Parse("2024-12-31T23:59:59Z")
    matches = {
        param($doc)
        if (-not $doc.ContainsKey($this.field)) {
            return $false
        }
        $dateStr = $doc[$this.field]
        if (-not $dateStr) {
            return $false
        }
        $date = [DateTime]::Parse($dateStr)
        return $date -ge $this.startDate -and $date -le $this.endDate
    }
}

$metadataFilter = @{
    conditions = @(
        @{
            field = "language"
            operator = "EQ"
            value = "fr"
            matches = {
                param($fieldValue)
                return $fieldValue -eq $this.value
            }
        }
    )
    logicalOperator = "AND"
    matches = {
        param($doc)
        foreach ($condition in $this.conditions) {
            $fieldValue = $doc[$condition.field]
            $matches = & $condition.matches $fieldValue
            if ($this.logicalOperator -eq "AND" -and -not $matches) {
                return $false
            }
            if ($this.logicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        return $this.logicalOperator -eq "AND"
    }
}

$textFilter = @{
    field = "content"
    text = "rapport"
    searchType = "CONTAINS"
    caseSensitive = $false
    matches = {
        param($doc)
        if (-not $doc.ContainsKey($this.field)) {
            return $false
        }
        $fieldValue = $doc[$this.field]
        if (-not $fieldValue -or -not ($fieldValue -is [string])) {
            return $false
        }
        $text = $this.text
        $value = $fieldValue
        if (-not $this.caseSensitive) {
            $text = $text.ToLower()
            $value = $value.ToLower()
        }
        switch ($this.searchType) {
            "EXACT" { return $value -eq $text }
            "CONTAINS" { return $value.Contains($text) }
            "STARTS_WITH" { return $value.StartsWith($text) }
            "ENDS_WITH" { return $value.EndsWith($text) }
            "MATCHES" { return $value -match $text }
            default { return $value.Contains($text) }
        }
    }
}

# Définir le combinateur de filtres
$combinedFilter = @{
    filters = @($typeFilter, $dateFilter, $metadataFilter, $textFilter)
    logicalOperator = "AND"
    matches = {
        param($doc)
        foreach ($filter in $this.filters) {
            $matches = & $filter.matches $doc
            if ($this.logicalOperator -eq "AND" -and -not $matches) {
                return $false
            }
            if ($this.logicalOperator -eq "OR" -and $matches) {
                return $true
            }
        }
        return $this.logicalOperator -eq "AND"
    }
}

# Tester les filtres individuels
Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow
$filteredDocuments = $documents | Where-Object { & $typeFilter.matches $_ }
Write-Host "Documents filtrés par type (document, pdf, email): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type))"
}

Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow
$filteredDocuments = $documents | Where-Object { & $dateFilter.matches $_ }
Write-Host "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Créé le: $($doc.created_at))"
}

Write-Host "`nTest du filtre par métadonnées:" -ForegroundColor Yellow
$filteredDocuments = $documents | Where-Object { & $metadataFilter.matches $_ }
Write-Host "Documents filtrés par métadonnées (langue = fr): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Langue: $($doc.language))"
}

Write-Host "`nTest du filtre par texte:" -ForegroundColor Yellow
$filteredDocuments = $documents | Where-Object { & $textFilter.matches $_ }
Write-Host "Documents filtrés par texte (contenu contenant 'rapport'): $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Contenu: $($doc.content))"
}

# Tester le combinateur de filtres
Write-Host "`nTest du combinateur de filtres:" -ForegroundColor Yellow
$filteredDocuments = $documents | Where-Object { & $combinedFilter.matches $_ }
Write-Host "Documents filtrés par combinaison de filtres: $($filteredDocuments.Count)" -ForegroundColor Cyan
foreach ($doc in $filteredDocuments) {
    Write-Host "  - $($doc.id): $($doc.title) (Type: $($doc.type), Créé le: $($doc.created_at), Langue: $($doc.language), Contenu: $($doc.content))"
}
