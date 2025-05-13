---
to: <%= h.projectPath() %>/development/scripts/mcp/servers/test_github_server.py
---
"""
Tests pour le serveur MCP GitHub.
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
from servers.github_server import app


class TestGitHubServer(unittest.TestCase):
    """
    Tests pour le serveur GitHub.
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
        self.assertEqual(data['server'], 'github')
        self.assertIn('timestamp', data)
    
    def test_server_info(self):
        """
        Teste l'endpoint /info.
        """
        response = self.client.get('/info')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['name'], 'github')
        self.assertIn('description', data)
        self.assertIn('version', data)
        self.assertIn('config', data)
    
    @patch('servers.github_server.requests.get')
    def test_list_repos(self, mock_get):
        """
        Teste l'endpoint /repos.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {
                'name': 'repo1',
                'full_name': 'user/repo1',
                'html_url': 'https://github.com/user/repo1'
            },
            {
                'name': 'repo2',
                'full_name': 'user/repo2',
                'html_url': 'https://github.com/user/repo2'
            }
        ]
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos?username=user')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('repos', data)
        self.assertEqual(len(data['repos']), 2)
    
    @patch('servers.github_server.requests.get')
    def test_get_repo(self, mock_get):
        """
        Teste l'endpoint /repos/<owner>/<repo>.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'name': 'repo1',
            'full_name': 'user/repo1',
            'html_url': 'https://github.com/user/repo1',
            'description': 'Test repository'
        }
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos/user/repo1')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('repo', data)
        self.assertEqual(data['repo']['name'], 'repo1')
    
    @patch('servers.github_server.requests.get')
    def test_get_content_file(self, mock_get):
        """
        Teste l'endpoint /repos/<owner>/<repo>/contents/<path:file_path> pour un fichier.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'type': 'file',
            'name': 'README.md',
            'path': 'README.md',
            'content': 'IyBUZXN0IFJlcG9zaXRvcnkK',  # Base64 pour "# Test Repository"
            'sha': '1234567890'
        }
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos/user/repo1/contents/README.md')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['type'], 'file')
        self.assertEqual(data['content'], '# Test Repository')
    
    @patch('servers.github_server.requests.get')
    def test_get_content_directory(self, mock_get):
        """
        Teste l'endpoint /repos/<owner>/<repo>/contents/<path:file_path> pour un répertoire.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {
                'type': 'file',
                'name': 'README.md',
                'path': 'README.md',
                'sha': '1234567890'
            },
            {
                'type': 'file',
                'name': 'LICENSE',
                'path': 'LICENSE',
                'sha': '0987654321'
            }
        ]
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos/user/repo1/contents/')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['type'], 'directory')
        self.assertEqual(len(data['contents']), 2)
    
    @patch('servers.github_server.requests.get')
    def test_list_branches(self, mock_get):
        """
        Teste l'endpoint /repos/<owner>/<repo>/branches.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {
                'name': 'main',
                'commit': {
                    'sha': '1234567890'
                }
            },
            {
                'name': 'develop',
                'commit': {
                    'sha': '0987654321'
                }
            }
        ]
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos/user/repo1/branches')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('branches', data)
        self.assertEqual(len(data['branches']), 2)
    
    @patch('servers.github_server.requests.get')
    def test_list_commits(self, mock_get):
        """
        Teste l'endpoint /repos/<owner>/<repo>/commits.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [
            {
                'sha': '1234567890',
                'commit': {
                    'message': 'Initial commit',
                    'author': {
                        'name': 'User',
                        'date': '2023-01-01T00:00:00Z'
                    }
                }
            },
            {
                'sha': '0987654321',
                'commit': {
                    'message': 'Update README.md',
                    'author': {
                        'name': 'User',
                        'date': '2023-01-02T00:00:00Z'
                    }
                }
            }
        ]
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/repos/user/repo1/commits')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertIn('commits', data)
        self.assertEqual(len(data['commits']), 2)
    
    @patch('servers.github_server.requests.get')
    def test_search_code(self, mock_get):
        """
        Teste l'endpoint /search/code.
        """
        # Configurer le mock
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'total_count': 2,
            'items': [
                {
                    'name': 'README.md',
                    'path': 'README.md',
                    'repository': {
                        'full_name': 'user/repo1'
                    }
                },
                {
                    'name': 'README.md',
                    'path': 'README.md',
                    'repository': {
                        'full_name': 'user/repo2'
                    }
                }
            ]
        }
        mock_get.return_value = mock_response
        
        # Tester l'endpoint
        response = self.client.get('/search/code?q=test')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['query'], 'test')
        self.assertIn('results', data)
        self.assertEqual(data['results']['total_count'], 2)


if __name__ == '__main__':
    unittest.main()
