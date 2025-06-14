#!/usr/bin/env pwsh

# Phase 7.1.2 - Script de migration de données en production
# Migration vectorielle Python → Go avec monitoring en temps réel

param(
   [string]$Environment = "production",
   [string]$SourcePath = "misc/vectorize_tasks.py",
   [string]$TargetCollection = "task_vectors",
   [int]$BatchSize = 100,
   [switch]$DryRun,
   [switch]$BackupFirst,
   [switch]$ValidateIntegrity
)

Write-Host "🔄 Migration de données vectorielles EMAIL_SENDER_1" -ForegroundColor Cyan
Write-Host "Environnement: $Environment" -ForegroundColor Gray
Write-Host "Collection cible: $TargetCollection" -ForegroundColor Gray
Write-Host "Taille de batch: $BatchSize" -ForegroundColor Gray

if ($DryRun) {
   Write-Host "⚠️  MODE DRY RUN - Aucune modification ne sera effectuée" -ForegroundColor Yellow
}

# Configuration
$QdrantUrl = "http://localhost:6333"
$MigrationLogPath = "logs/migration-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$BackupPath = "backup/production-migration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Fonction de logging
function Write-MigrationLog {
   param([string]$Message, [string]$Level = "INFO")
    
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   $logEntry = "[$timestamp] [$Level] $Message"
    
   # Affichage console avec couleurs
   switch ($Level) {
      "ERROR" { Write-Host $logEntry -ForegroundColor Red }
      "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
      "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
      default { Write-Host $logEntry -ForegroundColor White }
   }
    
   # Écriture dans le fichier de log
   if (-not $DryRun) {
      $logEntry | Out-File -FilePath $MigrationLogPath -Append -Encoding UTF8
   }
}

# Fonction de test de connectivité Qdrant
function Test-QdrantConnectivity {
   try {
      $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method GET -TimeoutSec 10
      Write-MigrationLog "Connexion Qdrant établie - $($response.result.collections.Count) collections trouvées" "SUCCESS"
      return $true
   }
   catch {
      Write-MigrationLog "Échec de connexion Qdrant: $($_.Exception.Message)" "ERROR"
      return $false
   }
}

# Fonction de backup des données existantes
function Backup-ExistingData {
   if (-not $BackupFirst) { return }
    
   Write-MigrationLog "Début du backup des données existantes..." "INFO"
    
   try {
      # Créer le répertoire de backup
      New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        
      # Backup des collections Qdrant
      $collections = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method GET
        
      foreach ($collection in $collections.result.collections) {
         $collectionName = $collection.name
         Write-MigrationLog "Backup de la collection: $collectionName" "INFO"
            
         # Export des points de la collection
         $points = Invoke-RestMethod -Uri "$QdrantUrl/collections/$collectionName/points" -Method POST -Body '{"limit": 10000}' -ContentType "application/json"
            
         $backupFile = Join-Path $BackupPath "$collectionName.json"
         $points | ConvertTo-Json -Depth 10 | Out-File -FilePath $backupFile -Encoding UTF8
            
         Write-MigrationLog "Collection $collectionName sauvegardée ($($points.result.points.Count) points)" "SUCCESS"
      }
        
      Write-MigrationLog "Backup terminé dans: $BackupPath" "SUCCESS"
   }
   catch {
      Write-MigrationLog "Erreur lors du backup: $($_.Exception.Message)" "ERROR"
      throw
   }
}

# Fonction de création de collection
function Create-TargetCollection {
   param([string]$CollectionName)
    
   Write-MigrationLog "Création de la collection cible: $CollectionName" "INFO"
    
   # Vérifier si la collection existe déjà
   try {
      $existingCollection = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method GET
      Write-MigrationLog "Collection $CollectionName existe déjà" "WARN"
        
      if (-not $DryRun) {
         # Demander confirmation pour recréer
         $response = Read-Host "Recréer la collection $CollectionName? (y/N)"
         if ($response -eq 'y' -or $response -eq 'Y') {
            Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method DELETE
            Write-MigrationLog "Collection $CollectionName supprimée" "INFO"
         }
         else {
            throw "Migration annulée par l'utilisateur"
         }
      }
   }
   catch {
      # Collection n'existe pas, c'est normal
   }
    
   # Créer la nouvelle collection
   $collectionConfig = @{
      vectors            = @{
         size     = 1536  # Taille des embeddings OpenAI
         distance = "Cosine"
      }
      optimizers_config  = @{
         default_segment_number = 2
      }
      replication_factor = 1
   } | ConvertTo-Json -Depth 3
    
   if (-not $DryRun) {
      $null = Invoke-RestMethod -Uri "$QdrantUrl/collections/$CollectionName" -Method PUT -Body $collectionConfig -ContentType "application/json"
      Write-MigrationLog "Collection $CollectionName créée avec succès" "SUCCESS"
   }
   else {
      Write-MigrationLog "DRY RUN: Collection $CollectionName serait créée" "INFO"
   }
}

