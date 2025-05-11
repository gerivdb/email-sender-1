# IndexAlerts.ps1
# Script implémentant les alertes en cas d'erreur d'indexation
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexStatisticsPath = Join-Path -Path $scriptPath -ChildPath "IndexStatistics.ps1"

if (Test-Path -Path $indexStatisticsPath) {
    . $indexStatisticsPath
} else {
    Write-Error "Le fichier IndexStatistics.ps1 est introuvable."
    exit 1
}

# Classe pour représenter un seuil d'alerte
class AlertThreshold {
    # Nom du seuil
    [string]$Name
    
    # Description du seuil
    [string]$Description
    
    # Valeur du seuil
    [double]$Value
    
    # Opérateur de comparaison (GT, GE, LT, LE, EQ, NE)
    [string]$Operator
    
    # Constructeur par défaut
    AlertThreshold() {
        $this.Name = ""
        $this.Description = ""
        $this.Value = 0
        $this.Operator = "GT"
    }
    
    # Constructeur avec nom et valeur
    AlertThreshold([string]$name, [double]$value) {
        $this.Name = $name
        $this.Description = ""
        $this.Value = $value
        $this.Operator = "GT"
    }
    
    # Constructeur complet
    AlertThreshold([string]$name, [string]$description, [double]$value, [string]$operator) {
        $this.Name = $name
        $this.Description = $description
        $this.Value = $value
        $this.Operator = $operator
    }
    
    # Méthode pour vérifier si une valeur dépasse le seuil
    [bool] IsExceeded([double]$value) {
        switch ($this.Operator) {
            "GT" { return $value -gt $this.Value }
            "GE" { return $value -ge $this.Value }
            "LT" { return $value -lt $this.Value }
            "LE" { return $value -le $this.Value }
            "EQ" { return $value -eq $this.Value }
            "NE" { return $value -ne $this.Value }
            default { return $value -gt $this.Value }
        }
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            name = $this.Name
            description = $this.Description
            value = $this.Value
            operator = $this.Operator
        }
    }
}

# Classe pour représenter une alerte
class Alert {
    # ID de l'alerte
    [string]$Id
    
    # Horodatage de l'alerte
    [DateTime]$Timestamp
    
    # Niveau de l'alerte (Info, Warning, Error, Critical)
    [string]$Level
    
    # Source de l'alerte
    [string]$Source
    
    # Message de l'alerte
    [string]$Message
    
    # Données supplémentaires
    [hashtable]$Data
    
    # Constructeur par défaut
    Alert() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = "Info"
        $this.Source = ""
        $this.Message = ""
        $this.Data = @{}
    }
    
    # Constructeur avec niveau, source et message
    Alert([string]$level, [string]$source, [string]$message) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = $level
        $this.Source = $source
        $this.Message = $message
        $this.Data = @{}
    }
    
    # Constructeur complet
    Alert([string]$level, [string]$source, [string]$message, [hashtable]$data) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Timestamp = Get-Date
        $this.Level = $level
        $this.Source = $source
        $this.Message = $message
        $this.Data = $data
    }
    
    # Méthode pour ajouter des données
    [void] AddData([string]$key, [object]$value) {
        $this.Data[$key] = $value
    }
    
    # Méthode pour convertir en chaîne
    [string] ToString() {
        return "[$($this.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$($this.Level)] [$($this.Source)] $($this.Message)"
    }
    
    # Méthode pour convertir en JSON
    [string] ToJson() {
        $obj = @{
            id = $this.Id
            timestamp = $this.Timestamp.ToString("o")
            level = $this.Level
            source = $this.Source
            message = $this.Message
            data = $this.Data
        }
        
        return ConvertTo-Json -InputObject $obj -Depth 10 -Compress
    }
    
    # Méthode pour créer à partir de JSON
    static [Alert] FromJson([string]$json) {
        $obj = ConvertFrom-Json -InputObject $json
        
        $alert = [Alert]::new()
        $alert.Id = $obj.id
        $alert.Timestamp = [DateTime]::Parse($obj.timestamp)
        $alert.Level = $obj.level
        $alert.Source = $obj.source
        $alert.Message = $obj.message
        
        $alert.Data = @{}
        foreach ($prop in $obj.data.PSObject.Properties) {
            $alert.Data[$prop.Name] = $prop.Value
        }
        
        return $alert
    }
}

