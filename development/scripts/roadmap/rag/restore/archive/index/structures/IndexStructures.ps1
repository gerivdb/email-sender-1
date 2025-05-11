# IndexStructures.ps1
# Script définissant les structures de données pour l'indexation des métadonnées
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$schemaPath = Join-Path -Path $parentPath -ChildPath "schema"
$indexSchemaPath = Join-Path -Path $schemaPath -ChildPath "IndexSchema.ps1"

if (Test-Path -Path $indexSchemaPath) {
    . $indexSchemaPath
} else {
    Write-Error "Le fichier IndexSchema.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un document indexé
class IndexDocument {
    # Identifiant unique du document
    [string]$Id
    
    # Contenu du document (hashtable)
    [hashtable]$Content
    
    # Métadonnées du document
    [hashtable]$Metadata
    
    # Constructeur par défaut
    IndexDocument() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Content = @{}
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            version = 1
        }
    }
    
    # Constructeur avec ID
    IndexDocument([string]$id) {
        $this.Id = $id
        $this.Content = @{}
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            version = 1
        }
    }
    
    # Constructeur avec contenu
    IndexDocument([hashtable]$content) {
        if ($content.ContainsKey("id")) {
            $this.Id = $content["id"]
        } else {
            $this.Id = [Guid]::NewGuid().ToString()
        }
        
        $this.Content = $content
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            version = 1
        }
    }
    
    # Méthode pour mettre à jour le contenu
    [void] UpdateContent([hashtable]$content) {
        $this.Content = $content
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.version++
    }
    
    # Méthode pour obtenir une valeur
    [object] GetValue([string]$fieldName) {
        if ($this.Content.ContainsKey($fieldName)) {
            return $this.Content[$fieldName]
        }
        return $null
    }
    
    # Méthode pour définir une valeur
    [void] SetValue([string]$fieldName, [object]$value) {
        $this.Content[$fieldName] = $value
        $this.Metadata.updated_at = (Get-Date).ToString("o")
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $obj = @{
            id = $this.Id
            content = $this.Content
            metadata = $this.Metadata
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour créer à partir de JSON
    static [IndexDocument] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $doc = [IndexDocument]::new()
        $doc.Id = $obj.id
        
        $doc.Content = @{}
        foreach ($prop in $obj.content.PSObject.Properties) {
            $doc.Content[$prop.Name] = $prop.Value
        }
        
        $doc.Metadata = @{}
        foreach ($prop in $obj.metadata.PSObject.Properties) {
            $doc.Metadata[$prop.Name] = $prop.Value
        }
        
        return $doc
    }
}

# Classe pour représenter un segment d'index
class IndexSegment {
    # Identifiant unique du segment
    [string]$Id
    
    # Nom du segment
    [string]$Name
    
    # Documents contenus dans le segment
    [System.Collections.Generic.Dictionary[string, IndexDocument]]$Documents
    
