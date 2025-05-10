# Test-EmbeddingVersioning.ps1
# Script de test pour le système de versionnage des embeddings
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis/test/output",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks_test",

    [Parameter(Mandatory = $false)]
    [string]$VersionsPath = "projet/roadmaps/analysis/test/output/embedding_versions.json",

    [Parameter(Mandatory = $false)]
    [string]$SnapshotPath = "projet/roadmaps/analysis/test/output/embedding_snapshot.json",

    [Parameter(Mandatory = $false)]
    [string]$ModelName1 = "all-MiniLM-L6-v2",

    [Parameter(Mandatory = $false)]
    [string]$ModelVersion1 = "1.0",

    [Parameter(Mandatory = $false)]
    [string]$ModelName2 = "all-mpnet-base-v2",

    [Parameter(Mandatory = $false)]
    [string]$ModelVersion2 = "1.0",

    [Parameter(Mandatory = $false)]
    [switch]$Cleanup,

    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }

        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$HostName = "localhost",
        [int]$Port = 6333
    )

    try {
        $null = Invoke-RestMethod -Uri "http://$HostName`:$Port/collections" -Method Get -ErrorAction Stop
        return $true
    } catch {
        Write-Log "Impossible de se connecter à Qdrant ($HostName`:$Port): $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer une collection de test
function New-TestCollection {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [switch]$Force
    )

    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -HostName ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }

    # Créer un script Python temporaire
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $pythonScript = @"
import sys
import logging
from qdrant_client import QdrantClient
from qdrant_client.http import models

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Paramètres
qdrant_url = "$QdrantUrl"
collection_name = "$CollectionName"
force = $($Force.ToString().ToLower() -eq "true")

# Connexion à Qdrant
client = QdrantClient(url=qdrant_url)

# Vérifier si la collection existe
collections = client.get_collections().collections
collection_exists = any(c.name == collection_name for c in collections)

if collection_exists:
    if force:
        logger.info(f"Suppression de la collection existante {collection_name}...")
        client.delete_collection(collection_name=collection_name)
    else:
        logger.info(f"La collection {collection_name} existe déjà.")
        sys.exit(0)

# Créer la collection
logger.info(f"Création de la collection {collection_name}...")
client.create_collection(
    collection_name=collection_name,
    vectors_config=models.VectorParams(
        size=384,  # Taille pour all-MiniLM-L6-v2
        distance=models.Distance.COSINE
    )
)

# Ajouter quelques points de test
points = []
for i in range(10):
    # Créer un vecteur aléatoire
    import numpy as np
    vector = np.random.rand(384).astype(np.float32)
    vector = vector / np.linalg.norm(vector)

    # Créer le point
    point = models.PointStruct(
        id=f"test_{i}",
        vector=vector.tolist(),
        payload={
            "text": f"Test point {i}",
            "metadata": {
                "created_at": "2025-05-15T12:00:00"
            }
        }
    )

    points.append(point)

# Insérer les points
client.upsert(
    collection_name=collection_name,
    points=points
)

logger.info(f"Collection {collection_name} créée avec succès.")
"@

    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    python $tempFile

    # Supprimer le script temporaire
    Remove-Item -Path $tempFile -Force

    return $LASTEXITCODE -eq 0
}

# Fonction pour nettoyer les collections de test
function Remove-TestCollections {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName
    )

    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }

    # Créer un script Python temporaire
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $pythonScript = @"
import sys
import logging
from qdrant_client import QdrantClient

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Paramètres
qdrant_url = "$QdrantUrl"
collection_name = "$CollectionName"

# Connexion à Qdrant
client = QdrantClient(url=qdrant_url)

# Obtenir toutes les collections
collections = client.get_collections().collections
collection_names = [c.name for c in collections]

# Supprimer les collections de test
for name in collection_names:
    if name == collection_name or name.startswith(f"{collection_name}_") or name.endswith("_rollback"):
        logger.info(f"Suppression de la collection {name}...")
        client.delete_collection(collection_name=name)
        logger.info(f"Collection {name} supprimée avec succès.")
"@

    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    python $tempFile

    # Supprimer le script temporaire
    Remove-Item -Path $tempFile -Force

    return $LASTEXITCODE -eq 0
}

# Fonction pour tester l'enregistrement d'une version d'embedding
function Test-RegisterEmbeddingVersion {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$ModelName,
        [string]$ModelVersion
    )

    $versionScriptPath = Join-Path -Path $parentPath -ChildPath "Track-EmbeddingVersions.ps1"

    if (-not (Test-Path -Path $versionScriptPath)) {
        Write-Log "Script de suivi des versions d'embedding introuvable: $versionScriptPath" -Level "Error"
        return $false
    }

    & $versionScriptPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion -Action "Register" -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Enregistrement de la version d'embedding terminé avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de l'enregistrement de la version d'embedding." -Level "Error"
        return $false
    }
}