# Classe pour représenter un gestionnaire d'alertes
class AlertManager {
    # Dictionnaire des seuils d'alerte
    [System.Collections.Generic.Dictionary[string, AlertThreshold]]$Thresholds
    
    # Liste des alertes
    [System.Collections.Generic.List[Alert]]$Alerts
    
    # Gestionnaire de statistiques
    [IndexStatisticsManager]$StatisticsManager
    
    # Gestionnaire de rotation des journaux
    [LogRotationManager]$LogManager
    
    # Intervalle de vérification des alertes (en secondes)
    [int]$CheckInterval
    
    # Dernière vérification
    [DateTime]$LastCheck
    
    # Constructeur par défaut
    AlertManager() {
        $this.Thresholds = [System.Collections.Generic.Dictionary[string, AlertThreshold]]::new()
        $this.Alerts = [System.Collections.Generic.List[Alert]]::new()
        $this.StatisticsManager = $null
        $this.LogManager = [LogRotationManager]::new()
        $this.CheckInterval = 60  # 1 minute
        $this.LastCheck = [DateTime]::MinValue
        
        # Initialiser les seuils par défaut
        $this.InitializeDefaultThresholds()
    }
    
    # Constructeur avec gestionnaire de statistiques
    AlertManager([IndexStatisticsManager]$statisticsManager) {
        $this.Thresholds = [System.Collections.Generic.Dictionary[string, AlertThreshold]]::new()
        $this.Alerts = [System.Collections.Generic.List[Alert]]::new()
        $this.StatisticsManager = $statisticsManager
        $this.LogManager = [LogRotationManager]::new()
        $this.CheckInterval = 60  # 1 minute
        $this.LastCheck = [DateTime]::MinValue
        
        # Initialiser les seuils par défaut
        $this.InitializeDefaultThresholds()
    }
    
    # Constructeur complet
    AlertManager([IndexStatisticsManager]$statisticsManager, [LogRotationManager]$logManager, [int]$checkInterval) {
        $this.Thresholds = [System.Collections.Generic.Dictionary[string, AlertThreshold]]::new()
        $this.Alerts = [System.Collections.Generic.List[Alert]]::new()
        $this.StatisticsManager = $statisticsManager
        $this.LogManager = $logManager
        $this.CheckInterval = $checkInterval
        $this.LastCheck = [DateTime]::MinValue
        
        # Initialiser les seuils par défaut
        $this.InitializeDefaultThresholds()
    }
    
    # Méthode pour initialiser les seuils par défaut
    [void] InitializeDefaultThresholds() {
        # Seuils pour les erreurs
        $this.SetThreshold("searches.failed", "Nombre d'erreurs de recherche", 10, "GT")
        $this.SetThreshold("searches.failed_percentage", "Pourcentage d'erreurs de recherche", 5, "GT")
        
        # Seuils pour les performances
        $this.SetThreshold("operations.search.average", "Temps moyen de recherche (ms)", 1000, "GT")
        $this.SetThreshold("operations.add_document.average", "Temps moyen d'ajout de document (ms)", 500, "GT")
        
        # Seuils pour le cache
        $this.SetThreshold("cache.hit_ratio", "Ratio de hits dans le cache (%)", 50, "LT")
    }
    
    # Méthode pour définir un seuil d'alerte
    [AlertThreshold] SetThreshold([string]$name, [string]$description, [double]$value, [string]$operator) {
        $threshold = [AlertThreshold]::new($name, $description, $value, $operator)
        $this.Thresholds[$name] = $threshold
        return $threshold
    }
    
    # Méthode pour obtenir un seuil d'alerte
    [AlertThreshold] GetThreshold([string]$name) {
        if (-not $this.Thresholds.ContainsKey($name)) {
            return $null
        }
        
        return $this.Thresholds[$name]
    }
    
