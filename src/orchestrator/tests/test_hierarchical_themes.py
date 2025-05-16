#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le module de gestion des thèmes hiérarchiques.
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

from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager

class TestHierarchicalThemeManager(unittest.TestCase):
    """Tests pour le gestionnaire de thèmes hiérarchiques."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        self.manager = HierarchicalThemeManager()
        
        # Créer un fichier de configuration temporaire
        self.temp_dir = tempfile.mkdtemp()
        self.config_path = os.path.join(self.temp_dir, "themes_config.json")
        
        # Configuration personnalisée pour les tests
        self.custom_config = {
            "themes": {
                "root": "Racine",
                "level1_a": "Niveau 1 A",
                "level1_b": "Niveau 1 B",
                "level2_a1": "Niveau 2 A1",
                "level2_a2": "Niveau 2 A2",
                "level2_b1": "Niveau 2 B1",
                "level3_a1_1": "Niveau 3 A1.1"
            },
            "theme_hierarchy": {
                "root": ["level1_a", "level1_b"],
                "level1_a": ["level2_a1", "level2_a2"],
                "level1_b": ["level2_b1"],
                "level2_a1": ["level3_a1_1"]
            },
            "theme_keywords": {
                "root": ["racine", "base", "principal"],
                "level1_a": ["niveau1", "a", "premier"],
                "level1_b": ["niveau1", "b", "premier"],
                "level2_a1": ["niveau2", "a1", "second"],
                "level2_a2": ["niveau2", "a2", "second"],
                "level2_b1": ["niveau2", "b1", "second"],
                "level3_a1_1": ["niveau3", "a1.1", "troisième"]
            }
        }
        
        with open(self.config_path, 'w', encoding='utf-8') as f:
            json.dump(self.custom_config, f, ensure_ascii=False, indent=2)
        
        # Créer un gestionnaire avec la configuration personnalisée
        self.custom_manager = HierarchicalThemeManager(self.config_path)
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le fichier de configuration temporaire
        if os.path.exists(self.config_path):
            os.remove(self.config_path)
        
        # Supprimer le répertoire temporaire
        if os.path.exists(self.temp_dir):
            os.rmdir(self.temp_dir)
    
    def test_default_config_loaded(self):
        """Teste le chargement de la configuration par défaut."""
        self.assertIn("technical", self.manager.themes)
        self.assertIn("functional", self.manager.themes)
        self.assertIn("organizational", self.manager.themes)
        
        self.assertIn("technical", self.manager.theme_hierarchy)
        self.assertIn("architecture", self.manager.theme_hierarchy["technical"])
    
    def test_custom_config_loaded(self):
        """Teste le chargement de la configuration personnalisée."""
        self.assertIn("root", self.custom_manager.themes)
        self.assertIn("level1_a", self.custom_manager.themes)
        self.assertIn("level3_a1_1", self.custom_manager.themes)
        
        self.assertIn("root", self.custom_manager.theme_hierarchy)
        self.assertIn("level1_a", self.custom_manager.theme_hierarchy["root"])
    
    def test_get_parent_themes(self):
        """Teste la récupération des thèmes parents."""
        # Test avec la configuration personnalisée
        parents = self.custom_manager.get_parent_themes("level3_a1_1")
        self.assertEqual(len(parents), 3)
        self.assertIn("level2_a1", parents)
        self.assertIn("level1_a", parents)
        self.assertIn("root", parents)
        
        # Test avec un thème de niveau intermédiaire
        parents = self.custom_manager.get_parent_themes("level2_a1")
        self.assertEqual(len(parents), 2)
        self.assertIn("level1_a", parents)
        self.assertIn("root", parents)
        
        # Test avec un thème de premier niveau
        parents = self.custom_manager.get_parent_themes("level1_a")
        self.assertEqual(len(parents), 1)
        self.assertIn("root", parents)
        
        # Test avec un thème racine
        parents = self.custom_manager.get_parent_themes("root")
        self.assertEqual(len(parents), 0)
    
    def test_get_child_themes(self):
        """Teste la récupération des thèmes enfants."""
        # Test avec la configuration personnalisée
        children = self.custom_manager.get_child_themes("root")
        self.assertEqual(len(children), 6)
        self.assertIn("level1_a", children)
        self.assertIn("level1_b", children)
        self.assertIn("level2_a1", children)
        self.assertIn("level2_a2", children)
        self.assertIn("level2_b1", children)
        self.assertIn("level3_a1_1", children)
        
        # Test avec un thème de niveau intermédiaire
        children = self.custom_manager.get_child_themes("level1_a")
        self.assertEqual(len(children), 3)
        self.assertIn("level2_a1", children)
        self.assertIn("level2_a2", children)
        self.assertIn("level3_a1_1", children)
        
        # Test avec un thème feuille
        children = self.custom_manager.get_child_themes("level3_a1_1")
        self.assertEqual(len(children), 0)
    
    def test_get_theme_path(self):
        """Teste la récupération du chemin d'un thème."""
        # Test avec la configuration personnalisée
        path = self.custom_manager.get_theme_path("level3_a1_1")
        self.assertEqual(len(path), 4)
        self.assertEqual(path[0], "root")
        self.assertEqual(path[1], "level1_a")
        self.assertEqual(path[2], "level2_a1")
        self.assertEqual(path[3], "level3_a1_1")
        
        # Test avec un thème de niveau intermédiaire
        path = self.custom_manager.get_theme_path("level2_a1")
        self.assertEqual(len(path), 3)
        self.assertEqual(path[0], "root")
        self.assertEqual(path[1], "level1_a")
        self.assertEqual(path[2], "level2_a1")
        
        # Test avec un thème racine
        path = self.custom_manager.get_theme_path("root")
        self.assertEqual(len(path), 1)
        self.assertEqual(path[0], "root")
    
    def test_propagate_theme_scores(self):
        """Teste la propagation des scores des thèmes."""
        # Scores initiaux
        theme_scores = {
            "level3_a1_1": 1.0
        }
        
        # Propager les scores
        propagated_scores = self.custom_manager.propagate_theme_scores(theme_scores)
        
        # Vérifier que les scores ont été propagés aux parents
        self.assertIn("level2_a1", propagated_scores)
        self.assertIn("level1_a", propagated_scores)
        self.assertIn("root", propagated_scores)
        
        # Vérifier que les scores diminuent en remontant la hiérarchie
        self.assertGreater(propagated_scores["level3_a1_1"], propagated_scores["level2_a1"])
        self.assertGreater(propagated_scores["level2_a1"], propagated_scores["level1_a"])
        self.assertGreater(propagated_scores["level1_a"], propagated_scores["root"])
        
        # Test avec plusieurs scores initiaux
        theme_scores = {
            "level2_a1": 0.8,
            "level2_b1": 0.6
        }
        
        # Propager les scores
        propagated_scores = self.custom_manager.propagate_theme_scores(theme_scores)
        
        # Vérifier que les scores ont été propagés aux parents et aux enfants
        self.assertIn("level3_a1_1", propagated_scores)
        self.assertIn("level1_a", propagated_scores)
        self.assertIn("level1_b", propagated_scores)
        self.assertIn("root", propagated_scores)
    
    def test_get_theme_keywords(self):
        """Teste la récupération des mots-clés d'un thème."""
        # Test avec la configuration personnalisée
        keywords = self.custom_manager.get_theme_keywords("level3_a1_1")
        self.assertIn("niveau3", keywords)
        self.assertIn("a1.1", keywords)
        self.assertIn("troisième", keywords)
        
        # Vérifier que les mots-clés des parents sont inclus
        self.assertIn("niveau2", keywords)
        self.assertIn("a1", keywords)
        self.assertIn("niveau1", keywords)
        self.assertIn("a", keywords)
        self.assertIn("racine", keywords)
        
        # Test avec un thème de niveau intermédiaire
        keywords = self.custom_manager.get_theme_keywords("level2_a1")
        self.assertIn("niveau2", keywords)
        self.assertIn("a1", keywords)
        self.assertIn("second", keywords)
        
        # Vérifier que les mots-clés des parents sont inclus
        self.assertIn("niveau1", keywords)
        self.assertIn("a", keywords)
        self.assertIn("racine", keywords)
    
    def test_save_config(self):
        """Teste la sauvegarde de la configuration."""
        # Modifier la configuration
        self.custom_manager.themes["new_theme"] = "Nouveau thème"
        self.custom_manager.theme_hierarchy["root"].append("new_theme")
        self.custom_manager.theme_keywords["new_theme"] = ["nouveau", "thème"]
        
        # Sauvegarder la configuration
        save_path = os.path.join(self.temp_dir, "saved_config.json")
        self.custom_manager.save_config(save_path)
        
        # Vérifier que le fichier a été créé
        self.assertTrue(os.path.exists(save_path))
        
        # Charger la configuration sauvegardée
        with open(save_path, 'r', encoding='utf-8') as f:
            saved_config = json.load(f)
        
        # Vérifier que la configuration a été sauvegardée correctement
        self.assertIn("new_theme", saved_config["themes"])
        self.assertIn("new_theme", saved_config["theme_hierarchy"]["root"])
        self.assertIn("new_theme", saved_config["theme_keywords"])
        
        # Supprimer le fichier de configuration sauvegardé
        os.remove(save_path)

if __name__ == '__main__':
    unittest.main()
