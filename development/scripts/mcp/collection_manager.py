"""
Module pour la gestion des collections vectorielles.
Ce module fournit des classes pour gérer les collections de vecteurs dans Qdrant.
"""

import os
import json
import time
import uuid
from typing import List, Dict, Any, Optional, Union, Tuple, Callable, Iterator
from datetime import datetime

from embedding_manager import Vector, Embedding, EmbeddingCollection
from vector_storage import QdrantConfig, QdrantClient
from vector_storage_manager import VectorStorageManager
from vector_crud import VectorCRUD


class CollectionConfig:
    """
    Configuration pour une collection vectorielle.
    """
    
    def __init__(
        self,
        name: str,
        vector_size: int = 1536,
        distance: str = "Cosine",
        on_disk_payload: bool = False,
        optimizers_config: Optional[Dict[str, Any]] = None,
        metadata_indices: Optional[List[Dict[str, Any]]] = None,
        description: str = ""
    ):
        """
        Initialise la configuration d'une collection.
        
        Args:
            name: Nom de la collection.
            vector_size: Taille des vecteurs.
            distance: Métrique de distance (Cosine, Euclid, Dot).
            on_disk_payload: Si True, stocke les payloads sur disque.
            optimizers_config: Configuration des optimiseurs.
            metadata_indices: Liste des indices à créer sur les métadonnées.
            description: Description de la collection.
        """
        self.name = name
        self.vector_size = vector_size
        self.distance = distance
        self.on_disk_payload = on_disk_payload
        self.optimizers_config = optimizers_config or {}
        self.metadata_indices = metadata_indices or []
        self.description = description
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la configuration en dictionnaire.
        
        Returns:
            Dictionnaire représentant la configuration.
        """
        return {
            "name": self.name,
            "vector_size": self.vector_size,
            "distance": self.distance,
            "on_disk_payload": self.on_disk_payload,
            "optimizers_config": self.optimizers_config,
            "metadata_indices": self.metadata_indices,
            "description": self.description
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'CollectionConfig':
        """
        Crée une configuration à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant la configuration.
            
        Returns:
            Configuration créée.
        """
        return cls(
            name=data["name"],
            vector_size=data.get("vector_size", 1536),
            distance=data.get("distance", "Cosine"),
            on_disk_payload=data.get("on_disk_payload", False),
            optimizers_config=data.get("optimizers_config"),
            metadata_indices=data.get("metadata_indices"),
            description=data.get("description", "")
        )
    
    def __repr__(self) -> str:
        """
        Représentation de la configuration.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"CollectionConfig(name='{self.name}', vector_size={self.vector_size}, distance='{self.distance}')"


