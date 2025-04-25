#Requires -Version 5.1
<#
.SYNOPSIS
    Module de collecte des données d'utilisation pour le cache prédictif.
.DESCRIPTION
    Collecte et stocke les données d'utilisation du cache pour alimenter
    les algorithmes de prédiction et d'optimisation.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour la gestion de la base de données d'utilisation
class UsageDatabase {
    [string]$DatabasePath
    [System.Data.SQLite.SQLiteConnection]$Connection
    [bool]$Initialized = $false
    
    # Constructeur
    UsageDatabase([string]$databasePath) {
        $this.DatabasePath = $databasePath
        $this.InitializeDatabase()
    }
    
    # Initialiser la base de données
    [void] InitializeDatabase() {
        try {
            # Vérifier si le répertoire existe
            $databaseDir = Split-Path -Path $this.DatabasePath -Parent
            if (-not (Test-Path -Path $databaseDir)) {
                New-Item -Path $databaseDir -ItemType Directory -Force | Out-Null
            }
            
            # Charger l'assembly SQLite
            Add-Type -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\lib\System.Data.SQLite.dll")
            
            # Créer la connexion
            $connectionString = "Data Source=$($this.DatabasePath);Version=3;"
            $this.Connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $this.Connection.Open()
            
            # Créer les tables si elles n'existent pas
            $this.CreateTables()
            
            $this.Initialized = $true
        }
        catch {
            Write-Error "Erreur lors de l'initialisation de la base de données: $_"
            
            # Fallback: utiliser une base de données en mémoire
            $this.UseFallbackDatabase()
        }
    }
    
    # Utiliser une base de données de secours en mémoire
    [void] UseFallbackDatabase() {
        try {
            Write-Warning "Utilisation d'une base de données en mémoire comme solution de secours."
            
            # Créer une base de données en mémoire
            $connectionString = "Data Source=:memory:;Version=3;"
            $this.Connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $this.Connection.Open()
            
            # Créer les tables
            $this.CreateTables()
            
            $this.Initialized = $true
        }
        catch {
            Write-Error "Erreur lors de la création de la base de données de secours: $_"
            $this.Initialized = $false
        }
    }
    
    # Créer les tables nécessaires
    [void] CreateTables() {
        $createAccessTable = @"
CREATE TABLE IF NOT EXISTS CacheAccess (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CacheName TEXT NOT NULL,
    KeyName TEXT NOT NULL,
    AccessTime DATETIME NOT NULL,
    Hit INTEGER NOT NULL,
    ExecutionTime INTEGER
);
"@
        
        $createSetTable = @"
CREATE TABLE IF NOT EXISTS CacheSet (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CacheName TEXT NOT NULL,
    KeyName TEXT NOT NULL,
    SetTime DATETIME NOT NULL,
    TTL INTEGER,
    ValueSize INTEGER
);
"@
        
        $createEvictionTable = @"
CREATE TABLE IF NOT EXISTS CacheEviction (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CacheName TEXT NOT NULL,
    KeyName TEXT NOT NULL,
    EvictionTime DATETIME NOT NULL,
    Reason TEXT
);
"@
        
        $createSequenceTable = @"
CREATE TABLE IF NOT EXISTS AccessSequence (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    CacheName TEXT NOT NULL,
    FirstKey TEXT NOT NULL,
    SecondKey TEXT NOT NULL,
    TimeDifference INTEGER NOT NULL,
    SequenceTime DATETIME NOT NULL
);
"@
        
        $createIndexes = @"
CREATE INDEX IF NOT EXISTS idx_access_key ON CacheAccess(KeyName, CacheName);
CREATE INDEX IF NOT EXISTS idx_access_time ON CacheAccess(AccessTime);
CREATE INDEX IF NOT EXISTS idx_set_key ON CacheSet(KeyName, CacheName);
CREATE INDEX IF NOT EXISTS idx_eviction_key ON CacheEviction(KeyName, CacheName);
CREATE INDEX IF NOT EXISTS idx_sequence_keys ON AccessSequence(FirstKey, SecondKey, CacheName);
"@
        
        # Exécuter les commandes SQL
        $command = $this.Connection.CreateCommand()
        $command.CommandText = $createAccessTable
        $command.ExecuteNonQuery() | Out-Null
        
        $command.CommandText = $createSetTable
        $command.ExecuteNonQuery() | Out-Null
        
        $command.CommandText = $createEvictionTable
        $command.ExecuteNonQuery() | Out-Null
        
        $command.CommandText = $createSequenceTable
        $command.ExecuteNonQuery() | Out-Null
        
        $command.CommandText = $createIndexes
        $command.ExecuteNonQuery() | Out-Null
    }
    
