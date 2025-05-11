# TextFilter.ps1
# Script implémentant les filtres par texte pour la recherche avancée
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$searchPath = Split-Path -Parent $parentPath
$indexPath = Split-Path -Parent $searchPath
$performancePath = Join-Path -Path $indexPath -ChildPath "performance\PerformanceMetrics.ps1"

if (Test-Path -Path $performancePath) {
    . $performancePath
} else {
    Write-Error "Le fichier PerformanceMetrics.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un filtre par texte
class TextFilter {
    # Champ à filtrer
    [string]$Field
    
    # Texte à rechercher
    [string]$Text
    
    # Type de recherche (EXACT, CONTAINS, STARTS_WITH, ENDS_WITH, MATCHES, FUZZY)
    [string]$SearchType
    
    # Sensibilité à la casse
    [bool]$CaseSensitive
    
    # Constructeur par défaut
    TextFilter() {
        $this.Field = "content"
        $this.Text = ""
        $this.SearchType = "CONTAINS"
        $this.CaseSensitive = $false
    }
    
    # Constructeur avec champ et texte
    TextFilter([string]$field, [string]$text) {
        $this.Field = $field
        $this.Text = $text
        $this.SearchType = "CONTAINS"
        $this.CaseSensitive = $false
    }
    
    # Constructeur complet
    TextFilter([string]$field, [string]$text, [string]$searchType, [bool]$caseSensitive) {
        $this.Field = $field
        $this.Text = $text
        $this.SearchType = $searchType
        $this.CaseSensitive = $caseSensitive
    }
    
    # Méthode pour vérifier si un document correspond au filtre
    [bool] Matches([IndexDocument]$document) {
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
            "FUZZY" { return $this.FuzzyMatch($value, $text) }
            default { return $value.Contains($text) }
        }
    }
    
    # Méthode pour effectuer une correspondance floue
    [bool] FuzzyMatch([string]$value, [string]$text) {
        # Calculer la distance de Levenshtein
        $distance = $this.LevenshteinDistance($value, $text)
        
        # Calculer le seuil de correspondance (30% de la longueur du texte)
        $threshold = [Math]::Max(1, [Math]::Ceiling($text.Length * 0.3))
        
        # Vérifier si la distance est inférieure au seuil
        return $distance -le $threshold
    }
    
    # Méthode pour calculer la distance de Levenshtein
    [int] LevenshteinDistance([string]$s, [string]$t) {
        $n = $s.Length
        $m = $t.Length
        
        # Cas particuliers
        if ($n -eq 0) { return $m }
        if ($m -eq 0) { return $n }
        
        # Créer la matrice de distance
        $d = New-Object 'int[,]' ($n + 1), ($m + 1)
        
        # Initialiser la première colonne et la première ligne
        for ($i = 0; $i -le $n; $i++) {
            $d[$i, 0] = $i
        }
        
        for ($j = 0; $j -le $m; $j++) {
            $d[0, $j] = $j
        }
        
        # Remplir la matrice
        for ($i = 1; $i -le $n; $i++) {
            for ($j = 1; $j -le $m; $j++) {
                $cost = if ($s[$i - 1] -eq $t[$j - 1]) { 0 } else { 1 }
                
                $d[$i, $j] = [Math]::Min(
                    [Math]::Min(
                        $d[$i - 1, $j] + 1,      # Suppression
                        $d[$i, $j - 1] + 1       # Insertion
                    ),
                    $d[$i - 1, $j - 1] + $cost   # Substitution
                )
            }
        }
        
        # Retourner la distance
        return $d[$n, $m]
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $caseStr = if ($this.CaseSensitive) { "case-sensitive" } else { "case-insensitive" }
        return "TextFilter[$($this.Field) $($this.SearchType) '$($this.Text)' ($caseStr)]"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            field = $this.Field
            text = $this.Text
            search_type = $this.SearchType
            case_sensitive = $this.CaseSensitive
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [TextFilter] FromHashtable([hashtable]$data) {
        $field = if ($data.ContainsKey("field")) { $data.field } else { "content" }
        $text = if ($data.ContainsKey("text")) { $data.text } else { "" }
        $searchType = if ($data.ContainsKey("search_type")) { $data.search_type } else { "CONTAINS" }
        $caseSensitive = if ($data.ContainsKey("case_sensitive")) { $data.case_sensitive } else { $false }
        
        return [TextFilter]::new($field, $text, $searchType, $caseSensitive)
    }
}

# Classe pour représenter un gestionnaire de filtres par texte
class TextFilterManager {
    # Dictionnaire des champs de texte disponibles
    [System.Collections.Generic.Dictionary[string, hashtable]]$AvailableFields
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    TextFilterManager() {
        $this.AvailableFields = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Initialiser les champs par défaut
        $this.InitializeDefaultFields()
    }
    
    # Méthode pour initialiser les champs par défaut
    [void] InitializeDefaultFields() {
        # Champ: content
        $this.RegisterField("content", "Contenu", @{
            description = "Contenu principal du document"
            type = "text"
        })
        
        # Champ: title
        $this.RegisterField("title", "Titre", @{
            description = "Titre du document"
            type = "text"
        })
        
        # Champ: description
        $this.RegisterField("description", "Description", @{
            description = "Description du document"
            type = "text"
        })
        
        # Champ: author
        $this.RegisterField("author", "Auteur", @{
            description = "Auteur du document"
            type = "text"
        })
        
        # Champ: keywords
        $this.RegisterField("keywords", "Mots-clés", @{
            description = "Mots-clés du document"
            type = "text"
        })
        
        # Champ: summary
        $this.RegisterField("summary", "Résumé", @{
            description = "Résumé du document"
            type = "text"
        })
        
        # Champ: comments
        $this.RegisterField("comments", "Commentaires", @{
            description = "Commentaires sur le document"
            type = "text"
        })
        
        # Champ: notes
        $this.RegisterField("notes", "Notes", @{
            description = "Notes sur le document"
            type = "text"
        })
    }
    
    # Méthode pour enregistrer un champ
    [void] RegisterField([string]$id, [string]$name, [hashtable]$metadata = @{}) {
        $field = @{
            id = $id
            name = $name
            metadata = $metadata
        }
        
        $this.AvailableFields[$id] = $field
    }
    
    # Méthode pour obtenir un champ
    [hashtable] GetField([string]$id) {
        if (-not $this.AvailableFields.ContainsKey($id)) {
            return $null
        }
        
        return $this.AvailableFields[$id]
    }
    
    # Méthode pour supprimer un champ
    [bool] RemoveField([string]$id) {
        return $this.AvailableFields.Remove($id)
    }
    
    # Méthode pour obtenir tous les champs
    [hashtable[]] GetAllFields() {
        return $this.AvailableFields.Values
    }
    
    # Méthode pour créer un filtre par texte
    [TextFilter] CreateFilter([string]$field = "content", [string]$text = "", [string]$searchType = "CONTAINS", [bool]$caseSensitive = $false) {
        return [TextFilter]::new($field, $text, $searchType, $caseSensitive)
    }
    
    # Méthode pour appliquer un filtre à une liste de documents
    [IndexDocument[]] ApplyFilter([TextFilter]$filter, [IndexDocument[]]$documents) {
        $timer = $this.Metrics.GetTimer("text_filter.apply_filter")
        $timer.Start()
        
        $result = $documents | Where-Object { $filter.Matches($_) }
        
        $timer.Stop()
        
        # Incrémenter les compteurs
        $this.Metrics.IncrementCounter("text_filter.documents_filtered", $documents.Count)
        $this.Metrics.IncrementCounter("text_filter.documents_matched", $result.Count)
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques du filtre
    [hashtable] GetStats() {
        return @{
            available_fields = $this.AvailableFields.Count
            metrics = $this.Metrics.GetAllMetrics()
        }
    }
}

# Fonction pour créer un filtre par texte
function New-TextFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Field = "content",
        
        [Parameter(Mandatory = $false)]
        [string]$Text = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("EXACT", "CONTAINS", "STARTS_WITH", "ENDS_WITH", "MATCHES", "FUZZY")]
        [string]$SearchType = "CONTAINS",
        
        [Parameter(Mandatory = $false)]
        [bool]$CaseSensitive = $false
    )
    
    return [TextFilter]::new($Field, $Text, $SearchType, $CaseSensitive)
}

# Fonction pour créer un gestionnaire de filtres par texte
function New-TextFilterManager {
    [CmdletBinding()]
    param ()
    
    return [TextFilterManager]::new()
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-TextFilter, New-TextFilterManager