class CollectionManager:
    """
    Gestionnaire de collections vectorielles.
    """
    
    def __init__(
        self,
        storage_manager: Optional[VectorStorageManager] = None,
        config_path: Optional[str] = None
    ):
        """
        Initialise le gestionnaire de collections.
        
        Args:
            storage_manager: Gestionnaire de stockage vectoriel (crée un nouveau gestionnaire si None).
            config_path: Chemin vers le fichier de configuration des collections (optionnel).
        """
        self.storage_manager = storage_manager or VectorStorageManager()
        self.config_path = config_path
        self.collections: Dict[str, CollectionConfig] = {}
        
        # Charger les configurations existantes
        if config_path and os.path.exists(config_path):
            self._load_configs()
        else:
            # Découvrir les collections existantes
            self._discover_collections()
    
    def _load_configs(self) -> None:
        """
        Charge les configurations de collections depuis le fichier de configuration.
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for collection_data in data.get("collections", []):
                config = CollectionConfig.from_dict(collection_data)
                self.collections[config.name] = config
        except Exception as e:
            print(f"Erreur lors du chargement des configurations: {e}")
    
    def _save_configs(self) -> None:
        """
        Sauvegarde les configurations de collections dans le fichier de configuration.
        """
        if not self.config_path:
            return
        
        try:
            data = {
                "collections": [config.to_dict() for config in self.collections.values()]
            }
            
            with open(self.config_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
        except Exception as e:
            print(f"Erreur lors de la sauvegarde des configurations: {e}")
    
    def _discover_collections(self) -> None:
        """
        Découvre les collections existantes dans le stockage.
        """
        collection_names = self.storage_manager.list_collections()
        
        for name in collection_names:
            # Récupérer les informations sur la collection
            info = self.storage_manager.get_collection_info(name)
            
            if info and "config" in info and "vectors" in info["config"]:
                vector_config = info["config"]["vectors"]
                
                # Créer une configuration pour la collection
                config = CollectionConfig(
                    name=name,
                    vector_size=vector_config.get("size", 1536),
                    distance=vector_config.get("distance", "Cosine"),
                    on_disk_payload=info["config"].get("on_disk_payload", False)
                )
                
                self.collections[name] = config
    
    def list_collections(self) -> List[str]:
        """
        Liste les noms des collections disponibles.
        
        Returns:
            Liste des noms de collections.
        """
        return list(self.collections.keys())
    
    def get_collection_config(self, name: str) -> Optional[CollectionConfig]:
        """
        Récupère la configuration d'une collection.
        
        Args:
            name: Nom de la collection.
            
        Returns:
            Configuration de la collection ou None si non trouvée.
        """
        return self.collections.get(name)
    
    def get_collection_info(self, name: str) -> Dict[str, Any]:
        """
        Récupère les informations sur une collection.
        
        Args:
            name: Nom de la collection.
            
        Returns:
            Informations sur la collection.
        """
        return self.storage_manager.get_collection_info(name)
    
    def create_collection(self, config: CollectionConfig) -> bool:
        """
        Crée une nouvelle collection.
        
        Args:
            config: Configuration de la collection.
            
        Returns:
            True si la création a réussi, False sinon.
        """
        # Vérifier si la collection existe déjà
        if config.name in self.collections:
            return True
        
        # Créer la collection
        success = self.storage_manager.create_collection(
            collection_name=config.name,
            vector_size=config.vector_size,
            distance=config.distance,
            on_disk_payload=config.on_disk_payload,
            create_metadata_indices=False
        )
        
        if not success:
            return False
        
        # Créer les indices sur les métadonnées
        for index in config.metadata_indices:
            field_name = index.get("field_name")
            field_schema = index.get("field_schema", "keyword")
            
            if field_name:
                self.storage_manager.client.create_payload_index(
                    collection_name=config.name,
                    field_name=field_name,
                    field_schema=field_schema
                )
        
        # Ajouter la configuration
        self.collections[config.name] = config
        
        # Sauvegarder les configurations
        self._save_configs()
        
        return True
    
    def delete_collection(self, name: str) -> bool:
        """
        Supprime une collection.
        
        Args:
            name: Nom de la collection.
            
        Returns:
            True si la suppression a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if name not in self.collections:
            return False
        
        # Supprimer la collection
        success = self.storage_manager.delete_collection(name)
        
        if success:
            # Supprimer la configuration
            del self.collections[name]
            
            # Sauvegarder les configurations
            self._save_configs()
        
        return success
    
    def rename_collection(self, old_name: str, new_name: str) -> bool:
        """
        Renomme une collection.
        
        Args:
            old_name: Ancien nom de la collection.
            new_name: Nouveau nom de la collection.
            
        Returns:
            True si le renommage a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if old_name not in self.collections:
            return False
        
        # Vérifier si le nouveau nom est déjà utilisé
        if new_name in self.collections:
            return False
        
        # Récupérer la configuration
        config = self.collections[old_name]
        
        # Créer une nouvelle collection avec la même configuration
        new_config = CollectionConfig(
            name=new_name,
            vector_size=config.vector_size,
            distance=config.distance,
            on_disk_payload=config.on_disk_payload,
            optimizers_config=config.optimizers_config,
            metadata_indices=config.metadata_indices,
            description=config.description
        )
        
        # Créer la nouvelle collection
        success = self.create_collection(new_config)
        
        if not success:
            return False
        
        # TODO: Copier les données de l'ancienne collection vers la nouvelle
        # Cette opération n'est pas supportée nativement par Qdrant
        # Il faudrait implémenter une copie manuelle des points
        
        # Supprimer l'ancienne collection
        self.delete_collection(old_name)
        
        return True
    
    def update_collection_config(self, name: str, config: CollectionConfig) -> bool:
        """
        Met à jour la configuration d'une collection.
        
        Args:
            name: Nom de la collection.
            config: Nouvelle configuration.
            
        Returns:
            True si la mise à jour a réussi, False sinon.
        """
        # Vérifier si la collection existe
        if name not in self.collections:
            return False
        
        # Vérifier que le nom n'a pas changé
        if name != config.name:
            return False
        
        # Mettre à jour la configuration
        self.collections[name] = config
        
        # Sauvegarder les configurations
        self._save_configs()
        
        return True
    
    def get_crud_for_collection(self, name: str) -> Optional[VectorCRUD]:
        """
        Récupère un gestionnaire CRUD pour une collection.
        
        Args:
            name: Nom de la collection.
            
        Returns:
            Gestionnaire CRUD ou None si la collection n'existe pas.
        """
        # Vérifier si la collection existe
        if name not in self.collections:
            return None
        
        # Créer un gestionnaire CRUD
        return VectorCRUD(
            storage_manager=self.storage_manager,
            default_collection=name
        )
    
    def get_collection_stats(self, name: str) -> Dict[str, Any]:
        """
        Récupère des statistiques sur une collection.
        
        Args:
            name: Nom de la collection.
            
        Returns:
            Statistiques sur la collection.
        """
        # Vérifier si la collection existe
        if name not in self.collections:
            return {}
        
        # Récupérer les informations sur la collection
        info = self.storage_manager.get_collection_info(name)
        
        if not info:
            return {}
        
        # Extraire les statistiques
        stats = {
            "name": name,
            "vectors_count": info.get("vectors_count", 0),
            "segments_count": info.get("segments_count", 0),
            "points_count": info.get("points_count", 0),
            "status": info.get("status", "unknown")
        }
        
        # Ajouter des informations sur la configuration
        config = self.collections[name]
        stats["vector_size"] = config.vector_size
        stats["distance"] = config.distance
        stats["on_disk_payload"] = config.on_disk_payload
        
        return stats
