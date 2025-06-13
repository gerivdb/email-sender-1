# Procédures de Maintenance

## Monitoring Quotidien

### 1. Vérification Santé Système

#### Check automatisé

```powershell
# Script de vérification quotidienne

./scripts/daily-health-check.ps1

# Vérification manuelle rapide

Invoke-RestMethod -Uri "http://localhost:8080/health" | ConvertTo-Json -Depth 3
```plaintext
**Output attendu :**
```json
{
  "status": "healthy",
  "timestamp": "2025-06-12T09:00:00Z",
  "services": {
    "database": {
      "postgres": "healthy",
      "qdrant": "healthy"
    },
    "sync_engine": "healthy",
    "validation_service": "healthy"
  },
  "metrics": {
    "active_syncs": 0,
    "pending_conflicts": 0,
    "last_sync": "2025-06-12T08:45:22Z"
  }
}
```plaintext
#### Métriques Performance

```powershell
# Métriques en temps réel

Invoke-RestMethod -Uri "http://localhost:8080/metrics" | ConvertTo-Json

# Dashboard monitoring

Start-Process "http://localhost:8080/monitoring"
```plaintext
**Seuils d'alerte :**
- CPU Usage > 80% pendant 5+ minutes
- Memory Usage > 90% 
- Sync Duration > 60s pour plans standards
- Error Rate > 5% sur 1 heure

### 2. Logs à Surveiller

#### Logs Critiques

```powershell
# Erreurs synchronisation

Select-String -Path "logs/sync-engine.log" -Pattern "ERROR.*sync" | Select-Object -Last 20

# Conflits non résolus

Select-String -Path "logs/conflicts.log" -Pattern "conflict.*unresolved" | Select-Object -Last 10

# Erreurs validation

Select-String -Path "logs/validation.log" -Pattern "ValidationError" | Select-Object -Last 15
```plaintext
#### Script d'analyse automatisée

```powershell
# ./scripts/analyze-logs.ps1

param(
    [string]$LogPath = "./logs",
    [int]$HoursBack = 24
)

$cutoffTime = (Get-Date).AddHours(-$HoursBack)

Write-Host "📊 Analyse des logs depuis $cutoffTime" -ForegroundColor Green

# Compter erreurs par type

$errors = @{}
Get-ChildItem "$LogPath/*.log" | ForEach-Object {
    $content = Get-Content $_.FullName | Where-Object { $_ -match "ERROR" }
    foreach ($line in $content) {
        if ($line -match "ERROR\s+(\w+)") {
            $errorType = $matches[1]
            $errors[$errorType] = ($errors[$errorType] ?? 0) + 1
        }
    }
}

Write-Host "🔍 Erreurs détectées :"
$errors.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Yellow
}

# Alertes si seuils dépassés

if ($errors.Values | Measure-Object -Sum).Sum -gt 50) {
    Write-Host "⚠️  ALERTE: Plus de 50 erreurs détectées !" -ForegroundColor Red
    # Envoyer notification

    ./scripts/send-alert.ps1 -Message "High error count detected" -Severity "High"
}
```plaintext
### 3. Vérification Base de Données

#### PostgreSQL

```powershell
# Connexions actives

$query = @"
SELECT datname, usename, application_name, state, query_start 
FROM pg_stat_activity 
WHERE datname = 'planning_sync' AND state = 'active';
"@

psql -U sync_user -d planning_sync -c $query

# Statistiques tables principales

$statsQuery = @"
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del, n_live_tup
FROM pg_stat_user_tables 
WHERE tablename IN ('plans', 'phases', 'tasks', 'sync_operations')
ORDER BY n_live_tup DESC;
"@

psql -U sync_user -d planning_sync -c $statsQuery
```plaintext
#### QDrant

```powershell
# Status collections

Invoke-RestMethod -Uri "http://localhost:6333/collections" | ConvertTo-Json

# Stats collection plans

Invoke-RestMethod -Uri "http://localhost:6333/collections/plans" | ConvertTo-Json
```plaintext
## Maintenance Hebdomadaire

