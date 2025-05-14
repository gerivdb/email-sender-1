#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation du Memory Manager.

Ce script montre comment utiliser le Memory Manager pour gérer les mémoires.
"""

import os
import sys
import json
import logging
import tempfile
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.mcp.memory_manager import MemoryManager, Memory
    from src.mcp.core.mcp.storage_provider import FileStorageProvider
    from src.mcp.core.mcp.embedding_provider import DummyEmbeddingProvider, CachedEmbeddingProvider
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("memory_manager_example")

def main():
    """
    Fonction principale.
    """
    # Créer un répertoire temporaire pour le stockage
    with tempfile.TemporaryDirectory() as temp_dir:
        storage_dir = os.path.join(temp_dir, "memories")
        cache_dir = os.path.join(temp_dir, "embeddings_cache")
        
        # Créer les fournisseurs
        storage_provider = FileStorageProvider(storage_dir)
        embedding_provider = DummyEmbeddingProvider(dimension=128)
        cached_embedding_provider = CachedEmbeddingProvider(embedding_provider, cache_dir)
        
        # Créer une instance du Memory Manager
        memory_manager = MemoryManager(
            storage_provider=storage_provider,
            embedding_provider=cached_embedding_provider
        )
        
        # Ajouter quelques mémoires
        logger.info("Ajout de mémoires...")
        memory_id1 = memory_manager.add_memory(
            content="Ceci est une mémoire sur Python. Python est un langage de programmation interprété, multi-paradigme et multiplateformes.",
            metadata={"type": "language", "tags": ["python", "programming"]}
        )
        
        memory_id2 = memory_manager.add_memory(
            content="JavaScript est un langage de programmation de scripts principalement employé dans les pages web interactives.",
            metadata={"type": "language", "tags": ["javascript", "web"]}
        )
        
        memory_id3 = memory_manager.add_memory(
            content="Le Machine Learning (apprentissage automatique) est un champ d'étude de l'intelligence artificielle.",
            metadata={"type": "concept", "tags": ["ml", "ai"]}
        )
        
        # Récupérer une mémoire
        logger.info(f"Récupération de la mémoire '{memory_id1}'...")
        memory = memory_manager.get_memory(memory_id1)
        if memory:
            logger.info(f"Mémoire récupérée: {memory.content}")
            logger.info(f"Métadonnées: {json.dumps(memory.metadata, indent=2)}")
        
        # Mettre à jour une mémoire
        logger.info(f"Mise à jour de la mémoire '{memory_id2}'...")
        memory_manager.update_memory(
            memory_id2,
            content="JavaScript est un langage de programmation de scripts principalement employé dans les pages web interactives et les applications Node.js.",
            metadata={"type": "language", "tags": ["javascript", "web", "node"]}
        )
        
        # Récupérer la mémoire mise à jour
        memory = memory_manager.get_memory(memory_id2)
        if memory:
            logger.info(f"Mémoire mise à jour: {memory.content}")
            logger.info(f"Métadonnées: {json.dumps(memory.metadata, indent=2)}")
        
        # Rechercher des mémoires par similarité sémantique
        logger.info("Recherche de mémoires par similarité sémantique...")
        results = memory_manager.search_memories("Python est un langage de programmation")
        logger.info(f"Résultats de la recherche ({len(results)}):")
        for memory, score in results:
            logger.info(f"  - Score: {score:.4f}, ID: {memory.memory_id}")
            logger.info(f"    Contenu: {memory.content}")
        
        # Rechercher des mémoires avec filtre de métadonnées
        logger.info("Recherche de mémoires avec filtre de métadonnées...")
        results = memory_manager.search_memories(
            "langage de programmation",
            metadata_filter={"type": "language"}
        )
        logger.info(f"Résultats de la recherche avec filtre ({len(results)}):")
        for memory, score in results:
            logger.info(f"  - Score: {score:.4f}, ID: {memory.memory_id}")
            logger.info(f"    Contenu: {memory.content}")
            logger.info(f"    Type: {memory.metadata.get('type')}")
        
        # Lister toutes les mémoires
        logger.info("Liste de toutes les mémoires...")
        memories = memory_manager.list_memories()
        logger.info(f"Nombre de mémoires: {len(memories)}")
        for memory in memories:
            logger.info(f"  - ID: {memory.memory_id}")
            logger.info(f"    Contenu: {memory.content}")
            logger.info(f"    Type: {memory.metadata.get('type')}")
            logger.info(f"    Tags: {memory.metadata.get('tags')}")
        
        # Supprimer une mémoire
        logger.info(f"Suppression de la mémoire '{memory_id3}'...")
        success = memory_manager.delete_memory(memory_id3)
        logger.info(f"Suppression {'réussie' if success else 'échouée'}")
        
        # Vérifier que la mémoire a été supprimée
        memory = memory_manager.get_memory(memory_id3)
        if memory:
            logger.info(f"La mémoire '{memory_id3}' existe encore")
        else:
            logger.info(f"La mémoire '{memory_id3}' a été supprimée")
        
        # Lister à nouveau toutes les mémoires
        logger.info("Liste de toutes les mémoires après suppression...")
        memories = memory_manager.list_memories()
        logger.info(f"Nombre de mémoires: {len(memories)}")
        for memory in memories:
            logger.info(f"  - ID: {memory.memory_id}")
            logger.info(f"    Contenu: {memory.content}")

if __name__ == "__main__":
    main()
