---
to: <%= h.projectPath() %>/development/scripts/mcp/tools/test_<%= name %>.py
---
"""
Tests pour l'outil MCP <%= name %>.
"""

import unittest
from unittest.mock import patch, MagicMock
import os
import json
from typing import List, Dict, Any, Optional, Union, Tuple

from tools.<%= name %> import <%= h.changeCase.pascal(name) %>Tool, create_tool


class Test<%= h.changeCase.pascal(name) %>Tool(unittest.TestCase):
    """
    Tests pour l'outil <%= h.changeCase.sentence(name) %>.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        <% if options && options.length > 0 -%>
        self.tool = <%= h.changeCase.pascal(name) %>Tool(<% options.forEach(function(opt, i) { -%><%= opt.name %>=<%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%>)
        <% } else { -%>
        self.tool = <%= h.changeCase.pascal(name) %>Tool()
        <% } -%>
    
    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        pass
    
    def test_initialization(self):
        """
        Teste l'initialisation de l'outil.
        """
        <% if options && options.length > 0 -%>
        <% options.forEach(function(opt) { -%>
        self.assertEqual(self.tool.<%= opt.name %>, <%= opt.default || 'None' %>)
        <% }) -%>
        <% } else { -%>
        # Vérifier que l'instance est correctement initialisée
        self.assertIsInstance(self.tool, <%= h.changeCase.pascal(name) %>Tool)
        <% } -%>
    
    def test_get_tool_info(self):
        """
        Teste la méthode get_tool_info.
        """
        info = self.tool.get_tool_info()
        self.assertEqual(info["name"], "<%= name %>")
        self.assertIn("description", info)
        self.assertIn("version", info)
        self.assertIn("methods", info)
    
    def test_create_tool(self):
        """
        Teste la fonction create_tool.
        """
        <% if options && options.length > 0 -%>
        tool = create_tool(<% options.forEach(function(opt, i) { -%><%= opt.name %>=<%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%>)
        <% } else { -%>
        tool = create_tool()
        <% } -%>
        self.assertIsInstance(tool, <%= h.changeCase.pascal(name) %>Tool)
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