# Fonction de migration par batch
function Migrate-VectorBatch {
   param([array]$VectorBatch, [int]$BatchNumber)
    
   Write-MigrationLog "Migration du batch $BatchNumber ($($VectorBatch.Count) vecteurs)" "INFO"
    
   # Préparer les points pour Qdrant
   $points = @()
    
   foreach ($vector in $VectorBatch) {
      $point = @{
         id      = $vector.id
         vector  = $vector.embedding
         payload = @{
            task        = $vector.task
            description = $vector.description
            created_at  = $vector.created_at
            source      = "python_migration"
         }
      }
      $points += $point
   }
    
   $batchData = @{
      points = $points
   } | ConvertTo-Json -Depth 5
    
   if (-not $DryRun) {
      try {
         $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$TargetCollection/points" -Method PUT -Body $batchData -ContentType "application/json"
            
         if ($response.status -eq "ok") {
            Write-MigrationLog "Batch $BatchNumber migré avec succès" "SUCCESS"
            return $true
         }
         else {
            Write-MigrationLog "Erreur lors de la migration du batch $BatchNumber: $($response.message)" "ERROR"
            return $false
         }
      }
      catch {
         Write-MigrationLog "Exception lors de la migration du batch $BatchNumber: $($_.Exception.Message)" "ERROR"
         return $false
      }
   }
   else {
      Write-MigrationLog "DRY RUN: Batch $BatchNumber serait migré" "INFO"
      return $true
   }
}

# Fonction de validation d'intégrité
function Validate-MigrationIntegrity {
   param([int]$ExpectedCount)
    
   Write-MigrationLog "Validation de l'intégrité de la migration..." "INFO"
    
   try {
      # Compter les points dans la collection
      $response = Invoke-RestMethod -Uri "$QdrantUrl/collections/$TargetCollection" -Method GET
      $actualCount = $response.result.points_count
        
      Write-MigrationLog "Points attendus: $ExpectedCount, Points actuels: $actualCount" "INFO"
        
      if ($actualCount -eq $ExpectedCount) {
         Write-MigrationLog "✅ Intégrité validée - Tous les vecteurs ont été migrés" "SUCCESS"
         return $true
      }
      else {
         $missingCount = $ExpectedCount - $actualCount
         Write-MigrationLog "❌ Intégrité compromise - $missingCount vecteurs manquants" "ERROR"
         return $false
      }
   }
   catch {
      Write-MigrationLog "Erreur lors de la validation: $($_.Exception.Message)" "ERROR"
      return $false
   }
}

