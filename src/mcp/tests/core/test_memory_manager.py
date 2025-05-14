#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le Memory Manager.

Ce module contient les tests unitaires pour le Memory Manager.
"""

import sys
import unittest
import tempfile
import os
import shutil
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.mcp.core.mcp.memory_manager import MemoryManager, Memory
from src.mcp.core.mcp.storage_provider import FileStorageProvider
from src.mcp.core.mcp.embedding_provider import DummyEmbeddingProvider

class TestMemory(unittest.TestCase):
    """Tests pour la classe Memory."""
    
    def test_init(self):
        """Teste l'initialisation d'une mémoire."""
        # Créer une mémoire avec des valeurs par défaut
        memory = Memory(content="Test content")
        
        # Vérifier les valeurs
        self.assertEqual(memory.content, "Test content")
        self.assertIsInstance(memory.metadata, dict)
        self.assertIsNotNone(memory.memory_id)
        self.assertIsNone(memory.embedding)
        
        # Vérifier les métadonnées par défaut
        self.assertIn("created_at", memory.metadata)
        self.assertIn("updated_at", memory.metadata)
        self.assertEqual(memory.metadata["created_at"], memory.metadata["updated_at"])
    
    def test_init_with_values(self):
        """Teste l'initialisation d'une mémoire avec des valeurs spécifiques."""
        # Créer une mémoire avec des valeurs spécifiques
        memory_id = "test-id"
        metadata = {"type": "test", "tags": ["unit", "test"]}
        embedding = [0.1, 0.2, 0.3]
        
        memory = Memory(
            content="Test content",
            metadata=metadata,
            memory_id=memory_id,
            embedding=embedding
        )
        
        # Vérifier les valeurs
        self.assertEqual(memory.content, "Test content")
        self.assertEqual(memory.metadata["type"], "test")
        self.assertEqual(memory.metadata["tags"], ["unit", "test"])
        self.assertEqual(memory.memory_id, memory_id)
        self.assertEqual(memory.embedding, embedding)
    
    def test_to_dict(self):
        """Teste la conversion d'une mémoire en dictionnaire."""
        # Créer une mémoire
        memory = Memory(
            content="Test content",
            metadata={"type": "test"},
            memory_id="test-id",
            embedding=[0.1, 0.2, 0.3]
        )
        
        # Convertir en dictionnaire
        data = memory.to_dict()
        
        # Vérifier les valeurs
        self.assertEqual(data["content"], "Test content")
        self.assertEqual(data["metadata"]["type"], "test")
        self.assertEqual(data["memory_id"], "test-id")
        self.assertEqual(data["embedding"], [0.1, 0.2, 0.3])
    
    def test_from_dict(self):
        """Teste la création d'une mémoire à partir d'un dictionnaire."""
        # Créer un dictionnaire
        data = {
            "content": "Test content",
            "metadata": {"type": "test"},
            "memory_id": "test-id",
            "embedding": [0.1, 0.2, 0.3]
        }
        
        # Créer une mémoire à partir du dictionnaire
        memory = Memory.from_dict(data)
        
        # Vérifier les valeurs
        self.assertEqual(memory.content, "Test content")
        self.assertEqual(memory.metadata["type"], "test")
        self.assertEqual(memory.memory_id, "test-id")
        self.assertEqual(memory.embedding, [0.1, 0.2, 0.3])
    
    def test_update_content(self):
        """Teste la mise à jour du contenu d'une mémoire."""
        # Créer une mémoire
        memory = Memory(content="Test content")
        
        # Enregistrer la date de mise à jour initiale
        initial_updated_at = memory.metadata["updated_at"]
        
        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)
        
        # Mettre à jour le contenu
        memory.update_content("Updated content")
        
        # Vérifier les valeurs
        self.assertEqual(memory.content, "Updated content")
        self.assertIsNone(memory.embedding)  # L'embedding doit être réinitialisé
        self.assertNotEqual(memory.metadata["updated_at"], initial_updated_at)
    
    def test_update_metadata(self):
        """Teste la mise à jour des métadonnées d'une mémoire."""
        # Créer une mémoire
        memory = Memory(content="Test content", metadata={"type": "test"})
        
        # Enregistrer la date de mise à jour initiale
        initial_updated_at = memory.metadata["updated_at"]
        
        # Attendre un peu pour s'assurer que la date de mise à jour change
        import time
        time.sleep(0.001)
        
        # Mettre à jour les métadonnées
        memory.update_metadata({"tags": ["unit", "test"]})
        
        # Vérifier les valeurs
        self.assertEqual(memory.metadata["type"], "test")  # La valeur existante est conservée
        self.assertEqual(memory.metadata["tags"], ["unit", "test"])  # La nouvelle valeur est ajoutée
        self.assertNotEqual(memory.metadata["updated_at"], initial_updated_at)

