# Invoke-RoadmapVectorSync.ps1
# Script principal pour la synchronisation optimisée des roadmaps avec Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "all-MiniLM-L6-v2",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelVersion = "1.0",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Full", "Selective", "Detect", "Propagate", "Version", "Migrate", "Rollback")]
    [string]$SyncMode = "Detect",
    
    [Parameter(Mandatory = $false)]
    [string]$VersionsPath = "projet/roadmaps/vectors/embedding_versions.json",
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TargetCollectionName,
    
    [Parameter(Mandatory = $false)]
    [string]$SourceVersionId,
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 100,
    
    [Parameter(Mandatory = $false)]
    [switch]$KeepSource,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        Write-Host "[$Level] $Message"
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$Host = "localhost",
        [int]$Port = 6333
    )
    
    try {
        $response = Invoke-RestMethod -Uri "http://$Host`:$Port/collections" -Method Get -ErrorAction Stop
        return $true
    }
    catch {
        Write-Log "Impossible de se connecter à Qdrant ($Host`:$Port): $_" -Level "Error"
        return $false
    }
}

# Fonction pour détecter les changements dans la roadmap
function Invoke-ChangeDetection {
    param (
        [string]$RoadmapPath,
        [string]$OutputDirectory
    )
    
    # Vérifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "Error"
        return $false
    }
    
    # Créer le répertoire de sortie si nécessaire
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Trouver la dernière version archivée de la roadmap
    $archiveDir = Join-Path -Path $OutputDirectory -ChildPath "archive"
    if (-not (Test-Path -Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
    }
    
    $latestArchive = Get-ChildItem -Path $archiveDir -Filter "roadmap_*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if (-not $latestArchive) {
        # Créer une première archive
        $archivePath = Join-Path -Path $archiveDir -ChildPath "roadmap_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        Copy-Item -Path $RoadmapPath -Destination $archivePath
        Write-Log "Première archive créée: $archivePath" -Level "Info"
        
        # Aucun changement à détecter
        Write-Log "Aucune archive précédente trouvée. Aucun changement à détecter." -Level "Info"
        return $null
    }
    
    # Détecter les changements
    $detectScriptPath = Join-Path -Path $scriptPath -ChildPath "Detect-RoadmapChanges.ps1"
    $changesPath = Join-Path -Path $OutputDirectory -ChildPath "changes.json"
    
    if (Test-Path -Path $detectScriptPath) {
        & $detectScriptPath -OriginalPath $latestArchive.FullName -NewPath $RoadmapPath -OutputPath $changesPath -OutputFormat "Json" -Force
        
        if ($LASTEXITCODE -eq 0) {
            # Créer une nouvelle archive si des changements ont été détectés
            $changes = Get-Content -Path $changesPath -Raw | ConvertFrom-Json
            
            if ($changes.HasChanges) {
                $archivePath = Join-Path -Path $archiveDir -ChildPath "roadmap_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
                Copy-Item -Path $RoadmapPath -Destination $archivePath
                Write-Log "Nouvelle archive créée: $archivePath" -Level "Info"
            }
            
            return $changesPath
        } else {
            Write-Log "Erreur lors de la détection des changements." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de détection des changements introuvable: $detectScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour propager les changements
function Invoke-ChangePropagation {
    param (
        [string]$RoadmapPath,
        [string]$ChangesPath,
        [string]$QdrantUrl,
        [string]$CollectionName
    )
    
    $propagateScriptPath = Join-Path -Path $scriptPath -ChildPath "Propagate-RoadmapChanges.ps1"
    
    if (Test-Path -Path $propagateScriptPath) {
        & $propagateScriptPath -RoadmapPath $RoadmapPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -UpdateVectors
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Propagation des changements terminée avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de la propagation des changements." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de propagation des changements introuvable: $propagateScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour mettre à jour sélectivement les vecteurs
function Update-VectorsSelectively {
    param (
        [string]$RoadmapPath,
        [string]$ChangesPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName
    )
    
    $updateScriptPath = Join-Path -Path $scriptPath -ChildPath "Update-SelectiveVectors.ps1"
    
    if (Test-Path -Path $updateScriptPath) {
        & $updateScriptPath -RoadmapPath $RoadmapPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -Force:$Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Mise à jour sélective des vecteurs terminée avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de la mise à jour sélective des vecteurs." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de mise à jour sélective des vecteurs introuvable: $updateScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour enregistrer une version d'embedding
function Register-EmbeddingVersion {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$ModelName,
        [string]$ModelVersion
    )
    
    $versionScriptPath = Join-Path -Path $scriptPath -ChildPath "Track-EmbeddingVersions.ps1"
    
    if (Test-Path -Path $versionScriptPath) {
        & $versionScriptPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion -Action "Register" -Force:$Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Enregistrement de la version d'embedding terminé avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de l'enregistrement de la version d'embedding." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de suivi des versions d'embedding introuvable: $versionScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour créer un snapshot d'une version d'embedding
function Create-EmbeddingSnapshot {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$SnapshotPath
    )
    
    $versionScriptPath = Join-Path -Path $scriptPath -ChildPath "Track-EmbeddingVersions.ps1"
    
    if (Test-Path -Path $versionScriptPath) {
        & $versionScriptPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -Action "Snapshot" -SnapshotPath $SnapshotPath -Force:$Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Création du snapshot terminée avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de la création du snapshot." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de suivi des versions d'embedding introuvable: $versionScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour migrer vers un nouveau modèle d'embedding
function Migrate-ToNewModel {
    param (
        [string]$QdrantUrl,
        [string]$SourceCollectionName,
        [string]$TargetCollectionName,
        [string]$SourceVersionId,
        [string]$SnapshotPath,
        [string]$NewModelName,
        [string]$NewModelVersion,
        [string]$VersionsPath,
        [int]$BatchSize,
        [switch]$KeepSource
    )
    
    $migrateScriptPath = Join-Path -Path $scriptPath -ChildPath "Migrate-EmbeddingModel.ps1"
    
    if (Test-Path -Path $migrateScriptPath) {
        & $migrateScriptPath -QdrantUrl $QdrantUrl -SourceCollectionName $SourceCollectionName -TargetCollectionName $TargetCollectionName -SourceVersionId $SourceVersionId -SnapshotPath $SnapshotPath -NewModelName $NewModelName -NewModelVersion $NewModelVersion -VersionsPath $VersionsPath -BatchSize $BatchSize -KeepSource:$KeepSource -Force:$Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Migration vers le nouveau modèle terminée avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de la migration vers le nouveau modèle." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de migration des embeddings introuvable: $migrateScriptPath" -Level "Error"
        return $false
    }
}

# Fonction pour effectuer un rollback vers une version précédente
function Invoke-VersionRollback {
    param (
        [string]$QdrantUrl,
        [string]$VersionsPath,
        [string]$VersionId,
        [string]$SnapshotPath,
        [string]$TargetCollectionName,
        [int]$BatchSize,
        [switch]$KeepCurrent
    )
    
    $rollbackScriptPath = Join-Path -Path $scriptPath -ChildPath "Invoke-EmbeddingRollback.ps1"
    
    if (Test-Path -Path $rollbackScriptPath) {
        & $rollbackScriptPath -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -VersionId $VersionId -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -BatchSize $BatchSize -KeepCurrent:$KeepCurrent -Force:$Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Rollback vers la version précédente terminé avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors du rollback vers la version précédente." -Level "Error"
            return $false
        }
    } else {
        Write-Log "Script de rollback des embeddings introuvable: $rollbackScriptPath" -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-RoadmapVectorSync {
    param (
        [string]$RoadmapPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName,
        [string]$ModelVersion,
        [string]$OutputDirectory,
        [string]$SyncMode,
        [string]$VersionsPath,
        [string]$SnapshotPath,
        [string]$TargetCollectionName,
        [string]$SourceVersionId,
        [int]$BatchSize,
        [switch]$KeepSource,
        [switch]$Force
    )
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Exécuter l'action demandée
    switch ($SyncMode) {
        "Full" {
            # Synchronisation complète (vectorisation de toute la roadmap)
            Write-Log "Exécution d'une synchronisation complète..." -Level "Info"
            
            $vectorizeScriptPath = Join-Path -Path $scriptPath -ChildPath "Invoke-RoadmapRAG.ps1"
            
            if (Test-Path -Path $vectorizeScriptPath) {
                # Analyser la roadmap
                $analysisScriptPath = Join-Path -Path $scriptPath -ChildPath "Simple-RoadmapAnalysis.ps1"
                $inventoryPath = Join-Path -Path $OutputDirectory -ChildPath "inventory.json"
                
                if (Test-Path -Path $analysisScriptPath) {
                    & $analysisScriptPath -Action "Inventory" -RoadmapPath $RoadmapPath -OutputPath $inventoryPath -Force:$Force
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-Log "Erreur lors de l'analyse de la roadmap." -Level "Error"
                        return $false
                    }
                } else {
                    Write-Log "Script d'analyse de la roadmap introuvable: $analysisScriptPath" -Level "Error"
                    return $false
                }
                
                # Vectoriser la roadmap
                & $vectorizeScriptPath -Action "Vectorize" -InventoryPath $inventoryPath -Collection $CollectionName -Host $QdrantUrl -Model $ModelName -Force:$Force
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Vectorisation complète terminée avec succès." -Level "Success"
                    
                    # Enregistrer la version
                    Register-EmbeddingVersion -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion
                    
                    return $true
                } else {
                    Write-Log "Erreur lors de la vectorisation complète." -Level "Error"
                    return $false
                }
            } else {
                Write-Log "Script de vectorisation introuvable: $vectorizeScriptPath" -Level "Error"
                return $false
            }
        }
        "Selective" {
            # Mise à jour sélective des vecteurs
            Write-Log "Exécution d'une mise à jour sélective..." -Level "Info"
            
            # Détecter les changements
            $changesPath = Invoke-ChangeDetection -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory
            
            if ($changesPath) {
                # Mettre à jour sélectivement les vecteurs
                $result = Update-VectorsSelectively -RoadmapPath $RoadmapPath -ChangesPath $changesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName
                
                if ($result) {
                    # Enregistrer la version
                    Register-EmbeddingVersion -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion
                }
                
                return $result
            } else {
                Write-Log "Aucun changement détecté ou erreur lors de la détection." -Level "Info"
                return $false
            }
        }
        "Detect" {
            # Détection des changements uniquement
            Write-Log "Exécution de la détection des changements..." -Level "Info"
            
            $changesPath = Invoke-ChangeDetection -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory
            
            if ($changesPath) {
                Write-Log "Détection des changements terminée avec succès." -Level "Success"
                Write-Log "Fichier de changements: $changesPath" -Level "Info"
                return $true
            } else {
                Write-Log "Aucun changement détecté ou erreur lors de la détection." -Level "Info"
                return $false
            }
        }
        "Propagate" {
            # Propagation des changements
            Write-Log "Exécution de la propagation des changements..." -Level "Info"
            
            # Vérifier si le fichier de changements existe
            $changesPath = Join-Path -Path $OutputDirectory -ChildPath "changes.json"
            
            if (-not (Test-Path -Path $changesPath)) {
                # Détecter les changements
                $changesPath = Invoke-ChangeDetection -RoadmapPath $RoadmapPath -OutputDirectory $OutputDirectory
                
                if (-not $changesPath) {
                    Write-Log "Aucun changement détecté ou erreur lors de la détection." -Level "Info"
                    return $false
                }
            }
            
            # Propager les changements
            $result = Invoke-ChangePropagation -RoadmapPath $RoadmapPath -ChangesPath $changesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName
            
            return $result
        }
        "Version" {
            # Gestion des versions d'embedding
            Write-Log "Exécution de la gestion des versions d'embedding..." -Level "Info"
            
            if ($SnapshotPath) {
                # Créer un snapshot
                $result = Create-EmbeddingSnapshot -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath
            } else {
                # Enregistrer une version
                $result = Register-EmbeddingVersion -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion
            }
            
            return $result
        }
        "Migrate" {
            # Migration vers un nouveau modèle
            Write-Log "Exécution de la migration vers un nouveau modèle..." -Level "Info"
            
            $result = Migrate-ToNewModel -QdrantUrl $QdrantUrl -SourceCollectionName $CollectionName -TargetCollectionName $TargetCollectionName -SourceVersionId $SourceVersionId -SnapshotPath $SnapshotPath -NewModelName $ModelName -NewModelVersion $ModelVersion -VersionsPath $VersionsPath -BatchSize $BatchSize -KeepSource:$KeepSource
            
            return $result
        }
        "Rollback" {
            # Rollback vers une version précédente
            Write-Log "Exécution du rollback vers une version précédente..." -Level "Info"
            
            $result = Invoke-VersionRollback -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -VersionId $SourceVersionId -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -BatchSize $BatchSize -KeepCurrent:$KeepSource
            
            return $result
        }
    }
}

# Exécuter la fonction principale
Invoke-RoadmapVectorSync -RoadmapPath $RoadmapPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -ModelVersion $ModelVersion -OutputDirectory $OutputDirectory -SyncMode $SyncMode -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -SourceVersionId $SourceVersionId -BatchSize $BatchSize -KeepSource:$KeepSource -Force:$Force
