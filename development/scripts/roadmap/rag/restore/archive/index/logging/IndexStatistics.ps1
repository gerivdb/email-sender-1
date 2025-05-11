# IndexStatistics.ps1
# Script implémentant les statistiques d'indexation
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logRotationPath = Join-Path -Path $scriptPath -ChildPath "LogRotation.ps1"

if (Test-Path -Path $logRotationPath) {
    . $logRotationPath
} else {
    Write-Error "Le fichier LogRotation.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un compteur de statistiques
class StatisticsCounter {
    # Nom du compteur
    [string]$Name
    
    # Description du compteur
    [string]$Description
    
    # Valeur du compteur
    [long]$Value
    
    # Valeur minimale
    [long]$Min
    
    # Valeur maximale
    [long]$Max
    
    # Nombre d'échantillons
    [long]$SampleCount
    
    # Somme des valeurs
    [long]$Sum
    
    # Somme des carrés des valeurs
    [long]$SumOfSquares
    
    # Constructeur par défaut
    StatisticsCounter() {
        $this.Name = ""
        $this.Description = ""
        $this.Value = 0
        $this.Min = [long]::MaxValue
        $this.Max = [long]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Constructeur avec nom
    StatisticsCounter([string]$name) {
        $this.Name = $name
        $this.Description = ""
        $this.Value = 0
        $this.Min = [long]::MaxValue
        $this.Max = [long]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Constructeur avec nom et description
    StatisticsCounter([string]$name, [string]$description) {
        $this.Name = $name
        $this.Description = $description
        $this.Value = 0
        $this.Min = [long]::MaxValue
        $this.Max = [long]::MinValue
        $this.SampleCount = 0
        $this.Sum = 0
        $this.SumOfSquares = 0
    }
    
    # Méthode pour incrémenter le compteur
    [void] Increment([long]$value = 1) {
        $this.Value += $value
        $this.Min = [Math]::Min($this.Min, $this.Value)
        $this.Max = [Math]::Max($this.Max, $this.Value)
        $this.SampleCount++
        $this.Sum += $value
        $this.SumOfSquares += $value * $value
    }
    
    # Méthode pour décrémenter le compteur
    [void] Decrement([long]$value = 1) {
        $this.Value -= $value
        $this.Min = [Math]::Min($this.Min, $this.Value)
        $this.Max = [Math]::Max($this.Max, $this.Value)
        $this.SampleCount++
        $this.Sum -= $value
        $this.SumOfSquares += $value * $value
    }
    
    # Méthode pour réinitialiser le compteur
    [void] Reset() {
        $this.Value = 0
        $this.Min = [long]::MaxValue
        $this.Max = [long]::MinValue
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
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            name = $this.Name
            description = $this.Description
            value = $this.Value
            min = $this.Min
            max = $this.Max
            sample_count = $this.SampleCount
            average = $this.GetAverage()
            standard_deviation = $this.GetStandardDeviation()
        }
    }
}

# Classe pour représenter un chronomètre de statistiques
class StatisticsTimer {
    # Nom du chronomètre
    [string]$Name
    
    # Description du chronomètre
    [string]$Description
    
    # Chronomètre interne
    [System.Diagnostics.Stopwatch]$Stopwatch
    
    # Compteur associé
    [StatisticsCounter]$Counter
    
    # Constructeur par défaut
    StatisticsTimer() {
        $this.Name = ""
        $this.Description = ""
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [StatisticsCounter]::new()
    }
    
    # Constructeur avec nom
    StatisticsTimer([string]$name) {
        $this.Name = $name
        $this.Description = ""
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [StatisticsCounter]::new($name)
    }
    
    # Constructeur avec nom et description
    StatisticsTimer([string]$name, [string]$description) {
        $this.Name = $name
        $this.Description = $description
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.Counter = [StatisticsCounter]::new($name, $description)
    }
    
    # Méthode pour démarrer le chronomètre
    [void] Start() {
        $this.Stopwatch.Restart()
    }
    
    # Méthode pour arrêter le chronomètre
    [long] Stop() {
        $this.Stopwatch.Stop()
        $elapsed = $this.Stopwatch.ElapsedMilliseconds
        $this.Counter.Increment($elapsed)
        return $elapsed
    }
    
    # Méthode pour mesurer le temps d'exécution d'un bloc de code
    [long] Measure([scriptblock]$scriptBlock) {
        $this.Start()
        & $scriptBlock
        return $this.Stop()
    }
    
    # Méthode pour réinitialiser le chronomètre
    [void] Reset() {
        $this.Stopwatch.Reset()
        $this.Counter.Reset()
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            name = $this.Name
            description = $this.Description
            counter = $this.Counter.ToHashtable()
        }
    }
}

# Classe pour représenter un gestionnaire de statistiques d'indexation
class IndexStatisticsManager {
    # Dictionnaire des compteurs
    [System.Collections.Generic.Dictionary[string, StatisticsCounter]]$Counters
    
    # Dictionnaire des chronomètres
    [System.Collections.Generic.Dictionary[string, StatisticsTimer]]$Timers
    
    # Gestionnaire de rotation des journaux
    [LogRotationManager]$LogManager
    
    # Intervalle d'enregistrement des statistiques (en secondes)
    [int]$LoggingInterval
    
    # Dernier enregistrement
    [DateTime]$LastLogging
    
    # Constructeur par défaut
    IndexStatisticsManager() {
        $this.Counters = [System.Collections.Generic.Dictionary[string, StatisticsCounter]]::new()
        $this.Timers = [System.Collections.Generic.Dictionary[string, StatisticsTimer]]::new()
        $this.LogManager = [LogRotationManager]::new()
        $this.LoggingInterval = 3600  # 1 heure
        $this.LastLogging = [DateTime]::MinValue
        
        # Initialiser les compteurs par défaut
        $this.InitializeDefaultCounters()
    }
    
    # Constructeur avec gestionnaire de rotation des journaux
    IndexStatisticsManager([LogRotationManager]$logManager) {
        $this.Counters = [System.Collections.Generic.Dictionary[string, StatisticsCounter]]::new()
        $this.Timers = [System.Collections.Generic.Dictionary[string, StatisticsTimer]]::new()
        $this.LogManager = $logManager
        $this.LoggingInterval = 3600  # 1 heure
        $this.LastLogging = [DateTime]::MinValue
        
        # Initialiser les compteurs par défaut
        $this.InitializeDefaultCounters()
    }
    
    # Constructeur complet
    IndexStatisticsManager([LogRotationManager]$logManager, [int]$loggingInterval) {
        $this.Counters = [System.Collections.Generic.Dictionary[string, StatisticsCounter]]::new()
        $this.Timers = [System.Collections.Generic.Dictionary[string, StatisticsTimer]]::new()
        $this.LogManager = $logManager
        $this.LoggingInterval = $loggingInterval
        $this.LastLogging = [DateTime]::MinValue
        
        # Initialiser les compteurs par défaut
        $this.InitializeDefaultCounters()
    }
    
    # Méthode pour initialiser les compteurs par défaut
    [void] InitializeDefaultCounters() {
        # Compteurs pour les documents
        $this.CreateCounter("documents.total", "Nombre total de documents indexés")
        $this.CreateCounter("documents.added", "Nombre de documents ajoutés")
        $this.CreateCounter("documents.updated", "Nombre de documents mis à jour")
        $this.CreateCounter("documents.deleted", "Nombre de documents supprimés")
        
        # Compteurs pour les segments
        $this.CreateCounter("segments.total", "Nombre total de segments")
        $this.CreateCounter("segments.active", "Nombre de segments actifs")
        $this.CreateCounter("segments.compacted", "Nombre de segments compactés")
        
        # Compteurs pour les recherches
        $this.CreateCounter("searches.total", "Nombre total de recherches")
        $this.CreateCounter("searches.successful", "Nombre de recherches réussies")
        $this.CreateCounter("searches.failed", "Nombre de recherches échouées")
        
        # Compteurs pour le cache
        $this.CreateCounter("cache.hits", "Nombre de hits dans le cache")
        $this.CreateCounter("cache.misses", "Nombre de misses dans le cache")
        
        # Chronomètres pour les opérations
        $this.CreateTimer("operations.add_document", "Temps d'ajout d'un document")
        $this.CreateTimer("operations.update_document", "Temps de mise à jour d'un document")
        $this.CreateTimer("operations.delete_document", "Temps de suppression d'un document")
        $this.CreateTimer("operations.search", "Temps de recherche")
        $this.CreateTimer("operations.compact", "Temps de compaction")
    }
    
    # Méthode pour créer un compteur
    [StatisticsCounter] CreateCounter([string]$name, [string]$description = "") {
        $counter = [StatisticsCounter]::new($name, $description)
        $this.Counters[$name] = $counter
        return $counter
    }
    
    # Méthode pour obtenir un compteur
    [StatisticsCounter] GetCounter([string]$name) {
        if (-not $this.Counters.ContainsKey($name)) {
            return $this.CreateCounter($name)
        }
        
        return $this.Counters[$name]
    }
    
    # Méthode pour créer un chronomètre
    [StatisticsTimer] CreateTimer([string]$name, [string]$description = "") {
        $timer = [StatisticsTimer]::new($name, $description)
        $this.Timers[$name] = $timer
        return $timer
    }
    
    # Méthode pour obtenir un chronomètre
    [StatisticsTimer] GetTimer([string]$name) {
        if (-not $this.Timers.ContainsKey($name)) {
            return $this.CreateTimer($name)
        }
        
        return $this.Timers[$name]
    }
    
    # Méthode pour incrémenter un compteur
    [void] IncrementCounter([string]$name, [long]$value = 1) {
        $counter = $this.GetCounter($name)
        $counter.Increment($value)
    }
    
    # Méthode pour décrémenter un compteur
    [void] DecrementCounter([string]$name, [long]$value = 1) {
        $counter = $this.GetCounter($name)
        $counter.Decrement($value)
    }
    
    # Méthode pour mesurer le temps d'exécution d'un bloc de code
    [long] MeasureTime([string]$name, [scriptblock]$scriptBlock) {
        $timer = $this.GetTimer($name)
        return $timer.Measure($scriptBlock)
    }
    
    # Méthode pour vérifier si un enregistrement des statistiques est nécessaire
    [bool] ShouldLogStatistics() {
        $now = Get-Date
        $elapsed = ($now - $this.LastLogging).TotalSeconds
        
        return $elapsed -ge $this.LoggingInterval -or $this.LastLogging -eq [DateTime]::MinValue
    }
    
    # Méthode pour enregistrer les statistiques
    [void] LogStatistics() {
        # Vérifier si un enregistrement est nécessaire
        if (-not $this.ShouldLogStatistics()) {
            return
        }
        
        # Créer une entrée de journal
        $entry = [IndexLogEntry]::new("Info", "Statistics", "Statistiques d'indexation")
        
        # Ajouter les statistiques des compteurs
        $countersData = @{}
        foreach ($name in $this.Counters.Keys) {
            $counter = $this.Counters[$name]
            $countersData[$name] = $counter.ToHashtable()
        }
        $entry.AddData("counters", $countersData)
        
        # Ajouter les statistiques des chronomètres
        $timersData = @{}
        foreach ($name in $this.Timers.Keys) {
            $timer = $this.Timers[$name]
            $timersData[$name] = $timer.ToHashtable()
        }
        $entry.AddData("timers", $timersData)
        
        # Écrire l'entrée dans le journal
        $this.LogManager.WriteLogEntry($entry, "JSON")
        
        # Mettre à jour la date du dernier enregistrement
        $this.LastLogging = Get-Date
    }
    
    # Méthode pour obtenir toutes les statistiques
    [hashtable] GetAllStatistics() {
        $stats = @{
            counters = @{}
            timers = @{}
            timestamp = Get-Date
        }
        
        foreach ($name in $this.Counters.Keys) {
            $counter = $this.Counters[$name]
            $stats.counters[$name] = $counter.ToHashtable()
        }
        
        foreach ($name in $this.Timers.Keys) {
            $timer = $this.Timers[$name]
            $stats.timers[$name] = $timer.ToHashtable()
        }
        
        return $stats
    }
    
    # Méthode pour réinitialiser toutes les statistiques
    [void] ResetAllStatistics() {
        foreach ($counter in $this.Counters.Values) {
            $counter.Reset()
        }
        
        foreach ($timer in $this.Timers.Values) {
            $timer.Reset()
        }
        
        $this.LastLogging = [DateTime]::MinValue
    }
    
    # Méthode pour démarrer l'enregistrement périodique des statistiques
    [void] StartPeriodicLogging() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = 60 * 1000  # 1 minute
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($manager)
            
            if ($manager.ShouldLogStatistics()) {
                $manager.LogStatistics()
            }
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
}

# Fonction pour créer un gestionnaire de statistiques d'indexation
function New-IndexStatisticsManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [LogRotationManager]$LogManager = (New-LogRotationManager),
        
        [Parameter(Mandatory = $false)]
        [int]$LoggingInterval = 3600  # 1 heure
    )
    
    return [IndexStatisticsManager]::new($LogManager, $LoggingInterval)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexStatisticsManager
