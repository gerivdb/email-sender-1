# Migrate-EmbeddingModel.ps1
# Script pour migrer les embeddings d'un modèle à un autre
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$SourceCollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [string]$TargetCollectionName,
    
    [Parameter(Mandatory = $false)]
    [string]$SourceVersionId,
    
    [Parameter(Mandatory = $false)]
    [string]$SnapshotPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewModelName,
    
    [Parameter(Mandatory = $false)]
    [string]$NewModelVersion,
    
    [Parameter(Mandatory = $false)]
    [string]$VersionsPath = "projet/roadmaps/vectors/embedding_versions.json",
    
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

# Fonction pour créer un script Python temporaire
function New-PythonMigrationScript {
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
        [bool]$KeepSource,
        [bool]$Force
    )
    
    $tempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".py"
    
    $pythonScript = @"
# Script Python temporaire pour la migration des embeddings
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
    from sentence_transformers import SentenceTransformer
    from qdrant_client import QdrantClient
    from qdrant_client.http import models
    from qdrant_client.http.exceptions import UnexpectedResponse
except ImportError:
    logger.error("Dépendances manquantes. Installez-les avec: pip install sentence-transformers qdrant-client")
    sys.exit(1)

# Paramètres
qdrant_url = "$QdrantUrl"
source_collection_name = "$SourceCollectionName"
target_collection_name = "$TargetCollectionName" or f"{source_collection_name}_migrated"
source_version_id = "$SourceVersionId"
snapshot_path = "$SnapshotPath"
new_model_name = "$NewModelName"
new_model_version = "$NewModelVersion"
versions_path = "$VersionsPath"
batch_size = $BatchSize
keep_source = $($KeepSource.ToString().ToLower())
force = $($Force.ToString().ToLower())