### 1. Nettoyage Base de Données

#### Script automatisé

```powershell
# ./scripts/weekly-maintenance.ps1

param(
    [int]$RetentionDays = 30
)

Write-Host "🧹 Début maintenance hebdomadaire..." -ForegroundColor Green

# 1. Backup avant nettoyage

Write-Host "📦 Création backup..."
$backupPath = ".\backups\weekly_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force

# Backup PostgreSQL

pg_dump -U sync_user -h localhost planning_sync | Compress-Archive -DestinationPath "$backupPath\postgres_backup.zip"

# Backup QDrant

Invoke-RestMethod -Uri "http://localhost:6333/collections/plans/snapshots" -Method POST
Write-Host "✅ Backup créé: $backupPath"

# 2. Nettoyage logs anciens

Write-Host "🗑️  Nettoyage logs > $RetentionDays jours..."
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem ".\logs\*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate } | Remove-Item -Force
Write-Host "✅ Logs nettoyés"

# 3. Nettoyage base de données

Write-Host "🗄️  Nettoyage base de données..."
$cleanupQuery = @"
-- Supprimer anciens logs sync (> $RetentionDays jours)
DELETE FROM sync_operations 
WHERE started_at < NOW() - INTERVAL '$RetentionDays days';

-- Supprimer anciens conflits résolus (> 7 jours)
DELETE FROM conflicts 
WHERE status = 'resolved' AND resolved_at < NOW() - INTERVAL '7 days';

-- Supprimer métriques anciennes (> 90 jours)
DELETE FROM performance_metrics 
WHERE timestamp < NOW() - INTERVAL '90 days';
"@

psql -U sync_user -d planning_sync -c $cleanupQuery
Write-Host "✅ Base de données nettoyée"

# 4. Vacuum et analyse PostgreSQL

Write-Host "⚡ Optimisation PostgreSQL..."
psql -U sync_user -d planning_sync -c "VACUUM ANALYZE;"
Write-Host "✅ PostgreSQL optimisé"

# 5. Optimisation QDrant

Write-Host "🔍 Optimisation QDrant..."
Invoke-RestMethod -Uri "http://localhost:6333/collections/plans/index" -Method POST
Write-Host "✅ QDrant optimisé"

Write-Host "🎉 Maintenance hebdomadaire terminée !" -ForegroundColor Green
```plaintext
### 2. Optimisation Performance

#### Analyse performance

```powershell
# ./scripts/performance-analysis.ps1

Write-Host "📈 Analyse performance système..." -ForegroundColor Green

# Requêtes PostgreSQL les plus lentes

$slowQueriesQuery = @"
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC 
LIMIT 10;
"@

Write-Host "🐌 Requêtes les plus lentes :"
psql -U sync_user -d planning_sync -c $slowQueriesQuery

# Taille des tables

$tableSizeQuery = @"
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) as size,
    pg_total_relation_size(tablename::regclass) as size_bytes
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY size_bytes DESC;
"@

Write-Host "📊 Taille des tables :"
psql -U sync_user -d planning_sync -c $tableSizeQuery

# Statistiques index

$indexUsageQuery = @"
SELECT 
    indexrelname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;
"@

Write-Host "🔍 Utilisation des index :"
psql -U sync_user -d planning_sync -c $indexUsageQuery
```plaintext
#### Recommandations automatisées

```powershell
# ./scripts/performance-recommendations.ps1

$recommendations = @()

# Vérifier utilisation index

$unusedIndexes = psql -U sync_user -d planning_sync -t -c @"
SELECT indexrelname 
FROM pg_stat_user_indexes 
WHERE idx_scan < 10;
"@

if ($unusedIndexes) {
    $recommendations += "Consider dropping unused indexes: $($unusedIndexes -join ', ')"
}

# Vérifier fragmentation tables

$fragmentedTables = psql -U sync_user -d planning_sync -t -c @"
SELECT tablename 
FROM pg_stat_user_tables 
WHERE n_dead_tup > n_live_tup * 0.1;
"@

if ($fragmentedTables) {
    $recommendations += "Consider VACUUM FULL for fragmented tables: $($fragmentedTables -join ', ')"
}

Write-Host "💡 Recommandations :"
$recommendations | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
```plaintext
### 3. Vérification Sécurité

