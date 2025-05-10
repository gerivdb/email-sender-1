# Test-SelectiveVectorUpdate.ps1
# Script de test pour la mise à jour sélective des vecteurs
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDataDirectory = "projet/roadmaps/analysis/test/files",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis/test/output",

    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks_test",

    [Parameter(Mandatory = $false)]
    [string]$ModelName = "all-MiniLM-L6-v2",

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
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
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

logger.info(f"Collection {collection_name} créée avec succès.")
"@

    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    python $tempFile

    # Supprimer le script temporaire
    Remove-Item -Path $tempFile -Force

    return $LASTEXITCODE -eq 0
}

# Fonction pour initialiser la collection avec des données de test
function Initialize-TestCollection {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$RoadmapPath
    )

    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -HostName ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }

    # Vérifier si le fichier roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "Error"
        return $false
    }

    # Créer un script Python temporaire
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"

    $pythonScript = @"
import os
import sys
import logging
import re
from datetime import datetime
from sentence_transformers import SentenceTransformer
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
roadmap_path = "$RoadmapPath"

# Connexion à Qdrant
client = QdrantClient(url=qdrant_url)

# Charger le modèle d'embedding
model = SentenceTransformer("all-MiniLM-L6-v2")

# Charger le contenu du fichier roadmap
with open(roadmap_path, "r", encoding="utf-8") as f:
    content = f.read()

# Extraire les tâches
tasks = []
lines = content.split("\n")
current_headers = []

for line in lines:
    # Détecter les en-têtes
    header_match = re.match(r'^(#+)\s+(.+)$', line)
    if header_match:
        level = len(header_match.group(1))
        title = header_match.group(2).strip()

        # Ajuster les en-têtes actuels
        current_headers = current_headers[:level-1]
        if len(current_headers) < level:
            current_headers.extend([""] * (level - len(current_headers)))
        current_headers[level-1] = title

    # Détecter les tâches
    task_match = re.match(r'^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$', line)
    if task_match:
        status = "Completed" if task_match.group(1) != " " else "Incomplete"
        task_id = task_match.group(2)
        description = task_match.group(3).strip()

        if task_id:
            tasks.append({
                "task_id": task_id,
                "description": description,
                "status": status,
                "context": " > ".join(filter(None, current_headers)),
                "original_line": line
            })

# Vectoriser les tâches
points = []
for i, task in enumerate(tasks):
    # Générer le texte pour l'embedding
    text = f"ID: {task['task_id']} | Description: {task['description']} | Status: {task['status']} | Context: {task['context']}"

    # Générer l'embedding
    embedding = model.encode(text)

    # Créer le point
    point = models.PointStruct(
        id=f"task_{i}",
        vector=embedding.tolist(),
        payload={
            "task_id": task["task_id"],
            "description": task["description"],
            "status": task["status"],
            "context": task["context"],
            "text": text,
            "last_updated": datetime.now().isoformat(),
            "history": [
                {
                    "timestamp": datetime.now().isoformat(),
                    "change_type": "Initial"
                }
            ]
        }
    )

    points.append(point)

# Insérer les points dans Qdrant
if points:
    logger.info(f"Insertion de {len(points)} points dans Qdrant...")
    client.upsert(
        collection_name=collection_name,
        points=points
    )
    logger.info("Insertion terminée avec succès.")
else:
    logger.warning("Aucune tâche trouvée dans le fichier roadmap.")

logger.info(f"Collection {collection_name} initialisée avec succès.")
"@

    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    python $tempFile

    # Supprimer le script temporaire
    Remove-Item -Path $tempFile -Force

    return $LASTEXITCODE -eq 0
}

# Fonction pour nettoyer la collection de test
function Remove-TestCollection {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName
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

# Vérifier si la collection existe
collections = client.get_collections().collections
collection_exists = any(c.name == collection_name for c in collections)

if collection_exists:
    logger.info(f"Suppression de la collection {collection_name}...")
    client.delete_collection(collection_name=collection_name)
    logger.info(f"Collection {collection_name} supprimée avec succès.")
else:
    logger.info(f"La collection {collection_name} n'existe pas.")
"@

    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8

    # Exécuter le script Python
    python $tempFile

    # Supprimer le script temporaire
    Remove-Item -Path $tempFile -Force

    return $LASTEXITCODE -eq 0
}