# Classe pour la migration des embeddings
class EmbeddingMigrator:
    def __init__(self, url, source_collection, target_collection, versions_path):
        self.url = url
        self.source_collection = source_collection
        self.target_collection = target_collection
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
    
    def _generate_version_id(self, model_name, model_version):
        """Génère un identifiant unique pour la version"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        hash_input = f"{model_name}_{model_version}_{timestamp}"
        hash_value = hashlib.md5(hash_input.encode()).hexdigest()[:8]
        return f"{model_name.replace('-', '_')}_{timestamp}_{hash_value}"
    
    def _get_source_version(self, version_id=None):
        """Obtient la version source"""
        if not version_id:
            # Utiliser la version courante
            version_id = self.versions["current_version"]
        
        if not version_id:
            logger.error("Aucune version courante définie.")
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
    
    def _create_target_collection(self, vector_size):
        """Crée la collection cible"""
        # Vérifier si la collection existe déjà
        collections = self.client.get_collections().collections
        collection_exists = any(c.name == self.target_collection for c in collections)
        
        if collection_exists:
            if force:
                logger.info(f"Suppression de la collection existante {self.target_collection}...")
                self.client.delete_collection(collection_name=self.target_collection)
            else:
                logger.error(f"La collection {self.target_collection} existe déjà. Utilisez -Force pour la remplacer.")
                return False
        
        # Créer la collection
        logger.info(f"Création de la collection {self.target_collection}...")
        self.client.create_collection(
            collection_name=self.target_collection,
            vectors_config=models.VectorParams(
                size=vector_size,
                distance=models.Distance.COSINE
            )
        )
        
        return True
    
    def _register_new_version(self, model_name, model_version):
        """Enregistre une nouvelle version d'embedding"""
        # Générer un identifiant unique pour la version
        version_id = self._generate_version_id(model_name, model_version)
        
        # Obtenir des informations sur la collection
        collection_info = self.client.get_collection(collection_name=self.target_collection)
        
        # Créer la nouvelle version
        new_version = {
            "id": version_id,
            "model_name": model_name,
            "model_version": model_version,
            "created_at": datetime.now().isoformat(),
            "vector_size": collection_info.config.params.vectors.size,
            "vector_distance": str(collection_info.config.params.vectors.distance),
            "point_count": collection_info.vectors_count,
            "collection_name": self.target_collection,
            "migrated_from": self.source_collection
        }
        
        # Ajouter la version à la liste
        self.versions["versions"].append(new_version)
        
        # Définir comme version courante
        self.versions["current_version"] = version_id
        
        # Enregistrer les versions
        self._save_versions()
        
        logger.info(f"Version {version_id} enregistrée avec succès.")
        return new_version
    
    def migrate_from_snapshot(self, snapshot_path, new_model_name, new_model_version):
        """Migre les embeddings à partir d'un snapshot"""
        # Charger le snapshot
        snapshot = self._load_snapshot(snapshot_path)
        if not snapshot:
            return False
        
        # Initialiser le nouveau modèle
        logger.info(f"Initialisation du modèle {new_model_name}...")
        try:
            model = SentenceTransformer(new_model_name)
        except Exception as e:
            logger.error(f"Erreur lors de l'initialisation du modèle: {str(e)}")
            return False
        
        # Créer la collection cible
        vector_size = model.get_sentence_embedding_dimension()
        if not self._create_target_collection(vector_size):
            return False
        
        # Migrer les points
        logger.info(f"Migration de {len(snapshot['points'])} points...")
        
        # Traiter les points par lots
        for i in range(0, len(snapshot["points"]), batch_size):
            batch = snapshot["points"][i:i+batch_size]
            
            # Extraire les textes pour l'embedding
            texts = []
            for point in batch:
                text = point["payload"].get("text", "")
                if not text:
                    # Construire un texte à partir des métadonnées
                    metadata = point["payload"]
                    text = f"ID: {metadata.get('task_id', '')} | Description: {metadata.get('description', '')}"
                    if "status" in metadata:
                        text += f" | Status: {metadata['status']}"
                    if "context" in metadata:
                        text += f" | Context: {metadata['context']}"
                
                texts.append(text)
            
            # Générer les nouveaux embeddings
            new_embeddings = model.encode(texts)
            
            # Créer les nouveaux points
            new_points = []
            for j, point in enumerate(batch):
                new_point = models.PointStruct(
                    id=point["id"],
                    vector=new_embeddings[j].tolist(),
                    payload=point["payload"]
                )
                
                # Ajouter des métadonnées sur la migration
                new_point.payload["migration"] = {
                    "source_collection": self.source_collection,
                    "migrated_at": datetime.now().isoformat(),
                    "source_model": snapshot["version"]["model_name"],
                    "target_model": new_model_name
                }
                
                new_points.append(new_point)
            
            # Insérer les points dans la collection cible
            self.client.upsert(
                collection_name=self.target_collection,
                points=new_points
            )
            
            logger.info(f"  - Lot {i//batch_size + 1}/{(len(snapshot['points'])-1)//batch_size + 1} migré")
        
        # Enregistrer la nouvelle version
        self._register_new_version(new_model_name, new_model_version)
        
        logger.info(f"Migration terminée avec succès!")
        return True
    
    def migrate_from_collection(self, source_version_id, new_model_name, new_model_version):
        """Migre les embeddings à partir d'une collection existante"""
        # Obtenir la version source
        source_version = self._get_source_version(source_version_id)
        if not source_version:
            return False
        
        # Initialiser le nouveau modèle
        logger.info(f"Initialisation du modèle {new_model_name}...")
        try:
            model = SentenceTransformer(new_model_name)
        except Exception as e:
            logger.error(f"Erreur lors de l'initialisation du modèle: {str(e)}")
            return False
        
        # Créer la collection cible
        vector_size = model.get_sentence_embedding_dimension()
        if not self._create_target_collection(vector_size):
            return False
        
        # Récupérer tous les points de la collection source
        logger.info(f"Récupération des points de la collection {self.source_collection}...")
        
        points = []
        offset = None
        limit = batch_size
        
        while True:
            scroll_result = self.client.scroll(
                collection_name=self.source_collection,
                limit=limit,
                offset=offset
            )
            
            batch = scroll_result[0]
            if not batch:
                break
            
            points.extend(batch)
            offset = scroll_result[1]
            
            if offset is None:
                break
        
        logger.info(f"Migration de {len(points)} points...")
        
        # Traiter les points par lots
        for i in range(0, len(points), batch_size):
            batch = points[i:i+batch_size]
            
            # Extraire les textes pour l'embedding
            texts = []
            for point in batch:
                text = point.payload.get("text", "")
                if not text:
                    # Construire un texte à partir des métadonnées
                    metadata = point.payload
                    text = f"ID: {metadata.get('task_id', '')} | Description: {metadata.get('description', '')}"
                    if "status" in metadata:
                        text += f" | Status: {metadata['status']}"
                    if "context" in metadata:
                        text += f" | Context: {metadata['context']}"
                
                texts.append(text)
            
            # Générer les nouveaux embeddings
            new_embeddings = model.encode(texts)
            
            # Créer les nouveaux points
            new_points = []
            for j, point in enumerate(batch):
                new_point = models.PointStruct(
                    id=point.id,
                    vector=new_embeddings[j].tolist(),
                    payload=point.payload
                )
                
                # Ajouter des métadonnées sur la migration
                if "migration" not in new_point.payload:
                    new_point.payload["migration"] = {}
                
                new_point.payload["migration"].update({
                    "source_collection": self.source_collection,
                    "migrated_at": datetime.now().isoformat(),
                    "source_model": source_version["model_name"],
                    "target_model": new_model_name
                })
                
                new_points.append(new_point)
            
            # Insérer les points dans la collection cible
            self.client.upsert(
                collection_name=self.target_collection,
                points=new_points
            )
            
            logger.info(f"  - Lot {i//batch_size + 1}/{(len(points)-1)//batch_size + 1} migré")
        
        # Enregistrer la nouvelle version
        self._register_new_version(new_model_name, new_model_version)
        
        # Supprimer la collection source si demandé
        if not keep_source:
            logger.info(f"Suppression de la collection source {self.source_collection}...")
            self.client.delete_collection(collection_name=self.source_collection)
        
        logger.info(f"Migration terminée avec succès!")
        return True

