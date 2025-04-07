# Script pour collecter les données d'erreurs
# Ce script collecte les données d'erreurs à partir de différentes sources

# Configuration
$ErrorDataConfig = @{
    # Dossier de stockage des données
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTracking"
    
    # Fichier de base de données des erreurs
    DatabaseFile = "errors.json"
    
    # Fichier de statistiques
    StatsFile = "error-stats.json"
    
    # Nombre de jours à conserver dans l'historique
    HistoryDays = 30
}

# Fonction pour initialiser le système de collecte
function Initialize-ErrorDataCollector {
    param (
        [Parameter(Mandatory = $false)]
        [string]$DataFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 30
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($DataFolder)) {
        $ErrorDataConfig.DataFolder = $DataFolder
    }
    
    if ($HistoryDays -gt 0) {
        $ErrorDataConfig.HistoryDays = $HistoryDays
    }
    
    # Créer le dossier de données s'il n'existe pas
    if (-not (Test-Path -Path $ErrorDataConfig.DataFolder)) {
        New-Item -Path $ErrorDataConfig.DataFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer le fichier de base de données s'il n'existe pas
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    if (-not (Test-Path -Path $databasePath)) {
        $initialData = @{
            Errors = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialData | ConvertTo-Json -Depth 5 | Set-Content -Path $databasePath
    }
    
    # Créer le fichier de statistiques s'il n'existe pas
    $statsPath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.StatsFile
    if (-not (Test-Path -Path $statsPath)) {
        $initialStats = @{
            TotalErrors = 0
            ErrorsByCategory = @{}
            ErrorsBySeverity = @{}
            ErrorsBySource = @{}
            DailyErrors = @{}
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialStats | ConvertTo-Json -Depth 5 | Set-Content -Path $statsPath
    }
    
    return $ErrorDataConfig
}

# Fonction pour ajouter une erreur à la base de données
function Add-ErrorData {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Error,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le dossier de données existe
    if (-not (Test-Path -Path $ErrorDataConfig.DataFolder)) {
        Initialize-ErrorDataCollector
    }
    
    # Charger la base de données
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
    
    # Créer l'entrée d'erreur
    $errorEntry = @{
        Id = [Guid]::NewGuid().ToString()
        Timestamp = Get-Date -Format "o"
        Source = $Source
        Category = if ($Error.Category) { $Error.Category } else { "Unknown" }
        Severity = if ($Error.Severity) { $Error.Severity } else { "Error" }
        Message = if ($Error.Message) { $Error.Message } else { $Error.ToString() }
        ScriptPath = if ($Error.ScriptPath) { $Error.ScriptPath } else { $null }
        LineNumber = if ($Error.Line -or $Error.LineNumber) { 
            if ($Error.Line) { $Error.Line } else { $Error.LineNumber } 
        } else { 0 }
        Suggestion = if ($Error.Suggestion) { $Error.Suggestion } else { $null }
        Metadata = $Metadata
    }
    
    # Ajouter l'erreur à la base de données
    $database.Errors += $errorEntry
    $database.LastUpdate = Get-Date -Format "o"
    
    # Nettoyer les anciennes entrées
    $cutoffDate = (Get-Date).AddDays(-$ErrorDataConfig.HistoryDays)
    $database.Errors = $database.Errors | Where-Object {
        [DateTime]::Parse($_.Timestamp) -ge $cutoffDate
    }
    
    # Enregistrer la base de données
    $database | ConvertTo-Json -Depth 5 | Set-Content -Path $databasePath
    
    # Mettre à jour les statistiques
    Update-ErrorStatistics
    
    return $errorEntry
}

# Fonction pour mettre à jour les statistiques
function Update-ErrorStatistics {
    # Charger la base de données
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
    
    # Charger les statistiques
    $statsPath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.StatsFile
    $stats = Get-Content -Path $statsPath -Raw | ConvertFrom-Json
    
    # Réinitialiser les statistiques
    $stats.TotalErrors = $database.Errors.Count
    $stats.ErrorsByCategory = @{}
    $stats.ErrorsBySeverity = @{}
    $stats.ErrorsBySource = @{}
    $stats.DailyErrors = @{}
    
    # Calculer les statistiques
    foreach ($error in $database.Errors) {
        # Par catégorie
        $category = $error.Category
        if (-not $stats.ErrorsByCategory.$category) {
            $stats.ErrorsByCategory | Add-Member -MemberType NoteProperty -Name $category -Value 0
        }
        $stats.ErrorsByCategory.$category++
        
        # Par sévérité
        $severity = $error.Severity
        if (-not $stats.ErrorsBySeverity.$severity) {
            $stats.ErrorsBySeverity | Add-Member -MemberType NoteProperty -Name $severity -Value 0
        }
        $stats.ErrorsBySeverity.$severity++
        
        # Par source
        $source = $error.Source
        if (-not $stats.ErrorsBySource.$source) {
            $stats.ErrorsBySource | Add-Member -MemberType NoteProperty -Name $source -Value 0
        }
        $stats.ErrorsBySource.$source++
        
        # Par jour
        $day = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd")
        if (-not $stats.DailyErrors.$day) {
            $stats.DailyErrors | Add-Member -MemberType NoteProperty -Name $day -Value 0
        }
        $stats.DailyErrors.$day++
    }
    
    # Mettre à jour la date de dernière mise à jour
    $stats.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les statistiques
    $stats | ConvertTo-Json -Depth 5 | Set-Content -Path $statsPath
    
    return $stats
}

# Fonction pour obtenir les erreurs
function Get-ErrorData {
    param (
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0
    )
    
    # Charger la base de données
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
    
    # Filtrer par date
    $errors = $database.Errors
    
    if ($Days -gt 0) {
        $cutoffDate = (Get-Date).AddDays(-$Days)
        $errors = $errors | Where-Object {
            [DateTime]::Parse($_.Timestamp) -ge $cutoffDate
        }
    }
    
    # Filtrer par catégorie
    if (-not [string]::IsNullOrEmpty($Category)) {
        $errors = $errors | Where-Object { $_.Category -eq $Category }
    }
    
    # Filtrer par sévérité
    if (-not [string]::IsNullOrEmpty($Severity)) {
        $errors = $errors | Where-Object { $_.Severity -eq $Severity }
    }
    
    # Filtrer par source
    if (-not [string]::IsNullOrEmpty($Source)) {
        $errors = $errors | Where-Object { $_.Source -eq $Source }
    }
    
    # Limiter le nombre de résultats
    if ($MaxResults -gt 0 -and $errors.Count -gt $MaxResults) {
        $errors = $errors | Select-Object -First $MaxResults
    }
    
    return $errors
}

# Fonction pour obtenir les statistiques
function Get-ErrorStatistics {
    # Charger les statistiques
    $statsPath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.StatsFile
    $stats = Get-Content -Path $statsPath -Raw | ConvertFrom-Json
    
    return $stats
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorDataCollector, Add-ErrorData, Update-ErrorStatistics, Get-ErrorData, Get-ErrorStatistics