    # Méthode pour supprimer un seuil d'alerte
    [bool] RemoveThreshold([string]$name) {
        return $this.Thresholds.Remove($name)
    }
    
    # Méthode pour créer une alerte
    [Alert] CreateAlert([string]$level, [string]$source, [string]$message, [hashtable]$data = @{}) {
        $alert = [Alert]::new($level, $source, $message, $data)
        $this.Alerts.Add($alert)
        
        # Enregistrer l'alerte dans le journal
        $this.LogAlert($alert)
        
        return $alert
    }
    
    # Méthode pour enregistrer une alerte dans le journal
    [void] LogAlert([Alert]$alert) {
        # Créer une entrée de journal
        $entry = [IndexLogEntry]::new($alert.Level, "Alert", $alert.Message)
        
        # Ajouter les données de l'alerte
        $entry.AddData("alert_id", $alert.Id)
        $entry.AddData("alert_source", $alert.Source)
        
        foreach ($key in $alert.Data.Keys) {
            $entry.AddData($key, $alert.Data[$key])
        }
        
        # Écrire l'entrée dans le journal
        $this.LogManager.WriteLogEntry($entry, "JSON")
    }
    
    # Méthode pour vérifier si une vérification des alertes est nécessaire
    [bool] ShouldCheckAlerts() {
        $now = Get-Date
        $elapsed = ($now - $this.LastCheck).TotalSeconds
        
        return $elapsed -ge $this.CheckInterval -or $this.LastCheck -eq [DateTime]::MinValue
    }
    
    # Méthode pour vérifier les alertes
    [Alert[]] CheckAlerts() {
        # Vérifier si une vérification est nécessaire
        if (-not $this.ShouldCheckAlerts()) {
            return @()
        }
        
        # Mettre à jour la date de la dernière vérification
        $this.LastCheck = Get-Date
        
        # Vérifier si le gestionnaire de statistiques est défini
        if ($null -eq $this.StatisticsManager) {
            return @()
        }
        
        # Récupérer les statistiques
        $stats = $this.StatisticsManager.GetAllStatistics()
        
        # Liste des alertes déclenchées
        $triggeredAlerts = [System.Collections.Generic.List[Alert]]::new()
        
        # Vérifier les seuils pour les compteurs
        foreach ($name in $this.Thresholds.Keys) {
            $threshold = $this.Thresholds[$name]
            
            # Vérifier si le nom correspond à un compteur
            if ($name -match '^([^.]+)\.([^.]+)$') {
                $category = $matches[1]
                $counterName = $matches[2]
                
                # Vérifier si la catégorie et le compteur existent
                if ($stats.counters.ContainsKey("$category.$counterName")) {
                    $counter = $stats.counters["$category.$counterName"]
                    $value = $counter.value
                    
                    # Vérifier si le seuil est dépassé
                    if ($threshold.IsExceeded($value)) {
                        # Créer une alerte
                        $alert = $this.CreateAlert("Warning", "Threshold", "Le seuil '$($threshold.Name)' a été dépassé", @{
                            threshold_name = $threshold.Name
                            threshold_value = $threshold.Value
                            threshold_operator = $threshold.Operator
                            actual_value = $value
                        })
                        
                        $triggeredAlerts.Add($alert)
                    }
                }
            }
            # Vérifier si le nom correspond à un chronomètre
            elseif ($name -match '^([^.]+)\.([^.]+)\.([^.]+)$') {
                $category = $matches[1]
                $timerName = $matches[2]
                $property = $matches[3]
                
                # Vérifier si la catégorie et le chronomètre existent
                if ($stats.timers.ContainsKey("$category.$timerName")) {
                    $timer = $stats.timers["$category.$timerName"]
                    
                    # Vérifier si la propriété existe
                    if ($timer.counter.ContainsKey($property)) {
                        $value = $timer.counter[$property]
                        
                        # Vérifier si le seuil est dépassé
                        if ($threshold.IsExceeded($value)) {
                            # Créer une alerte
                            $alert = $this.CreateAlert("Warning", "Threshold", "Le seuil '$($threshold.Name)' a été dépassé", @{
                                threshold_name = $threshold.Name
                                threshold_value = $threshold.Value
                                threshold_operator = $threshold.Operator
                                actual_value = $value
                            })
                            
                            $triggeredAlerts.Add($alert)
                        }
                    }
                }
            }
            # Vérifier les seuils calculés
            elseif ($name -eq "searches.failed_percentage") {
                # Calculer le pourcentage d'erreurs de recherche
                $totalSearches = $stats.counters["searches.total"].value
                $failedSearches = $stats.counters["searches.failed"].value
                
                if ($totalSearches -gt 0) {
                    $failedPercentage = ($failedSearches / $totalSearches) * 100
                    
                    # Vérifier si le seuil est dépassé
                    if ($threshold.IsExceeded($failedPercentage)) {
                        # Créer une alerte
                        $alert = $this.CreateAlert("Warning", "Threshold", "Le seuil '$($threshold.Name)' a été dépassé", @{
                            threshold_name = $threshold.Name
                            threshold_value = $threshold.Value
                            threshold_operator = $threshold.Operator
                            actual_value = $failedPercentage
                        })
                        
                        $triggeredAlerts.Add($alert)
                    }
                }
            }
            elseif ($name -eq "cache.hit_ratio") {
                # Calculer le ratio de hits dans le cache
                $hits = $stats.counters["cache.hits"].value
                $misses = $stats.counters["cache.misses"].value
                $total = $hits + $misses
                
                if ($total -gt 0) {
                    $hitRatio = ($hits / $total) * 100
                    
                    # Vérifier si le seuil est dépassé
                    if ($threshold.IsExceeded($hitRatio)) {
                        # Créer une alerte
                        $alert = $this.CreateAlert("Warning", "Threshold", "Le seuil '$($threshold.Name)' a été dépassé", @{
                            threshold_name = $threshold.Name
                            threshold_value = $threshold.Value
                            threshold_operator = $threshold.Operator
                            actual_value = $hitRatio
                        })
                        
                        $triggeredAlerts.Add($alert)
                    }
                }
            }
        }
        
        return $triggeredAlerts.ToArray()
    }
    
