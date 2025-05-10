# Invoke-EmbeddingRollback.ps1
# Script pour effectuer un rollback vers une version précédente des embeddings
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$VersionsPath = "projet/roadmaps/vectors/embedding_versions.json",
    
    [Parameter(Mandatory = $false)]
    [string]$VersionId,
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotPath,
    
    [Parameter(Mandatory = $false)]
    [string]$TargetCollectionName,
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 100,
    
    [Parameter(Mandatory = $false)]
    [switch]$KeepCurrent,
    
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
function New-PythonRollbackScript {
    param (
        [string]$QdrantUrl,
        [string]$VersionsPath,
        [string]$VersionId,
        [string]$SnapshotPath,
        [string]$TargetCollectionName,
        [int]$BatchSize,
        [bool]$KeepCurrent,
        [bool]$Force
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $pythonScript = @"
# Script Python temporaire pour le rollback des embeddings
import os
import json
import logging
import sys
import time
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
versions_path = "$VersionsPath"
version_id = "$VersionId"
snapshot_path = "$SnapshotPath"
target_collection_name = "$TargetCollectionName"
batch_size = $BatchSize
keep_current = $($KeepCurrent.ToString().ToLower())
force = $($Force.ToString().ToLower())

# Classe pour le rollback des embeddings
class EmbeddingRollback:
    def __init__(self, url, versions_path):
        self.url = url
        self.versions_path = versions_path
        self.client = QdrantClient(url=url)
        
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
    
    def _get_version(self, version_id=None):
        """Obtient une version spécifique"""
        if not version_id:
            # Utiliser la version précédente
            current_index = -1
            for i, version in enumerate(self.versions["versions"]):
                if version["id"] == self.versions["current_version"]:
                    current_index = i
                    break
            
            if current_index > 0:
                return self.versions["versions"][current_index - 1]
            else:
                logger.error("Aucune version précédente trouvée.")
                return None
        
        for version in self.versions["versions"]:
            if version["id"] == version_id:
                return version
        
        logger.error(f"Version {version_id} non trouvée.")
        return None
    
    def _load_snapshot(self, snapshot_path):
        """Charge un snapshot depuis un fichier"""
        if not os.path.exists(snapshot_path):
            logger.error(f"Le snapshot n'existe pas: {snapshot_path}")
            return None
        
        try:
            with open(snapshot_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Erreur lors du chargement du snapshot: {str(e)}")
            return None
    
    def _create_collection(self, collection_name, vector_size):
        """Crée une collection"""
        # Vérifier si la collection existe déjà
        collections = self.client.get_collections().collections
        collection_exists = any(c.name == collection_name for c in collections)
        
        if collection_exists:
            if force:
                logger.info(f"Suppression de la collection existante {collection_name}...")
                self.client.delete_collection(collection_name=collection_name)
            else:
                logger.error(f"La collection {collection_name} existe déjà. Utilisez -Force pour la remplacer.")
                return False
        
        # Créer la collection
        logger.info(f"Création de la collection {collection_name}...")
        self.client.create_collection(
            collection_name=collection_name,
            vectors_config=models.VectorParams(
                size=vector_size,
                distance=models.Distance.COSINE
            )
        )
        
        return True
    
    def rollback_from_snapshot(self, snapshot_path, target_collection=None):
        """Effectue un rollback à partir d'un snapshot"""
        # Charger le snapshot
        snapshot = self._load_snapshot(snapshot_path)
        if not snapshot:
            return False
        
        # Obtenir la version du snapshot
        version = snapshot["version"]
        
        # Définir le nom de la collection cible
        if not target_collection:
            target_collection = version["collection_name"] + "_rollback"
        
        # Créer la collection cible
        vector_size = version["vector_size"]
        if not self._create_collection(target_collection, vector_size):
            return False
        
        # Restaurer les points
        logger.info(f"Restauration de {len(snapshot['points'])} points...")
        
        # Traiter les points par lots
        for i in range(0, len(snapshot["points"]), batch_size):
            batch = snapshot["points"][i:i+batch_size]
            
            # Créer les points
            points = []
            for point in batch:
                points.append(models.PointStruct(
                    id=point["id"],
                    vector=point["vector"],
                    payload=point["payload"]
                ))
            
            # Insérer les points dans la collection cible
            self.client.upsert(
                collection_name=target_collection,
                points=points
            )
            
            logger.info(f"  - Lot {i//batch_size + 1}/{(len(snapshot['points'])-1)//batch_size + 1} restauré")
        
        # Mettre à jour la version courante
        if not keep_current:
            self.versions["current_version"] = version["id"]
            self._save_versions()
        
        logger.info(f"Rollback terminé avec succès!")
        logger.info(f"Collection restaurée: {target_collection}")
        
        return True
    
    def rollback_to_version(self, version_id=None, target_collection=None):
        """Effectue un rollback vers une version spécifique"""
        # Obtenir la version
        version = self._get_version(version_id)
        if not version:
            return False
        
        # Vérifier si la version a un snapshot
        if "snapshot_path" not in version or not os.path.exists(version["snapshot_path"]):
            logger.error(f"La version {version['id']} n'a pas de snapshot valide.")
            return False
        
        # Définir le nom de la collection cible
        if not target_collection:
            target_collection = version["collection_name"] + "_rollback"
        
        # Effectuer le rollback à partir du snapshot
        return self.rollback_from_snapshot(version["snapshot_path"], target_collection)
    
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

# Fonction principale
def main():
    # Créer le gestionnaire de rollback
    rollback = EmbeddingRollback(
        url=qdrant_url,
        versions_path=versions_path
    )
    
    # Lister les versions disponibles
    rollback.list_versions()
    
    # Effectuer le rollback
    if snapshot_path:
        # Rollback à partir d'un snapshot spécifique
        rollback.rollback_from_snapshot(snapshot_path, target_collection_name)
    else:
        # Rollback vers une version spécifique
        rollback.rollback_to_version(version_id, target_collection_name)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    return $tempFile
}

# Fonction principale
function Invoke-EmbeddingRollback {
    param (
        [string]$QdrantUrl,
        [string]$VersionsPath,
        [string]$VersionId,
        [string]$SnapshotPath,
        [string]$TargetCollectionName,
        [int]$BatchSize,
        [switch]$KeepCurrent,
        [switch]$Force
    )
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Vérifier si le fichier de versions existe
    if (-not (Test-Path -Path $VersionsPath) -and -not $SnapshotPath) {
        Write-Log "Le fichier de versions n'existe pas: $VersionsPath" -Level "Error"
        return $false
    }
    
    # Vérifier si le snapshot existe
    if ($SnapshotPath -and -not (Test-Path -Path $SnapshotPath)) {
        Write-Log "Le snapshot n'existe pas: $SnapshotPath" -Level "Error"
        return $false
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour le rollback des embeddings..." -Level "Info"
    $pythonScript = New-PythonRollbackScript -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -VersionId $VersionId -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -BatchSize $BatchSize -KeepCurrent $KeepCurrent -Force $Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour le rollback des embeddings..." -Level "Info"
    python $pythonScript
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Rollback des embeddings terminé avec succès." -Level "Success"
        $result = $true
    } else {
        Write-Log "Erreur lors du rollback des embeddings." -Level "Error"
        $result = $false
    }
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    return $result
}

# Exécuter la fonction principale
Invoke-EmbeddingRollback -QdrantUrl $QdrantUrl -VersionsPath $VersionsPath -VersionId $VersionId -SnapshotPath $SnapshotPath -TargetCollectionName $TargetCollectionName -BatchSize $BatchSize -KeepCurrent:$KeepCurrent -Force:$Force
