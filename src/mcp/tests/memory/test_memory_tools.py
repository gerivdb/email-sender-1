#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour les outils de mémoire MCP.

Ce module contient les tests unitaires pour les outils de mémoire MCP.
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
from src.mcp.core.memory.tools import add_memories, search_memory, list_memories, delete_memories

class TestMemoryTools(unittest.TestCase):
    """Tests pour les outils de mémoire MCP."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un fichier temporaire pour le stockage
        self.temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".json")
        self.temp_file.close()

        # Créer une instance de MemoryManager avec le fichier temporaire
        self.memory_manager = MemoryManager(self.temp_file.name)

        # Ajouter quelques mémoires pour les tests
        self.memory_manager.add_memory("Memory 1", {"category": "work", "priority": "high"})
        self.memory_manager.add_memory("Memory 2", {"category": "personal", "priority": "medium"})
        self.memory_manager.add_memory("Memory 3", {"category": "work", "priority": "low"})

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier temporaire
        if os.path.exists(self.temp_file.name):
            os.unlink(self.temp_file.name)

    def test_add_memories_tool(self):
        """Test de l'outil add_memories."""
        # Paramètres pour l'outil
        params = {
            "memories": [
                {
                    "content": "New memory 1",
                    "metadata": {"category": "work", "priority": "medium"}
                },
                {
                    "content": "New memory 2",
                    "metadata": {"category": "personal", "priority": "high"}
                }
            ]
        }

        # Appeler l'outil
        result = add_memories.add_memories(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(result["count"], 2)
        self.assertEqual(len(result["added_memories"]), 2)

        # Vérifier que les mémoires ont été ajoutées
        all_memories = self.memory_manager.list_memories()
        self.assertEqual(len(all_memories), 5)  # 3 initiales + 2 nouvelles

    def test_add_memories_tool_invalid_params(self):
        """Test de l'outil add_memories avec des paramètres invalides."""
        # Paramètres invalides
        invalid_params = {"invalid": "params"}

        # Vérifier que l'outil lève une exception
        with self.assertRaises(ValueError):
            add_memories.add_memories(self.memory_manager, invalid_params)

    def test_search_memory_tool(self):
        """Test de l'outil search_memory."""
        # Ajouter une mémoire spécifique pour la recherche
        self.memory_manager.add_memory("This is a special memory for testing search", {"category": "test"})

        # Paramètres pour l'outil
        params = {
            "query": "special memory",
            "limit": 2
        }

        # Appeler l'outil
        result = search_memory.search_memory(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(result["query"], "special memory")
        self.assertEqual(len(result["results"]), 1)
        self.assertEqual(result["count"], 1)
        self.assertIn("special memory", result["results"][0]["content"])

    def test_search_memory_tool_with_filters(self):
        """Test de l'outil search_memory avec des filtres."""
        # Paramètres pour l'outil
        params = {
            "query": "Memory",
            "limit": 10,
            "filters": {"category": "work"}
        }

        # Appeler l'outil
        result = search_memory.search_memory(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(result["query"], "Memory")
        self.assertEqual(len(result["results"]), 2)  # Memory 1 et Memory 3

    def test_list_memories_tool(self):
        """Test de l'outil list_memories."""
        # Paramètres pour l'outil
        params = {
            "page": 1,
            "page_size": 2,
            "sort_by": "created_at",
            "sort_order": "desc"
        }

        # Appeler l'outil
        result = list_memories.list_memories(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(len(result["items"]), 2)
        self.assertEqual(result["pagination"]["total_items"], 3)
        self.assertEqual(result["pagination"]["total_pages"], 2)

    def test_list_memories_tool_with_filters(self):
        """Test de l'outil list_memories avec des filtres."""
        # Paramètres pour l'outil
        params = {
            "page": 1,
            "page_size": 10,
            "filters": {"category": "work"}
        }

        # Appeler l'outil
        result = list_memories.list_memories(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(len(result["items"]), 2)  # Memory 1 et Memory 3

    def test_delete_memories_tool_by_ids(self):
        """Test de l'outil delete_memories par IDs."""
        # Récupérer les IDs des mémoires
        all_memories = self.memory_manager.list_memories()
        memory_ids = [memory["id"] for memory in all_memories[:2]]  # Prendre les 2 premières

        # Paramètres pour l'outil
        params = {
            "memory_ids": memory_ids
        }

        # Appeler l'outil
        result = delete_memories.delete_memories(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(result["deleted_count"], 2)
        self.assertEqual(len(result["deleted_ids"]), 2)
        self.assertEqual(len(result["failed_ids"]), 0)

        # Vérifier qu'il ne reste qu'une mémoire
        remaining_memories = self.memory_manager.list_memories()
        self.assertEqual(len(remaining_memories), 1)

    def test_delete_memories_tool_by_filters(self):
        """Test de l'outil delete_memories par filtres."""
        # Paramètres pour l'outil
        params = {
            "filters": {"category": "work"},
            "confirm": True
        }

        # Appeler l'outil
        result = delete_memories.delete_memories(self.memory_manager, params)

        # Vérifier le résultat
        self.assertEqual(result["deleted_count"], 2)  # Memory 1 et Memory 3

        # Vérifier qu'il ne reste qu'une mémoire
        remaining_memories = self.memory_manager.list_memories()
        self.assertEqual(len(remaining_memories), 1)
        self.assertEqual(remaining_memories[0]["metadata"]["category"], "personal")

    def test_delete_memories_tool_without_confirmation(self):
        """Test de l'outil delete_memories sans confirmation."""
        # Paramètres pour l'outil
        params = {
            "filters": {"category": "work"},
            "confirm": False
        }

        # Vérifier que l'outil lève une exception
        with self.assertRaises(ValueError):
            delete_memories.delete_memories(self.memory_manager, params)

if __name__ == "__main__":
    unittest.main()
