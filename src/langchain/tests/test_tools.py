#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour les outils Langchain.

Ce module contient des tests pour vérifier le bon fonctionnement des outils Langchain.
"""

import os
import sys
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

from src.langchain.tools import (
    CodeAnalysisTools,
    DocumentationTools,
    RecommendationTools
)

class TestCodeAnalysisTools(unittest.TestCase):
    """Tests pour les outils d'analyse de code."""

    def setUp(self):
        """Initialisation des tests."""
        self.sample_code = """
import os
import sys

def hello_world():
    \"\"\"Dit bonjour au monde.\"\"\"
    print("Hello, World!")

class MyClass:
    \"\"\"Une classe d'exemple.\"\"\"

    def __init__(self, name):
        self.name = name

    def say_hello(self):
        \"\"\"Dit bonjour.\"\"\"
        print(f"Hello, {self.name}!")
"""

    def test_analyze_python_code(self):
        """Teste l'analyse de code Python."""
        result = CodeAnalysisTools.analyze_python_code(self.sample_code)

        # Vérifier que le résultat est un dictionnaire
        self.assertIsInstance(result, dict)

        # Vérifier que les clés attendues sont présentes
        self.assertIn('stats', result)
        self.assertIn('issues', result)
        self.assertIn('quality_score', result)
        self.assertIn('recommendations', result)

        # Vérifier les statistiques
        self.assertIn('functions', result['stats'])
        self.assertIn('classes', result['stats'])

        # Vérifier qu'au moins une fonction a été détectée
        self.assertGreaterEqual(len(result['stats']['functions']), 1)

        # Vérifier qu'une classe a été détectée
        self.assertEqual(len(result['stats']['classes']), 1)

    def test_detect_code_smells(self):
        """Teste la détection des code smells."""
        result = CodeAnalysisTools.detect_code_smells(self.sample_code)

        # Vérifier que le résultat est une liste
        self.assertIsInstance(result, list)

class TestDocumentationTools(unittest.TestCase):
    """Tests pour les outils de génération de documentation."""

    def setUp(self):
        """Initialisation des tests."""
        self.sample_code = """
import os
import sys

def hello_world():
    \"\"\"Dit bonjour au monde.\"\"\"
    print("Hello, World!")

class MyClass:
    \"\"\"Une classe d'exemple.\"\"\"

    def __init__(self, name):
        self.name = name

    def say_hello(self):
        \"\"\"Dit bonjour.\"\"\"
        print(f"Hello, {self.name}!")
"""

    def test_extract_docstrings(self):
        """Teste l'extraction des docstrings."""
        result = DocumentationTools.extract_docstrings(self.sample_code)

        # Vérifier que le résultat est un dictionnaire
        self.assertIsInstance(result, dict)

        # Vérifier que les clés attendues sont présentes
        self.assertIn('module', result)
        self.assertIn('classes', result)
        self.assertIn('functions', result)

        # Vérifier qu'une fonction a été détectée
        self.assertIn('hello_world', result['functions'])

        # Vérifier qu'une classe a été détectée
        self.assertIn('MyClass', result['classes'])

        # Vérifier que la méthode de la classe a été détectée
        self.assertIn('say_hello', result['classes']['MyClass']['methods'])

    def test_generate_markdown_documentation(self):
        """Teste la génération de documentation Markdown."""
        result = DocumentationTools.generate_markdown_documentation(self.sample_code)

        # Vérifier que le résultat est une chaîne
        self.assertIsInstance(result, str)

        # Vérifier que la documentation contient des éléments attendus
        self.assertIn('# Module', result)
        self.assertIn('## Fonctions', result)
        self.assertIn('## Classes', result)
        self.assertIn('hello_world', result)
        self.assertIn('MyClass', result)

class TestRecommendationTools(unittest.TestCase):
    """Tests pour les outils de recommandation."""

    def setUp(self):
        """Initialisation des tests."""
        self.sample_code = """
import os
import sys

def hello_world():
    \"\"\"Dit bonjour au monde.\"\"\"
    print("Hello, World!")

class MyClass:
    \"\"\"Une classe d'exemple.\"\"\"

    def __init__(self, name):
        self.name = name

    def say_hello(self):
        \"\"\"Dit bonjour.\"\"\"
        print(f"Hello, {self.name}!")
"""

    def test_recommend_code_improvements(self):
        """Teste les recommandations d'amélioration de code."""
        result = RecommendationTools.recommend_code_improvements(self.sample_code)

        # Vérifier que le résultat est un dictionnaire
        self.assertIsInstance(result, dict)

        # Vérifier que les clés attendues sont présentes
        self.assertIn('style', result)
        self.assertIn('performance', result)
        self.assertIn('maintainability', result)
        self.assertIn('security', result)
        self.assertIn('overall_score', result)

        # Vérifier que le score global est un nombre
        self.assertIsInstance(result['overall_score'], (int, float))

    def test_recommend_technology_stack(self):
        """Teste les recommandations de pile technologique."""
        requirements = [
            "API REST",
            "Base de données SQL",
            "Interface web"
        ]

        result = RecommendationTools.recommend_technology_stack(requirements)

        # Vérifier que le résultat est un dictionnaire
        self.assertIsInstance(result, dict)

        # Vérifier que les clés attendues sont présentes
        self.assertIn('backend', result)
        self.assertIn('frontend', result)
        self.assertIn('database', result)
        self.assertIn('devops', result)
        self.assertIn('testing', result)

        # Vérifier que les recommandations sont des listes
        self.assertIsInstance(result['backend'], list)
        self.assertIsInstance(result['frontend'], list)
        self.assertIsInstance(result['database'], list)
        self.assertIsInstance(result['devops'], list)
        self.assertIsInstance(result['testing'], list)

if __name__ == '__main__':
    unittest.main()
