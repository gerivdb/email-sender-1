#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de lecture et recherche thématique.

Ce module fournit des fonctionnalités pour lire et rechercher des éléments
de roadmap par thème et autres critères.
"""

import os
import sys
import json
import glob
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Set, Tuple
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

class ThematicReadSearch:
    """Classe pour la lecture et recherche thématique."""
    
    def __init__(self, storage_path: str):
        """
        Initialise le gestionnaire de lecture et recherche thématique.
        
        Args:
            storage_path: Chemin vers le répertoire de stockage des données
        """
        self.storage_path = storage_path
    
    def get_item(self, item_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère un élément par son identifiant.
        
        Args:
            item_id: Identifiant de l'élément à récupérer
            
        Returns:
            Élément récupéré ou None si l'élément n'existe pas
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
    
    def get_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Récupère les éléments par thème.
        
        Args:
            theme: Thème à rechercher
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant au thème
        """
        theme_dir = os.path.join(self.storage_path, theme)
        
        if not os.path.exists(theme_dir) or not os.path.isdir(theme_dir):
            return []
        
        # Récupérer tous les fichiers JSON dans le répertoire thématique
        json_files = glob.glob(os.path.join(theme_dir, "*.json"))
        
        # Trier les fichiers par date de modification (du plus récent au plus ancien)
        json_files.sort(key=os.path.getmtime, reverse=True)
        
        # Appliquer la pagination
        paginated_files = json_files[offset:offset + limit]
        
        # Charger les éléments
        items = []
        for file_path in paginated_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    items.append(item)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")
        
        return items
    
    def search_items(self, query: str, themes: Optional[List[str]] = None, 
                    metadata_filters: Optional[Dict[str, Any]] = None, 
                    limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Recherche des éléments par requête textuelle et filtres.
        
        Args:
            query: Requête textuelle à rechercher
            themes: Liste des thèmes à inclure dans la recherche (optionnel)
            metadata_filters: Filtres sur les métadonnées (optionnel)
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant aux critères de recherche
        """
        # Déterminer les répertoires à explorer
        if themes:
            directories = [os.path.join(self.storage_path, theme) for theme in themes]
            # Filtrer les répertoires inexistants
            directories = [d for d in directories if os.path.exists(d) and os.path.isdir(d)]
        else:
            # Explorer le répertoire principal
            directories = [self.storage_path]
        
        # Récupérer tous les fichiers JSON dans les répertoires
        json_files = []
        for directory in directories:
            json_files.extend(glob.glob(os.path.join(directory, "*.json")))
        
        # Éliminer les doublons
        json_files = list(set(json_files))
        
        # Rechercher dans les fichiers
        matching_items = []
        for file_path in json_files:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    item = json.load(f)
                    
                    # Vérifier si l'élément correspond à la requête
                    if self._matches_query(item, query) and self._matches_metadata_filters(item, metadata_filters):
                        matching_items.append(item)
            except Exception as e:
                print(f"Erreur lors du chargement du fichier {file_path}: {str(e)}")
        
        # Trier les éléments par pertinence
        matching_items.sort(key=lambda x: self._calculate_relevance(x, query), reverse=True)
        
        # Appliquer la pagination
        return matching_items[offset:offset + limit]
    
    def get_theme_statistics(self) -> Dict[str, Dict[str, Any]]:
        """
        Récupère des statistiques sur les thèmes.
        
        Returns:
            Dictionnaire des statistiques par thème
        """
        statistics = {}
        
        # Explorer les sous-répertoires (thèmes)
        for item in os.listdir(self.storage_path):
            theme_dir = os.path.join(self.storage_path, item)
            
            if os.path.isdir(theme_dir):
                theme = os.path.basename(theme_dir)
                
                # Compter les éléments
                json_files = glob.glob(os.path.join(theme_dir, "*.json"))
                count = len(json_files)
                
                # Calculer la date de dernière modification
                if json_files:
                    latest_file = max(json_files, key=os.path.getmtime)
                    last_modified = datetime.fromtimestamp(os.path.getmtime(latest_file)).isoformat()
                else:
                    last_modified = None
                
                statistics[theme] = {
                    "count": count,
                    "last_modified": last_modified
                }
        
        return statistics
    
    def _matches_query(self, item: Dict[str, Any], query: str) -> bool:
        """
        Vérifie si un élément correspond à une requête textuelle.
        
        Args:
            item: Élément à vérifier
            query: Requête textuelle
            
        Returns:
            True si l'élément correspond à la requête, False sinon
        """
        if not query:
            return True
        
        query = query.lower()
        
        # Vérifier dans le contenu
        if "content" in item and query in item["content"].lower():
            return True
        
        # Vérifier dans les métadonnées
        if "metadata" in item:
            metadata = item["metadata"]
            
            # Vérifier dans le titre
            if "title" in metadata and query in metadata["title"].lower():
                return True
            
            # Vérifier dans les tags
            if "tags" in metadata and isinstance(metadata["tags"], list):
                for tag in metadata["tags"]:
                    if query in tag.lower():
                        return True
        
        return False
    
    def _matches_metadata_filters(self, item: Dict[str, Any], 
                                 metadata_filters: Optional[Dict[str, Any]]) -> bool:
        """
        Vérifie si un élément correspond aux filtres de métadonnées.
        
        Args:
            item: Élément à vérifier
            metadata_filters: Filtres sur les métadonnées
            
        Returns:
            True si l'élément correspond aux filtres, False sinon
        """
        if not metadata_filters:
            return True
        
        if "metadata" not in item:
            return False
        
        metadata = item["metadata"]
        
        for key, value in metadata_filters.items():
            if key not in metadata:
                return False
            
            if isinstance(value, list):
                # Vérifier si au moins une valeur correspond
                if not isinstance(metadata[key], list) or not any(v in metadata[key] for v in value):
                    return False
            elif metadata[key] != value:
                return False
        
        return True
    
    def _calculate_relevance(self, item: Dict[str, Any], query: str) -> float:
        """
        Calcule la pertinence d'un élément par rapport à une requête.
        
        Args:
            item: Élément à évaluer
            query: Requête textuelle
            
        Returns:
            Score de pertinence
        """
        if not query:
            return 0.0
        
        query = query.lower()
        relevance = 0.0
        
        # Vérifier dans le contenu
        if "content" in item:
            content = item["content"].lower()
            # Compter les occurrences
            relevance += content.count(query) * 0.5
            # Bonus si le contenu commence par la requête
            if content.startswith(query):
                relevance += 2.0
        
        # Vérifier dans les métadonnées
        if "metadata" in item:
            metadata = item["metadata"]
            
            # Vérifier dans le titre (plus important)
            if "title" in metadata:
                title = metadata["title"].lower()
                relevance += title.count(query) * 2.0
                # Bonus si le titre commence par la requête
                if title.startswith(query):
                    relevance += 5.0
            
            # Vérifier dans les tags
            if "tags" in metadata and isinstance(metadata["tags"], list):
                for tag in metadata["tags"]:
                    if query in tag.lower():
                        relevance += 1.0
                    # Bonus si le tag est exactement la requête
                    if tag.lower() == query:
                        relevance += 3.0
        
        return relevance