class TestMemoryManager(unittest.TestCase):
    """Tests pour la classe MemoryManager."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.temp_dir = tempfile.mkdtemp()
        self.storage_dir = os.path.join(self.temp_dir, "memories")
        self.cache_dir = os.path.join(self.temp_dir, "embeddings_cache")
        
        # Créer les fournisseurs
        self.storage_provider = FileStorageProvider(self.storage_dir)
        self.embedding_provider = DummyEmbeddingProvider(dimension=128)
        
        # Créer une instance du Memory Manager
        self.memory_manager = MemoryManager(
            storage_provider=self.storage_provider,
            embedding_provider=self.embedding_provider
        )
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)
    
    def test_add_memory(self):
        """Teste l'ajout d'une mémoire."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory(
            content="Test content",
            metadata={"type": "test"}
        )
        
        # Vérifier que l'ID a été retourné
        self.assertIsNotNone(memory_id)
        
        # Vérifier que la mémoire a été stockée
        memory = self.memory_manager.get_memory(memory_id)
        self.assertIsNotNone(memory)
        self.assertEqual(memory.content, "Test content")
        self.assertEqual(memory.metadata["type"], "test")
        self.assertIsNotNone(memory.embedding)
    
    def test_get_memory(self):
        """Teste la récupération d'une mémoire."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory(
            content="Test content",
            metadata={"type": "test"}
        )
        
        # Récupérer la mémoire
        memory = self.memory_manager.get_memory(memory_id)
        
        # Vérifier les valeurs
        self.assertIsNotNone(memory)
        self.assertEqual(memory.content, "Test content")
        self.assertEqual(memory.metadata["type"], "test")
        
        # Essayer de récupérer une mémoire inexistante
        memory = self.memory_manager.get_memory("nonexistent")
        self.assertIsNone(memory)
    
    def test_update_memory(self):
        """Teste la mise à jour d'une mémoire."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory(
            content="Test content",
            metadata={"type": "test"}
        )
        
        # Mettre à jour la mémoire
        success = self.memory_manager.update_memory(
            memory_id,
            content="Updated content",
            metadata={"tags": ["unit", "test"]}
        )
        
        # Vérifier que la mise à jour a réussi
        self.assertTrue(success)
        
        # Récupérer la mémoire mise à jour
        memory = self.memory_manager.get_memory(memory_id)
        
        # Vérifier les valeurs
        self.assertIsNotNone(memory)
        self.assertEqual(memory.content, "Updated content")
        self.assertEqual(memory.metadata["type"], "test")  # La valeur existante est conservée
        self.assertEqual(memory.metadata["tags"], ["unit", "test"])  # La nouvelle valeur est ajoutée
        
        # Essayer de mettre à jour une mémoire inexistante
        success = self.memory_manager.update_memory("nonexistent", content="Updated content")
        self.assertFalse(success)
    
    def test_delete_memory(self):
        """Teste la suppression d'une mémoire."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory(
            content="Test content",
            metadata={"type": "test"}
        )
        
        # Vérifier que la mémoire existe
        memory = self.memory_manager.get_memory(memory_id)
        self.assertIsNotNone(memory)
        
        # Supprimer la mémoire
        success = self.memory_manager.delete_memory(memory_id)
        
        # Vérifier que la suppression a réussi
        self.assertTrue(success)
        
        # Vérifier que la mémoire n'existe plus
        memory = self.memory_manager.get_memory(memory_id)
        self.assertIsNone(memory)
        
        # Essayer de supprimer une mémoire inexistante
        success = self.memory_manager.delete_memory("nonexistent")
        self.assertFalse(success)
    
    def test_search_memories(self):
        """Teste la recherche de mémoires."""
        # Ajouter quelques mémoires
        memory_id1 = self.memory_manager.add_memory(
            content="Python est un langage de programmation interprété.",
            metadata={"type": "language", "tags": ["python", "programming"]}
        )
        
        memory_id2 = self.memory_manager.add_memory(
            content="JavaScript est un langage de programmation de scripts.",
            metadata={"type": "language", "tags": ["javascript", "web"]}
        )
        
        memory_id3 = self.memory_manager.add_memory(
            content="Le Machine Learning est un champ d'étude de l'intelligence artificielle.",
            metadata={"type": "concept", "tags": ["ml", "ai"]}
        )
        
        # Rechercher des mémoires
        results = self.memory_manager.search_memories("langage de programmation")
        
        # Vérifier les résultats
        self.assertGreaterEqual(len(results), 2)  # Au moins 2 résultats
        
        # Vérifier que les résultats sont triés par score décroissant
        scores = [score for _, score in results]
        self.assertEqual(scores, sorted(scores, reverse=True))
        
        # Rechercher avec un filtre de métadonnées
        results = self.memory_manager.search_memories(
            "langage",
            metadata_filter={"type": "language"}
        )
        
        # Vérifier les résultats
        self.assertGreaterEqual(len(results), 2)  # Au moins 2 résultats
        
        # Vérifier que tous les résultats ont le type "language"
        for memory, _ in results:
            self.assertEqual(memory.metadata["type"], "language")
    
    def test_list_memories(self):
        """Teste la liste des mémoires."""
        # Ajouter quelques mémoires
        memory_id1 = self.memory_manager.add_memory(
            content="Python est un langage de programmation interprété.",
            metadata={"type": "language", "tags": ["python", "programming"]}
        )
        
        memory_id2 = self.memory_manager.add_memory(
            content="JavaScript est un langage de programmation de scripts.",
            metadata={"type": "language", "tags": ["javascript", "web"]}
        )
        
        memory_id3 = self.memory_manager.add_memory(
            content="Le Machine Learning est un champ d'étude de l'intelligence artificielle.",
            metadata={"type": "concept", "tags": ["ml", "ai"]}
        )
        
        # Lister toutes les mémoires
        memories = self.memory_manager.list_memories()
        
        # Vérifier le nombre de mémoires
        self.assertEqual(len(memories), 3)
        
        # Lister les mémoires avec un filtre de métadonnées
        memories = self.memory_manager.list_memories(metadata_filter={"type": "language"})
        
        # Vérifier le nombre de mémoires
        self.assertEqual(len(memories), 2)
        
        # Vérifier que toutes les mémoires ont le type "language"
        for memory in memories:
            self.assertEqual(memory.metadata["type"], "language")
        
        # Lister les mémoires avec pagination
        memories = self.memory_manager.list_memories(limit=2)
        
        # Vérifier le nombre de mémoires
        self.assertEqual(len(memories), 2)
        
        # Lister les mémoires avec décalage
        memories = self.memory_manager.list_memories(offset=2)
        
        # Vérifier le nombre de mémoires
        self.assertEqual(len(memories), 1)

if __name__ == "__main__":
    unittest.main()