    # Méthode pour démarrer la vérification périodique des alertes
    [void] StartPeriodicChecks() {
        # Créer un timer
        $timer = New-Object System.Timers.Timer
        $timer.Interval = $this.CheckInterval * 1000  # Convertir en millisecondes
        $timer.AutoReset = $true
        
        # Configurer l'événement
        $action = {
            param($manager)
            
            $manager.CheckAlerts()
        }
        
        $timer.Elapsed.Add({
            & $action $this
        }.GetNewClosure())
        
        # Démarrer le timer
        $timer.Start()
    }
    
    # Méthode pour obtenir les alertes récentes
    [Alert[]] GetRecentAlerts([int]$count = 10) {
        return $this.Alerts | Sort-Object -Property Timestamp -Descending | Select-Object -First $count
    }
    
    # Méthode pour obtenir les alertes par niveau
    [Alert[]] GetAlertsByLevel([string]$level) {
        return $this.Alerts | Where-Object { $_.Level -eq $level }
    }
    
    # Méthode pour obtenir les alertes par source
    [Alert[]] GetAlertsBySource([string]$source) {
        return $this.Alerts | Where-Object { $_.Source -eq $source }
    }
    
    # Méthode pour obtenir les alertes par plage de dates
    [Alert[]] GetAlertsByDateRange([DateTime]$startDate, [DateTime]$endDate) {
        return $this.Alerts | Where-Object { $_.Timestamp -ge $startDate -and $_.Timestamp -le $endDate }
    }
}

# Fonction pour créer un gestionnaire d'alertes
function New-AlertManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexStatisticsManager]$StatisticsManager,
        
        [Parameter(Mandatory = $false)]
        [LogRotationManager]$LogManager = (New-LogRotationManager),
        
        [Parameter(Mandatory = $false)]
        [int]$CheckInterval = 60  # 1 minute
    )
    
    return [AlertManager]::new($StatisticsManager, $LogManager, $CheckInterval)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-AlertManager
