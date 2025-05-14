#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion de mémoire pour MCP.

Ce module fournit une classe de base pour gérer les mémoires dans le contexte MCP.
Il permet d'ajouter, rechercher, lister et supprimer des mémoires.
"""

import os
import json
import uuid
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional, Callable, Union

# Configuration du logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp.memory")

class MemoryManager:
    """
    Gestionnaire de mémoire pour MCP.
    
    Cette classe fournit les fonctionnalités de base pour gérer les mémoires :
    - Ajouter des mémoires
    - Rechercher des mémoires
    - Lister les mémoires
    - Supprimer des mémoires
    """
    
    def __init__(self, storage_path: str = None):
        """
        Initialise le gestionnaire de mémoire.
        
        Args:
            storage_path (str, optional): Chemin vers le fichier de stockage des mémoires.
                Si non spécifié, utilise un emplacement par défaut.
        """
        self.memories = {}  # Dict[str, Dict[str, Any]]
        
        # Définir le chemin de stockage
        if storage_path:
            self.storage_path = storage_path
        else:
            # Chemin par défaut dans le dossier de l'utilisateur
            user_home = os.path.expanduser("~")
            mcp_dir = os.path.join(user_home, ".mcp", "memory")
            os.makedirs(mcp_dir, exist_ok=True)
            self.storage_path = os.path.join(mcp_dir, "memories.json")
        
        # Charger les mémoires existantes
        self._load_memories()
        
        logger.info(f"Gestionnaire de mémoire initialisé avec stockage: {self.storage_path}")
    
    def _load_memories(self) -> None:
        """Charge les mémoires depuis le fichier de stockage."""
        if os.path.exists(self.storage_path):
            try:
                with open(self.storage_path, 'r', encoding='utf-8') as f:
                    self.memories = json.load(f)
                logger.info(f"Mémoires chargées: {len(self.memories)} entrées")
            except Exception as e:
                logger.error(f"Erreur lors du chargement des mémoires: {e}")
                self.memories = {}
        else:
            logger.info("Aucun fichier de mémoires existant, création d'un nouveau stockage")
            self.memories = {}
    
    def _save_memories(self) -> None:
        """Sauvegarde les mémoires dans le fichier de stockage."""
        try:
            with open(self.storage_path, 'w', encoding='utf-8') as f:
                json.dump(self.memories, f, ensure_ascii=False, indent=2)
            logger.info(f"Mémoires sauvegardées: {len(self.memories)} entrées")
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde des mémoires: {e}")
    
    def add_memory(self, content: str, metadata: Dict[str, Any] = None) -> str:
        """
        Ajoute une nouvelle mémoire.
        
        Args:
            content (str): Contenu de la mémoire
            metadata (Dict[str, Any], optional): Métadonnées associées à la mémoire
        
        Returns:
            str: Identifiant unique de la mémoire créée
        """
        # Générer un ID unique
        memory_id = str(uuid.uuid4())
        
        # Créer l'entrée de mémoire
        memory_entry = {
            "content": content,
            "metadata": metadata or {},
            "created_at": datetime.now().isoformat(),
            "updated_at": None
        }
        
        # Ajouter la mémoire au dictionnaire
        self.memories[memory_id] = memory_entry
        
        # Sauvegarder les mémoires
        self._save_memories()
        
        logger.info(f"Mémoire ajoutée avec ID: {memory_id}")
        return memory_id
    
    def get_memory(self, memory_id: str) -> Optional[Dict[str, Any]]:
        """
        Récupère une mémoire par son ID.
        
        Args:
            memory_id (str): Identifiant de la mémoire à récupérer
        
        Returns:
            Optional[Dict[str, Any]]: La mémoire si trouvée, None sinon
        """
        memory = self.memories.get(memory_id)
        if memory:
            return memory
        logger.warning(f"Mémoire non trouvée avec ID: {memory_id}")
        return None
    
    def update_memory(self, memory_id: str, content: str = None, metadata: Dict[str, Any] = None) -> bool:
        """
        Met à jour une mémoire existante.
        
        Args:
            memory_id (str): Identifiant de la mémoire à mettre à jour
            content (str, optional): Nouveau contenu de la mémoire
            metadata (Dict[str, Any], optional): Nouvelles métadonnées à fusionner
        
        Returns:
            bool: True si la mise à jour a réussi, False sinon
        """
        memory = self.memories.get(memory_id)
        if not memory:
            logger.warning(f"Tentative de mise à jour d'une mémoire inexistante: {memory_id}")
            return False
        
        # Mettre à jour le contenu si spécifié
        if content is not None:
            memory["content"] = content
        
        # Mettre à jour les métadonnées si spécifiées
        if metadata:
            memory["metadata"].update(metadata)
        
        # Mettre à jour la date de modification
        memory["updated_at"] = datetime.now().isoformat()
        
        # Sauvegarder les mémoires
        self._save_memories()
        
        logger.info(f"Mémoire mise à jour avec ID: {memory_id}")
        return True
    
    def delete_memory(self, memory_id: str) -> bool:
        """
        Supprime une mémoire.
        
        Args:
            memory_id (str): Identifiant de la mémoire à supprimer
        
        Returns:
            bool: True si la suppression a réussi, False sinon
        """
        if memory_id in self.memories:
            del self.memories[memory_id]
            self._save_memories()
            logger.info(f"Mémoire supprimée avec ID: {memory_id}")
            return True
        
        logger.warning(f"Tentative de suppression d'une mémoire inexistante: {memory_id}")
        return False
    
    def list_memories(self, filter_func: Callable[[Dict[str, Any]], bool] = None) -> List[Dict[str, Any]]:
        """
        Liste toutes les mémoires, avec filtrage optionnel.
        
        Args:
            filter_func (Callable[[Dict[str, Any]], bool], optional): 
                Fonction de filtrage qui prend une mémoire et retourne True si elle doit être incluse
        
        Returns:
            List[Dict[str, Any]]: Liste des mémoires correspondant au filtre
        """
        result = []
        
        for memory_id, memory in self.memories.items():
            # Ajouter l'ID à la mémoire pour le résultat
            memory_with_id = memory.copy()
            memory_with_id["id"] = memory_id
            
            # Appliquer le filtre si spécifié
            if filter_func is None or filter_func(memory):
                result.append(memory_with_id)
        
        logger.info(f"Mémoires listées: {len(result)} entrées")
        return result
    
    def search_memory(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Recherche des mémoires par correspondance simple.
        
        Note: Cette implémentation est basique et utilise une recherche textuelle simple.
        Pour une recherche plus avancée, il faudrait intégrer une base de données vectorielle.
        
        Args:
            query (str): Requête de recherche
            limit (int, optional): Nombre maximum de résultats à retourner
        
        Returns:
            List[Dict[str, Any]]: Liste des mémoires correspondant à la requête
        """
        results = []
        query = query.lower()
        
        for memory_id, memory in self.memories.items():
            content = memory["content"].lower()
            
            # Vérifier si la requête est dans le contenu
            if query in content:
                # Ajouter l'ID à la mémoire pour le résultat
                memory_with_id = memory.copy()
                memory_with_id["id"] = memory_id
                results.append(memory_with_id)
        
        # Trier les résultats par pertinence (implémentation basique)
        results.sort(key=lambda x: x["content"].lower().count(query), reverse=True)
        
        # Limiter le nombre de résultats
        results = results[:limit]
        
        logger.info(f"Recherche pour '{query}': {len(results)} résultats")
        return results