# Fonction principale
def main():
    # Vérifier les paramètres requis
    if not new_model_name:
        logger.error("Le nom du nouveau modèle est requis.")
        sys.exit(1)
    
    if not new_model_version:
        new_model_version = "1.0"
        logger.info(f"Version du modèle non spécifiée, utilisation de la valeur par défaut: {new_model_version}")
    
    # Créer le migrateur
    migrator = EmbeddingMigrator(
        url=qdrant_url,
        source_collection=source_collection_name,
        target_collection=target_collection_name,
        versions_path=versions_path
    )
    
    # Exécuter la migration
    if snapshot_path:
        # Migration à partir d'un snapshot
        migrator.migrate_from_snapshot(snapshot_path, new_model_name, new_model_version)
    else:
        # Migration à partir d'une collection existante
        migrator.migrate_from_collection(source_version_id, new_model_name, new_model_version)

if __name__ == "__main__":
    main()
"@
    
    Set-Content -Path $tempFile -Value $pythonScript -Encoding UTF8
    return $tempFile
}

# Fonction principale
function Migrate-EmbeddingModel {
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
        [switch]$KeepSource,
        [switch]$Force
    )
    
    # Vérifier si Qdrant est en cours d'exécution
    if (-not (Test-QdrantRunning -Host ($QdrantUrl -replace "http://", "" -replace ":\d+$", "") -Port ([int]($QdrantUrl -replace "^.*:", "")))) {
        return $false
    }
    
    # Vérifier les paramètres requis
    if (-not $NewModelName) {
        Write-Log "Le nom du nouveau modèle est requis." -Level "Error"
        return $false
    }
    
    if (-not $NewModelVersion) {
        $NewModelVersion = "1.0"
        Write-Log "Version du modèle non spécifiée, utilisation de la valeur par défaut: $NewModelVersion" -Level "Info"
    }
    
    # Vérifier si le snapshot existe
    if ($SnapshotPath -and -not (Test-Path -Path $SnapshotPath)) {
        Write-Log "Le snapshot n'existe pas: $SnapshotPath" -Level "Error"
        return $false
    }
    
    # Créer le script Python temporaire
    Write-Log "Création du script Python pour la migration des embeddings..." -Level "Info"
    $pythonScript = New-PythonMigrationScript -QdrantUrl $QdrantUrl -SourceCollectionName $SourceCollectionName -TargetCollectionName $TargetCollectionName -SourceVersionId $SourceVersionId -SnapshotPath $SnapshotPath -NewModelName $NewModelName -NewModelVersion $NewModelVersion -VersionsPath $VersionsPath -BatchSize $BatchSize -KeepSource $KeepSource -Force $Force
    
    # Exécuter le script Python
    Write-Log "Exécution du script Python pour la migration des embeddings..." -Level "Info"
    python $pythonScript
    
    # Vérifier le code de sortie
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Migration des embeddings terminée avec succès." -Level "Success"
        $result = $true
    } else {
        Write-Log "Erreur lors de la migration des embeddings." -Level "Error"
        $result = $false
    }
    
    # Supprimer le script temporaire
    Remove-Item -Path $pythonScript -Force
    
    return $result
}

# Exécuter la fonction principale
Migrate-EmbeddingModel -QdrantUrl $QdrantUrl -SourceCollectionName $SourceCollectionName -TargetCollectionName $TargetCollectionName -SourceVersionId $SourceVersionId -SnapshotPath $SnapshotPath -NewModelName $NewModelName -NewModelVersion $NewModelVersion -VersionsPath $VersionsPath -BatchSize $BatchSize -KeepSource:$KeepSource -Force:$Force
