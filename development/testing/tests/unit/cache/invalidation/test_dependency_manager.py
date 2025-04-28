#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le gestionnaire de dépendances.

Ce module contient les tests unitaires pour la classe DependencyManager
qui gère les dépendances entre les éléments du cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import json
import shutil
import tempfile
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.dependency_manager import DependencyManager, get_default_manager


class TestDependencyManager(unittest.TestCase):
    """Tests pour la classe DependencyManager."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le stockage des dépendances
        self.temp_dir = tempfile.mkdtemp()
        self.storage_path = os.path.join(self.temp_dir, 'dependencies.json')
        self.manager = DependencyManager(self.storage_path)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_add_dependency(self):
        """Teste l'ajout d'une dépendance."""
        # Ajouter une dépendance
        self.manager.add_dependency("key1", "dep1")
        
        # Vérifier que la dépendance a été ajoutée
        self.assertIn("dep1", self.manager.get_dependencies("key1"))
        self.assertIn("key1", self.manager.get_dependent_keys("dep1"))
        
        # Vérifier que le fichier de stockage a été créé
        self.assertTrue(os.path.exists(self.storage_path))
        
        # Vérifier le contenu du fichier de stockage
        with open(self.storage_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            self.assertIn("key1", data["dependencies"])
            self.assertIn("dep1", data["dependencies"]["key1"])
            self.assertIn("dep1", data["reverse_dependencies"])
            self.assertIn("key1", data["reverse_dependencies"]["dep1"])

    def test_add_dependencies(self):
        """Teste l'ajout de plusieurs dépendances."""
        # Ajouter plusieurs dépendances
        self.manager.add_dependencies("key1", ["dep1", "dep2", "dep3"])
        
        # Vérifier que les dépendances ont été ajoutées
        dependencies = self.manager.get_dependencies("key1")
        self.assertIn("dep1", dependencies)
        self.assertIn("dep2", dependencies)
        self.assertIn("dep3", dependencies)
        
        # Vérifier les dépendances inverses
        self.assertIn("key1", self.manager.get_dependent_keys("dep1"))
        self.assertIn("key1", self.manager.get_dependent_keys("dep2"))
        self.assertIn("key1", self.manager.get_dependent_keys("dep3"))

    def test_remove_dependency(self):
        """Teste la suppression d'une dépendance."""
        # Ajouter des dépendances
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        
        # Supprimer une dépendance
        self.manager.remove_dependency("key1", "dep1")
        
        # Vérifier que la dépendance a été supprimée
        dependencies = self.manager.get_dependencies("key1")
        self.assertNotIn("dep1", dependencies)
        self.assertIn("dep2", dependencies)
        
        # Vérifier les dépendances inverses
        self.assertNotIn("key1", self.manager.get_dependent_keys("dep1"))
        self.assertIn("key1", self.manager.get_dependent_keys("dep2"))

    def test_get_dependencies(self):
        """Teste la récupération des dépendances."""
        # Ajouter des dépendances
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        self.manager.add_dependencies("key2", ["dep2", "dep3"])
        
        # Récupérer les dépendances
        dependencies1 = self.manager.get_dependencies("key1")
        dependencies2 = self.manager.get_dependencies("key2")
        
        # Vérifier les dépendances
        self.assertEqual(len(dependencies1), 2)
        self.assertIn("dep1", dependencies1)
        self.assertIn("dep2", dependencies1)
        
        self.assertEqual(len(dependencies2), 2)
        self.assertIn("dep2", dependencies2)
        self.assertIn("dep3", dependencies2)
        
        # Vérifier les dépendances d'une clé inexistante
        self.assertEqual(len(self.manager.get_dependencies("key3")), 0)

    def test_get_dependent_keys(self):
        """Teste la récupération des clés dépendantes."""
        # Ajouter des dépendances
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        self.manager.add_dependencies("key2", ["dep2", "dep3"])
        
        # Récupérer les clés dépendantes
        dependent_keys1 = self.manager.get_dependent_keys("dep1")
        dependent_keys2 = self.manager.get_dependent_keys("dep2")
        dependent_keys3 = self.manager.get_dependent_keys("dep3")
        
        # Vérifier les clés dépendantes
        self.assertEqual(len(dependent_keys1), 1)
        self.assertIn("key1", dependent_keys1)
        
        self.assertEqual(len(dependent_keys2), 2)
        self.assertIn("key1", dependent_keys2)
        self.assertIn("key2", dependent_keys2)
        
        self.assertEqual(len(dependent_keys3), 1)
        self.assertIn("key2", dependent_keys3)
        
        # Vérifier les clés dépendantes d'une dépendance inexistante
        self.assertEqual(len(self.manager.get_dependent_keys("dep4")), 0)

    def test_add_tag(self):
        """Teste l'ajout d'un tag."""
        # Ajouter un tag
        self.manager.add_tag("key1", "tag1")
        
        # Vérifier que le tag a été ajouté
        self.assertIn("tag1", self.manager.get_tags("key1"))
        self.assertIn("key1", self.manager.get_keys_by_tag("tag1"))

    def test_add_tags(self):
        """Teste l'ajout de plusieurs tags."""
        # Ajouter plusieurs tags
        self.manager.add_tags("key1", ["tag1", "tag2", "tag3"])
        
        # Vérifier que les tags ont été ajoutés
        tags = self.manager.get_tags("key1")
        self.assertIn("tag1", tags)
        self.assertIn("tag2", tags)
        self.assertIn("tag3", tags)
        
        # Vérifier les clés par tag
        self.assertIn("key1", self.manager.get_keys_by_tag("tag1"))
        self.assertIn("key1", self.manager.get_keys_by_tag("tag2"))
        self.assertIn("key1", self.manager.get_keys_by_tag("tag3"))

    def test_remove_tag(self):
        """Teste la suppression d'un tag."""
        # Ajouter des tags
        self.manager.add_tags("key1", ["tag1", "tag2"])
        
        # Supprimer un tag
        self.manager.remove_tag("key1", "tag1")
        
        # Vérifier que le tag a été supprimé
        tags = self.manager.get_tags("key1")
        self.assertNotIn("tag1", tags)
        self.assertIn("tag2", tags)
        
        # Vérifier les clés par tag
        self.assertNotIn("key1", self.manager.get_keys_by_tag("tag1"))
        self.assertIn("key1", self.manager.get_keys_by_tag("tag2"))

    def test_get_tags(self):
        """Teste la récupération des tags."""
        # Ajouter des tags
        self.manager.add_tags("key1", ["tag1", "tag2"])
        self.manager.add_tags("key2", ["tag2", "tag3"])
        
        # Récupérer les tags
        tags1 = self.manager.get_tags("key1")
        tags2 = self.manager.get_tags("key2")
        
        # Vérifier les tags
        self.assertEqual(len(tags1), 2)
        self.assertIn("tag1", tags1)
        self.assertIn("tag2", tags1)
        
        self.assertEqual(len(tags2), 2)
        self.assertIn("tag2", tags2)
        self.assertIn("tag3", tags2)
        
        # Vérifier les tags d'une clé inexistante
        self.assertEqual(len(self.manager.get_tags("key3")), 0)

    def test_get_keys_by_tag(self):
        """Teste la récupération des clés par tag."""
        # Ajouter des tags
        self.manager.add_tags("key1", ["tag1", "tag2"])
        self.manager.add_tags("key2", ["tag2", "tag3"])
        
        # Récupérer les clés par tag
        keys1 = self.manager.get_keys_by_tag("tag1")
        keys2 = self.manager.get_keys_by_tag("tag2")
        keys3 = self.manager.get_keys_by_tag("tag3")
        
        # Vérifier les clés
        self.assertEqual(len(keys1), 1)
        self.assertIn("key1", keys1)
        
        self.assertEqual(len(keys2), 2)
        self.assertIn("key1", keys2)
        self.assertIn("key2", keys2)
        
        self.assertEqual(len(keys3), 1)
        self.assertIn("key2", keys3)
        
        # Vérifier les clés d'un tag inexistant
        self.assertEqual(len(self.manager.get_keys_by_tag("tag4")), 0)

    def test_get_keys_by_tags(self):
        """Teste la récupération des clés par plusieurs tags."""
        # Ajouter des tags
        self.manager.add_tags("key1", ["tag1", "tag2"])
        self.manager.add_tags("key2", ["tag2", "tag3"])
        self.manager.add_tags("key3", ["tag1", "tag3"])
        
        # Récupérer les clés par tags (match_all=False)
        keys = self.manager.get_keys_by_tags(["tag1", "tag3"], match_all=False)
        
        # Vérifier les clés (union)
        self.assertEqual(len(keys), 3)
        self.assertIn("key1", keys)
        self.assertIn("key2", keys)
        self.assertIn("key3", keys)
        
        # Récupérer les clés par tags (match_all=True)
        keys = self.manager.get_keys_by_tags(["tag1", "tag3"], match_all=True)
        
        # Vérifier les clés (intersection)
        self.assertEqual(len(keys), 1)
        self.assertIn("key3", keys)

    def test_clear_key(self):
        """Teste la suppression de toutes les dépendances et tags d'une clé."""
        # Ajouter des dépendances et des tags
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        self.manager.add_tags("key1", ["tag1", "tag2"])
        
        # Supprimer toutes les dépendances et tags
        self.manager.clear_key("key1")
        
        # Vérifier que les dépendances et tags ont été supprimés
        self.assertEqual(len(self.manager.get_dependencies("key1")), 0)
        self.assertEqual(len(self.manager.get_tags("key1")), 0)
        self.assertEqual(len(self.manager.get_dependent_keys("dep1")), 0)
        self.assertEqual(len(self.manager.get_dependent_keys("dep2")), 0)
        self.assertEqual(len(self.manager.get_keys_by_tag("tag1")), 0)
        self.assertEqual(len(self.manager.get_keys_by_tag("tag2")), 0)

    def test_clear_all(self):
        """Teste la suppression de toutes les dépendances et tags."""
        # Ajouter des dépendances et des tags
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        self.manager.add_dependencies("key2", ["dep2", "dep3"])
        self.manager.add_tags("key1", ["tag1", "tag2"])
        self.manager.add_tags("key2", ["tag2", "tag3"])
        
        # Supprimer toutes les dépendances et tags
        self.manager.clear_all()
        
        # Vérifier que les dépendances et tags ont été supprimés
        self.assertEqual(len(self.manager.dependencies), 0)
        self.assertEqual(len(self.manager.reverse_dependencies), 0)
        self.assertEqual(len(self.manager.tags), 0)
        self.assertEqual(len(self.manager.key_tags), 0)

    def test_load_save_dependencies(self):
        """Teste le chargement et la sauvegarde des dépendances."""
        # Ajouter des dépendances et des tags
        self.manager.add_dependencies("key1", ["dep1", "dep2"])
        self.manager.add_tags("key1", ["tag1", "tag2"])
        
        # Créer une nouvelle instance du gestionnaire de dépendances
        manager2 = DependencyManager(self.storage_path)
        
        # Vérifier que les dépendances et tags ont été chargés
        self.assertEqual(len(manager2.get_dependencies("key1")), 2)
        self.assertEqual(len(manager2.get_tags("key1")), 2)
        self.assertIn("dep1", manager2.get_dependencies("key1"))
        self.assertIn("dep2", manager2.get_dependencies("key1"))
        self.assertIn("tag1", manager2.get_tags("key1"))
        self.assertIn("tag2", manager2.get_tags("key1"))

    def test_get_default_manager(self):
        """Teste la récupération de l'instance par défaut du gestionnaire de dépendances."""
        # Récupérer l'instance par défaut
        manager = get_default_manager()
        
        # Vérifier que l'instance n'est pas None
        self.assertIsNotNone(manager)
        
        # Vérifier que c'est bien une instance de DependencyManager
        self.assertIsInstance(manager, DependencyManager)
        
        # Vérifier que la récupération d'une deuxième instance renvoie la même instance
        manager2 = get_default_manager()
        self.assertIs(manager, manager2)


if __name__ == '__main__':
    unittest.main()
