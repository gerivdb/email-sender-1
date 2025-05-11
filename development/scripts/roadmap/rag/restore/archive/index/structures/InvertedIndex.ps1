# InvertedIndex.ps1
# Script implémentant les index inversés pour la recherche dans les métadonnées
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexStructuresPath = Join-Path -Path $scriptPath -ChildPath "IndexStructures.ps1"

if (Test-Path -Path $indexStructuresPath) {
    . $indexStructuresPath
} else {
    Write-Error "Le fichier IndexStructures.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un index inversé
class InvertedIndex {
    # Dictionnaire des termes (terme -> liste de documents)
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]$Terms
    
    # Dictionnaire des champs (champ -> liste de termes)
    [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]$Fields
    
    # Métadonnées de l'index
    [hashtable]$Metadata
    
    # Constructeur par défaut
    InvertedIndex() {
        $this.Terms = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()
        $this.Fields = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.HashSet[string]]]::new()
        $this.Metadata = @{
            created_at = (Get-Date).ToString("o")
            updated_at = (Get-Date).ToString("o")
            term_count = 0
            field_count = 0
            document_count = 0
        }
    }
    
    # Méthode pour ajouter un terme
    [void] AddTerm([string]$field, [string]$term, [string]$documentId) {
        # Construire la clé du terme
        $termKey = "$field:$term"
        
        # Ajouter le terme à l'index
        if (-not $this.Terms.ContainsKey($termKey)) {
            $this.Terms[$termKey] = [System.Collections.Generic.List[string]]::new()
        }
        
        if (-not $this.Terms[$termKey].Contains($documentId)) {
            $this.Terms[$termKey].Add($documentId)
        }
        
        # Ajouter le champ à l'index des champs
        if (-not $this.Fields.ContainsKey($field)) {
            $this.Fields[$field] = [System.Collections.Generic.HashSet[string]]::new()
        }
        
        $this.Fields[$field].Add($term)
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.term_count = $this.Terms.Count
        $this.Metadata.field_count = $this.Fields.Count
    }
    
    # Méthode pour supprimer un terme
    [void] RemoveTerm([string]$field, [string]$term, [string]$documentId) {
        # Construire la clé du terme
        $termKey = "$field:$term"
        
        # Vérifier si le terme existe
        if (-not $this.Terms.ContainsKey($termKey)) {
            return
        }
        
        # Supprimer le document de la liste
        $this.Terms[$termKey].Remove($documentId)
        
        # Si la liste est vide, supprimer le terme
        if ($this.Terms[$termKey].Count -eq 0) {
            $this.Terms.Remove($termKey)
            
            # Supprimer également le terme de l'index des champs
            if ($this.Fields.ContainsKey($field)) {
                $this.Fields[$field].Remove($term)
                
                # Si le champ n'a plus de termes, le supprimer
                if ($this.Fields[$field].Count -eq 0) {
                    $this.Fields.Remove($field)
                }
            }
        }
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.term_count = $this.Terms.Count
        $this.Metadata.field_count = $this.Fields.Count
    }
    
    # Méthode pour supprimer un document
    [void] RemoveDocument([string]$documentId) {
        # Liste des termes à supprimer
        $termsToRemove = [System.Collections.Generic.List[string]]::new()
        
        # Parcourir tous les termes
        foreach ($termKey in $this.Terms.Keys) {
            $docIds = $this.Terms[$termKey]
            
            # Supprimer le document de la liste
            $docIds.Remove($documentId)
            
            # Si la liste est vide, ajouter le terme à la liste des termes à supprimer
            if ($docIds.Count -eq 0) {
                $termsToRemove.Add($termKey)
            }
        }
        
        # Supprimer les termes
        foreach ($termKey in $termsToRemove) {
            $parts = $termKey -split ':', 2
            $field = $parts[0]
            $term = $parts[1]
            
            $this.Terms.Remove($termKey)
            
            # Supprimer également le terme de l'index des champs
            if ($this.Fields.ContainsKey($field)) {
                $this.Fields[$field].Remove($term)
                
                # Si le champ n'a plus de termes, le supprimer
                if ($this.Fields[$field].Count -eq 0) {
                    $this.Fields.Remove($field)
                }
            }
        }
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.term_count = $this.Terms.Count
        $this.Metadata.field_count = $this.Fields.Count
    }
    
    # Méthode pour rechercher des documents par terme exact
    [string[]] SearchExact([string]$field, [string]$term) {
        # Construire la clé du terme
        $termKey = "$field:$term"
        
        # Vérifier si le terme existe
        if (-not $this.Terms.ContainsKey($termKey)) {
            return @()
        }
        
        # Retourner la liste des documents
        return $this.Terms[$termKey].ToArray()
    }
    
    # Méthode pour rechercher des documents par préfixe
    [string[]] SearchPrefix([string]$field, [string]$prefix) {
        # Ensemble des documents correspondants
        $matchingDocs = [System.Collections.Generic.HashSet[string]]::new()
        
        # Parcourir tous les termes
        foreach ($termKey in $this.Terms.Keys) {
            # Vérifier si le terme correspond au champ et au préfixe
            if ($termKey -like "$field:$prefix*") {
                # Ajouter les documents à l'ensemble
                foreach ($docId in $this.Terms[$termKey]) {
                    $matchingDocs.Add($docId)
                }
            }
        }
        
        # Retourner la liste des documents
        return $matchingDocs.ToArray()
    }
    
    # Méthode pour rechercher des documents par expression régulière
    [string[]] SearchRegex([string]$field, [string]$pattern) {
        # Ensemble des documents correspondants
        $matchingDocs = [System.Collections.Generic.HashSet[string]]::new()
        
        # Vérifier si le champ existe
        if (-not $this.Fields.ContainsKey($field)) {
            return @()
        }
        
        # Parcourir tous les termes du champ
        foreach ($term in $this.Fields[$field]) {
            # Vérifier si le terme correspond au motif
            if ($term -match $pattern) {
                # Ajouter les documents à l'ensemble
                $termKey = "$field:$term"
                foreach ($docId in $this.Terms[$termKey]) {
                    $matchingDocs.Add($docId)
                }
            }
        }
        
        # Retourner la liste des documents
        return $matchingDocs.ToArray()
    }
    
    # Méthode pour rechercher des documents par plage de valeurs
    [string[]] SearchRange([string]$field, [object]$min, [object]$max) {
        # Ensemble des documents correspondants
        $matchingDocs = [System.Collections.Generic.HashSet[string]]::new()
        
        # Vérifier si le champ existe
        if (-not $this.Fields.ContainsKey($field)) {
            return @()
        }
        
        # Parcourir tous les termes du champ
        foreach ($term in $this.Fields[$field]) {
            # Convertir le terme en valeur numérique ou date
            $value = $null
            
            if ($term -match '^\d+(\.\d+)?$') {
                # Valeur numérique
                $value = [double]$term
            } elseif ($term -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}') {
                # Date ISO 8601
                $value = [DateTime]::Parse($term)
            } else {
                # Ignorer les autres formats
                continue
            }
            
            # Vérifier si la valeur est dans la plage
            $inRange = $true
            
            if ($null -ne $min) {
                if ($value -lt $min) {
                    $inRange = $false
                }
            }
            
            if ($null -ne $max) {
                if ($value -gt $max) {
                    $inRange = $false
                }
            }
            
            if ($inRange) {
                # Ajouter les documents à l'ensemble
                $termKey = "$field:$term"
                foreach ($docId in $this.Terms[$termKey]) {
                    $matchingDocs.Add($docId)
                }
            }
        }
        
        # Retourner la liste des documents
        return $matchingDocs.ToArray()
    }
    
    # Méthode pour rechercher des documents par requête textuelle
    [hashtable] SearchText([string]$field, [string]$query) {
        # Dictionnaire des documents correspondants (document -> score)
        $matchingDocs = [System.Collections.Generic.Dictionary[string, double]]::new()
        
        # Tokeniser la requête
        $tokens = $query -split '\s+'
        
        # Parcourir tous les tokens
        foreach ($token in $tokens) {
            # Ignorer les tokens vides
            if ([string]::IsNullOrWhiteSpace($token)) {
                continue
            }
            
            # Rechercher les documents correspondant au token
            $docIds = $this.SearchPrefix($field, $token)
            
            # Ajouter les documents au dictionnaire
            foreach ($docId in $docIds) {
                if (-not $matchingDocs.ContainsKey($docId)) {
                    $matchingDocs[$docId] = 0
                }
                
                # Incrémenter le score
                $matchingDocs[$docId]++
            }
        }
        
        # Normaliser les scores
        if ($tokens.Count -gt 0) {
            foreach ($docId in $matchingDocs.Keys) {
                $matchingDocs[$docId] = $matchingDocs[$docId] / $tokens.Count
            }
        }
        
        return $matchingDocs
    }
    
    # Méthode pour obtenir tous les termes d'un champ
    [string[]] GetTerms([string]$field) {
        # Vérifier si le champ existe
        if (-not $this.Fields.ContainsKey($field)) {
            return @()
        }
        
        # Retourner la liste des termes
        return $this.Fields[$field].ToArray()
    }
    
    # Méthode pour obtenir tous les champs
    [string[]] GetFields() {
        return $this.Fields.Keys
    }
    
    # Méthode pour obtenir le nombre de documents pour un terme
    [int] GetDocumentCount([string]$field, [string]$term) {
        # Construire la clé du terme
        $termKey = "$field:$term"
        
        # Vérifier si le terme existe
        if (-not $this.Terms.ContainsKey($termKey)) {
            return 0
        }
        
        # Retourner le nombre de documents
        return $this.Terms[$termKey].Count
    }
    
    # Méthode pour fusionner avec un autre index
    [void] Merge([InvertedIndex]$other) {
        # Parcourir tous les termes de l'autre index
        foreach ($termKey in $other.Terms.Keys) {
            $parts = $termKey -split ':', 2
            $field = $parts[0]
            $term = $parts[1]
            
            # Ajouter les documents à l'index
            foreach ($docId in $other.Terms[$termKey]) {
                $this.AddTerm($field, $term, $docId)
            }
        }
        
        # Mettre à jour les métadonnées
        $this.Metadata.updated_at = (Get-Date).ToString("o")
        $this.Metadata.term_count = $this.Terms.Count
        $this.Metadata.field_count = $this.Fields.Count
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        # Créer un objet sérialisable
        $obj = @{
            metadata = $this.Metadata
            terms = @{}
            fields = @{}
        }
        
        # Convertir les termes
        foreach ($termKey in $this.Terms.Keys) {
            $obj.terms[$termKey] = $this.Terms[$termKey]
        }
        
        # Convertir les champs
        foreach ($field in $this.Fields.Keys) {
            $obj.fields[$field] = [string[]]$this.Fields[$field]
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour créer à partir de JSON
    static [InvertedIndex] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $index = [InvertedIndex]::new()
        
        # Charger les métadonnées
        $index.Metadata = @{}
        foreach ($prop in $obj.metadata.PSObject.Properties) {
            $index.Metadata[$prop.Name] = $prop.Value
        }
        
        # Charger les termes
        foreach ($termKey in $obj.terms.PSObject.Properties.Name) {
            $docIds = [System.Collections.Generic.List[string]]::new()
            
            foreach ($docId in $obj.terms.$termKey) {
                $docIds.Add($docId)
            }
            
            $index.Terms[$termKey] = $docIds
        }
        
        # Charger les champs
        foreach ($field in $obj.fields.PSObject.Properties.Name) {
            $terms = [System.Collections.Generic.HashSet[string]]::new()
            
            foreach ($term in $obj.fields.$field) {
                $terms.Add($term)
            }
            
            $index.Fields[$field] = $terms
        }
        
        return $index
    }
}

# Exporter les classes
Export-ModuleMember -Function *
