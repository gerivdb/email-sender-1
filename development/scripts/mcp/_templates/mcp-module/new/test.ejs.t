---
to: <%= h.projectPath() %>/development/scripts/mcp/test_<%= name %>.py
---
"""
Script de test pour le module <%= name %>.
"""

import unittest
from unittest.mock import patch, MagicMock
import os
import json
from typing import List, Dict, Any, Optional, Union, Tuple

from <%= name %> import <%= h.changeCase.pascal(name) %>


class Test<%= h.changeCase.pascal(name) %>(unittest.TestCase):
    """
    Tests pour la classe <%= h.changeCase.pascal(name) %>.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        <% if options && options.length > 0 -%>
        self.<%= h.changeCase.camel(name) %> = <%= h.changeCase.pascal(name) %>(<% options.forEach(function(opt, i) { -%><%= opt.name %>=<%= opt.default || 'None' %><%= i < options.length - 1 ? ', ' : '' %><% }) -%>)
        <% } else { -%>
        self.<%= h.changeCase.camel(name) %> = <%= h.changeCase.pascal(name) %>()
        <% } -%>
    
    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        pass
    
    def test_initialization(self):
        """
        Teste l'initialisation de la classe.
        """
        <% if options && options.length > 0 -%>
        <% options.forEach(function(opt) { -%>
        self.assertEqual(self.<%= h.changeCase.camel(name) %>.<%= opt.name %>, <%= opt.default || 'None' %>)
        <% }) -%>
        <% } else { -%>
        # Vérifier que l'instance est correctement initialisée
        self.assertIsInstance(self.<%= h.changeCase.camel(name) %>, <%= h.changeCase.pascal(name) %>)
        <% } -%>
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
