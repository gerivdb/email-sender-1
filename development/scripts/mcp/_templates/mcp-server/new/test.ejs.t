---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/test_<%= name %>_server.py
---
"""
Tests pour le serveur MCP <%= name %>.
"""

import unittest
import json
import os
import sys
from unittest.mock import patch, MagicMock
from flask import Flask
from flask.testing import FlaskClient

# Importer le serveur
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from servers.<%= name %>_server import app


class Test<%= h.changeCase.pascal(name) %>Server(unittest.TestCase):
    """
    Tests pour le serveur <%= name %>.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
    
    def test_health_check(self):
        """
        Teste l'endpoint /health.
        """
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'ok')
        self.assertEqual(data['server'], '<%= name %>')
        self.assertIn('timestamp', data)
    
    def test_server_info(self):
        """
        Teste l'endpoint /info.
        """
        response = self.client.get('/info')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['name'], '<%= name %>')
        self.assertIn('description', data)
        self.assertIn('version', data)
        self.assertIn('config', data)
    <% if endpoints && endpoints.length > 0 -%>
    <% endpoints.forEach(function(endpoint) { -%>
    
    def test_<%= endpoint.name %>(self):
        """
        Teste l'endpoint <%= endpoint.path %>.
        """
        <% if endpoint.method === 'GET' -%>
        response = self.client.get('<%= endpoint.path %>')
        <% } else if (endpoint.method === 'POST') { -%>
        response = self.client.post('<%= endpoint.path %>', json={})
        <% } else if (endpoint.method === 'PUT') { -%>
        response = self.client.put('<%= endpoint.path %>', json={})
        <% } else if (endpoint.method === 'DELETE') { -%>
        response = self.client.delete('<%= endpoint.path %>')
        <% } -%>
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
    <% }) -%>
    <% } -%>


if __name__ == '__main__':
    unittest.main()
