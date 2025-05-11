# TestFilters.ps1
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
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            id = $this.Id
            content = $this.Content
            metadata = $this.Metadata
        }
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        return ConvertTo-Json -InputObject $this.ToHashtable() -Depth 10
    }
}

# Définir la classe PerformanceMetricsManager pour les tests
class PerformanceMetricsManager {
    # Dictionnaire des compteurs
    [hashtable]$Counters
    
    # Dictionnaire des chronomètres
    [hashtable]$Timers
    
    # Constructeur par défaut
    PerformanceMetricsManager() {
        $this.Counters = @{}
        $this.Timers = @{}
    }
    
    # Méthode pour obtenir un compteur
    [hashtable] GetCounter([string]$name) {
        if (-not $this.Counters.ContainsKey($name)) {
            $this.Counters[$name] = @{
                value = 0
                min = [long]::MaxValue
                max = [long]::MinValue
                sample_count = 0
                sum = 0
                sum_of_squares = 0
            }
        }
        
        return $this.Counters[$name]
    }
    
    # Méthode pour incrémenter un compteur
    [void] IncrementCounter([string]$name, [long]$value = 1) {
        $counter = $this.GetCounter($name)
        $counter.value += $value
        $counter.min = [Math]::Min($counter.min, $counter.value)
        $counter.max = [Math]::Max($counter.max, $counter.value)
        $counter.sample_count++
        $counter.sum += $value
        $counter.sum_of_squares += $value * $value
    }
    
    # Méthode pour obtenir un chronomètre
    [hashtable] GetTimer([string]$name) {
        if (-not $this.Timers.ContainsKey($name)) {
            $this.Timers[$name] = @{
                stopwatch = [System.Diagnostics.Stopwatch]::new()
                counter = $this.GetCounter($name)
            }
        }
        
        return $this.Timers[$name]
    }
    
