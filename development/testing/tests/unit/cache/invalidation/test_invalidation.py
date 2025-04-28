#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour l'invalidateur de cache.

Ce module contient les tests unitaires pour la classe CacheInvalidator
qui gère l'invalidation des éléments du cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import shutil
import tempfile
import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager
from scripts.utils.cache.invalidation import CacheInvalidator, get_default_invalidator


class TestCacheInvalidator(unittest.TestCase):
    """Tests pour la classe CacheInvalidator."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache
        self.temp_dir = tempfile.mkdtemp()
        
        # Créer une instance du cache local
        self.cache = LocalCache(cache_dir=os.path.join(self.temp_dir, 'cache'))
        
        # Créer une instance du gestionnaire de dépendances
        self.dependency_manager = DependencyManager(os.path.join(self.temp_dir, 'dependencies.json'))
        
        # Créer une instance de l'invalidateur de cache
        self.invalidator = CacheInvalidator(self.cache, self.dependency_manager)
        
        # Ajouter des données au cache
        self.cache.set("key1", "value1")
        self.cache.set("key2", "value2")
        self.cache.set("key3", "value3")
        self.cache.set("pattern:1", "pattern value 1")
        self.cache.set("pattern:2", "pattern value 2")
        
        # Ajouter des dépendances
        self.dependency_manager.add_dependency("key1", "dep1")
        self.dependency_manager.add_dependency("key2", "dep1")
        self.dependency_manager.add_dependency("key3", "dep2")
        
        # Ajouter des tags
        self.dependency_manager.add_tag("key1", "tag1")
        self.dependency_manager.add_tag("key2", "tag2")
        self.dependency_manager.add_tag("key3", "tag1")

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Arrêter le planificateur
        self.invalidator.stop_scheduler()
        
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_invalidate_key(self):
        """Teste l'invalidation d'une clé spécifique."""
        # Invalider une clé
        result = self.invalidator.invalidate_key("key1")
        
        # Vérifier que la clé a été invalidée
        self.assertTrue(result)
        self.assertIsNone(self.cache.get("key1"))
        
        # Vérifier que les autres clés n'ont pas été invalidées
        self.assertEqual(self.cache.get("key2"), "value2")
        self.assertEqual(self.cache.get("key3"), "value3")
        
        # Vérifier que les dépendances et tags ont été supprimés
        self.assertEqual(len(self.dependency_manager.get_dependencies("key1")), 0)
        self.assertEqual(len(self.dependency_manager.get_tags("key1")), 0)
        
        # Invalider une clé inexistante
        result = self.invalidator.invalidate_key("key4")
        self.assertFalse(result)

    def test_invalidate_keys(self):
        """Teste l'invalidation de plusieurs clés."""
        # Invalider plusieurs clés
        count = self.invalidator.invalidate_keys(["key1", "key2"])
        
        # Vérifier que les clés ont été invalidées
        self.assertEqual(count, 2)
        self.assertIsNone(self.cache.get("key1"))
        self.assertIsNone(self.cache.get("key2"))
        
        # Vérifier que les autres clés n'ont pas été invalidées
        self.assertEqual(self.cache.get("key3"), "value3")

    def test_invalidate_by_dependency(self):
        """Teste l'invalidation par dépendance."""
        # Invalider par dépendance
        count = self.invalidator.invalidate_by_dependency("dep1")
        
        # Vérifier que les clés dépendantes ont été invalidées
        self.assertEqual(count, 2)
        self.assertIsNone(self.cache.get("key1"))
        self.assertIsNone(self.cache.get("key2"))
        
        # Vérifier que les autres clés n'ont pas été invalidées
        self.assertEqual(self.cache.get("key3"), "value3")

    def test_invalidate_by_dependencies(self):
        """Teste l'invalidation par plusieurs dépendances."""
        # Invalider par plusieurs dépendances
        count = self.invalidator.invalidate_by_dependencies(["dep1", "dep2"])
        
        # Vérifier que toutes les clés ont été invalidées
        self.assertEqual(count, 3)
        self.assertIsNone(self.cache.get("key1"))
        self.assertIsNone(self.cache.get("key2"))
        self.assertIsNone(self.cache.get("key3"))

    def test_invalidate_by_tag(self):
        """Teste l'invalidation par tag."""
        # Invalider par tag
        count = self.invalidator.invalidate_by_tag("tag1")
        
        # Vérifier que les clés avec le tag ont été invalidées
        self.assertEqual(count, 2)
        self.assertIsNone(self.cache.get("key1"))
        self.assertEqual(self.cache.get("key2"), "value2")
        self.assertIsNone(self.cache.get("key3"))

    def test_invalidate_by_tags(self):
        """Teste l'invalidation par plusieurs tags."""
        # Invalider par plusieurs tags (match_all=False)
        count = self.invalidator.invalidate_by_tags(["tag1", "tag2"], match_all=False)
        
        # Vérifier que toutes les clés ont été invalidées
        self.assertEqual(count, 3)
        self.assertIsNone(self.cache.get("key1"))
        self.assertIsNone(self.cache.get("key2"))
        self.assertIsNone(self.cache.get("key3"))
        
        # Réinitialiser le cache
        self.cache.set("key1", "value1")
        self.cache.set("key2", "value2")
        self.cache.set("key3", "value3")
        
        # Ajouter des tags
        self.dependency_manager.add_tag("key1", "tag1")
        self.dependency_manager.add_tag("key1", "tag2")
        self.dependency_manager.add_tag("key2", "tag2")
        self.dependency_manager.add_tag("key3", "tag1")
        
        # Invalider par plusieurs tags (match_all=True)
        count = self.invalidator.invalidate_by_tags(["tag1", "tag2"], match_all=True)
        
        # Vérifier que seules les clés avec tous les tags ont été invalidées
        self.assertEqual(count, 1)
        self.assertIsNone(self.cache.get("key1"))
        self.assertEqual(self.cache.get("key2"), "value2")
        self.assertEqual(self.cache.get("key3"), "value3")

    def test_invalidate_by_pattern(self):
        """Teste l'invalidation par motif."""
        # Invalider par motif
        count = self.invalidator.invalidate_by_pattern("pattern:*")
        
        # Vérifier que les clés correspondant au motif ont été invalidées
        self.assertEqual(count, 2)
        self.assertIsNone(self.cache.get("pattern:1"))
        self.assertIsNone(self.cache.get("pattern:2"))
        
        # Vérifier que les autres clés n'ont pas été invalidées
        self.assertEqual(self.cache.get("key1"), "value1")
        self.assertEqual(self.cache.get("key2"), "value2")
        self.assertEqual(self.cache.get("key3"), "value3")

    def test_invalidate_all(self):
        """Teste l'invalidation de toutes les clés."""
        # Invalider toutes les clés
        count = self.invalidator.invalidate_all()
        
        # Vérifier que toutes les clés ont été invalidées
        self.assertEqual(count, 5)
        self.assertIsNone(self.cache.get("key1"))
        self.assertIsNone(self.cache.get("key2"))
        self.assertIsNone(self.cache.get("key3"))
        self.assertIsNone(self.cache.get("pattern:1"))
        self.assertIsNone(self.cache.get("pattern:2"))
        
        # Vérifier que toutes les dépendances et tags ont été supprimés
        self.assertEqual(len(self.dependency_manager.dependencies), 0)
        self.assertEqual(len(self.dependency_manager.reverse_dependencies), 0)
        self.assertEqual(len(self.dependency_manager.tags), 0)
        self.assertEqual(len(self.dependency_manager.key_tags), 0)

    def test_invalidate_expired(self):
        """Teste l'invalidation des clés expirées."""
        # Ajouter des clés avec TTL
        self.cache.set("expired:1", "expired value 1", ttl=1)  # 1 seconde
        self.cache.set("expired:2", "expired value 2", ttl=10)  # 10 secondes
        
        # Attendre que la première clé expire
        time.sleep(2)
        
        # Invalider les clés expirées
        count = self.invalidator.invalidate_expired()
        
        # Vérifier que seule la première clé a été invalidée
        self.assertEqual(count, 1)
        self.assertIsNone(self.cache.get("expired:1"))
        self.assertEqual(self.cache.get("expired:2"), "expired value 2")

    @patch('time.sleep')
    def test_schedule_invalidation(self, mock_sleep):
        """Teste la planification d'une invalidation."""
        # Simuler le comportement de time.sleep
        mock_sleep.side_effect = lambda x: None
        
        # Créer une fonction mock pour l'invalidation
        mock_invalidate = MagicMock()
        
        # Planifier une invalidation
        self.invalidator.schedule_invalidation(10, mock_invalidate, "arg1", kwarg="kwarg")
        
        # Démarrer le planificateur
        self.invalidator._start_scheduler()
        
        # Exécuter les tâches en attente
        self.invalidator.scheduler.run_pending()
        
        # Vérifier que la fonction d'invalidation a été appelée
        mock_invalidate.assert_called_once_with("arg1", kwarg="kwarg")

    @patch('time.sleep')
    def test_schedule_invalidation_by_tag(self, mock_sleep):
        """Teste la planification d'une invalidation par tag."""
        # Simuler le comportement de time.sleep
        mock_sleep.side_effect = lambda x: None
        
        # Créer une méthode mock pour l'invalidation par tag
        self.invalidator.invalidate_by_tag = MagicMock()
        
        # Planifier une invalidation par tag
        self.invalidator.schedule_invalidation_by_tag("tag1", 10)
        
        # Exécuter les tâches en attente
        self.invalidator.scheduler.run_pending()
        
        # Vérifier que la méthode d'invalidation par tag a été appelée
        self.invalidator.invalidate_by_tag.assert_called_once_with("tag1")

    @patch('time.sleep')
    def test_schedule_invalidation_by_pattern(self, mock_sleep):
        """Teste la planification d'une invalidation par motif."""
        # Simuler le comportement de time.sleep
        mock_sleep.side_effect = lambda x: None
        
        # Créer une méthode mock pour l'invalidation par motif
        self.invalidator.invalidate_by_pattern = MagicMock()
        
        # Planifier une invalidation par motif
        self.invalidator.schedule_invalidation_by_pattern("pattern:*", 10)
        
        # Exécuter les tâches en attente
        self.invalidator.scheduler.run_pending()
        
        # Vérifier que la méthode d'invalidation par motif a été appelée
        self.invalidator.invalidate_by_pattern.assert_called_once_with("pattern:*")

    @patch('time.sleep')
    def test_schedule_invalidation_expired(self, mock_sleep):
        """Teste la planification d'une invalidation des clés expirées."""
        # Simuler le comportement de time.sleep
        mock_sleep.side_effect = lambda x: None
        
        # Créer une méthode mock pour l'invalidation des clés expirées
        self.invalidator.invalidate_expired = MagicMock()
        
        # Planifier une invalidation des clés expirées
        self.invalidator.schedule_invalidation_expired(10)
        
        # Exécuter les tâches en attente
        self.invalidator.scheduler.run_pending()
        
        # Vérifier que la méthode d'invalidation des clés expirées a été appelée
        self.invalidator.invalidate_expired.assert_called_once()

    def test_stop_scheduler(self):
        """Teste l'arrêt du planificateur."""
        # Démarrer le planificateur
        self.invalidator._start_scheduler()
        
        # Vérifier que le planificateur est en cours d'exécution
        self.assertTrue(self.invalidator.scheduler_running)
        self.assertIsNotNone(self.invalidator.scheduler_thread)
        
        # Arrêter le planificateur
        self.invalidator.stop_scheduler()
        
        # Vérifier que le planificateur a été arrêté
        self.assertFalse(self.invalidator.scheduler_running)

    def test_get_default_invalidator(self):
        """Teste la récupération de l'instance par défaut de l'invalidateur de cache."""
        # Récupérer l'instance par défaut
        invalidator = get_default_invalidator()
        
        # Vérifier que l'instance n'est pas None
        self.assertIsNotNone(invalidator)
        
        # Vérifier que c'est bien une instance de CacheInvalidator
        self.assertIsInstance(invalidator, CacheInvalidator)
        
        # Vérifier que la récupération d'une deuxième instance renvoie la même instance
        invalidator2 = get_default_invalidator()
        self.assertIs(invalidator, invalidator2)


if __name__ == '__main__':
    unittest.main()
