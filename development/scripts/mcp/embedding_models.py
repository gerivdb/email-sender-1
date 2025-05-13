"""
Module pour l'interface avec les modèles d'embeddings.
Ce module fournit des classes pour interagir avec différents modèles d'embeddings.
"""

import os
import json
import time
import requests
import numpy as np
from typing import List, Dict, Any, Optional, Union, Tuple, Callable
from abc import ABC, abstractmethod
from datetime import datetime

from embedding_manager import Vector


class EmbeddingModelConfig:
    """
    Configuration pour un modèle d'embeddings.
    """
    
    def __init__(
        self,
        model_name: str,
        model_type: str,
        dimension: int,
        api_key: Optional[str] = None,
        api_url: Optional[str] = None,
        batch_size: int = 8,
        timeout: int = 30,
        normalize: bool = True,
        additional_params: Optional[Dict[str, Any]] = None
    ):
        """
        Initialise la configuration d'un modèle d'embeddings.
        
        Args:
            model_name: Nom du modèle.
            model_type: Type du modèle (openai, openrouter, huggingface, etc.).
            dimension: Dimension des vecteurs d'embedding.
            api_key: Clé API pour l'accès au modèle.
            api_url: URL de l'API du modèle.
            batch_size: Taille des lots pour les requêtes par lots.
            timeout: Timeout pour les requêtes en secondes.
            normalize: Si True, normalise les vecteurs d'embedding.
            additional_params: Paramètres supplémentaires spécifiques au modèle.
        """
        self.model_name = model_name
        self.model_type = model_type
        self.dimension = dimension
        self.api_key = api_key or os.environ.get(f"{model_type.upper()}_API_KEY")
        self.api_url = api_url
        self.batch_size = batch_size
        self.timeout = timeout
        self.normalize = normalize
        self.additional_params = additional_params or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la configuration en dictionnaire.
        
        Returns:
            Dictionnaire représentant la configuration.
        """
        return {
            "model_name": self.model_name,
            "model_type": self.model_type,
            "dimension": self.dimension,
            "api_key": self.api_key,
            "api_url": self.api_url,
            "batch_size": self.batch_size,
            "timeout": self.timeout,
            "normalize": self.normalize,
            "additional_params": self.additional_params
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'EmbeddingModelConfig':
        """
        Crée une configuration à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant la configuration.
            
        Returns:
            Configuration créée.
        """
        return cls(
            model_name=data["model_name"],
            model_type=data["model_type"],
            dimension=data["dimension"],
            api_key=data.get("api_key"),
            api_url=data.get("api_url"),
            batch_size=data.get("batch_size", 8),
            timeout=data.get("timeout", 30),
            normalize=data.get("normalize", True),
            additional_params=data.get("additional_params")
        )
    
    def __repr__(self) -> str:
        """
        Représentation de la configuration.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"EmbeddingModelConfig(model_name='{self.model_name}', model_type='{self.model_type}', dimension={self.dimension})"


class EmbeddingModel(ABC):
    """
    Classe abstraite pour les modèles d'embeddings.
    """
    
    def __init__(self, config: EmbeddingModelConfig):
        """
        Initialise le modèle d'embeddings.
        
        Args:
            config: Configuration du modèle.
        """
        self.config = config
    
    @abstractmethod
    def embed_text(self, text: str) -> Vector:
        """
        Génère un embedding pour un texte.
        
        Args:
            text: Texte à encoder.
            
        Returns:
            Vecteur d'embedding.
        """
        pass
    
    @abstractmethod
    def embed_batch(self, texts: List[str]) -> List[Vector]:
        """
        Génère des embeddings pour une liste de textes.
        
        Args:
            texts: Liste de textes à encoder.
            
        Returns:
            Liste de vecteurs d'embedding.
        """
        pass
    
    def _normalize_vector(self, vector: List[float]) -> List[float]:
        """
        Normalise un vecteur (norme L2 = 1).
        
        Args:
            vector: Vecteur à normaliser.
            
        Returns:
            Vecteur normalisé.
        """
        if not self.config.normalize:
            return vector
        
        norm = np.linalg.norm(vector)
        if norm > 0:
            return (np.array(vector) / norm).tolist()
        return vector


