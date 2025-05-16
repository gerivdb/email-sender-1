#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de vues thématiques personnalisées.

Ce module fournit des fonctionnalités pour créer et gérer des vues
personnalisées basées sur des thèmes et des critères de recherche.
"""

import os
import sys
import json
import glob
import copy
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Set, Tuple
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Import local
from src.orchestrator.thematic_crud.advanced_search import ThematicAdvancedSearch

class ThematicView:
    """Classe représentant une vue thématique personnalisée."""
    
    def __init__(self, name: str, description: str = "", 
                search_criteria: Optional[Dict[str, Any]] = None):
        """
        Initialise une vue thématique personnalisée.
        
        Args:
            name: Nom de la vue
            description: Description de la vue (optionnel)
            search_criteria: Critères de recherche pour la vue (optionnel)
        """
        self.id = f"view_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        self.name = name
        self.description = description
        self.created_at = datetime.now().isoformat()
        self.updated_at = self.created_at
        self.search_criteria = search_criteria or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """
        Convertit la vue en dictionnaire.
        
        Returns:
            Dictionnaire représentant la vue
        """
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "search_criteria": self.search_criteria
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'ThematicView':
        """
        Crée une vue à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire représentant la vue
            
        Returns:
            Instance de ThematicView
        """
        view = cls(data["name"], data.get("description", ""))
        view.id = data["id"]
        view.created_at = data["created_at"]
        view.updated_at = data["updated_at"]
        view.search_criteria = data["search_criteria"]
        return view

class ThematicViewManager:
    """Classe pour gérer les vues thématiques personnalisées."""
    
    def __init__(self, storage_path: str, views_path: Optional[str] = None):
        """
        Initialise le gestionnaire de vues thématiques.
        
        Args:
            storage_path: Chemin vers le répertoire de stockage des données
            views_path: Chemin vers le répertoire de stockage des vues (optionnel)
        """
        self.storage_path = storage_path
        
        # Utiliser un sous-répertoire "_views" par défaut
        if views_path is None:
            self.views_path = os.path.join(storage_path, "_views")
        else:
            self.views_path = views_path
        
        # Créer le répertoire de vues s'il n'existe pas
        os.makedirs(self.views_path, exist_ok=True)
        
        # Initialiser le moteur de recherche avancée
        self.search_engine = ThematicAdvancedSearch(storage_path)
    
    def create_view(self, name: str, description: str = "", 
                   search_criteria: Optional[Dict[str, Any]] = None) -> ThematicView:
        """
        Crée une nouvelle vue thématique.
        
        Args:
            name: Nom de la vue
            description: Description de la vue (optionnel)
            search_criteria: Critères de recherche pour la vue (optionnel)
            
        Returns:
            Vue thématique créée
        """
        # Créer la vue
        view = ThematicView(name, description, search_criteria)
        
        # Sauvegarder la vue
        self._save_view(view)
        
        return view
    
    def update_view(self, view_id: str, name: Optional[str] = None, 
                   description: Optional[str] = None,
                   search_criteria: Optional[Dict[str, Any]] = None) -> Optional[ThematicView]:
        """
        Met à jour une vue thématique existante.
        
        Args:
            view_id: Identifiant de la vue à mettre à jour
            name: Nouveau nom de la vue (optionnel)
            description: Nouvelle description de la vue (optionnel)
            search_criteria: Nouveaux critères de recherche pour la vue (optionnel)
            
        Returns:
            Vue thématique mise à jour ou None si la vue n'existe pas
        """
        # Récupérer la vue
        view = self.get_view(view_id)
        
        if view is None:
            return None
        
        # Mettre à jour les attributs
        if name is not None:
            view.name = name
        
        if description is not None:
            view.description = description
        
        if search_criteria is not None:
            view.search_criteria = search_criteria
        
        # Mettre à jour la date de modification
        view.updated_at = datetime.now().isoformat()
        
        # Sauvegarder la vue
        self._save_view(view)
        
        return view
    
    def delete_view(self, view_id: str) -> bool:
        """
        Supprime une vue thématique.
        
        Args:
            view_id: Identifiant de la vue à supprimer
            
        Returns:
            True si la vue a été supprimée, False sinon
        """
        view_path = os.path.join(self.views_path, f"{view_id}.json")
        
        if not os.path.exists(view_path):
            return False
        
        try:
            os.remove(view_path)
            return True
        except Exception as e:
            print(f"Erreur lors de la suppression de la vue {view_id}: {str(e)}")
            return False
    
    def get_view(self, view_id: str) -> Optional[ThematicView]:
        """
        Récupère une vue thématique par son identifiant.
        
        Args:
            view_id: Identifiant de la vue à récupérer
            
        Returns:
            Vue thématique ou None si la vue n'existe pas
        """
        view_path = os.path.join(self.views_path, f"{view_id}.json")
        
        if not os.path.exists(view_path):
            return None
        
        try:
            with open(view_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return ThematicView.from_dict(data)
        except Exception as e:
            print(f"Erreur lors du chargement de la vue {view_id}: {str(e)}")
            return None
    
    def get_all_views(self) -> List[ThematicView]:
        """
        Récupère toutes les vues thématiques.
        
        Returns:
            Liste des vues thématiques
        """
        view_files = glob.glob(os.path.join(self.views_path, "*.json"))
        
        views = []
        for view_path in view_files:
            try:
                with open(view_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    views.append(ThematicView.from_dict(data))
            except Exception as e:
                print(f"Erreur lors du chargement de la vue {view_path}: {str(e)}")
        
        # Trier les vues par nom
        views.sort(key=lambda v: v.name)
        
        return views
    
    def execute_view(self, view_id: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """
        Exécute une vue thématique pour récupérer les éléments correspondants.
        
        Args:
            view_id: Identifiant de la vue à exécuter
            limit: Nombre maximum d'éléments à récupérer (défaut: 100)
            offset: Décalage pour la pagination (défaut: 0)
            
        Returns:
            Liste des éléments correspondant aux critères de la vue
        """
        # Récupérer la vue
        view = self.get_view(view_id)
        
        if view is None:
            return []
        
        # Récupérer les critères de recherche
        search_criteria = view.search_criteria
        
        # Déterminer le type de recherche à effectuer
        search_type = search_criteria.get("search_type", "multi_criteria")
        
        if search_type == "multi_criteria":
            # Recherche multi-critères
            return self.search_engine.search_by_multi_criteria(
                themes=search_criteria.get("themes"),
                content_query=search_criteria.get("content_query"),
                metadata_filters=search_criteria.get("metadata_filters"),
                date_range=search_criteria.get("date_range"),
                theme_weights=search_criteria.get("theme_weights"),
                sort_by=search_criteria.get("sort_by", "relevance"),
                limit=limit,
                offset=offset
            )
        
        elif search_type == "theme_relationships":
            # Recherche par relations entre thèmes
            return self.search_engine.search_by_theme_relationships(
                primary_theme=search_criteria.get("primary_theme", ""),
                related_themes=search_criteria.get("related_themes"),
                relationship_type=search_criteria.get("relationship_type", "any"),
                min_overlap=search_criteria.get("min_overlap", 1),
                limit=limit,
                offset=offset
            )
        
        elif search_type == "theme_hierarchy":
            # Recherche par hiérarchie thématique
            return self.search_engine.search_by_theme_hierarchy(
                theme=search_criteria.get("theme", ""),
                include_subthemes=search_criteria.get("include_subthemes", True),
                include_parent_themes=search_criteria.get("include_parent_themes", False),
                max_depth=search_criteria.get("max_depth", 3),
                limit=limit,
                offset=offset
            )
        
        else:
            # Type de recherche non supporté
            print(f"Type de recherche non supporté: {search_type}")
            return []
    
    def _save_view(self, view: ThematicView) -> None:
        """
        Sauvegarde une vue thématique.
        
        Args:
            view: Vue thématique à sauvegarder
        """
        view_path = os.path.join(self.views_path, f"{view.id}.json")
        
        try:
            with open(view_path, 'w', encoding='utf-8') as f:
                json.dump(view.to_dict(), f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Erreur lors de la sauvegarde de la vue {view.id}: {str(e)}")
    
    def clone_view(self, view_id: str, new_name: Optional[str] = None) -> Optional[ThematicView]:
        """
        Clone une vue thématique existante.
        
        Args:
            view_id: Identifiant de la vue à cloner
            new_name: Nouveau nom pour la vue clonée (optionnel)
            
        Returns:
            Vue thématique clonée ou None si la vue source n'existe pas
        """
        # Récupérer la vue source
        source_view = self.get_view(view_id)
        
        if source_view is None:
            return None
        
        # Déterminer le nom de la vue clonée
        if new_name is None:
            new_name = f"Copie de {source_view.name}"
        
        # Créer une nouvelle vue avec les mêmes critères
        cloned_view = self.create_view(
            name=new_name,
            description=source_view.description,
            search_criteria=copy.deepcopy(source_view.search_criteria)
        )
        
        return cloned_view