    # Méthode pour obtenir toutes les métriques
    [hashtable] GetAllMetrics() {
        return @{
            counters = $this.Counters
            timers = $this.Timers
        }
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
    
    # Document 4: PDF
    $doc4 = [IndexDocument]::new("doc4")
    $doc4.Content["type"] = "pdf"
    $doc4.Content["title"] = "Manuel d'utilisation"
    $doc4.Content["description"] = "Manuel d'utilisation du logiciel"
    $doc4.Content["created_at"] = "2023-11-20T08:45:00Z"
    $doc4.Content["updated_at"] = "2024-01-05T16:10:00Z"
    $doc4.Content["author"] = "Sophie Lefebvre"
    $doc4.Content["tags"] = @("manuel", "documentation", "pdf")
    $doc4.Content["status"] = "published"
    $doc4.Content["priority"] = 1
    $doc4.Content["language"] = "fr"
    $documents += $doc4
    
    # Document 5: Email
    $doc5 = [IndexDocument]::new("doc5")
    $doc5.Content["type"] = "email"
    $doc5.Content["title"] = "Invitation à la réunion"
    $doc5.Content["content"] = "Vous êtes invité à la réunion du comité qui aura lieu le 15 mai 2024."
    $doc5.Content["created_at"] = "2024-05-01T09:30:00Z"
    $doc5.Content["updated_at"] = "2024-05-01T09:30:00Z"
    $doc5.Content["author"] = "Paul Dubois"
    $doc5.Content["tags"] = @("email", "invitation", "réunion")
    $doc5.Content["status"] = "sent"
    $doc5.Content["priority"] = 2
    $doc5.Content["language"] = "fr"
    $documents += $doc5
    
    return $documents
}

# Fonction pour tester les filtres
function Test-Filters {
    # Créer des documents de test
    $documents = Create-TestDocuments()
    
    Write-Host "Documents de test créés: $($documents.Count)" -ForegroundColor Green
    
    # Tester le filtre par type
    Write-Host "`nTest du filtre par type:" -ForegroundColor Yellow
    
    # Créer un filtre par type pour les documents
    $typeFilter = [PSCustomObject]@{
        IncludeTypes = @("document", "pdf")
        ExcludeTypes = @()
        Matches = {
            param($document)
            
            # Vérifier si le document a un type
            if (-not $document.Content.ContainsKey("type")) {
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
    
    $filteredDocuments = $documents | Where-Object { & $typeFilter.Matches $_ }
    
    Write-Host "Documents filtrés par type (document, pdf): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]))"
    }
    
    # Tester le filtre par date
    Write-Host "`nTest du filtre par date:" -ForegroundColor Yellow
    
    # Créer un filtre par date pour les documents créés en 2024
    $dateFilter = [PSCustomObject]@{
        Field = "created_at"
        StartDate = [DateTime]::Parse("2024-01-01T00:00:00Z")
        EndDate = [DateTime]::Parse("2024-12-31T23:59:59Z")
        Matches = {
            param($document)
            
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
    
    $filteredDocuments = $documents | Where-Object { & $dateFilter.Matches $_ }
    
    Write-Host "Documents filtrés par date (créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Créé le: $($doc.Content["created_at"]))"
    }
    
    # Tester le filtre par métadonnées
    Write-Host "`nTest du filtre par métadonnées:" -ForegroundColor Yellow
    
    # Créer un filtre par métadonnées pour les documents avec priorité 1
    $metadataFilter = [PSCustomObject]@{
        Conditions = @(
            [PSCustomObject]@{
                Field = "priority"
                Operator = "EQ"
                Value = 1
                Matches = {
                    param($fieldValue)
                    
                    # Si la valeur du champ est null, elle ne correspond que si la valeur à comparer est également null
                    if ($null -eq $fieldValue) {
                        return $null -eq $this.Value
                    }
                    
                    # Si la valeur à comparer est null, elle ne correspond que si la valeur du champ est également null
                    if ($null -eq $this.Value) {
                        return $null -eq $fieldValue
                    }
                    
                    # Comparer les valeurs selon l'opérateur
                    switch ($this.Operator) {
                        "EQ" { return $fieldValue -eq $this.Value }
                        "NE" { return $fieldValue -ne $this.Value }
                        "GT" { return $fieldValue -gt $this.Value }
                        "GE" { return $fieldValue -ge $this.Value }
                        "LT" { return $fieldValue -lt $this.Value }
                        "LE" { return $fieldValue -le $this.Value }
                        default { return $fieldValue -eq $this.Value }
                    }
                }
            }
        )
        LogicalOperator = "AND"
        Matches = {
            param($document)
            
            # Si aucune condition n'est spécifiée, le document correspond
            if ($this.Conditions.Count -eq 0) {
                return $true
            }
            
            # Vérifier chaque condition
            foreach ($condition in $this.Conditions) {
                # Vérifier si le document a le champ
                $hasField = $document.Content.ContainsKey($condition.Field)
                
                # Récupérer la valeur du champ
                $fieldValue = if ($hasField) { $document.Content[$condition.Field] } else { $null }
                
                # Vérifier si la valeur correspond à la condition
                $matches = & $condition.Matches $fieldValue
                
                # Appliquer l'opérateur logique
                if ($this.LogicalOperator -eq "AND" -and -not $matches) {
                    return $false
                } elseif ($this.LogicalOperator -eq "OR" -and $matches) {
                    return $true
                }
            }
            
            # Si l'opérateur est AND, toutes les conditions doivent correspondre
            # Si l'opérateur est OR, au moins une condition doit correspondre
            return $this.LogicalOperator -eq "AND"
        }
    }
    
    $filteredDocuments = $documents | Where-Object { & $metadataFilter.Matches $_ }
    
    Write-Host "Documents filtrés par métadonnées (priorité = 1): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Priorité: $($doc.Content["priority"]))"
    }
    
    # Tester le filtre par texte
    Write-Host "`nTest du filtre par texte:" -ForegroundColor Yellow
    
    # Créer un filtre par texte pour les documents contenant "rapport"
    $textFilter = [PSCustomObject]@{
        Field = "title"
        Text = "rapport"
        SearchType = "CONTAINS"
        CaseSensitive = $false
        Matches = {
            param($document)
            
            # Vérifier si le document a le champ
            if (-not $document.Content.ContainsKey($this.Field)) {
                return $false
            }
            
            # Récupérer la valeur du champ
            $fieldValue = $document.Content[$this.Field]
            
            # Vérifier si la valeur est une chaîne
            if ($null -eq $fieldValue -or -not ($fieldValue -is [string])) {
                return $false
            }
            
            # Préparer les valeurs pour la comparaison
            $text = $this.Text
            $value = $fieldValue
            
            if (-not $this.CaseSensitive) {
                $text = $text.ToLower()
                $value = $value.ToLower()
            }
            
            # Comparer selon le type de recherche
            switch ($this.SearchType) {
                "EXACT" { return $value -eq $text }
                "CONTAINS" { return $value.Contains($text) }
                "STARTS_WITH" { return $value.StartsWith($text) }
                "ENDS_WITH" { return $value.EndsWith($text) }
                "MATCHES" { return $value -match $text }
                default { return $value.Contains($text) }
            }
        }
    }
    
    $filteredDocuments = $documents | Where-Object { & $textFilter.Matches $_ }
    
    Write-Host "Documents filtrés par texte (titre contenant 'rapport'): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"])"
    }
    
    # Tester la combinaison de filtres
    Write-Host "`nTest de la combinaison de filtres:" -ForegroundColor Yellow
    
    # Créer un filtre combiné pour les documents de type "document" créés en 2024
    $combinedFilter = [PSCustomObject]@{
        TypeFilter = $typeFilter
        DateFilter = $dateFilter
        Matches = {
            param($document)
            
            # Vérifier si le document correspond au filtre par type
            $matchesType = & $this.TypeFilter.Matches $document
            
            # Vérifier si le document correspond au filtre par date
            $matchesDate = & $this.DateFilter.Matches $document
            
            # Combiner les résultats avec l'opérateur AND
            return $matchesType -and $matchesDate
        }
    }
    
    $filteredDocuments = $documents | Where-Object { & $combinedFilter.Matches $_ }
    
    Write-Host "Documents filtrés par type et date (document/pdf créés en 2024): $($filteredDocuments.Count)" -ForegroundColor Cyan
    foreach ($doc in $filteredDocuments) {
        Write-Host "  - $($doc.Id): $($doc.Content["title"]) (Type: $($doc.Content["type"]), Créé le: $($doc.Content["created_at"]))"
    }
}

# Exécuter les tests
Test-Filters