class OpenAIEmbeddingModel(EmbeddingModel):
    """
    Modèle d'embeddings utilisant l'API OpenAI.
    """
    
    def __init__(self, config: EmbeddingModelConfig):
        """
        Initialise le modèle d'embeddings OpenAI.
        
        Args:
            config: Configuration du modèle.
        """
        super().__init__(config)
        
        # Définir l'URL de l'API si non spécifiée
        if not self.config.api_url:
            self.config.api_url = "https://api.openai.com/v1/embeddings"
    
    def embed_text(self, text: str) -> Vector:
        """
        Génère un embedding pour un texte avec l'API OpenAI.
        
        Args:
            text: Texte à encoder.
            
        Returns:
            Vecteur d'embedding.
        """
        # Préparer les en-têtes
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.config.api_key}"
        }
        
        # Préparer les données
        data = {
            "input": text,
            "model": self.config.model_name
        }
        
        # Ajouter les paramètres supplémentaires
        data.update(self.config.additional_params)
        
        # Effectuer la requête
        response = requests.post(
            self.config.api_url,
            headers=headers,
            json=data,
            timeout=self.config.timeout
        )
        
        # Vérifier la réponse
        if response.status_code != 200:
            raise Exception(f"Erreur OpenAI: {response.status_code} - {response.text}")
        
        # Extraire l'embedding
        result = response.json()
        embedding = result["data"][0]["embedding"]
        
        # Normaliser si nécessaire
        if self.config.normalize:
            embedding = self._normalize_vector(embedding)
        
        return Vector(embedding, model_name=self.config.model_name)
    
    def embed_batch(self, texts: List[str]) -> List[Vector]:
        """
        Génère des embeddings pour une liste de textes avec l'API OpenAI.
        
        Args:
            texts: Liste de textes à encoder.
            
        Returns:
            Liste de vecteurs d'embedding.
        """
        # Diviser les textes en lots
        batches = [texts[i:i + self.config.batch_size] for i in range(0, len(texts), self.config.batch_size)]
        
        # Traiter chaque lot
        all_embeddings = []
        for batch in batches:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.config.api_key}"
            }
            
            # Préparer les données
            data = {
                "input": batch,
                "model": self.config.model_name
            }
            
            # Ajouter les paramètres supplémentaires
            data.update(self.config.additional_params)
            
            # Effectuer la requête
            response = requests.post(
                self.config.api_url,
                headers=headers,
                json=data,
                timeout=self.config.timeout
            )
            
            # Vérifier la réponse
            if response.status_code != 200:
                raise Exception(f"Erreur OpenAI: {response.status_code} - {response.text}")
            
            # Extraire les embeddings
            result = response.json()
            batch_embeddings = [item["embedding"] for item in result["data"]]
            
            # Normaliser si nécessaire
            if self.config.normalize:
                batch_embeddings = [self._normalize_vector(emb) for emb in batch_embeddings]
            
            # Créer les vecteurs
            vectors = [Vector(emb, model_name=self.config.model_name) for emb in batch_embeddings]
            all_embeddings.extend(vectors)
        
        return all_embeddings


class OpenRouterEmbeddingModel(EmbeddingModel):
    """
    Modèle d'embeddings utilisant l'API OpenRouter.
    """
    
    def __init__(self, config: EmbeddingModelConfig):
        """
        Initialise le modèle d'embeddings OpenRouter.
        
        Args:
            config: Configuration du modèle.
        """
        super().__init__(config)
        
        # Définir l'URL de l'API si non spécifiée
        if not self.config.api_url:
            self.config.api_url = "https://openrouter.ai/api/v1/embeddings"
    
    def embed_text(self, text: str) -> Vector:
        """
        Génère un embedding pour un texte avec l'API OpenRouter.
        
        Args:
            text: Texte à encoder.
            
        Returns:
            Vecteur d'embedding.
        """
        # Préparer les en-têtes
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.config.api_key}",
            "HTTP-Referer": self.config.additional_params.get("http_referer", "http://localhost"),
            "X-Title": self.config.additional_params.get("x_title", "Embedding API")
        }
        
        # Préparer les données
        data = {
            "input": text,
            "model": self.config.model_name
        }
        
        # Ajouter les paramètres supplémentaires (sauf ceux déjà utilisés dans les en-têtes)
        additional_params = {k: v for k, v in self.config.additional_params.items() 
                            if k not in ["http_referer", "x_title"]}
        data.update(additional_params)
        
        # Effectuer la requête
        response = requests.post(
            self.config.api_url,
            headers=headers,
            json=data,
            timeout=self.config.timeout
        )
        
        # Vérifier la réponse
        if response.status_code != 200:
            raise Exception(f"Erreur OpenRouter: {response.status_code} - {response.text}")
        
        # Extraire l'embedding
        result = response.json()
        embedding = result["data"][0]["embedding"]
        
        # Normaliser si nécessaire
        if self.config.normalize:
            embedding = self._normalize_vector(embedding)
        
        return Vector(embedding, model_name=self.config.model_name)
    
    def embed_batch(self, texts: List[str]) -> List[Vector]:
        """
        Génère des embeddings pour une liste de textes avec l'API OpenRouter.
        
        Args:
            texts: Liste de textes à encoder.
            
        Returns:
            Liste de vecteurs d'embedding.
        """
        # Diviser les textes en lots
        batches = [texts[i:i + self.config.batch_size] for i in range(0, len(texts), self.config.batch_size)]
        
        # Traiter chaque lot
        all_embeddings = []
        for batch in batches:
            # Préparer les en-têtes
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.config.api_key}",
                "HTTP-Referer": self.config.additional_params.get("http_referer", "http://localhost"),
                "X-Title": self.config.additional_params.get("x_title", "Embedding API")
            }
            
            # Préparer les données
            data = {
                "input": batch,
                "model": self.config.model_name
            }
            
            # Ajouter les paramètres supplémentaires (sauf ceux déjà utilisés dans les en-têtes)
            additional_params = {k: v for k, v in self.config.additional_params.items() 
                                if k not in ["http_referer", "x_title"]}
            data.update(additional_params)
            
            # Effectuer la requête
            response = requests.post(
                self.config.api_url,
                headers=headers,
                json=data,
                timeout=self.config.timeout
            )
            
            # Vérifier la réponse
            if response.status_code != 200:
                raise Exception(f"Erreur OpenRouter: {response.status_code} - {response.text}")
            
            # Extraire les embeddings
            result = response.json()
            batch_embeddings = [item["embedding"] for item in result["data"]]
            
            # Normaliser si nécessaire
            if self.config.normalize:
                batch_embeddings = [self._normalize_vector(emb) for emb in batch_embeddings]
            
            # Créer les vecteurs
            vectors = [Vector(emb, model_name=self.config.model_name) for emb in batch_embeddings]
            all_embeddings.extend(vectors)
        
        return all_embeddings