# Fonction pour tester la mise à jour sélective des vecteurs
function Test-SelectiveVectorUpdate {
    param (
        [string]$OriginalPath,
        [string]$ModifiedPath,
        [string]$ChangesPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName
    )

    # Détecter les changements
    $detectScriptPath = Join-Path -Path $parentPath -ChildPath "Detect-RoadmapChanges.ps1"

    if (-not (Test-Path -Path $detectScriptPath)) {
        Write-Log "Script de détection des changements introuvable: $detectScriptPath" -Level "Error"
        return $false
    }

    & $detectScriptPath -OriginalPath $OriginalPath -NewPath $ModifiedPath -OutputPath $ChangesPath -OutputFormat "Json" -Force

    if ($LASTEXITCODE -ne 0) {
        Write-Log "Erreur lors de la détection des changements." -Level "Error"
        return $false
    }

    # Mettre à jour sélectivement les vecteurs
    $updateScriptPath = Join-Path -Path $parentPath -ChildPath "Update-SelectiveVectors.ps1"

    if (-not (Test-Path -Path $updateScriptPath)) {
        Write-Log "Script de mise à jour sélective des vecteurs introuvable: $updateScriptPath" -Level "Error"
        return $false
    }

    & $updateScriptPath -RoadmapPath $ModifiedPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -Force

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Mise à jour sélective des vecteurs terminée avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de la mise à jour sélective des vecteurs." -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-SelectiveVectorUpdateTests {
    param (
        [string]$TestDataDirectory,
        [string]$OutputDirectory,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName,
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

    # Utiliser les fichiers de test existants
    $testChangeDetectionPath = Join-Path -Path $scriptPath -ChildPath "Test-ChangeDetection.ps1"

    if (Test-Path -Path $testChangeDetectionPath) {
        & $testChangeDetectionPath -TestDataDirectory $TestDataDirectory -OutputDirectory $OutputDirectory -Verbose:$false
    } else {
        Write-Log "Script de test de détection des changements introuvable: $testChangeDetectionPath" -Level "Error"
        return $false
    }

    # Initialiser la collection avec les données de test
    $originalPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_original.md"

    if (-not (Test-Path -Path $originalPath)) {
        Write-Log "Fichier roadmap original introuvable: $originalPath" -Level "Error"
        return $false
    }

    Write-Log "Initialisation de la collection de test..." -Level "Info"
    $collectionInitialized = Initialize-TestCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName -RoadmapPath $originalPath

    if (-not $collectionInitialized) {
        Write-Log "Erreur lors de l'initialisation de la collection de test." -Level "Error"
        return $false
    }

    # Exécuter les tests
    $testResults = @{
        Total  = 0
        Passed = 0
        Failed = 0
    }

    # Test 1: Mise à jour avec ajouts
    $testResults.Total++
    $addedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_added.md"
    $changesPath = Join-Path -Path $OutputDirectory -ChildPath "changes_added.json"

    Write-Log "Test: Mise à jour avec ajouts" -Level "Info"
    $result = Test-SelectiveVectorUpdate -OriginalPath $originalPath -ModifiedPath $addedPath -ChangesPath $changesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Test 2: Mise à jour avec modifications
    $testResults.Total++
    $modifiedPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_modified.md"
    $changesPath = Join-Path -Path $OutputDirectory -ChildPath "changes_modified.json"

    Write-Log "Test: Mise à jour avec modifications" -Level "Info"
    $result = Test-SelectiveVectorUpdate -OriginalPath $originalPath -ModifiedPath $modifiedPath -ChangesPath $changesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Test 3: Mise à jour avec changements de statut
    $testResults.Total++
    $statusPath = Join-Path -Path $TestDataDirectory -ChildPath "roadmap_status.md"
    $changesPath = Join-Path -Path $OutputDirectory -ChildPath "changes_status.json"

    Write-Log "Test: Mise à jour avec changements de statut" -Level "Info"
    $result = Test-SelectiveVectorUpdate -OriginalPath $originalPath -ModifiedPath $statusPath -ChangesPath $changesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName

    if ($result) { $testResults.Passed++ } else { $testResults.Failed++ }

    # Nettoyer la collection de test si demandé
    if ($Cleanup) {
        Write-Log "Nettoyage de la collection de test..." -Level "Info"
        Remove-TestCollection -QdrantUrl $QdrantUrl -CollectionName $CollectionName
    }

    # Afficher les résultats
    Write-Log "Résultats des tests:" -Level "Info"
    Write-Log "  - Total: $($testResults.Total)" -Level "Info"
    Write-Log "  - Réussis: $($testResults.Passed)" -Level "Success"
    Write-Log "  - Échoués: $($testResults.Failed)" -Level "Error"

    return $testResults
}

# Exécuter les tests
Invoke-SelectiveVectorUpdateTests -TestDataDirectory $TestDataDirectory -OutputDirectory $OutputDirectory -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -Cleanup:$Cleanup