#### Script de sécurité hebdomadaire

```powershell
# ./scripts/security-check.ps1

Write-Host "🔒 Vérification sécurité hebdomadaire..." -ForegroundColor Green

# 1. Vérifier permissions fichiers

Write-Host "📁 Vérification permissions fichiers..."
$sensitivePaths = @(
    ".\config\config.yaml",
    ".\scripts\*.ps1",
    ".\logs\*.log"
)

foreach ($path in $sensitivePaths) {
    $files = Get-ChildItem $path -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $acl = Get-Acl $file.FullName
        # Vérifier que seuls admin et system ont accès complet

        $dangerousPerms = $acl.Access | Where-Object { 
            $_.IdentityReference -notmatch "(Administrators|SYSTEM|sync_user)" -and 
            $_.FileSystemRights -match "FullControl|Modify"
        }
        if ($dangerousPerms) {
            Write-Host "⚠️  Permissions dangereuses sur $($file.Name)" -ForegroundColor Red
        }
    }
}

# 2. Vérifier tokens expirés

Write-Host "🔑 Vérification tokens..."
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/auth/validate" -Headers @{
        "Authorization" = "Bearer $(Get-Content './config/api-token.txt' -Raw)"
    }
    if ($response.expires_in -lt 86400) {  # < 24h

        Write-Host "⚠️  Token expire bientôt" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Token invalide ou expiré" -ForegroundColor Red
}

# 3. Scan ports ouverts

Write-Host "🌐 Scan ports ouverts..."
$openPorts = @()
$portsToCheck = @(8080, 5432, 6333)  # API, PostgreSQL, QDrant

foreach ($port in $portsToCheck) {
    $connection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        $openPorts += $port
    }
}

Write-Host "✅ Ports ouverts: $($openPorts -join ', ')"

# 4. Vérifier logs sécurité

$securityEvents = Select-String -Path ".\logs\*.log" -Pattern "(authentication|authorization|security)" | Select-Object -Last 10
if ($securityEvents) {
    Write-Host "🔍 Événements sécurité récents :"
    $securityEvents | ForEach-Object { Write-Host "  $_" }
}

Write-Host "✅ Vérification sécurité terminée" -ForegroundColor Green
```plaintext
## Backup et Restauration

### 1. Stratégie de Backup

#### Backup quotidien automatisé

```powershell
# ./scripts/backup-daily.ps1

param(
    [string]$BackupPath = ".\backups\daily",
    [int]$RetentionDays = 7
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dailyBackupPath = "$BackupPath\$timestamp"

Write-Host "📦 Début backup quotidien..." -ForegroundColor Green

# Créer dossier backup

New-Item -ItemType Directory -Path $dailyBackupPath -Force

# 1. Backup PostgreSQL

Write-Host "🗄️  Backup PostgreSQL..."
pg_dump -U sync_user -h localhost --verbose --clean --no-owner --no-acl planning_sync | Out-File "$dailyBackupPath\postgres.sql" -Encoding UTF8

# 2. Backup QDrant (snapshots)

Write-Host "🔍 Backup QDrant..."
$snapshotResponse = Invoke-RestMethod -Uri "http://localhost:6333/collections/plans/snapshots" -Method POST
$snapshotName = $snapshotResponse.name
# Copier snapshot vers backup

Copy-Item ".\qdrant\storage\collections\plans\snapshots\$snapshotName" "$dailyBackupPath\qdrant_snapshot" -Force

# 3. Backup configuration

Write-Host "⚙️  Backup configuration..."
Copy-Item ".\config\*.yaml" "$dailyBackupPath\" -Force

# 4. Backup scripts critiques

Copy-Item ".\scripts\*.ps1" "$dailyBackupPath\scripts\" -Recurse -Force

# 5. Backup plans Markdown

Write-Host "📝 Backup plans Markdown..."
Copy-Item ".\roadmaps\plans\*" "$dailyBackupPath\plans\" -Recurse -Force

# 6. Compresser backup

Write-Host "🗜️  Compression backup..."
Compress-Archive -Path "$dailyBackupPath\*" -DestinationPath "$dailyBackupPath.zip" -Force
Remove-Item -Path $dailyBackupPath -Recurse -Force

# 7. Nettoyage anciens backups

Write-Host "🧹 Nettoyage anciens backups..."
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem "$BackupPath\*.zip" | Where-Object { $_.LastWriteTime -lt $cutoffDate } | Remove-Item -Force

# 8. Vérification backup

$backupSize = (Get-Item "$dailyBackupPath.zip").Length / 1MB
Write-Host "✅ Backup terminé: $($backupSize.ToString('F2')) MB" -ForegroundColor Green

# 9. Log backup

$logEntry = @{
    timestamp = Get-Date
    backup_path = "$dailyBackupPath.zip"
    size_mb = $backupSize
    status = "success"
} | ConvertTo-Json -Compress

Add-Content -Path ".\logs\backup.log" -Value $logEntry
```plaintext
### 2. Procédures de Restauration