# Fonction pour tester la création d'un snapshot
function Test-CreateEmbeddingSnapshot {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$SnapshotPath
    )

    $versionScriptPath = Join-Path -Path $parentPath -ChildPath "Track-EmbeddingVersions.ps1"

    if (-not (Test-Path -Path $versionScriptPath)) {
        Write-Log "Script de suivi des versions d'embedding introuvable: $versionScriptPath" -Level "Error"
        return $false
    }

    & $versionScriptPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -Action "Snapshot" -SnapshotPath $SnapshotPath -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Création du snapshot terminée avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de la création du snapshot." -Level "Error"
        return $false
    }
}

# Fonction pour tester la migration vers un nouveau modèle
function Test-MigrateEmbeddingModel {
    param (
        [string]$QdrantUrl,
        [string]$SourceCollectionName,
        [string]$TargetCollectionName,
        [string]$VersionsPath,
        [string]$NewModelName,
        [string]$NewModelVersion
    )

    $migrateScriptPath = Join-Path -Path $parentPath -ChildPath "Migrate-EmbeddingModel.ps1"

    if (-not (Test-Path -Path $migrateScriptPath)) {
        Write-Log "Script de migration des embeddings introuvable: $migrateScriptPath" -Level "Error"
        return $false
    }

    & $migrateScriptPath -QdrantUrl $QdrantUrl -SourceCollectionName $SourceCollectionName -TargetCollectionName $TargetCollectionName -VersionsPath $VersionsPath -NewModelName $NewModelName -NewModelVersion $NewModelVersion -KeepSource -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Migration vers le nouveau modèle terminée avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de la migration vers le nouveau modèle." -Level "Error"
        return $false
    }
}

# Fonction pour tester le rollback vers une version précédente
function Test-EmbeddingRollback {
    param (
        [string]$QdrantUrl,
        [string]$VersionsPath,
        [string]$SnapshotPath,
        [string]$TargetCollectionName
    )

    $rollbackScriptPath = Join-Path -Path $parentPath -ChildPath "Invoke-EmbeddingRollback.ps1"

    if (-not (Test-Path -Path $rollbackScriptPath)) {
        Write-Log "Script de rollback des embeddings introuvable: $rollbackScriptPath" -Level "Error"
        return $false
    }

    & $rollbackScriptPath -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -KeepCurrent -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Rollback vers la version précédente terminé avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors du rollback vers la version précédente." -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-EmbeddingVersioningTests {
    param (
        [string]$OutputDirectory,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$SnapshotPath,
        [string]$ModelName1,
        [string]$ModelVersion1,
        [string]$ModelName2,
        [string]$ModelVersion2,
        [switch]$Cleanup
    )

    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -HostName ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        Write-Log "Qdrant n'est pas en cours d'exécution. Impossible de continuer." -Level "Error"
        return $false
    }

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }

    # Créer la collection de test
    Write-Log "Création de la collection de test..." -Level "Info"
    $collectionCreated = New-TestCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force

    if (-not $collectionCreated) {
        Write-Log "Erreur lors de la création de la collection de test." -Level "Error"
        return $false
    }

    # Exécuter les tests
    $testResults = @{
        Total  = 0
        Passed = 0
        Failed = 0
    }

    # Test 1: Enregistrement d'une version d'embedding
    $testResults.Total++
    Write-Log "Test: Enregistrement d'une version d'embedding" -Level "Info"
    $result = Test-RegisterEmbeddingVersion -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName1 -ModelVersion $ModelVersion1

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Test 2: Création d'un snapshot
    $testResults.Total++
    Write-Log "Test: Création d'un snapshot" -Level "Info"
    $result = Test-CreateEmbeddingSnapshot -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Test 3: Migration vers un nouveau modèle
    $testResults.Total++
    $targetCollectionName = "${CollectionName}_migrated"
    Write-Log "Test: Migration vers un nouveau modèle" -Level "Info"
    $result = Test-MigrateEmbeddingModel -QdrantUrl $QdrantUrl -SourceCollectionName $CollectionName -TargetCollectionName $targetCollectionName -VersionsPath $VersionsPath -NewModelName $ModelName2 -NewModelVersion $ModelVersion2

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Test 4: Rollback vers une version précédente
    $testResults.Total++
    $rollbackCollectionName = "${CollectionName}_rollback"
    Write-Log "Test: Rollback vers une version précédente" -Level "Info"
    $result = Test-EmbeddingRollback -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath -TargetCollectionName $rollbackCollectionName

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Nettoyer les collections de test si demandé
    if ($Cleanup) {
        Write-Log "Nettoyage des collections de test..." -Level "Info"
        Remove-TestCollections -QdrantUrl $QdrantUrl -CollectionName $CollectionName
    }

    # Afficher les résultats
    Write-Log "Résultats des tests:" -Level "Info"
    Write-Log "  - Total: $($testResults.Total)" -Level "Info"
    Write-Log "  - Réussis: $($testResults.Passed)" -Level "Success"
    Write-Log "  - Échoués: $($testResults.Failed)" -Level "Error"

    return $testResults
}

# Exécuter les tests
Invoke-EmbeddingVersioningTests -OutputDirectory $OutputDirectory -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -SnapshotPath $SnapshotPath -ModelName1 $ModelName1 -ModelVersion1 $ModelVersion1 -ModelName2 $ModelName2 -ModelVersion2 $ModelVersion2 -Cleanup:$Cleanup
