#Requires -Version 5.1
<#
.SYNOPSIS
    Module de collecte des donnÃ©es d'utilisation pour le cache prÃ©dictif.
.DESCRIPTION
    Collecte et stocke les donnÃ©es d'utilisation du cache pour alimenter
    les algorithmes de prÃ©diction et d'optimisation.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour la gestion de la base de donnÃ©es d'utilisation
class UsageDatabase {
    [string]$DatabasePath
    [System.Data.SQLite.SQLiteConnection]$Connection
    [bool]$Initialized = $false
    
    # Constructeur
    UsageDatabase([string]$databasePath) {
        $this.DatabasePath = $databasePath
        $this.InitializeDatabase()
    }
    
    # Initialiser la base de donnÃ©es
    [void] InitializeDatabase() {
        try {
            # VÃ©rifier si le rÃ©pertoire existe
            $databaseDir = Split-Path -Path $this.DatabasePath -Parent
            if (-not (Test-Path -Path $databaseDir)) {
                New-Item -Path $databaseDir -ItemType Directory -Force | Out-Null
            }
            
            # Charger l'assembly SQLite
            Add-Type -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\lib\System.Data.SQLite.dll")
            
            # CrÃ©er la connexion
            $connectionString = "Data Source=$($this.DatabasePath);Version=3;"
            $this.Connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $this.Connection.Open()
            
            # CrÃ©er les tables si elles n'existent pas
            $this.CreateTables()
            
            $this.Initialized = $true
        }
        catch {
            Write-Error "Erreur lors de l'initialisation de la base de donnÃ©es: $_"
            
            # Fallback: utiliser une base de donnÃ©es en mÃ©moire
            $this.UseFallbackDatabase()
        }
    }
    
    # Utiliser une base de donnÃ©es de secours en mÃ©moire
    [void] UseFallbackDatabase() {
        try {
            Write-Warning "Utilisation d'une base de donnÃ©es en mÃ©moire comme solution de secours."
            
            # CrÃ©er une base de donnÃ©es en mÃ©moire
            $connectionString = "Data Source=:memory:;Version=3;"
            $this.Connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
            $this.Connection.Open()
            
            # CrÃ©er les tables
            $this.CreateTables()
            
            $this.Initialized = $true
        }
        catch {
            Write-Error "Erreur lors de la crÃ©ation de la base de donnÃ©es de secours: $_"
            $this.Initialized = $false
        }
    }
    
    # CrÃ©er les tables nÃ©cessaires
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
        
        # ExÃ©cuter les commandes SQL
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
    
    # Enregistrer un accÃ¨s au cache
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
            