#### Restauration complète

```powershell
# ./scripts/restore-backup.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath,
    [switch]$DryRun
)

Write-Host "🔄 Début procédure de restauration..." -ForegroundColor Green

if ($DryRun) {
    Write-Host "🧪 MODE DRY-RUN - Aucun changement appliqué" -ForegroundColor Yellow
}

# 1. Vérifier backup

if (!(Test-Path $BackupPath)) {
    Write-Error "❌ Backup non trouvé: $BackupPath"
    exit 1
}

# Extraire backup

$tempRestore = ".\temp\restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempRestore -Force
Expand-Archive -Path $BackupPath -DestinationPath $tempRestore

Write-Host "📦 Backup extrait vers $tempRestore"

if (!$DryRun) {
    # 2. Arrêter services

    Write-Host "⏹️  Arrêt services..."
    Stop-Process -Name "planning-sync-server" -Force -ErrorAction SilentlyContinue
    
    # 3. Restaurer PostgreSQL

    Write-Host "🗄️  Restauration PostgreSQL..."
    psql -U sync_user -d planning_sync -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
    psql -U sync_user -d planning_sync -f "$tempRestore\postgres.sql"
    
    # 4. Restaurer QDrant

    Write-Host "🔍 Restauration QDrant..."
    # Arrêter QDrant, remplacer données, redémarrer

    Stop-Service qdrant -ErrorAction SilentlyContinue
    Copy-Item "$tempRestore\qdrant_snapshot\*" ".\qdrant\storage\collections\plans\" -Recurse -Force
    Start-Service qdrant
    
    # 5. Restaurer configuration

    Write-Host "⚙️  Restauration configuration..."
    Copy-Item "$tempRestore\*.yaml" ".\config\" -Force
    
    # 6. Restaurer plans

    Write-Host "📝 Restauration plans..."
    Copy-Item "$tempRestore\plans\*" ".\roadmaps\plans\" -Recurse -Force
    
    # 7. Redémarrer services

    Write-Host "▶️  Redémarrage services..."
    Start-Process ".\planning-sync-server.exe"
    
    # 8. Vérifier restauration

    Start-Sleep 10
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:8080/health" -ErrorAction SilentlyContinue
    if ($healthCheck.status -eq "healthy") {
        Write-Host "✅ Restauration réussie" -ForegroundColor Green
    } else {
        Write-Host "❌ Problème détecté après restauration" -ForegroundColor Red
    }
} else {
    Write-Host "✅ Simulation restauration terminée" -ForegroundColor Green
}

# Nettoyage

Remove-Item -Path $tempRestore -Recurse -Force
```plaintext
#### Restauration sélective

