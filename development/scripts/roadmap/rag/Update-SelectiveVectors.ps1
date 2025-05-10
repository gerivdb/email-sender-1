# Update-SelectiveVectors.ps1
# Script pour mettre à jour sélectivement les vecteurs dans Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$ChangesPath,
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName = "all-MiniLM-L6-v2",
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkSize = 512,
    
    [Parameter(Mandatory = $false)]
    [int]$ChunkOverlap = 50,
    
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

# Fonction pour créer un script Python temporaire
function New-PythonUpdateScript {
    param (
        [string]$RoadmapPath,
        [string]$ChangesPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName,
        [int]$ChunkSize,
        [int]$ChunkOverlap,
        [bool]$Force
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $pythonScript = @"
# Script Python temporaire pour la mise à jour sélective des vecteurs
import os
import json
import logging
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

try:
    from sentence_transformers import SentenceTransformer
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install sentence-transformers qdrant-client")
    sys.exit(1)

def main():
    # Paramètres
    roadmap_path = "$RoadmapPath"
    changes_path = "$ChangesPath"
    qdrant_url = "$QdrantUrl"
    collection_name = "$CollectionName"
    model_name = "$ModelName"
    chunk_size = $ChunkSize
    chunk_overlap = $ChunkOverlap
    force = $($Force.ToString().ToLower())
    
    # Vérifier si les fichiers existent
    if not os.path.exists(roadmap_path):
        logger.error(f"Le fichier roadmap n'existe pas: {roadmap_path}")
        sys.exit(1)
    
    if not os.path.exists(changes_path):
        logger.error(f"Le fichier de changements n'existe pas: {changes_path}")
        sys.exit(1)
    
    # Charger les changements
    with open(changes_path, "r", encoding="utf-8") as f:
        changes = json.load(f)
    
    # Vérifier s'il y a des changements
    if not changes.get("HasChanges", False):
        logger.info("Aucun changement détecté. Aucune mise à jour nécessaire.")
        sys.exit(0)
    
    # Charger le contenu de la roadmap
    with open(roadmap_path, "r", encoding="utf-8") as f:
        roadmap_content = f.read()
    
    # Initialiser le modèle d'embedding
    logger.info(f"Initialisation du modèle d'embedding: {model_name}")
    model = SentenceTransformer(model_name)
    
    # Connexion à Qdrant
    logger.info(f"Connexion à Qdrant: {qdrant_url}")
    client = QdrantClient(url=qdrant_url)
    
    # Vérifier si la collection existe
    collections = client.get_collections().collections
    collection_exists = any(c.name == collection_name for c in collections)
    
    if not collection_exists:
        logger.error(f"La collection {collection_name} n'existe pas.")
        sys.exit(1)
    
    # Extraire les tâches modifiées
    content_changes = changes.get("ContentChanges", {})
    task_movements = changes.get("TaskMovements", {})
    
    # Tâches à mettre à jour
    tasks_to_update = []
    
    # Ajouter les tâches ajoutées
    if "Changes" in content_changes and "Added" in content_changes["Changes"]:
        for task in content_changes["Changes"]["Added"]:
            tasks_to_update.append({
                "task_id": task.get("TaskId"),
                "description": task.get("Description"),
                "status": task.get("Status", "Incomplete"),
                "change_type": "Added"
            })
    
    # Ajouter les tâches modifiées
    if "Changes" in content_changes and "Modified" in content_changes["Changes"]:
        for task in content_changes["Changes"]["Modified"]:
            tasks_to_update.append({
                "task_id": task.get("TaskId"),
                "description": task.get("NewDescription"),
                "change_type": "Modified"
            })
    
    # Ajouter les tâches avec statut changé
    if "Changes" in content_changes and "StatusChanged" in content_changes["Changes"]:
        for task in content_changes["Changes"]["StatusChanged"]:
            tasks_to_update.append({
                "task_id": task.get("TaskId"),
                "description": task.get("Description"),
                "status": task.get("NewStatus"),
                "change_type": "StatusChanged"
            })
    
    # Ajouter les tâches déplacées
    if "Movements" in task_movements and "ContextChanges" in task_movements["Movements"]:
        for task in task_movements["Movements"]["ContextChanges"]:
            tasks_to_update.append({
                "task_id": task.get("TaskId"),
                "description": task.get("Description"),
                "context": task.get("NewContext"),
                "change_type": "ContextChanged"
            })
    
    # Ajouter les tâches avec parent changé
    if "Movements" in task_movements and "ParentChanges" in task_movements["Movements"]:
        for task in task_movements["Movements"]["ParentChanges"]:
            tasks_to_update.append({
                "task_id": task.get("TaskId"),
                "description": task.get("Description"),
                "parent_id": task.get("NewParentId"),
                "change_type": "ParentChanged"
            })
    
    # Supprimer les doublons (une tâche peut avoir plusieurs types de changements)
    unique_tasks = {}
    for task in tasks_to_update:
        if task["task_id"] not in unique_tasks:
            unique_tasks[task["task_id"]] = task
    
    tasks_to_update = list(unique_tasks.values())
    
    logger.info(f"Nombre de tâches à mettre à jour: {len(tasks_to_update)}")
    
    # Tâches à supprimer
    tasks_to_delete = []
    
    # Ajouter les tâches supprimées
    if "Changes" in content_changes and "Removed" in content_changes["Changes"]:
        for task in content_changes["Changes"]["Removed"]:
            tasks_to_delete.append(task.get("TaskId"))
    
    logger.info(f"Nombre de tâches à supprimer: {len(tasks_to_delete)}")
    
    # Supprimer les tâches
    if tasks_to_delete:
        logger.info("Suppression des tâches...")
        
        for task_id in tasks_to_delete:
            # Rechercher les points correspondant à cette tâche
            search_result = client.scroll(
                collection_name=collection_name,
                scroll_filter=models.Filter(
                    must=[
                        models.FieldCondition(
                            key="payload.task_id",
                            match=models.MatchValue(value=task_id)
                        )
                    ]
                ),
                limit=100
            )
            
            points = search_result[0]
            
            if points:
                # Supprimer les points
                point_ids = [point.id for point in points]
                client.delete(
                    collection_name=collection_name,
                    points_selector=models.PointIdsList(
                        points=point_ids
                    )
                )
                logger.info(f"  - Tâche {task_id} supprimée ({len(point_ids)} points)")
    
    # Mettre à jour les tâches
    if tasks_to_update:
        logger.info("Mise à jour des tâches...")
        
        for task in tasks_to_update:
            task_id = task["task_id"]
            
            # Extraire le texte de la tâche
            task_text = f"ID: {task_id} | Description: {task.get('description', '')}"
            if "status" in task:
                task_text += f" | Status: {task['status']}"
            if "context" in task:
                task_text += f" | Context: {task['context']}"
            if "parent_id" in task:
                task_text += f" | Parent: {task['parent_id']}"
            
            # Générer l'embedding
            embedding = model.encode(task_text)
            
            # Rechercher les points correspondant à cette tâche
            search_result = client.scroll(
                collection_name=collection_name,
                scroll_filter=models.Filter(
                    must=[
                        models.FieldCondition(
                            key="payload.task_id",
                            match=models.MatchValue(value=task_id)
                        )
                    ]
                ),
                limit=100
            )
            
            points = search_result[0]
            
            if points:
                # Mettre à jour les points existants
                for point in points:
                    # Mettre à jour le payload
                    payload = point.payload
                    
                    if "description" in task:
                        payload["description"] = task["description"]
                    
                    if "status" in task:
                        payload["status"] = task["status"]
                    
                    if "context" in task:
                        payload["context"] = task["context"]
                    
                    if "parent_id" in task:
                        payload["parent_id"] = task["parent_id"]
                    
                    # Ajouter l'historique des modifications
                    if "history" not in payload:
                        payload["history"] = []
                    
                    payload["history"].append({
                        "timestamp": datetime.now().isoformat(),
                        "change_type": task["change_type"]
                    })
                    
                    # Mettre à jour la date de dernière modification
                    payload["last_updated"] = datetime.now().isoformat()
                    
                    # Mettre à jour le texte
                    payload["text"] = task_text
                    
                    # Mettre à jour le point dans Qdrant
                    client.update_vectors(
                        collection_name=collection_name,
                        points=[
                            models.PointVectors(
                                id=point.id,
                                vector=embedding.tolist()
                            )
                        ]
                    )
                    
                    client.update_payload(
                        collection_name=collection_name,
                        payload=payload,
                        points=[point.id]
                    )
                
                logger.info(f"  - Tâche {task_id} mise à jour ({len(points)} points)")
            else:
                # Créer un nouveau point
                point_id = f"task_{task_id}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
                
                payload = {
                    "task_id": task_id,
                    "description": task.get("description", ""),
                    "status": task.get("status", "Incomplete"),
                    "context": task.get("context", ""),
                    "parent_id": task.get("parent_id", ""),
                    "text": task_text,
                    "last_updated": datetime.now().isoformat(),
                    "history": [
                        {
                            "timestamp": datetime.now().isoformat(),
                            "change_type": task["change_type"]
                        }
                    ]
                }
                
                client.upsert(
                    collection_name=collection_name,
                    points=[
                        models.PointStruct(
                            id=point_id,
                            vector=embedding.tolist(),
                            payload=payload
                        )
                    ]
                )
                
                logger.info(f"  - Tâche {task_id} créée (nouveau point)")
    
    logger.info("Mise à jour sélective terminée avec succès!")

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    return $tempFile
}

# Fonction principale
function Update-SelectiveVectors {
    param (
        [string]$RoadmapPath,
        [string]$ChangesPath,
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$ModelName,
        [int]$ChunkSize,
        [int]$ChunkOverlap,
        [switch]$Force
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "Error"
        return $false
    }
    
    if (-not (Test-Path -Path $ChangesPath)) {
        Write-Log "Le fichier de changements n'existe pas: $ChangesPath" -Level "Error"
        return $false
    }
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour la mise à jour sélective des vecteurs..." -Level "Info"
    $pythonScript = New-PythonUpdateScript -RoadmapPath $RoadmapPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -ChunkSize $ChunkSize -ChunkOverlap $ChunkOverlap -Force $Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour la mise à jour sélective des vecteurs..." -Level "Info"
    python $pythonScript
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Mise à jour sélective des vecteurs terminée avec succès." -Level "Success"
        $result = $true
    } else {
        Write-Log "Erreur lors de la mise à jour sélective des vecteurs." -Level "Error"
        $result = $false
    }
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    return $result
}

# Exécuter la fonction principale
Update-SelectiveVectors -RoadmapPath $RoadmapPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -ModelName $ModelName -ChunkSize $ChunkSize -ChunkOverlap $ChunkOverlap -Force:$Force
