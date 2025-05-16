#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le module d'attribution thématique automatique.
"""

import os
import sys
import unittest
import tempfile
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Vérifier si sklearn est disponible
try:
    import sklearn
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    print("Warning: sklearn not available. Some tests will be skipped.")

from src.orchestrator.thematic_crud.theme_attribution import ThemeAttributor

class TestThemeAttributor(unittest.TestCase):
    """Tests pour l'attributeur de thèmes."""

    def setUp(self):
        """Initialisation avant chaque test."""
        self.theme_attributor = ThemeAttributor()

        # Créer un fichier de configuration temporaire
        self.temp_dir = tempfile.mkdtemp()
        self.config_path = os.path.join(self.temp_dir, "themes_config.json")

        config = {
            "themes": {
                "architecture": "Architecture et conception",
                "development": "Développement et implémentation",
                "testing": "Tests et qualité"
            },
            "theme_keywords": {
                "architecture": ["architecture", "conception", "design"],
                "development": ["développement", "code", "implémentation"],
                "testing": ["test", "qualité", "validation"]
            }
        }

        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)

        # Créer un attributeur avec la configuration personnalisée
        self.custom_attributor = ThemeAttributor(self.config_path)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier de configuration temporaire
        if os.path.exists(self.config_path):
            os.remove(self.config_path)

        # Supprimer le répertoire temporaire
        if os.path.exists(self.temp_dir):
            os.rmdir(self.temp_dir)

    def test_default_themes_loaded(self):
        """Teste le chargement des thèmes par défaut."""
        self.assertIn("architecture", self.theme_attributor.themes)
        self.assertIn("development", self.theme_attributor.themes)
        self.assertIn("testing", self.theme_attributor.themes)
        self.assertIn("documentation", self.theme_attributor.themes)

    def test_custom_themes_loaded(self):
        """Teste le chargement des thèmes personnalisés."""
        self.assertIn("architecture", self.custom_attributor.themes)
        self.assertIn("development", self.custom_attributor.themes)
        self.assertIn("testing", self.custom_attributor.themes)
        self.assertNotIn("documentation", self.custom_attributor.themes)

    def test_preprocess_content(self):
        """Teste le prétraitement du contenu."""
        content = "Architecture et CONCEPTION du système!"
        processed = self.theme_attributor._preprocess_content(content)

        self.assertEqual(processed, "architecture et conception du système")

    def test_keyword_scores(self):
        """Teste le calcul des scores basés sur les mots-clés."""
        content = "Ce document décrit l'architecture et la conception du système."
        processed = self.theme_attributor._preprocess_content(content)
        scores = self.theme_attributor._calculate_keyword_scores(processed)

        self.assertGreater(scores["architecture"], 0)
        self.assertEqual(scores["testing"], 0)

    def test_attribute_theme_with_clear_content(self):
        """Teste l'attribution de thèmes avec un contenu clairement thématique."""
        content = """
        # Architecture du système

        Ce document décrit l'architecture et la conception du système.
        Il présente les différents composants et leurs interactions.
        """

        themes = self.theme_attributor.attribute_theme(content)

        self.assertIn("architecture", themes)
        # Ne pas vérifier la valeur exacte du score, car elle peut varier selon que sklearn est disponible ou non
        self.assertGreater(themes["architecture"], 0.0)

    def test_attribute_theme_with_mixed_content(self):
        """Teste l'attribution de thèmes avec un contenu mixte."""
        content = """
        # Développement et tests

        Ce document décrit les pratiques de développement et de test du système.
        Il présente les différentes étapes du cycle de développement et les tests associés.
        """

        themes = self.theme_attributor.attribute_theme(content)

        # Vérifier que les thèmes pertinents sont présents
        self.assertTrue("development" in themes or "testing" in themes)

    def test_attribute_theme_with_metadata(self):
        """Teste l'attribution de thèmes avec des métadonnées."""
        content = "Ce document décrit le système."
        metadata = {
            "title": "Architecture du système",
            "tags": ["conception", "design"]
        }

        themes = self.theme_attributor.attribute_theme(content, metadata)

        self.assertIn("architecture", themes)
        # Ne pas vérifier la valeur exacte du score, car elle peut varier selon que sklearn est disponible ou non
        self.assertGreater(themes["architecture"], 0.0)

    def test_normalize_and_filter_scores(self):
        """Teste la normalisation et le filtrage des scores."""
        scores = {
            "architecture": 0.8,
            "development": 0.4,
            "testing": 0.1,
            "documentation": 0.05
        }

        normalized = self.theme_attributor._normalize_and_filter_scores(scores, threshold=0.2)

        self.assertIn("architecture", normalized)
        self.assertIn("development", normalized)
        self.assertNotIn("documentation", normalized)
        self.assertEqual(normalized["architecture"], 1.0)
        self.assertEqual(normalized["development"], 0.5)

if __name__ == '__main__':
    unittest.main()
