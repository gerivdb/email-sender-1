# SearchOptimization.ps1
# Script implémentant l'optimisation des algorithmes de recherche
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$cachePath = Join-Path -Path $scriptPath -ChildPath "IndexCache.ps1"

if (Test-Path -Path $cachePath) {
    . $cachePath
} else {
    Write-Error "Le fichier IndexCache.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un terme de recherche
class SearchTerm {
    # Texte du terme
    [string]$Text
    
    # Type du terme (Exact, Prefix, Wildcard, Fuzzy, Range)
    [string]$Type
    
    # Champ sur lequel appliquer le terme
    [string]$Field
    
    # Boost (multiplicateur de score)
    [double]$Boost
    
    # Paramètres supplémentaires
    [hashtable]$Params
    
    # Constructeur par défaut
    SearchTerm() {
        $this.Text = ""
        $this.Type = "Exact"
        $this.Field = ""
        $this.Boost = 1.0
        $this.Params = @{}
    }
    
    # Constructeur avec texte
    SearchTerm([string]$text) {
        $this.Text = $text
        $this.Type = "Exact"
        $this.Field = ""
        $this.Boost = 1.0
        $this.Params = @{}
    }
    
    # Constructeur avec texte et type
    SearchTerm([string]$text, [string]$type) {
        $this.Text = $text
        $this.Type = $type
        $this.Field = ""
        $this.Boost = 1.0
        $this.Params = @{}
    }
    
    # Constructeur avec texte, type et champ
    SearchTerm([string]$text, [string]$type, [string]$field) {
        $this.Text = $text
        $this.Type = $type
        $this.Field = $field
        $this.Boost = 1.0
        $this.Params = @{}
    }
    
    # Constructeur complet
    SearchTerm([string]$text, [string]$type, [string]$field, [double]$boost, [hashtable]$params) {
        $this.Text = $text
        $this.Type = $type
        $this.Field = $field
        $this.Boost = $boost
        $this.Params = $params
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $fieldStr = if ([string]::IsNullOrEmpty($this.Field)) { "" } else { "$($this.Field):" }
        $boostStr = if ($this.Boost -eq 1.0) { "" } else { "^$($this.Boost)" }
        
        switch ($this.Type) {
            "Exact" { return "$fieldStr$($this.Text)$boostStr" }
            "Prefix" { return "$fieldStr$($this.Text)*$boostStr" }
            "Wildcard" { return "$fieldStr$($this.Text)$boostStr" }
            "Fuzzy" { 
                $fuzziness = if ($this.Params.ContainsKey("fuzziness")) { $this.Params.fuzziness } else { 2 }
                return "$fieldStr$($this.Text)~$fuzziness$boostStr" 
            }
            "Range" {
                $min = if ($this.Params.ContainsKey("min")) { $this.Params.min } else { "*" }
                $max = if ($this.Params.ContainsKey("max")) { $this.Params.max } else { "*" }
                $inclusive = if ($this.Params.ContainsKey("inclusive")) { $this.Params.inclusive } else { $true }
                
                if ($inclusive) {
                    return "$fieldStr[$min TO $max]$boostStr"
                } else {
                    return "$fieldStr{$min TO $max}$boostStr"
                }
            }
            default { return "$fieldStr$($this.Text)$boostStr" }
        }
    }
}

# Classe pour représenter une requête de recherche
class SearchQuery {
    # Liste des termes de la requête
    [System.Collections.Generic.List[SearchTerm]]$Terms
    
    # Type de requête (AND, OR, NOT)
    [string]$Type
    
    # Sous-requêtes
    [System.Collections.Generic.List[SearchQuery]]$SubQueries
    
    # Constructeur par défaut
    SearchQuery() {
        $this.Terms = [System.Collections.Generic.List[SearchTerm]]::new()
        $this.Type = "AND"
        $this.SubQueries = [System.Collections.Generic.List[SearchQuery]]::new()
    }
    
    # Constructeur avec type
    SearchQuery([string]$type) {
        $this.Terms = [System.Collections.Generic.List[SearchTerm]]::new()
        $this.Type = $type
        $this.SubQueries = [System.Collections.Generic.List[SearchQuery]]::new()
    }
    
    # Méthode pour ajouter un terme
    [void] AddTerm([SearchTerm]$term) {
        $this.Terms.Add($term)
    }
    
    # Méthode pour ajouter une sous-requête
    [void] AddSubQuery([SearchQuery]$query) {
        $this.SubQueries.Add($query)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $parts = [System.Collections.Generic.List[string]]::new()
        
        # Ajouter les termes
        foreach ($term in $this.Terms) {
            $parts.Add($term.ToString())
        }
        
        # Ajouter les sous-requêtes
        foreach ($query in $this.SubQueries) {
            $parts.Add("($($query.ToString()))")
        }
        
        # Joindre les parties avec l'opérateur approprié
        $operator = switch ($this.Type) {
            "AND" { " AND " }
            "OR" { " OR " }
            "NOT" { " NOT " }
            default { " AND " }
        }
        
        return $parts -join $operator
    }
}

# Classe pour représenter un analyseur de requête
class QueryParser {
    # Constructeur par défaut
    QueryParser() {
    }
    
    # Méthode pour analyser une requête textuelle
    [SearchQuery] Parse([string]$queryText) {
        # Normaliser la requête
        $queryText = $queryText.Trim()
        
        # Créer une requête par défaut
        $query = [SearchQuery]::new("AND")
        
        # Si la requête est vide, retourner la requête par défaut
        if ([string]::IsNullOrEmpty($queryText)) {
            return $query
        }
        
        # Diviser la requête en tokens
        $tokens = $this.Tokenize($queryText)
        
        # Analyser les tokens
        $i = 0
        while ($i -lt $tokens.Count) {
            $token = $tokens[$i]
            
            # Vérifier si le token est un opérateur
            if ($token -eq "AND" -or $token -eq "OR" -or $token -eq "NOT") {
                # Ignorer les opérateurs isolés
                $i++
                continue
            }
            
            # Vérifier si le token est une parenthèse ouvrante
            if ($token -eq "(") {
                # Trouver la parenthèse fermante correspondante
                $depth = 1
                $start = $i + 1
                $end = $start
                
                while ($end -lt $tokens.Count -and $depth -gt 0) {
                    if ($tokens[$end] -eq "(") {
                        $depth++
                    } elseif ($tokens[$end] -eq ")") {
                        $depth--
                    }
                    
                    if ($depth -gt 0) {
                        $end++
                    }
                }
                
                if ($depth -eq 0) {
                    # Extraire la sous-requête
                    $subQueryTokens = $tokens[$start..($end - 1)]
                    $subQueryText = $subQueryTokens -join " "
                    
                    # Analyser la sous-requête
                    $subQuery = $this.Parse($subQueryText)
                    
                    # Ajouter la sous-requête
                    $query.AddSubQuery($subQuery)
                    
                    # Avancer l'index
                    $i = $end + 1
                    continue
                }
            }
            
            # Vérifier si le token contient un champ
            if ($token -match "^([a-zA-Z0-9_]+):(.+)$") {
                $field = $matches[1]
                $value = $matches[2]
                
                # Vérifier le type de terme
                if ($value -match "^\*(.+)\*$") {
                    # Terme wildcard (contient)
                    $term = [SearchTerm]::new($matches[1], "Wildcard", $field)
                    $query.AddTerm($term)
                } elseif ($value -match "^(.+)\*$") {
                    # Terme prefix
                    $term = [SearchTerm]::new($matches[1], "Prefix", $field)
                    $query.AddTerm($term)
                } elseif ($value -match "^(.+)~(\d+)?$") {
                    # Terme fuzzy
                    $text = $matches[1]
                    $fuzziness = if ($matches.Count -gt 2) { [int]$matches[2] } else { 2 }
                    
                    $term = [SearchTerm]::new($text, "Fuzzy", $field)
                    $term.Params["fuzziness"] = $fuzziness
                    $query.AddTerm($term)
                } elseif ($value -match "^\[(.+) TO (.+)\]$") {
                    # Terme range inclusif
                    $min = $matches[1]
                    $max = $matches[2]
                    
                    $term = [SearchTerm]::new("", "Range", $field)
                    $term.Params["min"] = $min
                    $term.Params["max"] = $max
                    $term.Params["inclusive"] = $true
                    $query.AddTerm($term)
                } elseif ($value -match "^\{(.+) TO (.+)\}$") {
                    # Terme range exclusif
                    $min = $matches[1]
                    $max = $matches[2]
                    
                    $term = [SearchTerm]::new("", "Range", $field)
                    $term.Params["min"] = $min
                    $term.Params["max"] = $max
                    $term.Params["inclusive"] = $false
                    $query.AddTerm($term)
                } else {
                    # Terme exact
                    $term = [SearchTerm]::new($value, "Exact", $field)
                    $query.AddTerm($term)
                }
            } else {
                # Terme simple
                if ($token -match "^\*(.+)\*$") {
                    # Terme wildcard (contient)
                    $term = [SearchTerm]::new($matches[1], "Wildcard")
                    $query.AddTerm($term)
                } elseif ($token -match "^(.+)\*$") {
                    # Terme prefix
                    $term = [SearchTerm]::new($matches[1], "Prefix")
                    $query.AddTerm($term)
                } elseif ($token -match "^(.+)~(\d+)?$") {
                    # Terme fuzzy
                    $text = $matches[1]
                    $fuzziness = if ($matches.Count -gt 2) { [int]$matches[2] } else { 2 }
                    
                    $term = [SearchTerm]::new($text, "Fuzzy")
                    $term.Params["fuzziness"] = $fuzziness
                    $query.AddTerm($term)
                } else {
                    # Terme exact
                    $term = [SearchTerm]::new($token, "Exact")
                    $query.AddTerm($term)
                }
            }
            
            $i++
        }
        
        return $query
    }
    
    # Méthode pour tokeniser une requête
    [string[]] Tokenize([string]$queryText) {
        # Liste des tokens
        $tokens = [System.Collections.Generic.List[string]]::new()
        
        # État courant
        $currentToken = ""
        $inQuotes = $false
        $escapeNext = $false
        
        # Parcourir la chaîne caractère par caractère
        for ($i = 0; $i -lt $queryText.Length; $i++) {
            $char = $queryText[$i]
            
            if ($escapeNext) {
                $currentToken += $char
                $escapeNext = $false
                continue
            }
            
            if ($char -eq '\') {
                $escapeNext = $true
                continue
            }
            
            if ($char -eq '"') {
                $inQuotes = -not $inQuotes
                continue
            }
            
            if ($inQuotes) {
                $currentToken += $char
                continue
            }
            
            if ($char -eq ' ' -or $char -eq '(' -or $char -eq ')') {
                if (-not [string]::IsNullOrEmpty($currentToken)) {
                    $tokens.Add($currentToken)
                    $currentToken = ""
                }
                
                if ($char -eq '(' -or $char -eq ')') {
                    $tokens.Add($char.ToString())
                }
                
                continue
            }
            
            $currentToken += $char
        }
        
        if (-not [string]::IsNullOrEmpty($currentToken)) {
            $tokens.Add($currentToken)
        }
        
        return $tokens.ToArray()
    }
}

# Classe pour représenter un moteur de recherche optimisé
class OptimizedSearchEngine {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Cache de recherche
    [IndexSearchCache]$Cache
    
    # Analyseur de requête
    [QueryParser]$QueryParser
    
    # Constructeur par défaut
    OptimizedSearchEngine() {
        $this.SegmentManager = $null
        $this.Cache = [IndexSearchCache]::new()
        $this.QueryParser = [QueryParser]::new()
    }
    
    # Constructeur avec gestionnaire de segments
    OptimizedSearchEngine([IndexSegmentManager]$segmentManager) {
        $this.SegmentManager = $segmentManager
        $this.Cache = [IndexSearchCache]::new()
        $this.QueryParser = [QueryParser]::new()
    }
    
    # Constructeur complet
    OptimizedSearchEngine([IndexSegmentManager]$segmentManager, [IndexSearchCache]$cache) {
        $this.SegmentManager = $segmentManager
        $this.Cache = $cache
        $this.QueryParser = [QueryParser]::new()
    }
    
    # Méthode pour rechercher des documents
    [hashtable] Search([string]$queryText, [int]$limit = 100, [int]$offset = 0) {
        # Vérifier si le résultat est dans le cache
        $cacheKey = "search:$queryText:$limit:$offset"
        $cachedResult = $this.Cache.GetCachedSearchResult($cacheKey)
        
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
        
        # Analyser la requête
        $query = $this.QueryParser.Parse($queryText)
        
        # Exécuter la requête
        $result = $this.ExecuteQuery($query, $limit, $offset)
        
        # Mettre en cache le résultat
        $this.Cache.CacheSearchResult($cacheKey, $result)
        
        return $result
    }
    
    # Méthode pour exécuter une requête
    [hashtable] ExecuteQuery([SearchQuery]$query, [int]$limit = 100, [int]$offset = 0) {
        # Résultat de la recherche
        $result = @{
            total = 0
            documents = @()
            scores = @{}
            query = $query.ToString()
            execution_time_ms = 0
        }
        
        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Exécuter la requête sur tous les segments
        $documentScores = [System.Collections.Generic.Dictionary[string, double]]::new()
        
        # Exécuter les termes de la requête
        foreach ($term in $query.Terms) {
            $termResults = $this.ExecuteTerm($term)
            
            $this.MergeResults($documentScores, $termResults, $query.Type)
        }
        
        # Exécuter les sous-requêtes
        foreach ($subQuery in $query.SubQueries) {
            $subQueryResults = $this.ExecuteQuery($subQuery)
            
            $this.MergeResults($documentScores, $subQueryResults.scores, $query.Type)
        }
        
        # Trier les documents par score
        $sortedDocuments = $documentScores.GetEnumerator() | Sort-Object -Property Value -Descending
        
        # Appliquer la pagination
        $pagedDocuments = $sortedDocuments | Select-Object -Skip $offset -First $limit
        
        # Construire le résultat
        $result.total = $documentScores.Count
        $result.documents = $pagedDocuments | ForEach-Object { $_.Key }
        
        foreach ($doc in $pagedDocuments) {
            $result.scores[$doc.Key] = $doc.Value
        }
        
        # Arrêter le chronomètre
        $stopwatch.Stop()
        $result.execution_time_ms = $stopwatch.ElapsedMilliseconds
        
        return $result
    }
    
    # Méthode pour exécuter un terme
    [System.Collections.Generic.Dictionary[string, double]] ExecuteTerm([SearchTerm]$term) {
        $results = [System.Collections.Generic.Dictionary[string, double]]::new()
        
        # Déterminer les champs à rechercher
        $fields = @()
        
        if ([string]::IsNullOrEmpty($term.Field)) {
            # Rechercher dans tous les champs indexés
            $fields = @("search_text")  # Champ de recherche par défaut
        } else {
            $fields = @($term.Field)
        }
        
        # Rechercher dans chaque segment
        foreach ($segment in $this.SegmentManager.ActiveSegments.Values) {
            foreach ($field in $fields) {
                $docIds = @()
                
                # Exécuter la recherche selon le type de terme
                switch ($term.Type) {
                    "Exact" {
                        $termKey = "$field:$($term.Text)"
                        $docIds = $segment.InvertedIndex[$termKey]
                    }
                    "Prefix" {
                        foreach ($indexTerm in $segment.InvertedIndex.Keys) {
                            if ($indexTerm -like "$field:$($term.Text)*") {
                                $docIds += $segment.InvertedIndex[$indexTerm]
                            }
                        }
                    }
                    "Wildcard" {
                        foreach ($indexTerm in $segment.InvertedIndex.Keys) {
                            if ($indexTerm -like "$field:*$($term.Text)*") {
                                $docIds += $segment.InvertedIndex[$indexTerm]
                            }
                        }
                    }
                    "Fuzzy" {
                        # Implémentation simplifiée de la recherche fuzzy
                        # Dans une implémentation réelle, utiliser un algorithme de distance d'édition
                        foreach ($indexTerm in $segment.InvertedIndex.Keys) {
                            if ($indexTerm -match "^$field:") {
                                $indexTermValue = $indexTerm -replace "^$field:", ""
                                
                                if ($this.FuzzyMatch($indexTermValue, $term.Text, $term.Params.fuzziness)) {
                                    $docIds += $segment.InvertedIndex[$indexTerm]
                                }
                            }
                        }
                    }
                    "Range" {
                        # Implémentation simplifiée de la recherche par plage
                        $min = $term.Params.min
                        $max = $term.Params.max
                        $inclusive = $term.Params.inclusive
                        
                        foreach ($indexTerm in $segment.InvertedIndex.Keys) {
                            if ($indexTerm -match "^$field:") {
                                $indexTermValue = $indexTerm -replace "^$field:", ""
                                
                                if ($this.RangeMatch($indexTermValue, $min, $max, $inclusive)) {
                                    $docIds += $segment.InvertedIndex[$indexTerm]
                                }
                            }
                        }
                    }
                }
                
                # Ajouter les documents trouvés au résultat
                foreach ($docId in $docIds) {
                    if (-not $results.ContainsKey($docId)) {
                        $results[$docId] = 0
                    }
                    
                    $results[$docId] += $term.Boost
                }
            }
        }
        
        return $results
    }
    
    # Méthode pour fusionner des résultats
    [void] MergeResults([System.Collections.Generic.Dictionary[string, double]]$target, [System.Collections.Generic.Dictionary[string, double]]$source, [string]$operator) {
        switch ($operator) {
            "AND" {
                # Si le target est vide, initialiser avec la source
                if ($target.Count -eq 0) {
                    foreach ($docId in $source.Keys) {
                        $target[$docId] = $source[$docId]
                    }
                } else {
                    # Conserver uniquement les documents présents dans les deux ensembles
                    $docsToRemove = [System.Collections.Generic.List[string]]::new()
                    
                    foreach ($docId in $target.Keys) {
                        if (-not $source.ContainsKey($docId)) {
                            $docsToRemove.Add($docId)
                        } else {
                            $target[$docId] += $source[$docId]
                        }
                    }
                    
                    foreach ($docId in $docsToRemove) {
                        $target.Remove($docId)
                    }
                }
            }
            "OR" {
                # Ajouter tous les documents de la source
                foreach ($docId in $source.Keys) {
                    if ($target.ContainsKey($docId)) {
                        $target[$docId] += $source[$docId]
                    } else {
                        $target[$docId] = $source[$docId]
                    }
                }
            }
            "NOT" {
                # Supprimer les documents présents dans la source
                foreach ($docId in $source.Keys) {
                    $target.Remove($docId)
                }
            }
        }
    }
    
    # Méthode pour vérifier si deux chaînes correspondent avec une tolérance fuzzy
    [bool] FuzzyMatch([string]$s1, [string]$s2, [int]$maxDistance) {
        # Implémentation simplifiée de la distance de Levenshtein
        if ([string]::IsNullOrEmpty($s1) -and [string]::IsNullOrEmpty($s2)) {
            return $true
        }
        
        if ([string]::IsNullOrEmpty($s1) -or [string]::IsNullOrEmpty($s2)) {
            return $false
        }
        
        if ($s1 -eq $s2) {
            return $true
        }
        
        if ([Math]::Abs($s1.Length - $s2.Length) -gt $maxDistance) {
            return $false
        }
        
        # Calcul simplifié de la distance d'édition
        $distance = 0
        $minLength = [Math]::Min($s1.Length, $s2.Length)
        
        for ($i = 0; $i -lt $minLength; $i++) {
            if ($s1[$i] -ne $s2[$i]) {
                $distance++
                
                if ($distance -gt $maxDistance) {
                    return $false
                }
            }
        }
        
        $distance += [Math]::Abs($s1.Length - $s2.Length)
        
        return $distance -le $maxDistance
    }
    
    # Méthode pour vérifier si une valeur est dans une plage
    [bool] RangeMatch([string]$value, [string]$min, [string]$max, [bool]$inclusive) {
        # Vérifier si la valeur est numérique
        if ($value -match '^\d+(\.\d+)?$' -and $min -match '^\d+(\.\d+)?$' -and $max -match '^\d+(\.\d+)?$') {
            $valueNum = [double]$value
            $minNum = [double]$min
            $maxNum = [double]$max
            
            if ($inclusive) {
                return $valueNum -ge $minNum -and $valueNum -le $maxNum
            } else {
                return $valueNum -gt $minNum -and $valueNum -lt $maxNum
            }
        }
        
        # Vérifier si la valeur est une date
        try {
            $valueDate = [DateTime]::Parse($value)
            $minDate = [DateTime]::Parse($min)
            $maxDate = [DateTime]::Parse($max)
            
            if ($inclusive) {
                return $valueDate -ge $minDate -and $valueDate -le $maxDate
            } else {
                return $valueDate -gt $minDate -and $valueDate -lt $maxDate
            }
        } catch {
            # Ignorer les erreurs de parsing de date
        }
        
        # Comparaison lexicographique
        if ($inclusive) {
            return $value -ge $min -and $value -le $max
        } else {
            return $value -gt $min -and $value -lt $max
        }
    }
}

# Fonction pour créer un moteur de recherche optimisé
function New-OptimizedSearchEngine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $false)]
        [IndexSearchCache]$Cache = (New-IndexSearchCache)
    )
    
    return [OptimizedSearchEngine]::new($SegmentManager, $Cache)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-OptimizedSearchEngine
