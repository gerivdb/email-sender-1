# Script pour collecter les donnÃ©es d'erreurs
# Ce script collecte les donnÃ©es d'erreurs Ã  partir de diffÃ©rentes sources

# Configuration
$ErrorDataConfig = @{
    # Dossier de stockage des donnÃ©es
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTracking"
    
    # Fichier de base de donnÃ©es des erreurs
    DatabaseFile = "errors.json"
    
    # Fichier de statistiques
    StatsFile = "error-stats.json"
    
    # Nombre de jours Ã  conserver dans l'historique
    HistoryDays = 30
}

# Fonction pour initialiser le systÃ¨me de collecte

# Script pour collecter les donnÃ©es d'erreurs
# Ce script collecte les donnÃ©es d'erreurs Ã  partir de diffÃ©rentes sources

# Configuration
$ErrorDataConfig = @{
    # Dossier de stockage des donnÃ©es
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorTracking"
    
    # Fichier de base de donnÃ©es des erreurs
    DatabaseFile = "errors.json"
    
    # Fichier de statistiques
    StatsFile = "error-stats.json"
    
    # Nombre de jours Ã  conserver dans l'historique
    HistoryDays = 30
}

# Fonction pour initialiser le systÃ¨me de collecte
function Initialize-ErrorDataCollector {
    param (
        [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$DataFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$HistoryDays = 30
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($DataFolder)) {
        $ErrorDataConfig.DataFolder = $DataFolder
    }
    
    if ($HistoryDays -gt 0) {
        $ErrorDataConfig.HistoryDays = $HistoryDays
    }
    
    # CrÃ©er le dossier de donnÃ©es s'il n'existe pas
    if (-not (Test-Path -Path $ErrorDataConfig.DataFolder)) {
        New-Item -Path $ErrorDataConfig.DataFolder -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le fichier de base de donnÃ©es s'il n'existe pas
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    if (-not (Test-Path -Path $databasePath)) {
        $initialData = @{
            Errors = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialData | ConvertTo-Json -Depth 5 | Set-Content -Path $databasePath
    }
    
    # CrÃ©er le fichier de statistiques s'il n'existe pas
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

# Fonction pour ajouter une erreur Ã  la base de donnÃ©es
function Add-ErrorData {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Error,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si le dossier de donnÃ©es existe
    if (-not (Test-Path -Path $ErrorDataConfig.DataFolder)) {
        Initialize-ErrorDataCollector
    }
    
    # Charger la base de donnÃ©es
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
    
    # Utiliser Get-ErrorCategorization pour catÃ©goriser l'erreur
    $categorization = Get-ErrorCategorization -ErrorMessage $Error.ToString() -Metadata $Metadata
    
    # CrÃ©er l'entrÃ©e d'erreur
    $errorEntry = @{
        Id = [Guid]::NewGuid().ToString()
        Timestamp = Get-Date -Format "o"
        Source = $Source
        Category = $categorization.Category
        Severity = $categorization.Severity
        SeverityScore = $categorization.SeverityScore
        Message = $Error.ToString()
        ScriptPath = if ($Error.ScriptPath) { $Error.ScriptPath } else { $null }
        LineNumber = if ($Error.Line -or $Error.LineNumber) { 
            if ($Error.Line) { $Error.Line } else { $Error.LineNumber } 
        } else { 0 }
        Suggestion = if ($Error.Suggestion) { $Error.Suggestion } else { $null }
        Metadata = $Metadata
    }
    
    # Ajouter l'erreur Ã  la base de donnÃ©es
    $database.Errors += $errorEntry
    $database.LastUpdate = Get-Date -Format "o"
    
    # Nettoyer les anciennes entrÃ©es
    $cutoffDate = (Get-Date).AddDays(-$ErrorDataConfig.HistoryDays)
    $database.Errors = $database.Errors | Where-Object {
        [DateTime]::Parse($_.Timestamp) -ge $cutoffDate
    }
    
    # Enregistrer la base de donnÃ©es
    $database | ConvertTo-Json -Depth 5 | Set-Content -Path $databasePath
    
    # Mettre Ã  jour les statistiques
    Update-ErrorStatistics
    
    return $errorEntry
}

# Fonction pour mettre Ã  jour les statistiques
function Update-ErrorStatistics {
    # Charger la base de donnÃ©es
    $databasePath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.DatabaseFile
    $database = Get-Content -Path $databasePath -Raw | ConvertFrom-Json
    
    # Charger les statistiques
    $statsPath = Join-Path -Path $ErrorDataConfig.DataFolder -ChildPath $ErrorDataConfig.StatsFile
    $stats = Get-Content -Path $statsPath -Raw | ConvertFrom-Json
    
    # RÃ©initialiser les statistiques
    $stats.TotalErrors = $database.Errors.Count
    $stats.ErrorsByCategory = @{}
    $stats.ErrorsBySeverity = @{}
    $stats.ErrorsBySource = @{}
    $stats.DailyErrors = @{}
    
    # Calculer les statistiques
    foreach ($error in $database.Errors) {
        # Par catÃ©gorie
        $category = $error.Category
        if (-not $stats.ErrorsByCategory.$category) {
            $stats.ErrorsByCategory | Add-Member -MemberType NoteProperty -Name $category -Value 0
        }
        $stats.ErrorsByCategory.$category++
        
        # Par sÃ©vÃ©ritÃ©
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
    
    # Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
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
    
    # Charger la base de donnÃ©es
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
    
    # Filtrer par catÃ©gorie
    if (-not [string]::IsNullOrEmpty($Category)) {
        $errors = $errors | Where-Object { $_.Category -eq $Category }
    }
    
    # Filtrer par sÃ©vÃ©ritÃ©
    if (-not [string]::IsNullOrEmpty($Severity)) {
        $errors = $errors | Where-Object { $_.Severity -eq $Severity }
    }
    
    # Filtrer par source
    if (-not [string]::IsNullOrEmpty($Source)) {
        $errors = $errors | Where-Object { $_.Source -eq $Source }
    }
    
    # Limiter le nombre de rÃ©sultats
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

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
