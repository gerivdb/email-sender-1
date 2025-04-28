#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le profileur de mémoire.

Ce module contient les tests unitaires pour le profileur de mémoire
utilisé pour analyser et optimiser l'utilisation de la mémoire du cache.

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
from scripts.utils.cache.memory_profiler import MemoryProfiler


class TestMemoryProfiler(unittest.TestCase):
    """Tests pour le profileur de mémoire."""

    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour le cache et les rapports
        self.temp_dir = tempfile.mkdtemp()
        self.cache_dir = os.path.join(self.temp_dir, 'cache')
        self.reports_dir = os.path.join(self.temp_dir, 'reports')
        
        # Créer une instance du cache
        self.cache = LocalCache(self.cache_dir)
        
        # Créer une instance du profileur de mémoire
        self.profiler = MemoryProfiler(self.cache, self.reports_dir)

    def tearDown(self):
        """Nettoyage après chaque test."""
        # Fermer le cache
        self.cache.cache.close()
        
        # Supprimer le répertoire temporaire
        shutil.rmtree(self.temp_dir)

    @patch('psutil.Process')
    def test_measure(self, mock_process):
        """Teste la mesure de la consommation mémoire."""
        # Simuler les informations de mémoire
        mock_memory_info = MagicMock()
        mock_memory_info.rss = 1024 * 1024  # 1 Mo
        mock_memory_info.vms = 2 * 1024 * 1024  # 2 Mo
        
        mock_process_instance = MagicMock()
        mock_process_instance.memory_info.return_value = mock_memory_info
        mock_process.return_value = mock_process_instance
        
        # Ajouter des données au cache
        for i in range(10):
            self.cache.set(f"key{i}", f"value{i}")
        
        # Mesurer la consommation mémoire
        measurement = self.profiler.measure()
        
        # Vérifier les champs de la mesure
        self.assertIn("timestamp", measurement)
        self.assertIn("cache_size", measurement)
        self.assertIn("cache_count", measurement)
        self.assertIn("process_rss", measurement)
        self.assertIn("process_vms", measurement)
        self.assertIn("cache_hits", measurement)
        self.assertIn("cache_misses", measurement)
        self.assertIn("cache_sets", measurement)
        self.assertIn("cache_deletes", measurement)
        self.assertIn("memory_per_item", measurement)
        
        # Vérifier les valeurs
        self.assertEqual(measurement["cache_count"], 10)
        self.assertEqual(measurement["process_rss"], 1024 * 1024)
        self.assertEqual(measurement["process_vms"], 2 * 1024 * 1024)
        self.assertEqual(measurement["cache_sets"], 10)
        
        # Vérifier que la mesure a été ajoutée à l'historique
        self.assertEqual(len(self.profiler.history), 1)
        self.assertEqual(self.profiler.history[0], measurement)
        
        # Vérifier que les statistiques ont été mises à jour
        self.assertEqual(self.profiler.stats["measurements"], 1)

    def test_analyze_key_distribution(self):
        """Teste l'analyse de la distribution des clés."""
        # Ajouter des données au cache avec différents préfixes
        self.cache.set("user:1", "User 1")
        self.cache.set("user:2", "User 2")
        self.cache.set("product:1", "Product 1")
        self.cache.set("product:2", "Product 2")
        self.cache.set("product:3", "Product 3")
        self.cache.set("order:1", "Order 1")
        
        # Analyser la distribution des clés
        distribution = self.profiler.analyze_key_distribution()
        
        # Vérifier les champs de la distribution
        self.assertIn("total_keys", distribution)
        self.assertIn("prefixes", distribution)
        self.assertIn("key_length_min", distribution)
        self.assertIn("key_length_max", distribution)
        self.assertIn("key_length_avg", distribution)
        
        # Vérifier les valeurs
        self.assertEqual(distribution["total_keys"], 6)
        self.assertEqual(distribution["prefixes"]["user"], 2)
        self.assertEqual(distribution["prefixes"]["product"], 3)
        self.assertEqual(distribution["prefixes"]["order"], 1)
        self.assertEqual(distribution["key_length_min"], 6)  # "user:1"
        self.assertEqual(distribution["key_length_max"], 9)  # "product:3"

    def test_analyze_value_sizes(self):
        """Teste l'analyse de la taille des valeurs."""
        # Ajouter des données au cache avec différentes tailles
        self.cache.set("key1", "x" * 100)
        self.cache.set("key2", "x" * 200)
        self.cache.set("key3", "x" * 300)
        
        # Analyser la taille des valeurs
        value_sizes = self.profiler.analyze_value_sizes()
        
        # Vérifier les champs de l'analyse
        self.assertIn("sample_size", value_sizes)
        self.assertIn("value_size_min", value_sizes)
        self.assertIn("value_size_max", value_sizes)
        self.assertIn("value_size_avg", value_sizes)
        self.assertIn("value_size_total", value_sizes)
        
        # Vérifier les valeurs
        self.assertEqual(value_sizes["sample_size"], 3)
        
        # Les tailles exactes peuvent varier selon l'implémentation de Python
        # Donc on vérifie juste que les valeurs sont cohérentes
        self.assertTrue(value_sizes["value_size_min"] > 0)
        self.assertTrue(value_sizes["value_size_max"] > value_sizes["value_size_min"])
        self.assertTrue(value_sizes["value_size_avg"] > 0)
        self.assertTrue(value_sizes["value_size_total"] > 0)

    def test_generate_report(self):
        """Teste la génération d'un rapport."""
        # Ajouter des données au cache
        for i in range(10):
            self.cache.set(f"key{i}", f"value{i}")
        
        # Mesurer la consommation mémoire
        self.profiler.measure()
        
        # Générer un rapport
        report_file = self.profiler.generate_report()
        
        # Vérifier que le fichier de rapport a été créé
        self.assertTrue(os.path.exists(report_file))
        
        # Vérifier le contenu du rapport
        with open(report_file, 'r', encoding='utf-8') as f:
            report = json.load(f)
        
        # Vérifier les champs du rapport
        self.assertIn("timestamp", report)
        self.assertIn("duration", report)
        self.assertIn("measurements", report)
        self.assertIn("peak_memory", report)
        self.assertIn("peak_items", report)
        self.assertIn("avg_memory_per_item", report)
        self.assertIn("key_distribution", report)
        self.assertIn("value_sizes", report)
        self.assertIn("history", report)
        
        # Vérifier les valeurs
        self.assertEqual(report["measurements"], 1)
        self.assertEqual(report["peak_items"], 10)
        self.assertEqual(len(report["history"]), 1)

    def test_recommend_optimizations(self):
        """Teste les recommandations d'optimisation."""
        # Ajouter des données au cache
        for i in range(100):
            self.cache.set(f"user:{i}", "x" * 10000)  # Valeurs volumineuses
        
        # Mesurer la consommation mémoire
        self.profiler.measure()
        
        # Obtenir des recommandations
        recommendations = self.profiler.recommend_optimizations()
        
        # Vérifier que des recommandations ont été générées
        self.assertTrue(len(recommendations) > 0)
        
        # Vérifier que les recommandations sont des chaînes de caractères
        for recommendation in recommendations:
            self.assertIsInstance(recommendation, str)


if __name__ == '__main__':
    unittest.main()
