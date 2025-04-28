#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module de reporting du framework de benchmarking.

Ce module teste les fonctionnalités du module reporting.py.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import json
import unittest
import tempfile
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../')))

# Importer les modules à tester
from scripts.utils.cache.benchmark.reporting import (
    generate_report, generate_summary, compare_reports
)


class TestReporting(unittest.TestCase):
    """Tests pour le module de reporting."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.test_dir = tempfile.mkdtemp()
        
        # Créer des résultats de benchmark fictifs
        self.results = {
            "start_time": 1650000000,
            "end_time": 1650000030,
            "duration_seconds": 30,
            "operations": {
                "total": 10000,
                "get": 8000,
                "set": 1500,
                "delete": 500,
                "get_many": 0,
                "set_many": 0,
                "delete_many": 0
            },
            "latencies": {
                "get": {
                    "avg": 1.5,
                    "min": 0.5,
                    "max": 10.0,
                    "p50": 1.2,
                    "p95": 3.0,
                    "p99": 5.0
                },
                "set": {
                    "avg": 2.0,
                    "min": 1.0,
                    "max": 15.0,
                    "p50": 1.8,
                    "p95": 4.0,
                    "p99": 8.0
                },
                "delete": {
                    "avg": 1.8,
                    "min": 0.8,
                    "max": 12.0,
                    "p50": 1.5,
                    "p95": 3.5,
                    "p99": 6.0
                },
                "get_many": {
                    "avg": None,
                    "min": None,
                    "max": None,
                    "p50": None,
                    "p95": None,
                    "p99": None
                },
                "set_many": {
                    "avg": None,
                    "min": None,
                    "max": None,
                    "p50": None,
                    "p95": None,
                    "p99": None
                },
                "delete_many": {
                    "avg": None,
                    "min": None,
                    "max": None,
                    "p50": None,
                    "p95": None,
                    "p99": None
                }
            },
            "hit_ratio": {
                "values": [0.75, 0.78, 0.80, 0.82],
                "avg": 0.79,
                "min": 0.75,
                "max": 0.82
            },
            "memory_usage": {
                "values": [50.0, 52.0, 55.0, 53.0],
                "avg": 52.5,
                "min": 50.0,
                "max": 55.0
            },
            "throughput": {
                "operations_per_second": 333.33
            }
        }
        
        # Créer une configuration de benchmark fictive
        self.config = {
            "test_id": "test_lru_throughput",
            "cache_type": "lru",
            "benchmark_type": "throughput",
            "dataset_size": 10000,
            "value_size": 1024,
            "data_distribution": "uniform",
            "operation_mix": {
                "get": 0.8,
                "set": 0.15,
                "delete": 0.05
            },
            "concurrency_level": 1,
            "duration_seconds": 30,
            "expected_hit_ratio": 0.7,
            "max_latency_ms": 5.0,
            "max_memory_mb": 100.0,
            "output_dir": self.test_dir
        }
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer les fichiers de test
        for root, dirs, files in os.walk(self.test_dir, topdown=False):
            for file in files:
                os.remove(os.path.join(root, file))
            for dir in dirs:
                os.rmdir(os.path.join(root, dir))
        
        # Supprimer le répertoire de test
        os.rmdir(self.test_dir)
    
    def test_generate_summary(self):
        """Teste la génération d'un résumé des résultats."""
        # Générer un résumé
        summary = generate_summary(self.results, self.config)
        
        # Vérifier les attributs du résumé
        self.assertEqual(summary["test_id"], "test_lru_throughput")
        self.assertEqual(summary["cache_type"], "lru")
        self.assertEqual(summary["benchmark_type"], "throughput")
        self.assertEqual(summary["duration_seconds"], 30)
        self.assertEqual(summary["total_operations"], 10000)
        self.assertEqual(summary["operations_per_second"], 333.33)
        
        # Vérifier les statistiques de latence
        self.assertEqual(summary["latency"]["get"]["avg_ms"], 1.5)
        self.assertEqual(summary["latency"]["get"]["p95_ms"], 3.0)
        self.assertEqual(summary["latency"]["get"]["p99_ms"], 5.0)
        
        # Vérifier les statistiques du taux de succès
        self.assertEqual(summary["hit_ratio"]["avg"], 0.79)
        self.assertEqual(summary["hit_ratio"]["min"], 0.75)
        self.assertEqual(summary["hit_ratio"]["max"], 0.82)
        
        # Vérifier les statistiques d'utilisation de la mémoire
        self.assertEqual(summary["memory_usage"]["avg_mb"], 52.5)
        self.assertEqual(summary["memory_usage"]["max_mb"], 55.0)
        
        # Vérifier le statut de succès
        self.assertTrue(summary["success"])
        
        # Vérifier les recommandations
        self.assertTrue(len(summary["recommendations"]) > 0)
    
    def test_generate_report(self):
        """Teste la génération d'un rapport."""
        # Générer un rapport
        report_file = generate_report(self.results, self.config)
        
        # Vérifier que le fichier existe
        self.assertTrue(os.path.exists(report_file))
        
        # Vérifier que le fichier est un JSON valide
        with open(report_file, 'r', encoding='utf-8') as f:
            report = json.load(f)
        
        # Vérifier les attributs du rapport
        self.assertIn("timestamp", report)
        self.assertIn("config", report)
        self.assertIn("results", report)
        self.assertIn("summary", report)
        
        # Vérifier les attributs de la configuration
        self.assertEqual(report["config"]["test_id"], "test_lru_throughput")
        self.assertEqual(report["config"]["cache_type"], "lru")
        self.assertEqual(report["config"]["benchmark_type"], "throughput")
        
        # Vérifier les attributs des résultats
        self.assertEqual(report["results"]["duration_seconds"], 30)
        self.assertEqual(report["results"]["operations"]["total"], 10000)
        self.assertEqual(report["results"]["throughput"]["operations_per_second"], 333.33)
        
        # Vérifier les attributs du résumé
        self.assertEqual(report["summary"]["test_id"], "test_lru_throughput")
        self.assertEqual(report["summary"]["cache_type"], "lru")
        self.assertEqual(report["summary"]["benchmark_type"], "throughput")
        self.assertEqual(report["summary"]["duration_seconds"], 30)
        self.assertEqual(report["summary"]["total_operations"], 10000)
        self.assertEqual(report["summary"]["operations_per_second"], 333.33)
    
    def test_compare_reports(self):
        """Teste la comparaison de rapports."""
        # Générer deux rapports
        report_file1 = generate_report(self.results, self.config)
        
        # Modifier la configuration pour le deuxième rapport
        config2 = self.config.copy()
        config2["cache_type"] = "lfu"
        config2["test_id"] = "test_lfu_throughput"
        
        report_file2 = generate_report(self.results, config2)
        
        # Comparer les rapports
        comparison = compare_reports([report_file1, report_file2])
        
        # Vérifier les attributs de la comparaison
        self.assertIn("timestamp", comparison)
        self.assertIn("reports", comparison)
        self.assertIn("throughput", comparison)
        self.assertIn("latency", comparison)
        self.assertIn("hit_ratio", comparison)
        self.assertIn("memory_usage", comparison)
        
        # Vérifier les labels
        self.assertEqual(comparison["throughput"]["labels"], ["lru", "lfu"])
        
        # Vérifier les valeurs
        self.assertEqual(comparison["throughput"]["values"], [333.33, 333.33])
        self.assertEqual(comparison["latency"]["get"]["values"], [1.5, 1.5])
        self.assertEqual(comparison["hit_ratio"]["values"], [0.79, 0.79])
        self.assertEqual(comparison["memory_usage"]["values"], [52.5, 52.5])


if __name__ == "__main__":
    unittest.main()
