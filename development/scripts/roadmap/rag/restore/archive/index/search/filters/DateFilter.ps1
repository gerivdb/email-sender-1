# DateFilter.ps1
# Script implémentant les filtres par date pour la recherche avancée
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

# Classe pour représenter une plage de dates
class DateRange {
    # Date de début
    [DateTime]$StartDate
    
    # Date de fin
    [DateTime]$EndDate
    
    # Constructeur par défaut
    DateRange() {
        $this.StartDate = [DateTime]::MinValue
        $this.EndDate = [DateTime]::MaxValue
    }
    
    # Constructeur avec dates
    DateRange([DateTime]$startDate, [DateTime]$endDate) {
        $this.StartDate = $startDate
        $this.EndDate = $endDate
    }
    
    # Méthode pour vérifier si une date est dans la plage
    [bool] Contains([DateTime]$date) {
        return $date -ge $this.StartDate -and $date -le $this.EndDate
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        $startStr = if ($this.StartDate -eq [DateTime]::MinValue) {
            "Min"
        } else {
            $this.StartDate.ToString("yyyy-MM-dd")
        }
        
        $endStr = if ($this.EndDate -eq [DateTime]::MaxValue) {
            "Max"
        } else {
            $this.EndDate.ToString("yyyy-MM-dd")
        }
        
        return "[$startStr, $endStr]"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            start_date = $this.StartDate.ToString("o")
            end_date = $this.EndDate.ToString("o")
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [DateRange] FromHashtable([hashtable]$data) {
        $startDate = if ($data.ContainsKey("start_date")) {
            [DateTime]::Parse($data.start_date)
        } else {
            [DateTime]::MinValue
        }
        
        $endDate = if ($data.ContainsKey("end_date")) {
            [DateTime]::Parse($data.end_date)
        } else {
            [DateTime]::MaxValue
        }
        
        return [DateRange]::new($startDate, $endDate)
    }
}

# Classe pour représenter un filtre par date
class DateFilter {
    # Champ de date à filtrer
    [string]$Field
    
    # Plage de dates
    [DateRange]$Range
    
    # Constructeur par défaut
    DateFilter() {
        $this.Field = "created_at"
        $this.Range = [DateRange]::new()
    }
    
    # Constructeur avec champ
    DateFilter([string]$field) {
        $this.Field = $field
        $this.Range = [DateRange]::new()
    }
    
    # Constructeur avec champ et plage
    DateFilter([string]$field, [DateRange]$range) {
        $this.Field = $field
        $this.Range = $range
    }
    
    # Constructeur avec champ et dates
    DateFilter([string]$field, [DateTime]$startDate, [DateTime]$endDate) {
        $this.Field = $field
        $this.Range = [DateRange]::new($startDate, $endDate)
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
        return $this.Range.Contains($date)
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "DateFilter[$($this.Field): $($this.Range.ToString())]"
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            field = $this.Field
            range = $this.Range.ToHashtable()
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [DateFilter] FromHashtable([hashtable]$data) {
        $field = if ($data.ContainsKey("field")) { $data.field } else { "created_at" }
        $range = if ($data.ContainsKey("range")) {
            [DateRange]::FromHashtable($data.range)
        } else {
            [DateRange]::new()
        }
        
        return [DateFilter]::new($field, $range)
    }
}

# Classe pour représenter un gestionnaire de filtres par date
class DateFilterManager {
    # Dictionnaire des champs de date disponibles
    [System.Collections.Generic.Dictionary[string, hashtable]]$AvailableFields
    
    # Métriques de performance
    [PerformanceMetricsManager]$Metrics
    
    # Constructeur par défaut
    DateFilterManager() {
        $this.AvailableFields = [System.Collections.Generic.Dictionary[string, hashtable]]::new()
        $this.Metrics = [PerformanceMetricsManager]::new()
        
        # Initialiser les champs par défaut
        $this.InitializeDefaultFields()
    }
    