    # Index inversé (terme -> liste de documents)
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]$InvertedIndex
    
    # Métadonnées du segment
    [hashtable]$Metadata
    
    # Constructeur par défaut
    IndexSegment() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = "segment_$($this.Id.Substring(0, 8))"
        $this.Documents = [System.Collections.Generic.Dictionary[string, IndexDocument]]::new()
        $this.InvertedIndex = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            document_count = 0
            term_count = 0
            size_bytes = 0
        }
    }
    
    # Constructeur avec nom
    IndexSegment([string]$name) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Documents = [System.Collections.Generic.Dictionary[string, IndexDocument]]::new()
        $this.InvertedIndex = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            document_count = 0
            term_count = 0
            size_bytes = 0
        }
    }
    
    # Méthode pour ajouter un document
    [void] AddDocument([IndexDocument]$document) {
        # Ajouter le document à la collection
        $this.Documents[$document.Id] = $document
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.document_count = $this.Documents.Count
        
        # Indexer le document
        $this.IndexDocument($document)
    }
    
    # Méthode pour supprimer un document
    [bool] RemoveDocument([string]$documentId) {
        if (-not $this.Documents.ContainsKey($documentId)) {
            return $false
        }
        
        # Supprimer le document de l'index inversé
        foreach ($term in $this.InvertedIndex.Keys) {
            $docIds = $this.InvertedIndex[$term]
            $docIds.Remove($documentId)
            
            # Supprimer le terme si plus aucun document ne l'utilise
            if ($docIds.Count -eq 0) {
                $this.InvertedIndex.Remove($term)
            }
        }
        
        # Supprimer le document de la collection
        $this.Documents.Remove($documentId)
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.document_count = $this.Documents.Count
        $this.Metadata.term_count = $this.InvertedIndex.Count
        
        return $true
    }
    
    # Méthode pour indexer un document
    [void] IndexDocument([IndexDocument]$document) {
        # Obtenir le schéma d'index
        $schema = Get-IndexSchema
        
        # Parcourir tous les champs indexables
        foreach ($fieldName in $schema.Documents.IndexedFields) {
            # Vérifier si le champ existe dans le document
            if (-not $document.Content.ContainsKey($fieldName)) {
                continue
            }
            
            $value = $document.Content[$fieldName]
            
            # Ignorer les valeurs nulles
            if ($null -eq $value) {
                continue
            }
            
            # Déterminer le type de champ
            $fieldDef = $null
            foreach ($mapping in $schema.Mappings.GetEnumerator()) {
                if ($mapping.Key -eq $fieldName) {
                    $fieldDef = $mapping.Value
                    break
                }
            }
            
            if ($null -eq $fieldDef) {
                continue
            }
            
            # Indexer selon le type
            switch ($fieldDef.Type) {
                { $_ -in @("text", "string") -and $fieldDef.Analyzer -ne "keyword" } {
                    # Texte tokenisé
                    $this.IndexTextField($fieldName, $value, $document.Id)
                }
                { $_ -in @("keyword", "string") -and $fieldDef.Analyzer -eq "keyword" } {
                    # Mot-clé
                    $this.IndexKeywordField($fieldName, $value, $document.Id)
                }
                { $_ -in @("number", "double", "float") } {
                    # Numérique
                    $this.IndexNumericField($fieldName, $value, $document.Id)
                }
                { $_ -in @("date", "datetime") } {
                    # Date
                    $this.IndexDateField($fieldName, $value, $document.Id)
                }
                { $_ -in @("boolean", "bool") } {
                    # Booléen
                    $this.IndexBooleanField($fieldName, $value, $document.Id)
                }
            }
        }
        
        # Mettre à jour les métadonnées
        $this.Metadata.term_count = $this.InvertedIndex.Count
    }
    
    # Méthode pour indexer un champ de texte
    [void] IndexTextField([string]$fieldName, [object]$value, [string]$documentId) {
        # Convertir en chaîne
        $text = [string]$value
        
        # Tokeniser le texte
        $tokens = $this.TokenizeText($text)
        
        # Ajouter chaque token à l'index inversé
        foreach ($token in $tokens) {
            $term = "$fieldName:$token"
            
            if (-not $this.InvertedIndex.ContainsKey($term)) {
                $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
            }
            
            if (-not $this.InvertedIndex[$term].Contains($documentId)) {
                $this.InvertedIndex[$term].Add($documentId)
            }
        }
    }
    
    # Méthode pour indexer un champ de mot-clé
    [void] IndexKeywordField([string]$fieldName, [object]$value, [string]$documentId) {
        # Traiter les tableaux
        if ($value -is [array] -or $value -is [System.Collections.IList]) {
            foreach ($item in $value) {
                $keyword = [string]$item
                $term = "$fieldName:$keyword"
                
                if (-not $this.InvertedIndex.ContainsKey($term)) {
                    $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
                }
                
                if (-not $this.InvertedIndex[$term].Contains($documentId)) {
                    $this.InvertedIndex[$term].Add($documentId)
                }
            }
        } else {
            # Valeur unique
            $keyword = [string]$value
            $term = "$fieldName:$keyword"
            
            if (-not $this.InvertedIndex.ContainsKey($term)) {
                $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
            }
            
            if (-not $this.InvertedIndex[$term].Contains($documentId)) {
                $this.InvertedIndex[$term].Add($documentId)
            }
        }
    }
    
    # Méthode pour indexer un champ numérique
    [void] IndexNumericField([string]$fieldName, [object]$value, [string]$documentId) {
        # Convertir en nombre
        $number = [double]$value
        
        # Ajouter à l'index inversé
        $term = "$fieldName:$number"
        
        if (-not $this.InvertedIndex.ContainsKey($term)) {
            $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
        }
        
        if (-not $this.InvertedIndex[$term].Contains($documentId)) {
            $this.InvertedIndex[$term].Add($documentId)
        }
    }
    
    # Méthode pour indexer un champ de date
    [void] IndexDateField([string]$fieldName, [object]$value, [string]$documentId) {
        # Convertir en date
        $date = if ($value -is [DateTime]) {
            $value
        } else {
            [DateTime]::Parse([string]$value)
        }
        
        # Format ISO 8601
        $dateStr = $date.ToString("o")
        
        # Ajouter à l'index inversé
        $term = "$fieldName:$dateStr"
        
        if (-not $this.InvertedIndex.ContainsKey($term)) {
            $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
        }
        
        if (-not $this.InvertedIndex[$term].Contains($documentId)) {
            $this.InvertedIndex[$term].Add($documentId)
        }
        
        # Ajouter également l'année, le mois et le jour pour faciliter les recherches
        $year = $date.Year
        $month = $date.Month
        $day = $date.Day
        
        $termYear = "$fieldName.year:$year"
        $termMonth = "$fieldName.month:$month"
        $termDay = "$fieldName.day:$day"
        
        foreach ($t in @($termYear, $termMonth, $termDay)) {
            if (-not $this.InvertedIndex.ContainsKey($t)) {
                $this.InvertedIndex[$t] = [System.Collections.Generic.List[string]]::new()
            }
            
            if (-not $this.InvertedIndex[$t].Contains($documentId)) {
                $this.InvertedIndex[$t].Add($documentId)
            }
        }
    }
    
    # Méthode pour indexer un champ booléen
    [void] IndexBooleanField([string]$fieldName, [object]$value, [string]$documentId) {
        # Convertir en booléen
        $bool = [bool]$value
        
        # Ajouter à l'index inversé
        $term = "$fieldName:$($bool.ToString().ToLower())"
        
        if (-not $this.InvertedIndex.ContainsKey($term)) {
            $this.InvertedIndex[$term] = [System.Collections.Generic.List[string]]::new()
        }
        
        if (-not $this.InvertedIndex[$term].Contains($documentId)) {
            $this.InvertedIndex[$term].Add($documentId)
        }
    }
    
    # Méthode pour tokeniser un texte
    [string[]] TokenizeText([string]$text) {
        # Convertir en minuscules
        $text = $text.ToLower()
        
        # Supprimer la ponctuation
        $text = $text -replace '[^\p{L}\p{N}\s]', ' '
        
        # Diviser en tokens
        $tokens = $text -split '\s+'
        
        # Filtrer les tokens vides
        $tokens = $tokens | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
        return $tokens
    }
    
    # Méthode pour rechercher des documents
    [string[]] Search([string]$query) {
        # Tokeniser la requête
        $tokens = $this.TokenizeText($query)
        
        # Rechercher chaque token
        $results = [System.Collections.Generic.Dictionary[string, int]]::new()
        
        foreach ($token in $tokens) {
            # Rechercher dans tous les champs de texte
            foreach ($term in $this.InvertedIndex.Keys) {
                if ($term -like "*:*$token*") {
                    $docIds = $this.InvertedIndex[$term]
                    
                    foreach ($docId in $docIds) {
                        if (-not $results.ContainsKey($docId)) {
                            $results[$docId] = 0
                        }
                        
                        $results[$docId]++
                    }
                }
            }
        }
        
        # Trier les résultats par score (nombre de tokens correspondants)
        $sortedResults = $results.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { $_.Key }
        
        return $sortedResults
    }
    
    # Méthode pour filtrer des documents
    [string[]] Filter([hashtable]$filters) {
        # Ensemble de documents correspondant à tous les filtres
        $matchingDocs = $null
        
        foreach ($fieldName in $filters.Keys) {
            $value = $filters[$fieldName]
            
            # Ignorer les valeurs nulles
            if ($null -eq $value) {
                continue
            }
            
            # Construire le terme
            $term = "$fieldName:$value"
            
            # Vérifier si le terme existe dans l'index
            if (-not $this.InvertedIndex.ContainsKey($term)) {
                # Aucun document ne correspond à ce filtre
                return @()
            }
            
            $docIds = $this.InvertedIndex[$term]
            
            if ($null -eq $matchingDocs) {
                # Premier filtre, initialiser l'ensemble
                $matchingDocs = [System.Collections.Generic.HashSet[string]]::new($docIds)
            } else {
                # Intersection avec les résultats précédents
                $matchingDocs.IntersectWith($docIds)
                
                # Si l'ensemble est vide, aucun document ne correspond à tous les filtres
                if ($matchingDocs.Count -eq 0) {
                    return @()
                }
            }
        }
        
        # Si aucun filtre n'a été appliqué, retourner tous les documents
        if ($null -eq $matchingDocs) {
            return $this.Documents.Keys
        }
        
        return [string[]]$matchingDocs
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        # Créer un objet sérialisable
        $obj = @{
            id = $this.Id
            name = $this.Name
            metadata = $this.Metadata
            documents = @{}
            inverted_index = @{}
        }
        
        # Convertir les documents
        foreach ($docId in $this.Documents.Keys) {
            $obj.documents[$docId] = $this.Documents[$docId].Content
        }
        
        # Convertir l'index inversé
        foreach ($term in $this.InvertedIndex.Keys) {
            $obj.inverted_index[$term] = $this.InvertedIndex[$term]
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour créer à partir de JSON
    static [IndexSegment] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $segment = [IndexSegment]::new($obj.name)
        $segment.Id = $obj.id
        
        # Charger les métadonnées
        $segment.Metadata = @{}
        foreach ($prop in $obj.metadata.PSObject.Properties) {
            $segment.Metadata[$prop.Name] = $prop.Value
        }
        
        # Charger les documents
        foreach ($docId in $obj.documents.PSObject.Properties.Name) {
            $docContent = @{}
            
            foreach ($prop in $obj.documents.$docId.PSObject.Properties) {
                $docContent[$prop.Name] = $prop.Value
            }
            
            $document = [IndexDocument]::new($docContent)
            $segment.Documents[$docId] = $document
        }
        
        # Charger l'index inversé
        foreach ($term in $obj.inverted_index.PSObject.Properties.Name) {
            $docIds = [System.Collections.Generic.List[string]]::new()
            
            foreach ($docId in $obj.inverted_index.$term) {
                $docIds.Add($docId)
            }
            
            $segment.InvertedIndex[$term] = $docIds
        }
        
        return $segment
    }
}

# Exporter les classes
Export-ModuleMember -Function *
