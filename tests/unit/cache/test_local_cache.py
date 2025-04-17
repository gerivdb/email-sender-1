#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module local_cache.py.

Ce module contient les tests unitaires pour la classe LocalCache
qui implémente un système de cache local avec DiskCache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import json
import time
import shutil
import tempfile
import unittest
from unittest.mock import patch, MagicMock

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache, create_cache_from_config


class TestLocalCache(unittest.TestCase):
    """Tests pour la classe LocalCache."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache
        self.temp_dir = tempfile.mkdtemp()
        self.cache = LocalCache(cache_dir=self.temp_dir)
        
        # Créer un fichier de configuration temporaire pour les tests
        self.config_file = os.path.join(self.temp_dir, 'test_config.json')
        self.test_config = {
            "DefaultTTL": 1800,
            "MaxDiskSize": 500,
            "CachePath": os.path.join(self.temp_dir, 'config_cache'),
            "EvictionPolicy": "LRU"
        }
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self.test_config, f)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Fermer le cache
        self.cache.cache.close()
        
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    def test_init_default(self):
        """Teste l'initialisation avec les paramètres par défaut."""
        cache = LocalCache()
        self.assertEqual(cache.config["DefaultTTL"], 3600)
        self.assertEqual(cache.config["MaxDiskSize"], 1000)
        self.assertEqual(cache.config["EvictionPolicy"], "LRU")
        cache.cache.close()

    def test_init_with_config_file(self):
        """Teste l'initialisation avec un fichier de configuration."""
        cache = LocalCache(config_path=self.config_file)
        self.assertEqual(cache.config["DefaultTTL"], 1800)
        self.assertEqual(cache.config["MaxDiskSize"], 500)
        self.assertEqual(cache.config["CachePath"], os.path.join(self.temp_dir, 'config_cache'))
        self.assertEqual(cache.config["EvictionPolicy"], "LRU")
        cache.cache.close()

    def test_set_get(self):
        """Teste les opérations de base set et get."""
        # Stocker une valeur
        self.cache.set('test_key', 'test_value')
        
        # Récupérer la valeur
        value = self.cache.get('test_key')
        self.assertEqual(value, 'test_value')
        
        # Vérifier les statistiques
        stats = self.cache.get_statistics()
        self.assertEqual(stats['hits'], 1)
        self.assertEqual(stats['sets'], 1)

    def test_get_nonexistent(self):
        """Teste la récupération d'une clé inexistante."""
        # Récupérer une clé inexistante
        value = self.cache.get('nonexistent_key')
        self.assertIsNone(value)
        
        # Récupérer une clé inexistante avec une valeur par défaut
        value = self.cache.get('nonexistent_key', 'default_value')
        self.assertEqual(value, 'default_value')
        
        # Vérifier les statistiques
        stats = self.cache.get_statistics()
        self.assertEqual(stats['misses'], 2)

    def test_delete(self):
        """Teste la suppression d'éléments du cache."""
        # Stocker une valeur
        self.cache.set('test_key', 'test_value')
        
        # Vérifier que la valeur existe
        self.assertEqual(self.cache.get('test_key'), 'test_value')
        
        # Supprimer la valeur
        result = self.cache.delete('test_key')
        self.assertTrue(result)
        
        # Vérifier que la valeur n'existe plus
        self.assertIsNone(self.cache.get('test_key'))
        
        # Vérifier les statistiques
        stats = self.cache.get_statistics()
        self.assertEqual(stats['deletes'], 1)
        
        # Tenter de supprimer une clé inexistante
        result = self.cache.delete('nonexistent_key')
        self.assertFalse(result)

    def test_clear(self):
        """Teste le vidage du cache."""
        # Stocker plusieurs valeurs
        self.cache.set('key1', 'value1')
        self.cache.set('key2', 'value2')
        self.cache.set('key3', 'value3')
        
        # Vérifier que les valeurs existent
        self.assertEqual(self.cache.get('key1'), 'value1')
        self.assertEqual(self.cache.get('key2'), 'value2')
        self.assertEqual(self.cache.get('key3'), 'value3')
        
        # Vider le cache
        self.cache.clear()
        
        # Vérifier que les valeurs n'existent plus
        self.assertIsNone(self.cache.get('key1'))
        self.assertIsNone(self.cache.get('key2'))
        self.assertIsNone(self.cache.get('key3'))
        
        # Vérifier que les statistiques ont été réinitialisées
        stats = self.cache.get_statistics()
        self.assertEqual(stats['hits'], 0)
        self.assertEqual(stats['misses'], 3)
        self.assertEqual(stats['sets'], 0)
        self.assertEqual(stats['deletes'], 0)

    def test_ttl(self):
        """Teste l'expiration des éléments du cache."""
        # Stocker une valeur avec un TTL court
        self.cache.set('short_ttl', 'value', ttl=1)
        
        # Vérifier que la valeur existe
        self.assertEqual(self.cache.get('short_ttl'), 'value')
        
        # Attendre l'expiration
        time.sleep(1.1)
        
        # Vérifier que la valeur a expiré
        self.assertIsNone(self.cache.get('short_ttl'))

    def test_memoize(self):
        """Teste le décorateur de mémoïsation."""
        # Créer une fonction mock
        mock_func = MagicMock(return_value='result')
        
        # Appliquer le décorateur
        memoized_func = self.cache.memoize()(mock_func)
        
        # Premier appel (devrait exécuter la fonction)
        result1 = memoized_func('arg1', 'arg2', kwarg='kwarg')
        self.assertEqual(result1, 'result')
        mock_func.assert_called_once_with('arg1', 'arg2', kwarg='kwarg')
        
        # Réinitialiser le mock
        mock_func.reset_mock()
        
        # Deuxième appel (devrait utiliser le cache)
        result2 = memoized_func('arg1', 'arg2', kwarg='kwarg')
        self.assertEqual(result2, 'result')
        mock_func.assert_not_called()
        
        # Vérifier les statistiques
        stats = self.cache.get_statistics()
        self.assertEqual(stats['hits'], 1)
        self.assertEqual(stats['sets'], 1)

    def test_context_manager(self):
        """Teste l'utilisation comme gestionnaire de contexte."""
        with LocalCache(cache_dir=self.temp_dir) as cache:
            # Stocker une valeur
            cache.set('test_key', 'test_value')
            
            # Récupérer la valeur
            value = cache.get('test_key')
            self.assertEqual(value, 'test_value')

    def test_create_cache_from_config(self):
        """Teste la fonction utilitaire create_cache_from_config."""
        cache = create_cache_from_config(self.config_file)
        self.assertEqual(cache.config["DefaultTTL"], 1800)
        self.assertEqual(cache.config["MaxDiskSize"], 500)
        self.assertEqual(cache.config["CachePath"], os.path.join(self.temp_dir, 'config_cache'))
        self.assertEqual(cache.config["EvictionPolicy"], "LRU")
        cache.cache.close()

    def test_size_and_count(self):
        """Teste les propriétés size et count."""
        # Stocker plusieurs valeurs
        self.cache.set('key1', 'value1')
        self.cache.set('key2', 'value2')
        self.cache.set('key3', 'value3')
        
        # Vérifier le nombre d'éléments
        self.assertEqual(self.cache.count, 3)
        
        # Vérifier que la taille est positive
        self.assertGreater(self.cache.size, 0)


if __name__ == '__main__':
    unittest.main()