            # Enregistrer la sÃ©quence d'accÃ¨s si nÃ©cessaire
            $this.RecordAccessSequence($cacheName, $key)
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'accÃ¨s au cache: $_"
        }
    }
    
    # Enregistrer une sÃ©quence d'accÃ¨s
    [void] RecordAccessSequence([string]$cacheName, [string]$currentKey) {
        if (-not $this.Initialized) { return }
        
        try {
            # RÃ©cupÃ©rer la derniÃ¨re clÃ© accÃ©dÃ©e
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
                
                # Calculer la diffÃ©rence de temps
                $currentTime = Get-Date
                $timeDifference = ($currentTime - $lastAccessTime).TotalMilliseconds
                
                # Enregistrer la sÃ©quence si la diffÃ©rence est infÃ©rieure Ã  30 secondes
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
            Write-Warning "Erreur lors de l'enregistrement de la sÃ©quence d'accÃ¨s: $_"
        }
    }
    
    # Enregistrer une opÃ©ration de dÃ©finition dans le cache
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
            Write-Warning "Erreur lors de l'enregistrement de la dÃ©finition dans le cache: $_"
        }
    }
    
    # Enregistrer une Ã©viction du cache
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
            Write-Warning "Erreur lors de l'enregistrement de l'Ã©viction du cache: $_"
        }
    }
    
    # Obtenir les statistiques d'accÃ¨s pour une clÃ©
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
            Write-Warning "Erreur lors de la rÃ©cupÃ©ration des statistiques d'accÃ¨s: $_"
            return $null
        }
    }
    
    # Obtenir les clÃ©s les plus frÃ©quemment accÃ©dÃ©es
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
            Write-Warning "Erreur lors de la rÃ©cupÃ©ration des clÃ©s les plus accÃ©dÃ©es: $_"
            return @()
        }
    }
    
    # Obtenir les sÃ©quences d'accÃ¨s les plus frÃ©quentes
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
            Write-Warning "Erreur lors de la rÃ©cupÃ©ration des sÃ©quences frÃ©quentes: $_"
            return @()
        }
    }
    
    # Nettoyer les anciennes donnÃ©es
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
            
            # Optimiser la base de donnÃ©es
            $command.CommandText = "VACUUM;"
            $command.ExecuteNonQuery() | Out-Null
        }
        catch {
            Write-Warning "Erreur lors du nettoyage des anciennes donnÃ©es: $_"
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
    
    # Initialiser la base de donnÃ©es
    [void] InitializeDatabase() {
        try {
            $this.Database = [UsageDatabase]::new($this.DatabasePath)
            
            # VÃ©rifier si un nettoyage est nÃ©cessaire
            $now = Get-Date
            if (($now - $this.LastCleanup).TotalDays -ge $this.CleanupInterval) {
                $this.Database.CleanupOldData()
                $this.LastCleanup = $now
            }
        }
        catch {
            Write-Error "Erreur lors de l'initialisation de la base de donnÃ©es d'utilisation: $_"
        }
    }
    
    # Enregistrer un accÃ¨s au cache
    [void] RecordAccess([string]$key, [bool]$hit) {
        try {
            # Calculer le temps d'exÃ©cution si disponible
            $executionTime = 0
            $now = Get-Date
            
            if ($this.LastAccesses.ContainsKey($key)) {
                $lastAccess = $this.LastAccesses[$key]
                $executionTime = ($now - $lastAccess).TotalMilliseconds
            }
            
            # Enregistrer l'accÃ¨s
            $this.Database.RecordAccess($this.CacheName, $key, $hit, $executionTime)
            
            # Mettre Ã  jour le dernier accÃ¨s
            $this.LastAccesses[$key] = $now
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'accÃ¨s: $_"
        }
    }
    
    # Enregistrer une opÃ©ration de dÃ©finition dans le cache
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
            Write-Warning "Erreur lors de l'enregistrement de la dÃ©finition: $_"
        }
    }
    
    # Enregistrer une Ã©viction du cache
    [void] RecordEviction([string]$key) {
        try {
            $this.Database.RecordEviction($this.CacheName, $key)
        }
        catch {
            Write-Warning "Erreur lors de l'enregistrement de l'Ã©viction: $_"
        }
    }
    
    # Obtenir les statistiques d'accÃ¨s pour une clÃ©
    [PSCustomObject] GetKeyAccessStats([string]$key) {
        return $this.Database.GetKeyAccessStats($this.CacheName, $key)
    }
    
    # Obtenir les clÃ©s les plus frÃ©quemment accÃ©dÃ©es
    [array] GetMostAccessedKeys([int]$limit = 10, [int]$timeWindowMinutes = 60) {
        return $this.Database.GetMostAccessedKeys($this.CacheName, $limit, $timeWindowMinutes)
    }
    
    # Obtenir les sÃ©quences d'accÃ¨s les plus frÃ©quentes
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

# Fonctions exportÃ©es

<#
.SYNOPSIS
    CrÃ©e un nouveau collecteur d'utilisation.
.DESCRIPTION
    CrÃ©e un nouveau collecteur d'utilisation pour enregistrer les accÃ¨s au cache.
.PARAMETER DatabasePath
    Chemin vers la base de donnÃ©es d'utilisation.
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
        Write-Error "Erreur lors de la crÃ©ation du collecteur d'utilisation: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-UsageCollector
