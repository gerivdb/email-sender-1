---
to: <%= h.projectPath() %>/development/scripts/mcp/memories/test_<%= name %>.py
---
"""
Tests pour la mémoire MCP <%= name %>.
"""

import unittest
from unittest.mock import patch, MagicMock
import os
import json
from typing import List, Dict, Any, Optional, Union, Tuple

from memories.<%= name %> import <%= h.changeCase.pascal(name) %>Memory, create_memory


class Test<%= h.changeCase.pascal(name) %>Memory(unittest.TestCase):
    """
    Tests pour la mémoire <%= h.changeCase.sentence(name) %>.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        <% if options && options.length > 0 -%>
        self.memory = <%= h.changeCase.pascal(name) %>Memory(<% options.forEach(function(opt, i) { -%><%= opt.name %>=<%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%>)
        <% } else { -%>
        self.memory = <%= h.changeCase.pascal(name) %>Memory()
        <% } -%>
    
    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        pass
    
    def test_initialization(self):
        """
        Teste l'initialisation de la mémoire.
        """
        <% if options && options.length > 0 -%>
        <% options.forEach(function(opt) { -%>
        self.assertEqual(self.memory.<%= opt.name %>, <%= opt.default || 'None' %>)
        <% }) -%>
        <% } else { -%>
        # Vérifier que l'instance est correctement initialisée
        self.assertIsInstance(self.memory, <%= h.changeCase.pascal(name) %>Memory)
        <% } -%>
        self.assertEqual(len(self.memory.memories), 0)
    
    def test_add_memory(self):
        """
        Teste la méthode add_memory.
        """
        memory_id = self.memory.add_memory("Test memory", {"source": "test"})
        self.assertIsNotNone(memory_id)
        self.assertIn(memory_id, self.memory.memories)
        self.assertEqual(self.memory.memories[memory_id]["content"], "Test memory")
        self.assertEqual(self.memory.memories[memory_id]["metadata"], {"source": "test"})
    
    def test_get_memory(self):
        """
        Teste la méthode get_memory.
        """
        memory_id = self.memory.add_memory("Test memory")
        memory = self.memory.get_memory(memory_id)
        self.assertIsNotNone(memory)
        self.assertEqual(memory["content"], "Test memory")
        
        # Tester avec un ID inexistant
        self.assertIsNone(self.memory.get_memory("non_existent_id"))
    
    def test_update_memory(self):
        """
        Teste la méthode update_memory.
        """
        memory_id = self.memory.add_memory("Test memory", {"source": "test"})
        
        # Mettre à jour le contenu
        result = self.memory.update_memory(memory_id, "Updated memory")
        self.assertTrue(result)
        memory = self.memory.get_memory(memory_id)
        self.assertEqual(memory["content"], "Updated memory")
        self.assertEqual(memory["metadata"], {"source": "test"})
        
        # Mettre à jour les métadonnées
        result = self.memory.update_memory(memory_id, metadata={"updated": True})
        self.assertTrue(result)
        memory = self.memory.get_memory(memory_id)
        self.assertEqual(memory["content"], "Updated memory")
        self.assertEqual(memory["metadata"], {"source": "test", "updated": True})
        
        # Tester avec un ID inexistant
        result = self.memory.update_memory("non_existent_id", "Updated memory")
        self.assertFalse(result)
    
    def test_delete_memory(self):
        """
        Teste la méthode delete_memory.
        """
        memory_id = self.memory.add_memory("Test memory")
        
        # Supprimer la mémoire
        result = self.memory.delete_memory(memory_id)
        self.assertTrue(result)
        self.assertNotIn(memory_id, self.memory.memories)
        
        # Tester avec un ID inexistant
        result = self.memory.delete_memory("non_existent_id")
        self.assertFalse(result)
    
    def test_list_memories(self):
        """
        Teste la méthode list_memories.
        """
        # Ajouter des mémoires
        self.memory.add_memory("Memory 1", {"type": "note"})
        self.memory.add_memory("Memory 2", {"type": "reminder"})
        self.memory.add_memory("Memory 3", {"type": "note"})
        
        # Lister toutes les mémoires
        memories = self.memory.list_memories()
        self.assertEqual(len(memories), 3)
        
        # Lister les mémoires filtrées
        memories = self.memory.list_memories(lambda m: m["metadata"]["type"] == "note")
        self.assertEqual(len(memories), 2)
    
    def test_create_memory(self):
        """
        Teste la fonction create_memory.
        """
        <% if options && options.length > 0 -%>
        memory = create_memory(<% options.forEach(function(opt, i) { -%><%= opt.name %>=<%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%>)
        <% } else { -%>
        memory = create_memory()
        <% } -%>
        self.assertIsInstance(memory, <%= h.changeCase.pascal(name) %>Memory)
    <% if methods && methods.length > 0 -%>
    <% methods.forEach(function(method) { -%>
    
    def test_<%= method.name %>(self):
        """
        Teste la méthode <%= method.name %>.
        """
        # TODO: Implémenter le test pour <%= method.name %>
        pass
    <% }) -%>
    <% } -%>


if __name__ == "__main__":
    unittest.main()
