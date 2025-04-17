#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le planificateur de purge.

Ce module contient les tests unitaires pour la classe PurgeScheduler
qui gère la planification de la purge du cache.

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
from unittest.mock import patch, MagicMock
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager
from scripts.utils.cache.invalidation import CacheInvalidator
from scripts.utils.cache.purge_scheduler import PurgeScheduler, get_default_scheduler


class TestPurgeScheduler(unittest.TestCase):
    """Tests pour la classe PurgeScheduler."""

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
        
        # Créer une instance du planificateur de purge
        self.config_path = os.path.join(self.temp_dir, 'purge_config.json')
        self.scheduler = PurgeScheduler(self.invalidator, self.config_path)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Arrêter le planificateur
        self.scheduler.stop()
        
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_init_default(self):
        """Teste l'initialisation avec les paramètres par défaut."""
        # Vérifier la configuration par défaut
        self.assertTrue(self.scheduler.config["enabled"])
        self.assertEqual(self.scheduler.config["purge_expired_interval"], 300)
        self.assertEqual(len(self.scheduler.config["purge_patterns"]), 1)
        self.assertEqual(self.scheduler.config["purge_patterns"][0]["pattern"], "temp:*")
        self.assertEqual(self.scheduler.config["purge_patterns"][0]["interval"], 3600)
        self.assertEqual(len(self.scheduler.config["purge_tags"]), 1)
        self.assertEqual(self.scheduler.config["purge_tags"][0]["tag"], "temporary")
        self.assertEqual(self.scheduler.config["purge_tags"][0]["interval"], 3600)
        self.assertEqual(self.scheduler.config["max_cache_size"], 100 * 1024 * 1024)
        self.assertEqual(self.scheduler.config["size_check_interval"], 3600)

    def test_save_load_config(self):
        """Teste la sauvegarde et le chargement de la configuration."""
        # Modifier la configuration
        self.scheduler.config["purge_expired_interval"] = 600
        self.scheduler.config["max_cache_size"] = 200 * 1024 * 1024
        
        # Sauvegarder la configuration
        self.scheduler._save_config()
        
        # Créer une nouvelle instance du planificateur de purge
        scheduler2 = PurgeScheduler(self.invalidator, self.config_path)
        
        # Vérifier que la configuration a été chargée
        self.assertEqual(scheduler2.config["purge_expired_interval"], 600)
        self.assertEqual(scheduler2.config["max_cache_size"], 200 * 1024 * 1024)

    @patch('scripts.utils.cache.invalidation.CacheInvalidator.schedule_invalidation_expired')
    def test_start(self, mock_schedule_invalidation_expired):
        """Teste le démarrage du planificateur."""
        # Démarrer le planificateur
        self.scheduler.start()
        
        # Vérifier que les méthodes de planification ont été appelées
        mock_schedule_invalidation_expired.assert_called_once_with(300)

    def test_stop(self):
        """Teste l'arrêt du planificateur."""
        # Créer une méthode mock pour l'arrêt du planificateur de l'invalidateur
        self.invalidator.stop_scheduler = MagicMock()
        
        # Arrêter le planificateur
        self.scheduler.stop()
        
        # Vérifier que la méthode d'arrêt du planificateur de l'invalidateur a été appelée
        self.invalidator.stop_scheduler.assert_called_once()

    def test_add_pattern_purge(self):
        """Teste l'ajout d'une purge périodique pour un motif."""
        # Ajouter une purge périodique pour un motif
        self.scheduler.add_pattern_purge("test:*", 1800)
        
        # Vérifier que le motif a été ajouté à la configuration
        patterns = [p["pattern"] for p in self.scheduler.config["purge_patterns"]]
        self.assertIn("test:*", patterns)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            patterns = [p["pattern"] for p in config["purge_patterns"]]
            self.assertIn("test:*", patterns)

    def test_add_tag_purge(self):
        """Teste l'ajout d'une purge périodique pour un tag."""
        # Ajouter une purge périodique pour un tag
        self.scheduler.add_tag_purge("test", 1800)
        
        # Vérifier que le tag a été ajouté à la configuration
        tags = [t["tag"] for t in self.scheduler.config["purge_tags"]]
        self.assertIn("test", tags)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            tags = [t["tag"] for t in config["purge_tags"]]
            self.assertIn("test", tags)

    def test_remove_pattern_purge(self):
        """Teste la suppression d'une purge périodique pour un motif."""
        # Ajouter une purge périodique pour un motif
        self.scheduler.add_pattern_purge("test:*", 1800)
        
        # Supprimer la purge périodique
        result = self.scheduler.remove_pattern_purge("test:*")
        
        # Vérifier que la purge a été supprimée
        self.assertTrue(result)
        patterns = [p["pattern"] for p in self.scheduler.config["purge_patterns"]]
        self.assertNotIn("test:*", patterns)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            patterns = [p["pattern"] for p in config["purge_patterns"]]
            self.assertNotIn("test:*", patterns)
        
        # Supprimer une purge inexistante
        result = self.scheduler.remove_pattern_purge("nonexistent:*")
        self.assertFalse(result)

    def test_remove_tag_purge(self):
        """Teste la suppression d'une purge périodique pour un tag."""
        # Ajouter une purge périodique pour un tag
        self.scheduler.add_tag_purge("test", 1800)
        
        # Supprimer la purge périodique
        result = self.scheduler.remove_tag_purge("test")
        
        # Vérifier que la purge a été supprimée
        self.assertTrue(result)
        tags = [t["tag"] for t in self.scheduler.config["purge_tags"]]
        self.assertNotIn("test", tags)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            tags = [t["tag"] for t in config["purge_tags"]]
            self.assertNotIn("test", tags)
        
        # Supprimer une purge inexistante
        result = self.scheduler.remove_tag_purge("nonexistent")
        self.assertFalse(result)

    def test_set_max_cache_size(self):
        """Teste la définition de la taille maximale du cache."""
        # Définir la taille maximale du cache
        self.scheduler.set_max_cache_size(50 * 1024 * 1024)
        
        # Vérifier que la taille maximale a été définie
        self.assertEqual(self.scheduler.config["max_cache_size"], 50 * 1024 * 1024)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.assertEqual(config["max_cache_size"], 50 * 1024 * 1024)

    def test_set_size_check_interval(self):
        """Teste la définition de l'intervalle de vérification de la taille du cache."""
        # Définir l'intervalle de vérification de la taille du cache
        self.scheduler.set_size_check_interval(1800)
        
        # Vérifier que l'intervalle a été défini
        self.assertEqual(self.scheduler.config["size_check_interval"], 1800)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.assertEqual(config["size_check_interval"], 1800)

    def test_set_purge_expired_interval(self):
        """Teste la définition de l'intervalle de purge des clés expirées."""
        # Définir l'intervalle de purge des clés expirées
        self.scheduler.set_purge_expired_interval(1800)
        
        # Vérifier que l'intervalle a été défini
        self.assertEqual(self.scheduler.config["purge_expired_interval"], 1800)
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.assertEqual(config["purge_expired_interval"], 1800)

    def test_enable_disable(self):
        """Teste l'activation et la désactivation du planificateur."""
        # Désactiver le planificateur
        self.scheduler.disable()
        
        # Vérifier que le planificateur est désactivé
        self.assertFalse(self.scheduler.config["enabled"])
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.assertFalse(config["enabled"])
        
        # Activer le planificateur
        self.scheduler.enable()
        
        # Vérifier que le planificateur est activé
        self.assertTrue(self.scheduler.config["enabled"])
        
        # Vérifier que la configuration a été sauvegardée
        with open(self.config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
            self.assertTrue(config["enabled"])

    @patch('scripts.utils.cache.invalidation.CacheInvalidator.invalidate_keys')
    def test_check_cache_size(self, mock_invalidate_keys):
        """Teste la vérification de la taille du cache."""
        # Créer une méthode mock pour récupérer la taille du cache
        self.invalidator.cache.get_size = MagicMock(return_value=200 * 1024 * 1024)
        
        # Créer une méthode mock pour récupérer les clés avec leur date d'accès
        self.invalidator.cache.get_keys_with_access_time = MagicMock(return_value=[
            ("key1", 1000),
            ("key2", 2000),
            ("key3", 3000)
        ])
        
        # Définir la taille maximale du cache
        self.scheduler.set_max_cache_size(100 * 1024 * 1024)
        
        # Vérifier la taille du cache
        self.scheduler._check_cache_size()
        
        # Vérifier que la méthode d'invalidation a été appelée avec les clés les plus anciennes
        mock_invalidate_keys.assert_called_once_with(["key1"])

    def test_get_default_scheduler(self):
        """Teste la récupération de l'instance par défaut du planificateur de purge."""
        # Récupérer l'instance par défaut
        scheduler = get_default_scheduler()
        
        # Vérifier que l'instance n'est pas None
        self.assertIsNotNone(scheduler)
        
        # Vérifier que c'est bien une instance de PurgeScheduler
        self.assertIsInstance(scheduler, PurgeScheduler)
        
        # Vérifier que la récupération d'une deuxième instance renvoie la même instance
        scheduler2 = get_default_scheduler()
        self.assertIs(scheduler, scheduler2)


if __name__ == '__main__':
    unittest.main()
