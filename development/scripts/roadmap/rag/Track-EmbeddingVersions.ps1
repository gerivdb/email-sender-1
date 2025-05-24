# Trace-EmbeddingVersions.ps1
# Script pour suivre les versions d'embeddings dans Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$VersionsPath = "projet/roadmaps/vectors/embedding_versions.json",
    
    [Parameter(Mandatory = $false)]
    [string]$ModelName,
    
    [Parameter(Mandatory = $false)]
    [string]$ModelVersion,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Register", "List", "Get", "Snapshot")]
    [string]$Action = "List",
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotPath,
    
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
function New-PythonVersionScript {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$ModelName,
        [string]$ModelVersion,
        [string]$Action,
        [string]$SnapshotPath,
        [bool]$Force
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $pythonScript = @"
# Script Python temporaire pour le suivi des versions d'embeddings
import os
import json
import logging
import sys
import time
import hashlib
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
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    from qdrant_client.http.exceptions import UnexpectedResponse
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install qdrant-client")
    sys.exit(1)

# Paramètres
qdrant_url = "$QdrantUrl"
collection_name = "$CollectionName"
versions_path = "$VersionsPath"
model_name = "$ModelName"
model_version = "$ModelVersion"
action = "$Action"
snapshot_path = "$SnapshotPath"
force = $($Force.ToString().ToLower())

# Classe pour le suivi des versions d'embeddings
class EmbeddingVersionTracker:
    def __init__(self, url, collection_name, versions_path):
        self.url = url
        self.collection_name = collection_name
        self.versions_path = versions_path
        self.client = QdrantClient(url=url)
        
        # Vérifier si la collection existe
        collections = self.client.get_collections().collections
        collection_exists = any(c.name == collection_name for c in collections)
        
        if not collection_exists:
            logger.error(f"La collection {collection_name} n'existe pas.")
            sys.exit(1)
        
        # Charger les versions existantes
        self.versions = self._load_versions()
    
    def _load_versions(self):
        """Charge les versions existantes depuis le fichier"""
        if os.path.exists(self.versions_path):
            try:
                with open(self.versions_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.warning(f"Erreur lors du chargement des versions: {str(e)}")
                return {"versions": [], "current_version": None}
        else:
            return {"versions": [], "current_version": None}
    
    def _save_versions(self):
        """Enregistre les versions dans le fichier"""
        # Créer le répertoire si nécessaire
        os.makedirs(os.path.dirname(self.versions_path), exist_ok=True)
        
        with open(self.versions_path, "w", encoding="utf-8") as f:
            json.dump(self.versions, f, indent=2)
    
    def _generate_version_id(self, model_name, model_version):
        """Génère un identifiant unique pour la version"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        hash_input = f"{model_name}_{model_version}_{timestamp}"
        hash_value = hashlib.md5(hash_input.encode()).hexdigest()[:8]
        return f"{model_name.replace('-', '_')}_{timestamp}_{hash_value}"
    
    def register_version(self, model_name, model_version):
        """Enregistre une nouvelle version d'embedding"""
        # Vérifier si la version existe déjà
        for version in self.versions["versions"]:
            if version["model_name"] == model_name and version["model_version"] == model_version:
                logger.warning(f"La version {model_name} {model_version} existe déjà.")
                return version
        
        # Obtenir des informations sur la collection
        collection_info = self.client.get_collection(collection_name=self.collection_name)
        
        # Générer un identifiant unique pour la version
        version_id = self._generate_version_id(model_name, model_version)
        
        # Créer la nouvelle version
        new_version = {
            "id": version_id,
            "model_name": model_name,
            "model_version": model_version,
            "created_at": datetime.now().isoformat(),
            "vector_size": collection_info.config.params.vectors.size,
            "vector_distance": str(collection_info.config.params.vectors.distance),
            "point_count": collection_info.vectors_count,
            "collection_name": self.collection_name
        }
        
        # Ajouter la version à la liste
        self.versions["versions"].append(new_version)
        
        # Définir comme version courante
        self.versions["current_version"] = version_id
        
        # Enregistrer les versions
        self._save_versions()
        
        logger.info(f"Version {version_id} enregistrée avec succès.")
        return new_version
    
    def list_versions(self):
        """Liste toutes les versions d'embedding"""
        if not self.versions["versions"]:
            logger.info("Aucune version d'embedding enregistrée.")
            return []
        
        logger.info(f"Versions d'embedding enregistrées ({len(self.versions['versions'])}):")
        for i, version in enumerate(self.versions["versions"]):
            current = " (courante)" if version["id"] == self.versions["current_version"] else ""
            logger.info(f"{i+1}. {version['id']} - {version['model_name']} {version['model_version']} - {version['created_at']}{current}")
        
        return self.versions["versions"]
    
    def get_version(self, version_id=None):
        """Obtient les détails d'une version spécifique"""
        if not version_id:
            # Utiliser la version courante
            version_id = self.versions["current_version"]
        
        if not version_id:
            logger.error("Aucune version courante définie.")
            return None
        
        for version in self.versions["versions"]:
            if version["id"] == version_id:
                logger.info(f"Version {version_id}:")
                for key, value in version.items():
                    logger.info(f"  - {key}: {value}")
                return version
        
        logger.error(f"Version {version_id} non trouvée.")
        return None
    
    def create_snapshot(self, version_id=None, snapshot_path=None):
        """Crée un snapshot de la collection pour une version spécifique"""
        if not version_id:
            # Utiliser la version courante
            version_id = self.versions["current_version"]
        
        if not version_id:
            logger.error("Aucune version courante définie.")
            return False
        
        # Trouver la version
        version = None
        for v in self.versions["versions"]:
            if v["id"] == version_id:
                version = v
                break
        
        if not version:
            logger.error(f"Version {version_id} non trouvée.")
            return False
        
        # Définir le chemin du snapshot
        if not snapshot_path:
            snapshot_dir = os.path.join(os.path.dirname(self.versions_path), "snapshots")
            os.makedirs(snapshot_dir, exist_ok=True)
            snapshot_path = os.path.join(snapshot_dir, f"{version_id}.json")
        
        # Vérifier si le snapshot existe déjà
        if os.path.exists(snapshot_path) and not force:
            logger.error(f"Le snapshot existe déjà: {snapshot_path}. Utilisez -Force pour l'écraser.")
            return False
        
        # Récupérer tous les points de la collection
        logger.info(f"Création d'un snapshot pour la version {version_id}...")
        
        points = []
        offset = None
        limit = 100
        
        while True:
            scroll_result = self.client.scroll(
                collection_name=self.collection_name,
                limit=limit,
                offset=offset
            )
            
            batch = scroll_result[0]
            if not batch:
                break
            
            for point in batch:
                points.append({
                    "id": point.id,
                    "vector": point.vector,
                    "payload": point.payload
                })
            
            offset = scroll_result[1]
            if offset is None:
                break
        
        # Créer le snapshot
        snapshot = {
            "version": version,
            "created_at": datetime.now().isoformat(),
            "points_count": len(points),
            "points": points
        }
        
        # Enregistrer le snapshot
        with open(snapshot_path, "w", encoding="utf-8") as f:
            json.dump(snapshot, f, indent=2)
        
        logger.info(f"Snapshot créé avec succès: {snapshot_path}")
        logger.info(f"  - Points: {len(points)}")
        
        # Mettre à jour la version avec le chemin du snapshot
        for v in self.versions["versions"]:
            if v["id"] == version_id:
                v["snapshot_path"] = snapshot_path
                v["snapshot_created_at"] = datetime.now().isoformat()
                break
        
        # Enregistrer les versions
        self._save_versions()
        
        return True

# Fonction principale
def main():
    # Créer le tracker de versions
    tracker = EmbeddingVersionTracker(
        url=qdrant_url,
        collection_name=collection_name,
        versions_path=versions_path
    )
    
    # Exécuter l'action demandée
    if action == "Register":
        if not model_name:
            logger.error("Le nom du modèle est requis pour l'action Register.")
            sys.exit(1)
        
        if not model_version:
            logger.error("La version du modèle est requise pour l'action Register.")
            sys.exit(1)
        
        tracker.register_version(model_name, model_version)
    
    elif action == "List":
        tracker.list_versions()
    
    elif action == "Get":
        tracker.get_version()
    
    elif action == "Snapshot":
        if not snapshot_path and not os.path.exists(os.path.dirname(versions_path)):
            os.makedirs(os.path.dirname(versions_path), exist_ok=True)
        
        tracker.create_snapshot(snapshot_path=snapshot_path)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    return $tempFile
}

# Fonction principale
function Trace-EmbeddingVersions {
    param (
        [string]$QdrantUrl,
        [string]$CollectionName,
        [string]$VersionsPath,
        [string]$ModelName,
        [string]$ModelVersion,
        [string]$Action,
        [string]$SnapshotPath,
        [switch]$Force
    )
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Vérifier les paramètres requis selon l'action
    if ($Action -eq "Register" -and (-not $ModelName -or -not $ModelVersion)) {
        Write-Log "Le nom et la version du modèle sont requis pour l'action Register." -Level "Error"
        return $false
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour le suivi des versions d'embeddings..." -Level "Info"
    $pythonScript = New-PythonVersionScript -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion -Action $Action -SnapshotPath $SnapshotPath -Force $Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour le suivi des versions d'embeddings..." -Level "Info"
    python $pythonScript
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Suivi des versions d'embeddings terminé avec succès." -Level "Success"
        $result = $true
    } else {
        Write-Log "Erreur lors du suivi des versions d'embeddings." -Level "Error"
        $result = $false
    }
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    return $result
}

# Exécuter la fonction principale
Trace-EmbeddingVersions -QdrantUrl $QdrantUrl -CollectionName $CollectionName -VersionsPath $VersionsPath -ModelName $ModelName -ModelVersion $ModelVersion -Action $Action -SnapshotPath $SnapshotPath -Force:$Force

