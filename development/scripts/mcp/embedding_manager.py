"""
Module pour gérer les embeddings vectoriels.
Ce module fournit des classes et fonctions pour créer, manipuler et stocker des embeddings.
"""

import os
import json
import numpy as np
from typing import List, Dict, Any, Optional, Union, Tuple
from datetime import datetime
import hashlib


class Vector:
    """
    Classe représentant un vecteur d'embedding.
    """
    
    def __init__(
        self,
        data: Union[List[float], np.ndarray],
        model_name: str = "unknown",
        normalize: bool = True
    ):
        """
        Initialise un vecteur d'embedding.
        
        Args:
            data: Données du vecteur (liste de flottants ou tableau numpy).
            model_name: Nom du modèle ayant généré l'embedding.
            normalize: Si True, normalise le vecteur à la création.
        """
        if isinstance(data, list):
            self.data = np.array(data, dtype=np.float32)
        else:
            self.data = data.astype(np.float32)
        
        self.model_name = model_name
        self.dimension = len(self.data)
        
        if normalize:
            self.normalize()
    
    def normalize(self) -> None:
        """
        Normalise le vecteur (norme L2 = 1).
        """
        norm = np.linalg.norm(self.data)
        if norm > 0:
            self.data = self.data / norm
    
    def to_list(self) -> List[float]:
        """
        Convertit le vecteur en liste de flottants.
        
        Returns:
            Liste de flottants.
        """
        return self.data.tolist()
    
    def to_numpy(self) -> np.ndarray:
        """
        Convertit le vecteur en tableau numpy.
        
        Returns:
            Tableau numpy.
        """
        return self.data
    
    def cosine_similarity(self, other: 'Vector') -> float:
        """
        Calcule la similarité cosinus avec un autre vecteur.
        
        Args:
            other: Autre vecteur.
            
        Returns:
            Similarité cosinus (entre -1 et 1).
        """
        return np.dot(self.data, other.data) / (np.linalg.norm(self.data) * np.linalg.norm(other.data))
    
    def euclidean_distance(self, other: 'Vector') -> float:
        """
        Calcule la distance euclidienne avec un autre vecteur.
        
        Args:
            other: Autre vecteur.
            
        Returns:
            Distance euclidienne.
        """
        return np.linalg.norm(self.data - other.data)
    
    def dot_product(self, other: 'Vector') -> float:
        """
        Calcule le produit scalaire avec un autre vecteur.
        
        Args:
            other: Autre vecteur.
            
        Returns:
            Produit scalaire.
        """
        return np.dot(self.data, other.data)
    
    def __len__(self) -> int:
        """
        Retourne la dimension du vecteur.
        
        Returns:
            Dimension du vecteur.
        """
        return self.dimension
    
    def __getitem__(self, index: int) -> float:
        """
        Accède à un élément du vecteur.
        
        Args:
            index: Index de l'élément.
            
        Returns:
            Valeur de l'élément.
        """
        return float(self.data[index])
    
    def __repr__(self) -> str:
        """
        Représentation du vecteur.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"Vector(dim={self.dimension}, model='{self.model_name}')"


class Embedding:
    """
    Classe représentant un embedding avec métadonnées.
    """
    
    def __init__(
        self,
        vector: Vector,
        text: str,
        metadata: Optional[Dict[str, Any]] = None,
        id: Optional[str] = None
    ):
        """
        Initialise un embedding.
        
        Args:
            vector: Vecteur d'embedding.
            text: Texte associé à l'embedding.
            metadata: Métadonnées associées à l'embedding.
            id: Identifiant unique de l'embedding (généré automatiquement si None).
        """
        self.vector = vector
        self.text = text
        self.metadata = metadata or {}
        
        # Générer un ID si non fourni
        if id is None:
            self.id = self._generate_id()
        else:
            self.id = id
        
        # Ajouter des métadonnées de base
        self._add_basic_metadata()
    
    def _generate_id(self) -> str:
        """
        Génère un identifiant unique pour l'embedding.
        
        Returns:
            Identifiant unique.
        """
        # Utiliser un hash du texte et de l'horodatage
        text_hash = hashlib.md5(self.text.encode()).hexdigest()
        timestamp = datetime.now().isoformat()
        return f"emb_{text_hash[:10]}_{int(datetime.now().timestamp())}"
    
    def _add_basic_metadata(self) -> None:
        """
        Ajoute des métadonnées de base à l'embedding.
        """
        if "created_at" not in self.metadata:
            self.metadata["created_at"] = datetime.now().isoformat()
        
        if "model" not in self.metadata:
            self.metadata["model"] = self.vector.model_name
        
        if "dimension" not in self.metadata:
            self.metadata["dimension"] = self.vector.dimension
        
        if "content_hash" not in self.metadata:
            self.metadata["content_hash"] = hashlib.md5(self.text.encode()).hexdigest()
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit l'embedding en dictionnaire.
        
        Returns:
            Dictionnaire représentant l'embedding.
        """
        return {
            "id": self.id,
            "vector": self.vector.to_list(),
            "text": self.text,
            "metadata": self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Embedding':
        """
        Crée un embedding à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant l'embedding.
            
        Returns:
            Embedding créé.
        """
        vector = Vector(
            data=data["vector"],
            model_name=data.get("metadata", {}).get("model", "unknown")
        )
        
        return cls(
            vector=vector,
            text=data["text"],
            metadata=data.get("metadata", {}),
            id=data.get("id")
        )
    
    def save_to_file(self, file_path: str) -> None:
        """
        Sauvegarde l'embedding dans un fichier JSON.
        
        Args:
            file_path: Chemin du fichier de sortie.
        """
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
    
    @classmethod
    def load_from_file(cls, file_path: str) -> 'Embedding':
        """
        Charge un embedding depuis un fichier JSON.
        
        Args:
            file_path: Chemin du fichier d'entrée.
            
        Returns:
            Embedding chargé.
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return cls.from_dict(data)
    
    def __repr__(self) -> str:
        """
        Représentation de l'embedding.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"Embedding(id='{self.id}', vector={self.vector}, text_preview='{self.text[:30]}...')"


class EmbeddingCollection:
    """
    Classe représentant une collection d'embeddings.
    """
    
    def __init__(self, name: str = "default"):
        """
        Initialise une collection d'embeddings.
        
        Args:
            name: Nom de la collection.
        """
        self.name = name
        self.embeddings: Dict[str, Embedding] = {}
        self.metadata: Dict[str, Any] = {
            "name": name,
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "count": 0
        }
    
    def add(self, embedding: Embedding) -> str:
        """
        Ajoute un embedding à la collection.
        
        Args:
            embedding: Embedding à ajouter.
            
        Returns:
            Identifiant de l'embedding.
        """
        self.embeddings[embedding.id] = embedding
        self.metadata["count"] = len(self.embeddings)
        self.metadata["updated_at"] = datetime.now().isoformat()
        return embedding.id
    
    def get(self, id: str) -> Optional[Embedding]:
        """
        Récupère un embedding par son identifiant.
        
        Args:
            id: Identifiant de l'embedding.
            
        Returns:
            Embedding correspondant ou None si non trouvé.
        """
        return self.embeddings.get(id)
    
    def remove(self, id: str) -> bool:
        """
        Supprime un embedding de la collection.
        
        Args:
            id: Identifiant de l'embedding.
            
        Returns:
            True si l'embedding a été supprimé, False sinon.
        """
        if id in self.embeddings:
            del self.embeddings[id]
            self.metadata["count"] = len(self.embeddings)
            self.metadata["updated_at"] = datetime.now().isoformat()
            return True
        return False
    
    def search(
        self,
        query_vector: Vector,
        top_k: int = 5,
        threshold: float = 0.0,
        filter_func: Optional[callable] = None
    ) -> List[Tuple[Embedding, float]]:
        """
        Recherche les embeddings les plus similaires à un vecteur de requête.
        
        Args:
            query_vector: Vecteur de requête.
            top_k: Nombre maximum de résultats à retourner.
            threshold: Seuil minimal de similarité.
            filter_func: Fonction de filtrage des embeddings.
            
        Returns:
            Liste de tuples (embedding, score) triés par score décroissant.
        """
        results = []
        
        for embedding in self.embeddings.values():
            # Appliquer le filtre si fourni
            if filter_func and not filter_func(embedding):
                continue
            
            # Calculer la similarité
            similarity = query_vector.cosine_similarity(embedding.vector)
            
            # Appliquer le seuil
            if similarity >= threshold:
                results.append((embedding, similarity))
        
        # Trier par similarité décroissante et limiter à top_k
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:top_k]
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la collection en dictionnaire.
        
        Returns:
            Dictionnaire représentant la collection.
        """
        return {
            "metadata": self.metadata,
            "embeddings": {id: emb.to_dict() for id, emb in self.embeddings.items()}
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'EmbeddingCollection':
        """
        Crée une collection à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant la collection.
            
        Returns:
            Collection créée.
        """
        collection = cls(name=data.get("metadata", {}).get("name", "default"))
        collection.metadata = data.get("metadata", {})
        
        for id, emb_data in data.get("embeddings", {}).items():
            embedding = Embedding.from_dict(emb_data)
            collection.embeddings[id] = embedding
        
        return collection
    
    def save_to_file(self, file_path: str) -> None:
        """
        Sauvegarde la collection dans un fichier JSON.
        
        Args:
            file_path: Chemin du fichier de sortie.
        """
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2, ensure_ascii=False)
    
    @classmethod
    def load_from_file(cls, file_path: str) -> 'EmbeddingCollection':
        """
        Charge une collection depuis un fichier JSON.
        
        Args:
            file_path: Chemin du fichier d'entrée.
            
        Returns:
            Collection chargée.
        """
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return cls.from_dict(data)
    
    def __len__(self) -> int:
        """
        Retourne le nombre d'embeddings dans la collection.
        
        Returns:
            Nombre d'embeddings.
        """
        return len(self.embeddings)
    
    def __iter__(self):
        """
        Itère sur les embeddings de la collection.
        
        Returns:
            Itérateur sur les embeddings.
        """
        return iter(self.embeddings.values())
    
    def __repr__(self) -> str:
        """
        Représentation de la collection.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"EmbeddingCollection(name='{self.name}', count={len(self.embeddings)})"
