# TypeFilter.ps1
# Script implémentant les filtres par type de point pour la recherche avancée
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

# Classe pour représenter un filtre par type
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
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $includeStr = if ($this.IncludeTypes.Count -gt 0) {
            "Include: $($this.IncludeTypes -join ', ')"
        } else {
            "Include: All"
        }
        
        $excludeStr = if ($this.ExcludeTypes.Count -gt 0) {
            "Exclude: $($this.ExcludeTypes -join ', ')"
        } else {
            "Exclude: None"
        }
        
        return "TypeFilter[$includeStr; $excludeStr]"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            include_types = $this.IncludeTypes
            exclude_types = $this.ExcludeTypes
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [TypeFilter] FromHashtable([hashtable]$data) {
        $includeTypes = if ($data.ContainsKey("include_types")) { $data.include_types } else { @() }
        $excludeTypes = if ($data.ContainsKey("exclude_types")) { $data.exclude_types } else { @() }
        
        return [TypeFilter]::new($includeTypes, $excludeTypes)
    }
}

# Classe pour représenter un gestionnaire de filtres par type
class TypeFilterManager {
    # Dictionnaire des types disponibles
    [System.Collections.Generic.Dictionary[string, hashtable]]$AvailableTypes
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    TypeFilterManager() {
        $this.AvailableTypes = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Initialiser les types par défaut
        $this.InitializeDefaultTypes()
    }
    
    # Méthode pour initialiser les types par défaut
    [void] InitializeDefaultTypes() {
        # Type: document
        $this.RegisterType("document", "Document", @{
            description = "Document textuel"
            icon = "file-text"
            color = "#3498db"
        })
        
        # Type: image
        $this.RegisterType("image", "Image", @{
            description = "Image ou photo"
            icon = "image"
            color = "#2ecc71"
        })
        
        # Type: video
        $this.RegisterType("video", "Vidéo", @{
            description = "Fichier vidéo"
            icon = "video"
            color = "#e74c3c"
        })
        
        # Type: audio
        $this.RegisterType("audio", "Audio", @{
            description = "Fichier audio"
            icon = "music"
            color = "#9b59b6"
        })
        
        # Type: archive
        $this.RegisterType("archive", "Archive", @{
            description = "Fichier d'archive (zip, tar, etc.)"
            icon = "archive"
            color = "#f39c12"
        })
        
        # Type: code
        $this.RegisterType("code", "Code", @{
            description = "Fichier de code source"
            icon = "code"
            color = "#1abc9c"
        })
        
        # Type: spreadsheet
        $this.RegisterType("spreadsheet", "Tableur", @{
            description = "Feuille de calcul"
            icon = "table"
            color = "#27ae60"
        })
        
        # Type: presentation
        $this.RegisterType("presentation", "Présentation", @{
            description = "Présentation ou diaporama"
            icon = "file-powerpoint"
            color = "#d35400"
        })
        
        # Type: pdf
        $this.RegisterType("pdf", "PDF", @{
            description = "Document PDF"
            icon = "file-pdf"
            color = "#c0392b"
        })
        
        # Type: email
        $this.RegisterType("email", "Email", @{
            description = "Message électronique"
            icon = "envelope"
            color = "#3498db"
        })
        
        # Type: contact
        $this.RegisterType("contact", "Contact", @{
            description = "Information de contact"
            icon = "address-book"
            color = "#2980b9"
        })
        
        # Type: event
        $this.RegisterType("event", "Événement", @{
            description = "Événement ou rendez-vous"
            icon = "calendar"
            color = "#8e44ad"
        })
        
        # Type: task
        $this.RegisterType("task", "Tâche", @{
            description = "Tâche ou élément de liste"
            icon = "check-square"
            color = "#f1c40f"
        })
        
        # Type: note
        $this.RegisterType("note", "Note", @{
            description = "Note ou mémo"
            icon = "sticky-note"
            color = "#f39c12"
        })
        
        # Type: bookmark
        $this.RegisterType("bookmark", "Signet", @{
            description = "Signet ou favori"
            icon = "bookmark"
            color = "#e67e22"
        })
    }
    
    # Méthode pour enregistrer un type
    [void] RegisterType([string]$id, [string]$name, [hashtable]$metadata = @{}) {
        $type = @{
            id = $id
            name = $name
            metadata = $metadata
        }
        
        $this.AvailableTypes[$id] = $type
    }
    
    # Méthode pour obtenir un type
    [hashtable] GetType([string]$id) {
        if (-not $this.AvailableTypes.ContainsKey($id)) {
            return $null
        }
        
        return $this.AvailableTypes[$id]
    }
    
    # Méthode pour supprimer un type
    [bool] RemoveType([string]$id) {
        return $this.AvailableTypes.Remove($id)
    }
    
    # Méthode pour obtenir tous les types
    [hashtable[]] GetAllTypes() {
        return $this.AvailableTypes.Values
    }
    
    # Méthode pour créer un filtre par type
    [TypeFilter] CreateFilter([string[]]$includeTypes = @(), [string[]]$excludeTypes = @()) {
        return [TypeFilter]::new($includeTypes, $excludeTypes)
    }
    
    # Méthode pour appliquer un filtre à une liste de documents
    [IndexDocument[]] ApplyFilter([TypeFilter]$filter, [IndexDocument[]]$documents) {
        $timer = $this.Metrics.GetTimer("type_filter.apply_filter")
        $timer.Start()
        
        $result = $documents | Where-Object { $filter.Matches($_) }
        
        $timer.Stop()
        
        # Incrémenter les compteurs
        $this.Metrics.IncrementCounter("type_filter.documents_filtered", $documents.Count)
        $this.Metrics.IncrementCounter("type_filter.documents_matched", $result.Count)
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques du filtre
    [hashtable] GetStats() {
        return @{
            available_types = $this.AvailableTypes.Count
            metrics = $this.Metrics.GetAllMetrics()
        }
    }
}

# Fonction pour créer un filtre par type
function New-TypeFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeTypes = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeTypes = @()
    )
    
    return [TypeFilter]::new($IncludeTypes, $ExcludeTypes)
}

# Fonction pour créer un gestionnaire de filtres par type
function New-TypeFilterManager {
    [CmdletBinding()]
    param ()
    
    return [TypeFilterManager]::new()
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-TypeFilter, New-TypeFilterManager
