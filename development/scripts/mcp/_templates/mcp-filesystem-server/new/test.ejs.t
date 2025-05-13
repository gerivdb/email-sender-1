---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/test_filesystem_server.py
---
"""
Tests pour le serveur MCP filesystem.
"""

import unittest
import json
import os
import sys
import base64
from unittest.mock import patch, MagicMock
from flask import Flask
from flask.testing import FlaskClient

# Importer le serveur
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from servers.filesystem_server import app


class TestFilesystemServer(unittest.TestCase):
    """
    Tests pour le serveur filesystem.
    """
    
    def setUp(self):
        """
        Initialisation des tests.
        """
        self.app = app
        self.app.config['TESTING'] = True
        self.client = self.app.test_client()
        
        # Créer un répertoire et un fichier de test
        self.test_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'test_files')
        os.makedirs(self.test_dir, exist_ok=True)
        
        self.test_file = os.path.join(self.test_dir, 'test.txt')
        with open(self.test_file, 'w', encoding='utf-8') as f:
            f.write('Test content')
    
    def tearDown(self):
        """
        Nettoyage après les tests.
        """
        # Supprimer le répertoire et le fichier de test
        if os.path.exists(self.test_file):
            os.remove(self.test_file)
        
        if os.path.exists(self.test_dir):
            os.rmdir(self.test_dir)
    
    def test_health_check(self):
        """
        Teste l'endpoint /health.
        """
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'ok')
        self.assertEqual(data['server'], 'filesystem')
        self.assertIn('timestamp', data)
    
    def test_server_info(self):
        """
        Teste l'endpoint /info.
        """
        response = self.client.get('/info')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['name'], 'filesystem')
        self.assertIn('description', data)
        self.assertIn('version', data)
        self.assertIn('config', data)
    
    @patch('servers.filesystem_server.CONFIG')
    def test_list_files(self, mock_config):
        """
        Teste l'endpoint /files.
        """
        # Configurer le mock
        mock_config.__getitem__.side_effect = lambda key: self.test_dir if key == 'root_dir' else None
        
        # Tester l'endpoint
        response = self.client.get('/files')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('files', data)
        
        # Vérifier que le fichier de test est dans la liste
        file_names = [f['name'] for f in data['files']]
        self.assertIn('test.txt', file_names)
    
    @patch('servers.filesystem_server.CONFIG')
    def test_get_file(self, mock_config):
        """
        Teste l'endpoint /files/<path:file_path>.
        """
        # Configurer le mock
        mock_config.__getitem__.side_effect = lambda key: self.test_dir if key == 'root_dir' else None
        
        # Tester l'endpoint
        response = self.client.get('/files/test.txt')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['content'], 'Test content')
        self.assertEqual(data['encoding'], 'utf-8')
    
    @patch('servers.filesystem_server.CONFIG')
    def test_update_file(self, mock_config):
        """
        Teste l'endpoint /files/<path:file_path> (PUT).
        """
        # Configurer le mock
        mock_config.__getitem__.side_effect = lambda key: self.test_dir if key == 'root_dir' else None
        
        # Tester l'endpoint
        response = self.client.put(
            '/files/test.txt',
            json={
                'content': 'Updated content',
                'encoding': 'utf-8'
            }
        )
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        
        # Vérifier que le fichier a été mis à jour
        with open(os.path.join(self.test_dir, 'test.txt'), 'r', encoding='utf-8') as f:
            content = f.read()
        self.assertEqual(content, 'Updated content')
    
    @patch('servers.filesystem_server.CONFIG')
    def test_delete_file(self, mock_config):
        """
        Teste l'endpoint /files/<path:file_path> (DELETE).
        """
        # Configurer le mock
        mock_config.__getitem__.side_effect = lambda key: self.test_dir if key == 'root_dir' else None
        
        # Tester l'endpoint
        response = self.client.delete('/files/test.txt')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        
        # Vérifier que le fichier a été supprimé
        self.assertFalse(os.path.exists(os.path.join(self.test_dir, 'test.txt')))
    
    @patch('servers.filesystem_server.CONFIG')
    def test_search_files(self, mock_config):
        """
        Teste l'endpoint /search.
        """
        # Configurer le mock
        mock_config.__getitem__.side_effect = lambda key: self.test_dir if key == 'root_dir' else (['txt'] if key == 'allowed_extensions' else None)
        
        # Tester l'endpoint
        response = self.client.get('/search?query=Test')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('results', data)
        
        # Vérifier que le fichier de test est dans les résultats
        file_names = [f['name'] for f in data['results']]
        self.assertIn('test.txt', file_names)


if __name__ == '__main__':
    unittest.main()
