#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de recherche vectorielle thématique.

Ce module fournit des fonctionnalités pour effectuer des recherches
vectorielles sur les éléments thématiques.
"""

import os
import sys
import json
import glob
import numpy as np
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Tuple
from pathlib import Path
import requests
from collections import defaultdict

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

class ThematicVectorSearch:
    """Classe pour la recherche vectorielle thématique."""
    
    def __init__(self, storage_path: str, embeddings_path: Optional[str] = None,
                embedding_model: str = "openrouter/qwen/qwen3-235b-a22b",
                api_key: Optional[str] = None,
                api_url: Optional[str] = None):
        """
        Initialise le gestionnaire de recherche vectorielle thématique.
        
        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            embeddings_path: Chemin vers le répertoire de stockage des embeddings (optionnel)
            embedding_model: Modèle d'embedding à utiliser (défaut: "openrouter/qwen/qwen3-235b-a22b")
            api_key: Clé API pour le service d'embedding (optionnel)
            api_url: URL de l'API pour le service d'embedding (optionnel)
        """
        self.storage_path = storage_path
        
        # Utiliser un sous-répertoire "_embeddings" par défaut
        if embeddings_path is None:
            self.embeddings_path = os.path.join(storage_path, "_embeddings")
        else:
            self.embeddings_path = embeddings_path
        
        # Créer le répertoire d'embeddings s'il n'existe pas
        os.makedirs(self.embeddings_path, exist_ok=True)
        
        # Configuration du modèle d'embedding
        self.embedding_model = embedding_model
        self.api_key = api_key or os.environ.get("OPENROUTER_API_KEY")
        self.api_url = api_url or "https://openrouter.ai/api/v1/embeddings"
        
        # Cache des embeddings
        self.embeddings_cache = {}
    
    def generate_embedding(self, text: str) -> Optional[List[float]]:
        """
        Génère un embedding pour un texte donné.
        
        Args:
            text: Texte à encoder
            
        Returns:
            Vecteur d'embedding ou None en cas d'erreur
        """
        if not self.api_key:
            print("Erreur: Clé API non définie pour le service d'embedding")
            return None
        
        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            data = {
                "model": self.embedding_model,
                "input": text
            }
            
            response = requests.post(self.api_url, headers=headers, json=data)
            response.raise_for_status()
            
            result = response.json()
            
            if "data" in result and len(result["data"]) > 0 and "embedding" in result["data"][0]:
                return result["data"][0]["embedding"]
            else:
                print(f"Erreur: Format de réponse inattendu: {result}")
                return None
        
        except Exception as e:
            print(f"Erreur lors de la génération de l'embedding: {str(e)}")
            return None
    
    def compute_similarity(self, embedding1: List[float], embedding2: List[float]) -> float:
        """
        Calcule la similarité cosinus entre deux embeddings.
        
        Args:
            embedding1: Premier vecteur d'embedding
            embedding2: Deuxième vecteur d'embedding
            
        Returns:
            Score de similarité cosinus (entre -1 et 1)
        """
        # Convertir en tableaux numpy
        vec1 = np.array(embedding1)
        vec2 = np.array(embedding2)
        
        # Calculer la similarité cosinus
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return dot_product / (norm1 * norm2)
    
    def index_item(self, item: Dict[str, Any]) -> bool:
        """
        Indexe un élément pour la recherche vectorielle.
        
        Args:
            item: Élément à indexer
            
        Returns:
            True si l'indexation a réussi, False sinon
        """
        if "id" not in item:
            print("Erreur: L'élément n'a pas d'identifiant")
            return False
        
        item_id = item["id"]
        
        # Extraire le texte à encoder
        text_to_encode = self._extract_text_for_embedding(item)
        
        # Générer l'embedding
        embedding = self.generate_embedding(text_to_encode)
        
        if embedding is None:
            return False
        
        # Sauvegarder l'embedding
        embedding_data = {
            "item_id": item_id,
            "embedding": embedding,
            "indexed_at": datetime.now().isoformat()
        }
        
        embedding_path = os.path.join(self.embeddings_path, f"{item_id}.json")
        
        try:
            with open(embedding_path, 'w', encoding='utf-8') as f:
                json.dump(embedding_data, f, ensure_ascii=False, indent=2)
            
            # Mettre à jour le cache
            self.embeddings_cache[item_id] = embedding
            
            return True
        except Exception as e:
            print(f"Erreur lors de la sauvegarde de l'embedding pour l'élément {item_id}: {str(e)}")
            return False
    
    def index_items_by_theme(self, theme: str) -> Dict[str, Any]:
        """
        Indexe tous les éléments d'un thème pour la recherche vectorielle.
        
        Args:
            theme: Thème des éléments à indexer
            
        Returns:
            Statistiques sur l'indexation
        """
        theme_dir = os.path.join(self.storage_path, theme)
        
        if not os.path.exists(theme_dir) or not os.path.isdir(theme_dir):
            return {"indexed_count": 0, "error_count": 0, "skipped_count": 0}
        
        # Récupérer tous les fichiers JSON dans le répertoire thématique
        json_files = glob.glob(os.path.join(theme_dir, "*.json"))
        
        # Statistiques
        stats = {
            "total_items": len(json_files),
            "indexed_count": 0,
            "error_count": 0,
            "skipped_count": 0
        }
        
        # Indexer chaque élément
        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    
                    # Vérifier si l'élément est déjà indexé
                    item_id = item["id"]
                    embedding_path = os.path.join(self.embeddings_path, f"{item_id}.json")
                    
                    if os.path.exists(embedding_path):
                        stats["skipped_count"] += 1
                        continue
                    
                    # Indexer l'élément
                    if self.index_item(item):
                        stats["indexed_count"] += 1
                    else:
                        stats["error_count"] += 1
            
            except Exception as e:
                print(f"Erreur lors de l'indexation du fichier {file_path}: {str(e)}")
                stats["error_count"] += 1
        
        return stats
    
    def search_similar(self, query: str, themes: Optional[List[str]] = None,
                     top_k: int = 10, similarity_threshold: float = 0.7) -> List[Dict[str, Any]]:
        """
        Recherche des éléments similaires à une requête textuelle.
        
        Args:
            query: Requête textuelle
            themes: Liste des thèmes à inclure dans la recherche (optionnel)
            top_k: Nombre maximum d'éléments à récupérer (défaut: 10)
            similarity_threshold: Seuil de similarité minimum (défaut: 0.7)
            
        Returns:
            Liste des éléments similaires avec leur score de similarité
        """
        # Générer l'embedding de la requête
        query_embedding = self.generate_embedding(query)
        
        if query_embedding is None:
            return []
        
        # Charger tous les embeddings
        self._load_embeddings_cache()
        
        # Calculer les similarités
        similarities = []
        
        for item_id, embedding in self.embeddings_cache.items():
            # Calculer la similarité
            similarity = self.compute_similarity(query_embedding, embedding)
            
            # Ajouter à la liste si la similarité est suffisante
            if similarity >= similarity_threshold:
                similarities.append((item_id, similarity))
        
        # Trier par similarité décroissante
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        # Limiter au nombre d'éléments demandé
        top_similarities = similarities[:top_k]
        
        # Récupérer les éléments correspondants
        results = []
        for item_id, similarity in top_similarities:
            # Récupérer l'élément
            item = self._get_item_by_id(item_id)
            
            if item is not None:
                # Filtrer par thème si nécessaire
                if themes is None or self._item_has_theme(item, themes):
                    # Ajouter le score de similarité
                    item_with_score = item.copy()
                    item_with_score["_similarity_score"] = similarity
                    
                    results.append(item_with_score)
        
        return results
    
    def find_theme_clusters(self, min_similarity: float = 0.8, 
                          min_cluster_size: int = 3) -> List[Dict[str, Any]]:
        """
        Identifie des clusters thématiques basés sur la similarité vectorielle.
        
        Args:
            min_similarity: Similarité minimum pour considérer deux éléments comme similaires
            min_cluster_size: Taille minimum d'un cluster
            
        Returns:
            Liste des clusters identifiés
        """
        # Charger tous les embeddings
        self._load_embeddings_cache()
        
        # Matrice de similarité
        item_ids = list(self.embeddings_cache.keys())
        n_items = len(item_ids)
        
        if n_items == 0:
            return []
        
        # Calculer les similarités entre tous les éléments
        similarities = {}
        for i in range(n_items):
            item_id1 = item_ids[i]
            embedding1 = self.embeddings_cache[item_id1]
            
            for j in range(i + 1, n_items):
                item_id2 = item_ids[j]
                embedding2 = self.embeddings_cache[item_id2]
                
                # Calculer la similarité
                similarity = self.compute_similarity(embedding1, embedding2)
                
                # Stocker la similarité si elle est suffisante
                if similarity >= min_similarity:
                    if item_id1 not in similarities:
                        similarities[item_id1] = {}
                    
                    if item_id2 not in similarities:
                        similarities[item_id2] = {}
                    
                    similarities[item_id1][item_id2] = similarity
                    similarities[item_id2][item_id1] = similarity
        
        # Identifier les clusters (implémentation simple)
        visited = set()
        clusters = []
        
        for item_id in item_ids:
            if item_id in visited:
                continue
            
            # Démarrer un nouveau cluster
            cluster = [item_id]
            visited.add(item_id)
            
            # Ajouter les éléments similaires
            i = 0
            while i < len(cluster):
                current_id = cluster[i]
                
                if current_id in similarities:
                    for similar_id, similarity in similarities[current_id].items():
                        if similar_id not in visited:
                            cluster.append(similar_id)
                            visited.add(similar_id)
                
                i += 1
            
            # Ajouter le cluster s'il est suffisamment grand
            if len(cluster) >= min_cluster_size:
                # Récupérer les éléments du cluster
                cluster_items = []
                for cluster_id in cluster:
                    item = self._get_item_by_id(cluster_id)
                    if item is not None:
                        cluster_items.append(item)
                
                # Identifier les thèmes communs
                common_themes = self._identify_common_themes(cluster_items)
                
                clusters.append({
                    "size": len(cluster),
                    "items": cluster_items,
                    "common_themes": common_themes
                })
        
        # Trier les clusters par taille décroissante
        clusters.sort(key=lambda x: x["size"], reverse=True)
        
        return clusters
    
    def _extract_text_for_embedding(self, item: Dict[str, Any]) -> str:
        """
        Extrait le texte à encoder à partir d'un élément.
        
        Args:
            item: Élément à traiter
            
        Returns:
            Texte à encoder
        """
        text_parts = []
        
        # Ajouter le contenu
        if "content" in item:
            text_parts.append(item["content"])
        
        # Ajouter les métadonnées importantes
        if "metadata" in item:
            metadata = item["metadata"]
            
            # Ajouter le titre
            if "title" in metadata:
                text_parts.append(f"Titre: {metadata['title']}")
            
            # Ajouter les tags
            if "tags" in metadata and isinstance(metadata["tags"], list):
                text_parts.append(f"Tags: {', '.join(metadata['tags'])}")
            
            # Ajouter les thèmes
            if "themes" in metadata:
                themes_str = ", ".join(metadata["themes"].keys())
                text_parts.append(f"Thèmes: {themes_str}")
        
        # Joindre toutes les parties
        return "\n\n".join(text_parts)
    
    def _load_embeddings_cache(self) -> None:
        """
        Charge tous les embeddings dans le cache.
        """
        # Réinitialiser le cache
        self.embeddings_cache = {}
        
        # Récupérer tous les fichiers d'embedding
        embedding_files = glob.glob(os.path.join(self.embeddings_path, "*.json"))
        
        for file_path in embedding_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                    if "item_id" in data and "embedding" in data:
                        self.embeddings_cache[data["item_id"]] = data["embedding"]
            except Exception as e:
                print(f"Erreur lors du chargement de l'embedding {file_path}: {str(e)}")
    
    def _get_item_by_id(self, item_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un élément par son identifiant.
        
        Args:
            item_id: Identifiant de l'élément
            
        Returns:
            Élément ou None si l'élément n'existe pas
        """
        item_path = os.path.join(self.storage_path, f"{item_id}.json")
        
        if not os.path.exists(item_path):
            return None
        
        try:
            with open(item_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Erreur lors du chargement de l'élément {item_id}: {str(e)}")
            return None
    
    def _item_has_theme(self, item: Dict[str, Any], themes: List[str]) -> bool:
        """
        Vérifie si un élément a au moins un des thèmes spécifiés.
        
        Args:
            item: Élément à vérifier
            themes: Liste des thèmes à rechercher
            
        Returns:
            True si l'élément a au moins un des thèmes, False sinon
        """
        if "metadata" not in item or "themes" not in item["metadata"]:
            return False
        
        item_themes = item["metadata"]["themes"]
        
        for theme in themes:
            if theme in item_themes:
                return True
        
        return False
    
    def _identify_common_themes(self, items: List[Dict[str, Any]]) -> Dict[str, float]:
        """
        Identifie les thèmes communs à un ensemble d'éléments.
        
        Args:
            items: Liste d'éléments
            
        Returns:
            Dictionnaire des thèmes communs avec leur fréquence
        """
        if not items:
            return {}
        
        # Compter les occurrences de chaque thème
        theme_counts = defaultdict(int)
        
        for item in items:
            if "metadata" in item and "themes" in item["metadata"]:
                for theme in item["metadata"]["themes"]:
                    theme_counts[theme] += 1
        
        # Calculer la fréquence de chaque thème
        n_items = len(items)
        theme_frequencies = {theme: count / n_items for theme, count in theme_counts.items()}
        
        # Trier par fréquence décroissante
        sorted_themes = dict(sorted(theme_frequencies.items(), key=lambda x: x[1], reverse=True))
        
        return sorted_themes