# Script principal de migration
try {
   Write-MigrationLog "=== DÉBUT DE LA MIGRATION ===" "INFO"
    
   # Étape 1: Vérifications préliminaires
   Write-MigrationLog "Étape 1: Vérifications préliminaires" "INFO"
    
   if (-not (Test-QdrantConnectivity)) {
      throw "Impossible de se connecter à Qdrant"
   }
    
   # Vérifier que le fichier source existe
   if (-not (Test-Path "misc/task_vectors.json")) {
      Write-MigrationLog "Fichier source task_vectors.json non trouvé. Tentative de génération..." "WARN"
        
      # Générer les vecteurs si nécessaire
      if (Test-Path $SourcePath) {
         Write-MigrationLog "Exécution de $SourcePath pour générer les vecteurs..." "INFO"
         if (-not $DryRun) {
            python $SourcePath
         }
      }
      else {
         throw "Fichier source $SourcePath introuvable"
      }
   }
    
   # Étape 2: Backup des données existantes
   if ($BackupFirst) {
      Write-MigrationLog "Étape 2: Backup des données existantes" "INFO"
      Backup-ExistingData
   }
    
   # Étape 3: Chargement des données source
   Write-MigrationLog "Étape 3: Chargement des données source" "INFO"
    
   $sourceData = Get-Content "misc/task_vectors.json" | ConvertFrom-Json
   $totalVectors = $sourceData.Count
   Write-MigrationLog "Chargement de $totalVectors vecteurs depuis le fichier source" "INFO"
    
   # Étape 4: Création de la collection cible
   Write-MigrationLog "Étape 4: Création de la collection cible" "INFO"
   Create-TargetCollection -CollectionName $TargetCollection
    
   # Étape 5: Migration par batch
   Write-MigrationLog "Étape 5: Migration par batch (taille: $BatchSize)" "INFO"
    
   $totalBatches = [Math]::Ceiling($totalVectors / $BatchSize)
   $successfulBatches = 0
   $failedBatches = 0
    
   for ($i = 0; $i -lt $totalBatches; $i++) {
      $startIndex = $i * $BatchSize
      $endIndex = [Math]::Min(($i + 1) * $BatchSize - 1, $totalVectors - 1)
        
      $batch = $sourceData[$startIndex..$endIndex]
        
      # Affichage du progrès
      $progressPercent = [Math]::Round(($i + 1) / $totalBatches * 100, 1)
      Write-Progress -Activity "Migration en cours" -Status "Batch $($i + 1)/$totalBatches ($progressPercent%)" -PercentComplete $progressPercent
        
      if (Migrate-VectorBatch -VectorBatch $batch -BatchNumber ($i + 1)) {
         $successfulBatches++
      }
      else {
         $failedBatches++
            
         if ($failedBatches -gt ($totalBatches * 0.05)) {
            Write-MigrationLog "Trop d'échecs détectés (>5%), arrêt de la migration" "ERROR"
            throw "Migration arrêtée due aux échecs"
         }
      }
        
      # Pause entre les batches pour éviter la surcharge
      if (-not $DryRun -and $i -lt $totalBatches - 1) {
         Start-Sleep -Milliseconds 100
      }
   }
    
   Write-Progress -Activity "Migration en cours" -Completed
    
   # Étape 6: Validation de l'intégrité
   if ($ValidateIntegrity -and -not $DryRun) {
      Write-MigrationLog "Étape 6: Validation de l'intégrité" "INFO"
        
      if (-not (Validate-MigrationIntegrity -ExpectedCount $totalVectors)) {
         throw "Échec de la validation d'intégrité"
      }
   }
    
   # Étape 7: Rapport final
   Write-MigrationLog "=== RAPPORT DE MIGRATION ===" "INFO"
   Write-MigrationLog "Vecteurs traités: $totalVectors" "INFO"
   Write-MigrationLog "Batches réussis: $successfulBatches" "SUCCESS"
   Write-MigrationLog "Batches échoués: $failedBatches" "INFO"
   Write-MigrationLog "Taux de succès: $([Math]::Round($successfulBatches / $totalBatches * 100, 1))%" "INFO"
    
   if ($DryRun) {
      Write-MigrationLog "Mode DRY RUN - Aucune modification effectuée" "INFO"
   }
   else {
      Write-MigrationLog "Migration terminée avec succès!" "SUCCESS"
      Write-MigrationLog "Log détaillé: $MigrationLogPath" "INFO"
        
      if ($BackupFirst) {
         Write-MigrationLog "Backup disponible: $BackupPath" "INFO"
      }
   }
    
   Write-MigrationLog "=== FIN DE LA MIGRATION ===" "INFO"
    
}
catch {
   Write-MigrationLog "ÉCHEC DE LA MIGRATION: $($_.Exception.Message)" "ERROR"
    
   # Plan de contingence
   if (-not $DryRun) {
      Write-MigrationLog "Activation du plan de contingence..." "WARN"
        
      # Nettoyer la collection partiellement migrée
      try {
         Invoke-RestMethod -Uri "$QdrantUrl/collections/$TargetCollection" -Method DELETE
         Write-MigrationLog "Collection partiellement migrée supprimée" "INFO"
      }
      catch {
         Write-MigrationLog "Impossible de nettoyer la collection: $($_.Exception.Message)" "ERROR"
      }
        
      # Restaurer depuis le backup si disponible
      if ($BackupFirst -and (Test-Path $BackupPath)) {
         Write-MigrationLog "Restauration depuis le backup recommandée" "WARN"
         Write-MigrationLog "Chemin du backup: $BackupPath" "INFO"
      }
   }
    
   exit 1
}