    # Enregistrer un accès au cache
    [void] RecordAccess([string]$cacheName, [string]$key, [bool]$hit, [int]$executionTime = 0) {
        if (-not $this.Initialized) { return }
        
        try {
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
INSERT INTO CacheAccess (CacheName, KeyName, AccessTime, Hit, ExecutionTime)
VALUES (@CacheName, @KeyName, @AccessTime, @Hit, @ExecutionTime);
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@KeyName", $key)
            $command.Parameters.AddWithValue("@AccessTime", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff"))
            $command.Parameters.AddWithValue("@Hit", [int]$hit)
            $command.Parameters.AddWithValue("@ExecutionTime", $executionTime)
            
            $command.ExecuteNonQuery() | Out-Null
            
            # Enregistrer la séquence d'accès si nécessaire
            $this.RecordAccessSequence($cacheName, $key)
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'accès au cache: $_"
        }
    }
    
    # Enregistrer une séquence d'accès
    [void] RecordAccessSequence([string]$cacheName, [string]$currentKey) {
        if (-not $this.Initialized) { return }
        
        try {
            # Récupérer la dernière clé accédée
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
SELECT KeyName, AccessTime FROM CacheAccess
WHERE CacheName = @CacheName AND KeyName != @CurrentKey
ORDER BY AccessTime DESC LIMIT 1;
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@CurrentKey", $currentKey)
            
            $reader = $command.ExecuteReader()
            
            if ($reader.Read()) {
                $lastKey = $reader["KeyName"].ToString()
                $lastAccessTime = [datetime]::Parse($reader["AccessTime"].ToString())
                $reader.Close()
                
                # Calculer la différence de temps
                $currentTime = Get-Date
                $timeDifference = ($currentTime - $lastAccessTime).TotalMilliseconds
                
                # Enregistrer la séquence si la différence est inférieure à 30 secondes
                if ($timeDifference -lt 30000) {
                    $command = $this.Connection.CreateCommand()
                    $command.CommandText = @"
INSERT INTO AccessSequence (CacheName, FirstKey, SecondKey, TimeDifference, SequenceTime)
VALUES (@CacheName, @FirstKey, @SecondKey, @TimeDifference, @SequenceTime);
"@
                    $command.Parameters.AddWithValue("@CacheName", $cacheName)
                    $command.Parameters.AddWithValue("@FirstKey", $lastKey)
                    $command.Parameters.AddWithValue("@SecondKey", $currentKey)
                    $command.Parameters.AddWithValue("@TimeDifference", [int]$timeDifference)
                    $command.Parameters.AddWithValue("@SequenceTime", $currentTime.ToString("yyyy-MM-dd HH:mm:ss.fff"))
                    
                    $command.ExecuteNonQuery() | Out-Null
                }
            }
            else {
                $reader.Close()
            }
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de la séquence d'accès: $_"
        }
    }
    
    # Enregistrer une opération de définition dans le cache
    [void] RecordSet([string]$cacheName, [string]$key, [int]$ttl, [int]$valueSize = 0) {
        if (-not $this.Initialized) { return }
        
        try {
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
INSERT INTO CacheSet (CacheName, KeyName, SetTime, TTL, ValueSize)
VALUES (@CacheName, @KeyName, @SetTime, @TTL, @ValueSize);
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@KeyName", $key)
            $command.Parameters.AddWithValue("@SetTime", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff"))
            $command.Parameters.AddWithValue("@TTL", $ttl)
            $command.Parameters.AddWithValue("@ValueSize", $valueSize)
            
            $command.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de la définition dans le cache: $_"
        }
    }
    
    # Enregistrer une éviction du cache
    [void] RecordEviction([string]$cacheName, [string]$key, [string]$reason = "Unknown") {
        if (-not $this.Initialized) { return }
        
        try {
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
INSERT INTO CacheEviction (CacheName, KeyName, EvictionTime, Reason)
VALUES (@CacheName, @KeyName, @EvictionTime, @Reason);
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@KeyName", $key)
            $command.Parameters.AddWithValue("@EvictionTime", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff"))
            $command.Parameters.AddWithValue("@Reason", $reason)
            
            $command.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'éviction du cache: $_"
        }
    }
    
    # Obtenir les statistiques d'accès pour une clé
    [PSCustomObject] GetKeyAccessStats([string]$cacheName, [string]$key) {
        if (-not $this.Initialized) { return $null }
        
        try {
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
SELECT 
    COUNT(*) AS TotalAccesses,
    SUM(CASE WHEN Hit = 1 THEN 1 ELSE 0 END) AS Hits,
    SUM(CASE WHEN Hit = 0 THEN 1 ELSE 0 END) AS Misses,
    AVG(ExecutionTime) AS AvgExecutionTime,
    MAX(AccessTime) AS LastAccess
FROM CacheAccess
WHERE CacheName = @CacheName AND KeyName = @KeyName;
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@KeyName", $key)
            
            $reader = $command.ExecuteReader()
            
            if ($reader.Read()) {
                $stats = [PSCustomObject]@{
                    Key = $key
                    TotalAccesses = [int]$reader["TotalAccesses"]
                    Hits = [int]$reader["Hits"]
                    Misses = [int]$reader["Misses"]
                    HitRatio = if ([int]$reader["TotalAccesses"] -gt 0) {
                        [int]$reader["Hits"] / [int]$reader["TotalAccesses"]
                    } else { 0 }
                    AvgExecutionTime = [double]$reader["AvgExecutionTime"]
                    LastAccess = if ($reader["LastAccess"] -isnot [DBNull]) {
                        [datetime]::Parse($reader["LastAccess"].ToString())
                    } else { $null }
                }
                $reader.Close()
                return $stats
            }
            else {
                $reader.Close()
                return $null
            }
        }
        catch {
            Write-Warning "Erreur lors de la récupération des statistiques d'accès: $_"
            return $null
        }
    }
    
    # Obtenir les clés les plus fréquemment accédées
    [array] GetMostAccessedKeys([string]$cacheName, [int]$limit = 10, [int]$timeWindowMinutes = 60) {
        if (-not $this.Initialized) { return @() }
        
        try {
            $command = $this.Connection.CreateCommand()
            $timeWindow = (Get-Date).AddMinutes(-$timeWindowMinutes).ToString("yyyy-MM-dd HH:mm:ss.fff")
            
            $command.CommandText = @"
SELECT 
    KeyName,
    COUNT(*) AS AccessCount,
    SUM(CASE WHEN Hit = 1 THEN 1 ELSE 0 END) AS Hits,
    SUM(CASE WHEN Hit = 0 THEN 1 ELSE 0 END) AS Misses,
    MAX(AccessTime) AS LastAccess
FROM CacheAccess
WHERE CacheName = @CacheName AND AccessTime > @TimeWindow
GROUP BY KeyName
ORDER BY AccessCount DESC
LIMIT @Limit;
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@TimeWindow", $timeWindow)
            $command.Parameters.AddWithValue("@Limit", $limit)
            
            $reader = $command.ExecuteReader()
            $results = @()
            
            while ($reader.Read()) {
                $results += [PSCustomObject]@{
                    Key = $reader["KeyName"].ToString()
                    AccessCount = [int]$reader["AccessCount"]
                    Hits = [int]$reader["Hits"]
                    Misses = [int]$reader["Misses"]
                    HitRatio = if ([int]$reader["AccessCount"] -gt 0) {
                        [int]$reader["Hits"] / [int]$reader["AccessCount"]
                    } else { 0 }
                    LastAccess = [datetime]::Parse($reader["LastAccess"].ToString())
                }
            }
            
            $reader.Close()
            return $results
        }
        catch {
            Write-Warning "Erreur lors de la récupération des clés les plus accédées: $_"
            return @()
        }
    }
    
    # Obtenir les séquences d'accès les plus fréquentes
    [array] GetFrequentSequences([string]$cacheName, [int]$limit = 10, [int]$timeWindowMinutes = 60) {
        if (-not $this.Initialized) { return @() }
        
        try {
            $command = $this.Connection.CreateCommand()
            $timeWindow = (Get-Date).AddMinutes(-$timeWindowMinutes).ToString("yyyy-MM-dd HH:mm:ss.fff")
            
            $command.CommandText = @"
SELECT 
    FirstKey,
    SecondKey,
    COUNT(*) AS SequenceCount,
    AVG(TimeDifference) AS AvgTimeDifference,
    MAX(SequenceTime) AS LastOccurrence
FROM AccessSequence
WHERE CacheName = @CacheName AND SequenceTime > @TimeWindow
GROUP BY FirstKey, SecondKey
ORDER BY SequenceCount DESC
LIMIT @Limit;
"@
            $command.Parameters.AddWithValue("@CacheName", $cacheName)
            $command.Parameters.AddWithValue("@TimeWindow", $timeWindow)
            $command.Parameters.AddWithValue("@Limit", $limit)
            
            $reader = $command.ExecuteReader()
            $results = @()
            
            while ($reader.Read()) {
                $results += [PSCustomObject]@{
                    FirstKey = $reader["FirstKey"].ToString()
                    SecondKey = $reader["SecondKey"].ToString()
                    SequenceCount = [int]$reader["SequenceCount"]
                    AvgTimeDifference = [double]$reader["AvgTimeDifference"]
                    LastOccurrence = [datetime]::Parse($reader["LastOccurrence"].ToString())
                }
            }
            
            $reader.Close()
            return $results
        }
        catch {
            Write-Warning "Erreur lors de la récupération des séquences fréquentes: $_"
            return @()
        }
    }
    
    # Nettoyer les anciennes données
    [void] CleanupOldData([int]$daysToKeep = 30) {
        if (-not $this.Initialized) { return }
        
        try {
            $cutoffDate = (Get-Date).AddDays(-$daysToKeep).ToString("yyyy-MM-dd HH:mm:ss.fff")
            
            $command = $this.Connection.CreateCommand()
            $command.CommandText = @"
DELETE FROM CacheAccess WHERE AccessTime < @CutoffDate;
DELETE FROM CacheSet WHERE SetTime < @CutoffDate;
DELETE FROM CacheEviction WHERE EvictionTime < @CutoffDate;
DELETE FROM AccessSequence WHERE SequenceTime < @CutoffDate;
"@
            $command.Parameters.AddWithValue("@CutoffDate", $cutoffDate)
            
            $command.ExecuteNonQuery() | Out-Null
            
            # Optimiser la base de données
            $command.CommandText = "VACUUM;"
            $command.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Warning "Erreur lors du nettoyage des anciennes données: $_"
        }
    }
    
    # Fermer la connexion
    [void] Close() {
        if ($this.Connection -ne $null) {
            $this.Connection.Close()
            $this.Connection.Dispose()
        }
    }
}

# Classe pour le collecteur d'utilisation
class UsageCollector {
    [string]$DatabasePath
    [UsageDatabase]$Database
    [string]$CacheName
    [hashtable]$LastAccesses = @{}
    [int]$CleanupInterval = 7 # Jours
    [datetime]$LastCleanup = [datetime]::MinValue
    
    # Constructeur
    UsageCollector([string]$databasePath, [string]$cacheName) {
        $this.DatabasePath = $databasePath
        $this.CacheName = $cacheName
        $this.InitializeDatabase()
    }
    
    # Initialiser la base de données
    [void] InitializeDatabase() {
        try {
            $this.Database = [UsageDatabase]::new($this.DatabasePath)
            
            # Vérifier si un nettoyage est nécessaire
            $now = Get-Date
            if (($now - $this.LastCleanup).TotalDays -ge $this.CleanupInterval) {
                $this.Database.CleanupOldData()
                $this.LastCleanup = $now
            }
        }
        catch {
            Write-Error "Erreur lors de l'initialisation de la base de données d'utilisation: $_"
        }
    }
    
    # Enregistrer un accès au cache
    [void] RecordAccess([string]$key, [bool]$hit) {
        try {
            # Calculer le temps d'exécution si disponible
            $executionTime = 0
            $now = Get-Date
            
            if ($this.LastAccesses.ContainsKey($key)) {
                $lastAccess = $this.LastAccesses[$key]
                $executionTime = ($now - $lastAccess).TotalMilliseconds
            }
            
            # Enregistrer l'accès
            $this.Database.RecordAccess($this.CacheName, $key, $hit, $executionTime)
            
            # Mettre à jour le dernier accès
            $this.LastAccesses[$key] = $now
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'accès: $_"
        }
    }
    
    # Enregistrer une opération de définition dans le cache
    [void] RecordSet([string]$key, [object]$value, [int]$ttl) {
        try {
            # Estimer la taille de la valeur
            $valueSize = 0
            if ($value -ne $null) {
                # Estimation simple de la taille
                $valueSize = [System.Text.Encoding]::UTF8.GetByteCount(($value | ConvertTo-Json -Depth 2 -Compress))
            }
            
            $this.Database.RecordSet($this.CacheName, $key, $ttl, $valueSize)
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de la définition: $_"
        }
    }
    
    # Enregistrer une éviction du cache
    [void] RecordEviction([string]$key) {
        try {
            $this.Database.RecordEviction($this.CacheName, $key)
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'éviction: $_"
        }
    }
    
    # Obtenir les statistiques d'accès pour une clé
    [PSCustomObject] GetKeyAccessStats([string]$key) {
        return $this.Database.GetKeyAccessStats($this.CacheName, $key)
    }
    
    # Obtenir les clés les plus fréquemment accédées
    [array] GetMostAccessedKeys([int]$limit = 10, [int]$timeWindowMinutes = 60) {
        return $this.Database.GetMostAccessedKeys($this.CacheName, $limit, $timeWindowMinutes)
    }
    
    # Obtenir les séquences d'accès les plus fréquentes
    [array] GetFrequentSequences([int]$limit = 10, [int]$timeWindowMinutes = 60) {
        return $this.Database.GetFrequentSequences($this.CacheName, $limit, $timeWindowMinutes)
    }
    
    # Fermer la connexion
    [void] Close() {
        if ($this.Database -ne $null) {
            $this.Database.Close()
        }
    }
}

# Fonctions exportées

<#
.SYNOPSIS
    Crée un nouveau collecteur d'utilisation.
.DESCRIPTION
    Crée un nouveau collecteur d'utilisation pour enregistrer les accès au cache.
.PARAMETER DatabasePath
    Chemin vers la base de données d'utilisation.
.PARAMETER CacheName
    Nom du cache.
.EXAMPLE
    $collector = New-UsageCollector -DatabasePath "C:\Cache\usage.db" -CacheName "MyCache"
#>
function New-UsageCollector {
    [CmdletBinding()]
    [OutputType([UsageCollector])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabasePath,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheName
    )
    
    try {
        return [UsageCollector]::new($DatabasePath, $CacheName)
    }
    catch {
        Write-Error "Erreur lors de la création du collecteur d'utilisation: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-UsageCollector