```powershell
# ./scripts/restore-selective.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupPath,
    [string[]]$Components = @("postgres", "qdrant", "config", "plans")
)

Write-Host "🎯 Restauration sélective: $($Components -join ', ')" -ForegroundColor Green

# Extraire backup

$tempRestore = ".\temp\selective_restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempRestore -Force
Expand-Archive -Path $BackupPath -DestinationPath $tempRestore

foreach ($component in $Components) {
    switch ($component) {
        "postgres" {
            Write-Host "🗄️  Restauration PostgreSQL uniquement..."
            psql -U sync_user -d planning_sync -f "$tempRestore\postgres.sql"
        }
        "qdrant" {
            Write-Host "🔍 Restauration QDrant uniquement..."
            Stop-Service qdrant -ErrorAction SilentlyContinue
            Copy-Item "$tempRestore\qdrant_snapshot\*" ".\qdrant\storage\collections\plans\" -Recurse -Force
            Start-Service qdrant
        }
        "config" {
            Write-Host "⚙️  Restauration configuration uniquement..."
            Copy-Item "$tempRestore\*.yaml" ".\config\" -Force
        }
        "plans" {
            Write-Host "📝 Restauration plans uniquement..."
            Copy-Item "$tempRestore\plans\*" ".\roadmaps\plans\" -Recurse -Force
        }
    }
}

Remove-Item -Path $tempRestore -Recurse -Force
Write-Host "✅ Restauration sélective terminée" -ForegroundColor Green
```plaintext
## Monitoring et Alertes

### 1. Configuration Alertes

```yaml
# config/alerts.yaml

alerts:
  email:
    enabled: true
    smtp_server: smtp.gmail.com
    smtp_port: 587
    username: alerts@yourcompany.com
    password: ${SMTP_PASSWORD}
    recipients:
      - admin@yourcompany.com
      - ops@yourcompany.com

  slack:
    enabled: true
    webhook_url: ${SLACK_WEBHOOK}
    channel: "#planning-sync-alerts"

  discord:
    enabled: false
    webhook_url: ${DISCORD_WEBHOOK}

thresholds:
  error_rate: 5          # % sur 1 heure

  sync_duration: 60      # secondes

  cpu_usage: 80          # %

  memory_usage: 90       # %

  disk_usage: 85         # %

  response_time: 2000    # ms

```plaintext
### 2. Scripts de Monitoring

```powershell
# ./scripts/monitoring-daemon.ps1

param(
    [int]$CheckIntervalSeconds = 300  # 5 minutes

)

Write-Host "👁️  Démarrage monitoring daemon..." -ForegroundColor Green

while ($true) {
    try {
        # Check santé système

        $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 10
        
        if ($health.status -ne "healthy") {
            ./scripts/send-alert.ps1 -Message "System health check failed" -Severity "Critical"
        }
        
        # Check métriques performance

        $metrics = Invoke-RestMethod -Uri "http://localhost:8080/metrics"
        
        # CPU Usage

        if ($metrics.system.cpu_usage -gt 80) {
            ./scripts/send-alert.ps1 -Message "High CPU usage: $($metrics.system.cpu_usage)%" -Severity "Warning"
        }
        
        # Memory Usage

        if ($metrics.system.memory_usage -gt 90) {
            ./scripts/send-alert.ps1 -Message "High memory usage: $($metrics.system.memory_usage)%" -Severity "Critical"
        }
        
        # Error Rate

        $errorRate = ($metrics.sync.failed_operations / $metrics.sync.total_operations) * 100
        if ($errorRate -gt 5) {
            ./scripts/send-alert.ps1 -Message "High error rate: $($errorRate.ToString('F2'))%" -Severity "High"
        }
        
        Write-Host "✅ $(Get-Date -Format 'HH:mm:ss') - All checks passed" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ $(Get-Date -Format 'HH:mm:ss') - Monitoring check failed: $_" -ForegroundColor Red
        ./scripts/send-alert.ps1 -Message "Monitoring daemon error: $_" -Severity "High"
    }
    
    Start-Sleep $CheckIntervalSeconds
}
```plaintext
Ces procédures de maintenance assurent la stabilité, la performance et la sécurité continue du système Planning Ecosystem Sync.
