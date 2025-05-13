"""
Module pour l'interface avec le stockage vectoriel Qdrant.
Ce module fournit des classes pour interagir avec Qdrant pour le stockage et la recherche de vecteurs.
"""

import os
import json
import time
import requests
from typing import List, Dict, Any, Optional, Union, Tuple
from datetime import datetime

from embedding_manager import Vector, Embedding, EmbeddingCollection


class QdrantConfig:
    """
    Configuration pour la connexion à Qdrant.
    """
    
    def __init__(
        self,
        host: str = "localhost",
        port: int = 6333,
        api_key: Optional[str] = None,
        https: bool = False,
        timeout: int = 10,
        prefix: str = ""
    ):
        """
        Initialise la configuration Qdrant.
        
        Args:
            host: Hôte du serveur Qdrant.
            port: Port du serveur Qdrant.
            api_key: Clé API pour l'authentification (optionnelle).
            https: Si True, utilise HTTPS au lieu de HTTP.
            timeout: Timeout pour les requêtes en secondes.
            prefix: Préfixe pour les URL (optionnel).
        """
        self.host = host
        self.port = port
        self.api_key = api_key
        self.https = https
        self.timeout = timeout
        self.prefix = prefix
    
    @property
    def base_url(self) -> str:
        """
        Retourne l'URL de base pour les requêtes Qdrant.
        
        Returns:
            URL de base.
        """
        protocol = "https" if self.https else "http"
        return f"{protocol}://{self.host}:{self.port}{self.prefix}"
    
    def get_headers(self) -> Dict[str, str]:
        """
        Retourne les en-têtes HTTP pour les requêtes Qdrant.
        
        Returns:
            En-têtes HTTP.
        """
        headers = {
            "Content-Type": "application/json"
        }
        
        if self.api_key:
            headers["API-Key"] = self.api_key
        
        return headers
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la configuration en dictionnaire.
        
        Returns:
            Dictionnaire représentant la configuration.
        """
        return {
            "host": self.host,
            "port": self.port,
            "api_key": self.api_key,
            "https": self.https,
            "timeout": self.timeout,
            "prefix": self.prefix
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'QdrantConfig':
        """
        Crée une configuration à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant la configuration.
            
        Returns:
            Configuration créée.
        """
        return cls(
            host=data.get("host", "localhost"),
            port=data.get("port", 6333),
            api_key=data.get("api_key"),
            https=data.get("https", False),
            timeout=data.get("timeout", 10),
            prefix=data.get("prefix", "")
        )
    
    @classmethod
    def from_env(cls) -> 'QdrantConfig':
        """
        Crée une configuration à partir des variables d'environnement.
        
        Returns:
            Configuration créée.
        """
        return cls(
            host=os.environ.get("QDRANT_HOST", "localhost"),
            port=int(os.environ.get("QDRANT_PORT", "6333")),
            api_key=os.environ.get("QDRANT_API_KEY"),
            https=os.environ.get("QDRANT_HTTPS", "false").lower() == "true",
            timeout=int(os.environ.get("QDRANT_TIMEOUT", "10")),
            prefix=os.environ.get("QDRANT_PREFIX", "")
        )
    
    def __repr__(self) -> str:
        """
        Représentation de la configuration.
        
        Returns:
            Représentation sous forme de chaîne.
        """
        return f"QdrantConfig(host='{self.host}', port={self.port}, https={self.https})"


class QdrantClient:
    """
    Client pour interagir avec Qdrant.
    """
    
    def __init__(self, config: Optional[QdrantConfig] = None):
        """
        Initialise le client Qdrant.
        
        Args:
            config: Configuration Qdrant (utilise la configuration par défaut si None).
        """
        self.config = config or QdrantConfig()
    
    def _make_request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None
    ) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Effectue une requête HTTP vers Qdrant.
        
        Args:
            method: Méthode HTTP (GET, POST, PUT, DELETE).
            endpoint: Point de terminaison de l'API.
            data: Données à envoyer (pour POST, PUT).
            params: Paramètres de requête (pour GET).
            
        Returns:
            Tuple (succès, résultat).
        """
        url = f"{self.config.base_url}{endpoint}"
        headers = self.config.get_headers()
        
        try:
            if method == "GET":
                response = requests.get(url, headers=headers, params=params, timeout=self.config.timeout)
            elif method == "POST":
                response = requests.post(url, headers=headers, json=data, timeout=self.config.timeout)
            elif method == "PUT":
                response = requests.put(url, headers=headers, json=data, timeout=self.config.timeout)
            elif method == "DELETE":
                response = requests.delete(url, headers=headers, json=data, timeout=self.config.timeout)
            else:
                return False, f"Méthode HTTP non supportée: {method}"
            
            if response.status_code >= 200 and response.status_code < 300:
                try:
                    return True, response.json()
                except json.JSONDecodeError:
                    return True, response.text
            else:
                return False, f"Erreur {response.status_code}: {response.text}"
        
        except requests.exceptions.RequestException as e:
            return False, f"Erreur de requête: {str(e)}"
    
    def check_health(self) -> bool:
        """
        Vérifie si le serveur Qdrant est en ligne.
        
        Returns:
            True si le serveur est en ligne, False sinon.
        """
        success, _ = self._make_request("GET", "/healthz")
        return success
    
    def get_collections(self) -> Tuple[bool, List[str]]:
        """
        Récupère la liste des collections.
        
        Returns:
            Tuple (succès, liste des collections).
        """
        success, result = self._make_request("GET", "/collections")
        
        if success and isinstance(result, dict) and "result" in result and "collections" in result["result"]:
            collections = [collection["name"] for collection in result["result"]["collections"]]
            return True, collections
        
        return False, []
    
    def collection_exists(self, collection_name: str) -> bool:
        """
        Vérifie si une collection existe.
        
        Args:
            collection_name: Nom de la collection.
            
        Returns:
            True si la collection existe, False sinon.
        """
        success, result = self._make_request("GET", f"/collections/{collection_name}")
        return success
    
    def create_collection(
        self,
        collection_name: str,
        vector_size: int,
        distance: str = "Cosine",
        on_disk_payload: bool = False,
        optimizers_config: Optional[Dict[str, Any]] = None
    ) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Crée une nouvelle collection.
        
        Args:
            collection_name: Nom de la collection.
            vector_size: Taille des vecteurs.
            distance: Métrique de distance (Cosine, Euclid, Dot).
            on_disk_payload: Si True, stocke les payloads sur disque.
            optimizers_config: Configuration des optimiseurs.
            
        Returns:
            Tuple (succès, résultat).
        """
        data = {
            "vectors": {
                "size": vector_size,
                "distance": distance
            },
            "optimizers_config": optimizers_config or {},
            "on_disk_payload": on_disk_payload
        }
        
        return self._make_request("PUT", f"/collections/{collection_name}", data=data)
    
    def delete_collection(self, collection_name: str) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Supprime une collection.
        
        Args:
            collection_name: Nom de la collection.
            
        Returns:
            Tuple (succès, résultat).
        """
        return self._make_request("DELETE", f"/collections/{collection_name}")
    
    def get_collection_info(self, collection_name: str) -> Tuple[bool, Dict[str, Any]]:
        """
        Récupère les informations sur une collection.
        
        Args:
            collection_name: Nom de la collection.
            
        Returns:
            Tuple (succès, informations).
        """
        success, result = self._make_request("GET", f"/collections/{collection_name}")
        
        if success and isinstance(result, dict) and "result" in result:
            return True, result["result"]
        
        return False, {}
    
    def create_payload_index(
        self,
        collection_name: str,
        field_name: str,
        field_schema: str = "keyword"
    ) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Crée un index sur un champ de payload.
        
        Args:
            collection_name: Nom de la collection.
            field_name: Nom du champ.
            field_schema: Type de schéma (keyword, integer, float, geo).
            
        Returns:
            Tuple (succès, résultat).
        """
        data = {
            "field_name": field_name,
            "field_schema": field_schema
        }
        
        return self._make_request("PUT", f"/collections/{collection_name}/index", data=data)
    
    def upsert_points(
        self,
        collection_name: str,
        points: List[Dict[str, Any]]
    ) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Insère ou met à jour des points dans une collection.
        
        Args:
            collection_name: Nom de la collection.
            points: Liste des points à insérer ou mettre à jour.
            
        Returns:
            Tuple (succès, résultat).
        """
        data = {
            "points": points
        }
        
        return self._make_request("PUT", f"/collections/{collection_name}/points", data=data)
    
    def delete_points(
        self,
        collection_name: str,
        points_selector: Dict[str, Any]
    ) -> Tuple[bool, Union[Dict[str, Any], str]]:
        """
        Supprime des points d'une collection.
        
        Args:
            collection_name: Nom de la collection.
            points_selector: Sélecteur de points (filter ou ids).
            
        Returns:
            Tuple (succès, résultat).
        """
        return self._make_request("POST", f"/collections/{collection_name}/points/delete", data=points_selector)
    
    def search_points(
        self,
        collection_name: str,
        vector: List[float],
        limit: int = 10,
        filter: Optional[Dict[str, Any]] = None,
        with_payload: bool = True,
        with_vector: bool = False
    ) -> Tuple[bool, List[Dict[str, Any]]]:
        """
        Recherche des points similaires à un vecteur.
        
        Args:
            collection_name: Nom de la collection.
            vector: Vecteur de requête.
            limit: Nombre maximum de résultats.
            filter: Filtre sur les payloads.
            with_payload: Si True, inclut les payloads dans les résultats.
            with_vector: Si True, inclut les vecteurs dans les résultats.
            
        Returns:
            Tuple (succès, résultats).
        """
        data = {
            "vector": vector,
            "limit": limit,
            "with_payload": with_payload,
            "with_vector": with_vector
        }
        
        if filter:
            data["filter"] = filter
        
        success, result = self._make_request("POST", f"/collections/{collection_name}/points/search", data=data)
        
        if success and isinstance(result, dict) and "result" in result:
            return True, result["result"]
        
        return False, []
