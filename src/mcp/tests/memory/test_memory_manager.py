#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour la classe MemoryManager.

Ce module contient les tests unitaires pour la classe MemoryManager.
"""

import os
import sys
import unittest
import tempfile
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent.parent))

from src.mcp.core.memory.MemoryManager import MemoryManager

class TestMemoryManager(unittest.TestCase):
    """Tests pour la classe MemoryManager."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un fichier temporaire pour le stockage
        self.temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".json")
        self.temp_file.close()

        # Créer une instance de MemoryManager avec le fichier temporaire
        self.memory_manager = MemoryManager(self.temp_file.name)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier temporaire
        if os.path.exists(self.temp_file.name):
            os.unlink(self.temp_file.name)

    def test_add_memory(self):
        """Test de la méthode add_memory."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory("Test memory", {"source": "test"})

        # Vérifier que l'ID est retourné
        self.assertIsNotNone(memory_id)

        # Vérifier que la mémoire est dans le dictionnaire
        self.assertIn(memory_id, self.memory_manager.memories)

        # Vérifier le contenu de la mémoire
        memory = self.memory_manager.memories[memory_id]
        self.assertEqual(memory["content"], "Test memory")
        self.assertEqual(memory["metadata"], {"source": "test"})
        self.assertIsNotNone(memory["created_at"])
        self.assertIsNone(memory["updated_at"])

    def test_get_memory(self):
        """Test de la méthode get_memory."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory("Test memory")

        # Récupérer la mémoire
        memory = self.memory_manager.get_memory(memory_id)

        # Vérifier que la mémoire est récupérée
        self.assertIsNotNone(memory)
        self.assertEqual(memory["content"], "Test memory")

        # Tester avec un ID inexistant
        self.assertIsNone(self.memory_manager.get_memory("non_existent_id"))

    def test_update_memory(self):
        """Test de la méthode update_memory."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory("Test memory", {"source": "test"})

        # Mettre à jour la mémoire
        success = self.memory_manager.update_memory(memory_id, "Updated memory", {"updated": True})

        # Vérifier que la mise à jour a réussi
        self.assertTrue(success)

        # Récupérer la mémoire mise à jour
        memory = self.memory_manager.get_memory(memory_id)

        # Vérifier le contenu mis à jour
        self.assertEqual(memory["content"], "Updated memory")
        self.assertEqual(memory["metadata"], {"source": "test", "updated": True})
        self.assertIsNotNone(memory["updated_at"])

        # Tester avec un ID inexistant
        self.assertFalse(self.memory_manager.update_memory("non_existent_id", "Updated memory"))

    def test_delete_memory(self):
        """Test de la méthode delete_memory."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory("Test memory")

        # Supprimer la mémoire
        success = self.memory_manager.delete_memory(memory_id)

        # Vérifier que la suppression a réussi
        self.assertTrue(success)

        # Vérifier que la mémoire n'existe plus
        self.assertNotIn(memory_id, self.memory_manager.memories)

        # Tester avec un ID inexistant
        self.assertFalse(self.memory_manager.delete_memory("non_existent_id"))

    def test_list_memories(self):
        """Test de la méthode list_memories."""
        # Ajouter des mémoires
        self.memory_manager.add_memory("Memory 1", {"type": "note"})
        self.memory_manager.add_memory("Memory 2", {"type": "reminder"})
        self.memory_manager.add_memory("Memory 3", {"type": "note"})

        # Lister toutes les mémoires
        memories = self.memory_manager.list_memories()
        self.assertEqual(len(memories), 3)

        # Lister les mémoires filtrées
        def filter_func(memory):
            return memory["metadata"].get("type") == "note"

        filtered_memories = self.memory_manager.list_memories(filter_func)
        self.assertEqual(len(filtered_memories), 2)

    def test_search_memory(self):
        """Test de la méthode search_memory."""
        # Ajouter des mémoires
        self.memory_manager.add_memory("This is a test memory about Python")
        self.memory_manager.add_memory("Another memory about programming")
        self.memory_manager.add_memory("Python is a great language")
        self.memory_manager.add_memory("This has nothing to do with the search")

        # Rechercher des mémoires
        results = self.memory_manager.search_memory("Python")

        # Vérifier les résultats
        self.assertEqual(len(results), 2)

        # Vérifier que les résultats sont triés par pertinence
        self.assertIn("Python", results[0]["content"])

    def test_persistence(self):
        """Test de la persistance des mémoires."""
        # Ajouter une mémoire
        memory_id = self.memory_manager.add_memory("Test memory", {"source": "test"})

        # Créer une nouvelle instance avec le même fichier
        new_manager = MemoryManager(self.temp_file.name)

        # Vérifier que la mémoire est chargée
        self.assertIn(memory_id, new_manager.memories)
        memory = new_manager.get_memory(memory_id)
        self.assertEqual(memory["content"], "Test memory")
        self.assertEqual(memory["metadata"], {"source": "test"})

if __name__ == "__main__":
    unittest.main()