    # Méthode pour initialiser les champs par défaut
    [void] InitializeDefaultFields() {
        # Champ: created_at
        $this.RegisterField("created_at", "Date de création", @{
            description = "Date à laquelle le document a été créé"
            format = "yyyy-MM-dd HH:mm:ss"
        })
        
        # Champ: updated_at
        $this.RegisterField("updated_at", "Date de mise à jour", @{
            description = "Date à laquelle le document a été mis à jour"
            format = "yyyy-MM-dd HH:mm:ss"
        })
        
        # Champ: published_at
        $this.RegisterField("published_at", "Date de publication", @{
            description = "Date à laquelle le document a été publié"
            format = "yyyy-MM-dd HH:mm:ss"
        })
        
        # Champ: deleted_at
        $this.RegisterField("deleted_at", "Date de suppression", @{
            description = "Date à laquelle le document a été supprimé"
            format = "yyyy-MM-dd HH:mm:ss"
        })
        
        # Champ: event_date
        $this.RegisterField("event_date", "Date de l'événement", @{
            description = "Date à laquelle l'événement a lieu"
            format = "yyyy-MM-dd"
        })
        
        # Champ: due_date
        $this.RegisterField("due_date", "Date d'échéance", @{
            description = "Date à laquelle la tâche doit être terminée"
            format = "yyyy-MM-dd"
        })
        
        # Champ: start_date
        $this.RegisterField("start_date", "Date de début", @{
            description = "Date de début de l'événement ou de la tâche"
            format = "yyyy-MM-dd"
        })
        
        # Champ: end_date
        $this.RegisterField("end_date", "Date de fin", @{
            description = "Date de fin de l'événement ou de la tâche"
            format = "yyyy-MM-dd"
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
    
    # Méthode pour créer une plage de dates
    [DateRange] CreateDateRange([DateTime]$startDate = [DateTime]::MinValue, [DateTime]$endDate = [DateTime]::MaxValue) {
        return [DateRange]::new($startDate, $endDate)
    }
    
    # Méthode pour créer un filtre par date
    [DateFilter] CreateFilter([string]$field = "created_at", [DateRange]$range = $null) {
        if ($null -eq $range) {
            $range = [DateRange]::new()
        }
        
        return [DateFilter]::new($field, $range)
    }
    
    # Méthode pour créer un filtre par date avec des dates
    [DateFilter] CreateFilterWithDates([string]$field = "created_at", [DateTime]$startDate = [DateTime]::MinValue, [DateTime]$endDate = [DateTime]::MaxValue) {
        return [DateFilter]::new($field, $startDate, $endDate)
    }
    
    # Méthode pour créer un filtre pour aujourd'hui
    [DateFilter] CreateTodayFilter([string]$field = "created_at") {
        $today = Get-Date
        $startDate = $today.Date
        $endDate = $startDate.AddDays(1).AddSeconds(-1)
        
        return [DateFilter]::new($field, $startDate, $endDate)
    }
    
    # Méthode pour créer un filtre pour cette semaine
    [DateFilter] CreateThisWeekFilter([string]$field = "created_at") {
        $today = Get-Date
        $dayOfWeek = [int]$today.DayOfWeek
        $startDate = $today.Date.AddDays(-$dayOfWeek)
        $endDate = $startDate.AddDays(7).AddSeconds(-1)
        
        return [DateFilter]::new($field, $startDate, $endDate)
    }
    
    # Méthode pour créer un filtre pour ce mois
    [DateFilter] CreateThisMonthFilter([string]$field = "created_at") {
        $today = Get-Date
        $startDate = [DateTime]::new($today.Year, $today.Month, 1)
        $endDate = $startDate.AddMonths(1).AddSeconds(-1)
        
        return [DateFilter]::new($field, $startDate, $endDate)
    }
    
    # Méthode pour créer un filtre pour cette année
    [DateFilter] CreateThisYearFilter([string]$field = "created_at") {
        $today = Get-Date
        $startDate = [DateTime]::new($today.Year, 1, 1)
        $endDate = $startDate.AddYears(1).AddSeconds(-1)
        
        return [DateFilter]::new($field, $startDate, $endDate)
    }
    
    # Méthode pour appliquer un filtre à une liste de documents
    [IndexDocument[]] ApplyFilter([DateFilter]$filter, [IndexDocument[]]$documents) {
        $timer = $this.Metrics.GetTimer("date_filter.apply_filter")
        $timer.Start()
        
        $result = $documents | Where-Object { $filter.Matches($_) }
        
        $timer.Stop()
        
        # Incrémenter les compteurs
        $this.Metrics.IncrementCounter("date_filter.documents_filtered", $documents.Count)
        $this.Metrics.IncrementCounter("date_filter.documents_matched", $result.Count)
        
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

# Fonction pour créer une plage de dates
function New-DateRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = [DateTime]::MinValue,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = [DateTime]::MaxValue
    )
    
    return [DateRange]::new($StartDate, $EndDate)
}

# Fonction pour créer un filtre par date
function New-DateFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Field = "created_at",
        
        [Parameter(Mandatory = $false)]
        [DateRange]$Range = $null,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate = [DateTime]::MinValue,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = [DateTime]::MaxValue
    )
    
    if ($null -ne $Range) {
        return [DateFilter]::new($Field, $Range)
    } else {
        return [DateFilter]::new($Field, $StartDate, $EndDate)
    }
}

# Fonction pour créer un gestionnaire de filtres par date
function New-DateFilterManager {
    [CmdletBinding()]
    param ()
    
    return [DateFilterManager]::new()
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-DateRange, New-DateFilter, New-DateFilterManager
