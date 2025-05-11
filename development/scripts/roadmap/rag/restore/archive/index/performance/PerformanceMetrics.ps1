# PerformanceMetrics.ps1
# Script implémentant les métriques de performance pour l'indexation et la recherche
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$preloadingPath = Join-Path -Path $scriptPath -ChildPath "SegmentPreloading.ps1"

if (Test-Path -Path $preloadingPath) {
    . $preloadingPath
} else {
    Write-Error "Le fichier SegmentPreloading.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un compteur de performance
class PerformanceCounter {
    # Nom du compteur
    [string]$Name
    
    # Description du compteur
    [string]$Description
    
    # Unité de mesure
    [string]$Unit
    
    # Valeur actuelle
    [double]$Value
    
    # Valeur minimale
    [double]$Min
    
    # Valeur maximale
    [double]$Max
    
    # Nombre d'échantillons
    [int]$SampleCount
    
    # Somme des valeurs
    [double]$Sum
    
    # Somme des carrés des valeurs
    [double]$SumOfSquares
    
    # Constructeur par défaut
    PerformanceCounter() {
        $this.Name = ""
        $this.Description = ""
        $this.Unit = ""
        $this.Value = 0
        $this.Min = [double]::MaxValue
        $this.Max = [double]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Constructeur avec nom
    PerformanceCounter([string]$name) {
        $this.Name = $name
        $this.Description = ""
        $this.Unit = ""
        $this.Value = 0
        $this.Min = [double]::MaxValue
        $this.Max = [double]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Constructeur complet
    PerformanceCounter([string]$name, [string]$description, [string]$unit) {
        $this.Name = $name
        $this.Description = $description
        $this.Unit = $unit
        $this.Value = 0
        $this.Min = [double]::MaxValue
        $this.Max = [double]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Méthode pour mettre à jour le compteur
    [void] Update([double]$value) {
        $this.Value = $value
        $this.Min = [Math]::Min($this.Min, $value)
        $this.Max = [Math]::Max($this.Max, $value)
        $this.SampleCount++
        $this.Sum += $value
        $this.SumOfSquares += $value * $value
    }
    
    # Méthode pour incrémenter le compteur
    [void] Increment([double]$value = 1) {
        $this.Update($this.Value + $value)
    }
    
    # Méthode pour décrémenter le compteur
    [void] Decrement([double]$value = 1) {
        $this.Update($this.Value - $value)
    }
    
    # Méthode pour réinitialiser le compteur
    [void] Reset() {
        $this.Value = 0
        $this.Min = [double]::MaxValue
        $this.Max = [double]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Méthode pour obtenir la moyenne
    [double] GetAverage() {
        if ($this.SampleCount -eq 0) {
            return 0
        }
        
        return $this.Sum / $this.SampleCount
    }
    
    # Méthode pour obtenir l'écart-type
    [double] GetStandardDeviation() {
        if ($this.SampleCount -le 1) {
            return 0
        }
        
        $variance = ($this.SumOfSquares - ($this.Sum * $this.Sum / $this.SampleCount)) / ($this.SampleCount - 1)
        
        if ($variance -lt 0) {
            # Erreur d'arrondi
            return 0
        }
        
        return [Math]::Sqrt($variance)
    }
    
    # Méthode pour obtenir les statistiques
    [hashtable] GetStats() {
        return @{
            name = $this.Name
            description = $this.Description
            unit = $this.Unit
            value = $this.Value
            min = $this.Min
            max = $this.Max
            average = $this.GetAverage()
            std_dev = $this.GetStandardDeviation()
            sample_count = $this.SampleCount
        }
    }
}

# Classe pour représenter un chronomètre de performance
class PerformanceTimer {
    # Nom du chronomètre
    [string]$Name
    
    # Description du chronomètre
    [string]$Description
    
    # Chronomètre interne
    [System.Diagnostics.Stopwatch]$Stopwatch
    
    # Compteur de performance associé
    [PerformanceCounter]$Counter
    
    # Constructeur par défaut
    PerformanceTimer() {
        $this.Name = ""
        $this.Description = ""
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [PerformanceCounter]::new("", "", "ms")
    }
    
    # Constructeur avec nom
    PerformanceTimer([string]$name) {
        $this.Name = $name
        $this.Description = ""
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [PerformanceCounter]::new($name, "", "ms")
    }
    
    # Constructeur complet
    PerformanceTimer([string]$name, [string]$description) {
        $this.Name = $name
        $this.Description = $description
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [PerformanceCounter]::new($name, $description, "ms")
    }
    
    # Méthode pour démarrer le chronomètre
    [void] Start() {
        $this.Stopwatch.Restart()
    }
    
    # Méthode pour arrêter le chronomètre
    [double] Stop() {
        $this.Stopwatch.Stop()
        $elapsed = $this.Stopwatch.ElapsedMilliseconds
        $this.Counter.Update($elapsed)
        return $elapsed
    }
    
    # Méthode pour mesurer le temps d'exécution d'un bloc de code
    [double] Measure([scriptblock]$scriptBlock) {
        $this.Start()
        & $scriptBlock
        return $this.Stop()
    }
    
    # Méthode pour obtenir les statistiques
    [hashtable] GetStats() {
        return $this.Counter.GetStats()
    }
}

# Classe pour représenter un gestionnaire de métriques de performance
class PerformanceMetricsManager {
    # Dictionnaire des compteurs
    [System.Collections.Generic.Dictionary[string, PerformanceCounter]]$Counters
    
    # Dictionnaire des chronomètres
    [System.Collections.Generic.Dictionary[string, PerformanceTimer]]$Timers
    
    # Horodatage de démarrage
    [DateTime]$StartTime
    
    # Constructeur par défaut
    PerformanceMetricsManager() {
        $this.Counters = [System.Collections.Generic.Dictionary[string, PerformanceCounter]]::new()
        $this.Timers = [System.Collections.Generic.Dictionary[string, PerformanceTimer]]::new()
        $this.StartTime = Get-Date
        
        # Initialiser les compteurs par défaut
        $this.CreateCounter("index.documents.count", "Nombre total de documents indexés", "documents")
        $this.CreateCounter("index.terms.count", "Nombre total de termes indexés", "termes")
        $this.CreateCounter("index.segments.count", "Nombre total de segments", "segments")
        $this.CreateCounter("index.size", "Taille totale de l'index", "octets")
        $this.CreateCounter("search.queries.count", "Nombre total de requêtes de recherche", "requêtes")
        $this.CreateCounter("search.results.count", "Nombre total de résultats de recherche", "résultats")
        $this.CreateCounter("search.cache.hits", "Nombre de hits dans le cache", "hits")
        $this.CreateCounter("search.cache.misses", "Nombre de misses dans le cache", "misses")
        
        # Initialiser les chronomètres par défaut
        $this.CreateTimer("index.document.add", "Temps d'ajout d'un document")
        $this.CreateTimer("index.document.update", "Temps de mise à jour d'un document")
        $this.CreateTimer("index.document.remove", "Temps de suppression d'un document")
        $this.CreateTimer("index.segment.load", "Temps de chargement d'un segment")
        $this.CreateTimer("index.segment.save", "Temps de sauvegarde d'un segment")
        $this.CreateTimer("search.query.parse", "Temps d'analyse d'une requête")
        $this.CreateTimer("search.query.execute", "Temps d'exécution d'une requête")
        $this.CreateTimer("search.results.sort", "Temps de tri des résultats")
    }
    
    # Méthode pour créer un compteur
    [PerformanceCounter] CreateCounter([string]$name, [string]$description, [string]$unit) {
        $counter = [PerformanceCounter]::new($name, $description, $unit)
        $this.Counters[$name] = $counter
        return $counter
    }
    
    # Méthode pour obtenir un compteur
    [PerformanceCounter] GetCounter([string]$name) {
        if (-not $this.Counters.ContainsKey($name)) {
            return $this.CreateCounter($name, "", "")
        }
        
        return $this.Counters[$name]
    }
    
    # Méthode pour créer un chronomètre
    [PerformanceTimer] CreateTimer([string]$name, [string]$description) {
        $timer = [PerformanceTimer]::new($name, $description)
        $this.Timers[$name] = $timer
        return $timer
    }
    
    # Méthode pour obtenir un chronomètre
    [PerformanceTimer] GetTimer([string]$name) {
        if (-not $this.Timers.ContainsKey($name)) {
            return $this.CreateTimer($name, "")
        }
        
        return $this.Timers[$name]
    }
    
    # Méthode pour mettre à jour un compteur
    [void] UpdateCounter([string]$name, [double]$value) {
        $counter = $this.GetCounter($name)
        $counter.Update($value)
    }
    
    # Méthode pour incrémenter un compteur
    [void] IncrementCounter([string]$name, [double]$value = 1) {
        $counter = $this.GetCounter($name)
        $counter.Increment($value)
    }
    
    # Méthode pour décrémenter un compteur
    [void] DecrementCounter([string]$name, [double]$value = 1) {
        $counter = $this.GetCounter($name)
        $counter.Decrement($value)
    }
    
    # Méthode pour mesurer le temps d'exécution d'un bloc de code
    [double] MeasureTime([string]$name, [scriptblock]$scriptBlock) {
        $timer = $this.GetTimer($name)
        return $timer.Measure($scriptBlock)
    }
    
    # Méthode pour obtenir toutes les métriques
    [hashtable] GetAllMetrics() {
        $metrics = @{
            counters = @{}
            timers = @{}
            uptime = (Get-Date) - $this.StartTime
            uptime_seconds = ((Get-Date) - $this.StartTime).TotalSeconds
        }
        
        foreach ($name in $this.Counters.Keys) {
            $metrics.counters[$name] = $this.Counters[$name].GetStats()
        }
        
        foreach ($name in $this.Timers.Keys) {
            $metrics.timers[$name] = $this.Timers[$name].GetStats()
        }
        
        return $metrics
    }
    
    # Méthode pour réinitialiser toutes les métriques
    [void] ResetAllMetrics() {
        foreach ($counter in $this.Counters.Values) {
            $counter.Reset()
        }
        
        foreach ($timer in $this.Timers.Values) {
            $timer.Counter.Reset()
        }
        
        $this.StartTime = Get-Date
    }
    
    # Méthode pour exporter les métriques au format JSON
    [string] ExportMetricsAsJson() {
        $metrics = $this.GetAllMetrics()
        return ConvertTo-Json -InputObject $metrics -Depth 10
    }
    
    # Méthode pour exporter les métriques au format CSV
    [string] ExportMetricsAsCsv() {
        $rows = [System.Collections.Generic.List[PSObject]]::new()
        
        # Ajouter les compteurs
        foreach ($name in $this.Counters.Keys) {
            $counter = $this.Counters[$name]
            $stats = $counter.GetStats()
            
            $row = [PSCustomObject]@{
                Type = "Counter"
                Name = $name
                Description = $counter.Description
                Unit = $counter.Unit
                Value = $counter.Value
                Min = $counter.Min
                Max = $counter.Max
                Average = $counter.GetAverage()
                StdDev = $counter.GetStandardDeviation()
                SampleCount = $counter.SampleCount
            }
            
            $rows.Add($row)
        }
        
        # Ajouter les chronomètres
        foreach ($name in $this.Timers.Keys) {
            $timer = $this.Timers[$name]
            $stats = $timer.Counter.GetStats()
            
            $row = [PSCustomObject]@{
                Type = "Timer"
                Name = $name
                Description = $timer.Description
                Unit = "ms"
                Value = $timer.Counter.Value
                Min = $timer.Counter.Min
                Max = $timer.Counter.Max
                Average = $timer.Counter.GetAverage()
                StdDev = $timer.Counter.GetStandardDeviation()
                SampleCount = $timer.Counter.SampleCount
            }
            
            $rows.Add($row)
        }
        
        return $rows | ConvertTo-Csv -NoTypeInformation
    }
}

# Fonction pour créer un gestionnaire de métriques de performance
function New-PerformanceMetricsManager {
    [CmdletBinding()]
    param()
    
    return [PerformanceMetricsManager]::new()
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-PerformanceMetricsManager
