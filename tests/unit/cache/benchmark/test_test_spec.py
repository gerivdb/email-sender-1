#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests unitaires pour le module de spécification de test du framework de benchmarking.

Ce module teste les fonctionnalités du module test_spec.py.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import json
import unittest
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../')))

# Importer les modules à tester
from scripts.utils.cache.benchmark.test_spec import (
    CacheTestSpec, CacheType, BenchmarkType, DataDistribution, OperationType,
    create_test_spec, create_standard_test_suite
)


class TestCacheTestSpec(unittest.TestCase):
    """Tests pour la classe CacheTestSpec."""
    
    def setUp(self):
        """Initialisation avant chaque test."""
        # Créer un répertoire temporaire pour les tests
        self.test_dir = os.path.join(os.path.dirname(__file__), 'test_output')
        os.makedirs(self.test_dir, exist_ok=True)
    
    def tearDown(self):
        """Nettoyage après chaque test."""
        # Supprimer les fichiers de test
        for file in os.listdir(self.test_dir):
            os.remove(os.path.join(self.test_dir, file))
        
        # Supprimer le répertoire de test
        os.rmdir(self.test_dir)
    
    def test_create_test_spec(self):
        """Teste la création d'une spécification de test."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=10000,
            value_size=1024
        )
        
        # Vérifier les attributs
        self.assertEqual(test_spec.test_id, "test_lru_throughput")
        self.assertEqual(test_spec.cache_type, "lru")
        self.assertEqual(test_spec.benchmark_type, "throughput")
        self.assertEqual(test_spec.dataset_size, 10000)
        self.assertEqual(test_spec.value_size, 1024)
        self.assertEqual(test_spec.data_distribution, "uniform")
        self.assertEqual(test_spec.concurrency_level, 1)
        self.assertEqual(test_spec.duration_seconds, 60)
    
    def test_create_test_spec_with_string_types(self):
        """Teste la création d'une spécification de test avec des types sous forme de chaînes."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type="lru",
            benchmark_type="throughput",
            dataset_size=10000,
            value_size=1024,
            data_distribution="zipf"
        )
        
        # Vérifier les attributs
        self.assertEqual(test_spec.test_id, "test_lru_throughput")
        self.assertEqual(test_spec.cache_type, "lru")
        self.assertEqual(test_spec.benchmark_type, "throughput")
        self.assertEqual(test_spec.dataset_size, 10000)
        self.assertEqual(test_spec.value_size, 1024)
        self.assertEqual(test_spec.data_distribution, "zipf")
    
    def test_invalid_cache_type(self):
        """Teste la validation du type de cache."""
        # Vérifier qu'une exception est levée pour un type de cache invalide
        with self.assertRaises(ValueError):
            create_test_spec(
                test_id="test_invalid",
                cache_type="invalid_type",
                benchmark_type=BenchmarkType.THROUGHPUT,
                dataset_size=10000,
                value_size=1024
            )
    
    def test_invalid_benchmark_type(self):
        """Teste la validation du type de benchmark."""
        # Vérifier qu'une exception est levée pour un type de benchmark invalide
        with self.assertRaises(ValueError):
            create_test_spec(
                test_id="test_invalid",
                cache_type=CacheType.LRU,
                benchmark_type="invalid_type",
                dataset_size=10000,
                value_size=1024
            )
    
    def test_invalid_data_distribution(self):
        """Teste la validation de la distribution des données."""
        # Vérifier qu'une exception est levée pour une distribution invalide
        with self.assertRaises(ValueError):
            create_test_spec(
                test_id="test_invalid",
                cache_type=CacheType.LRU,
                benchmark_type=BenchmarkType.THROUGHPUT,
                dataset_size=10000,
                value_size=1024,
                data_distribution="invalid_distribution"
            )
    
    def test_invalid_operation_mix(self):
        """Teste la validation du mélange d'opérations."""
        # Vérifier qu'une exception est levée pour un mélange d'opérations invalide
        with self.assertRaises(ValueError):
            create_test_spec(
                test_id="test_invalid",
                cache_type=CacheType.LRU,
                benchmark_type=BenchmarkType.THROUGHPUT,
                dataset_size=10000,
                value_size=1024,
                operation_mix={
                    "get": 0.5,
                    "set": 0.3
                }  # Somme = 0.8, devrait être proche de 1
            )
    
    def test_to_dict(self):
        """Teste la conversion en dictionnaire."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=10000,
            value_size=1024
        )
        
        # Convertir en dictionnaire
        test_dict = test_spec.to_dict()
        
        # Vérifier les attributs
        self.assertEqual(test_dict["test_id"], "test_lru_throughput")
        self.assertEqual(test_dict["cache_type"], "lru")
        self.assertEqual(test_dict["benchmark_type"], "throughput")
        self.assertEqual(test_dict["dataset_size"], 10000)
        self.assertEqual(test_dict["value_size"], 1024)
    
    def test_to_json(self):
        """Teste la conversion en JSON."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=10000,
            value_size=1024
        )
        
        # Convertir en JSON
        test_json = test_spec.to_json()
        
        # Vérifier que le JSON est valide
        test_dict = json.loads(test_json)
        
        # Vérifier les attributs
        self.assertEqual(test_dict["test_id"], "test_lru_throughput")
        self.assertEqual(test_dict["cache_type"], "lru")
        self.assertEqual(test_dict["benchmark_type"], "throughput")
        self.assertEqual(test_dict["dataset_size"], 10000)
        self.assertEqual(test_dict["value_size"], 1024)
    
    def test_save_and_load(self):
        """Teste l'enregistrement et le chargement d'une spécification de test."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=10000,
            value_size=1024,
            output_dir=self.test_dir
        )
        
        # Enregistrer la spécification
        file_path = test_spec.save()
        
        # Vérifier que le fichier existe
        self.assertTrue(os.path.exists(file_path))
        
        # Charger la spécification
        loaded_spec = CacheTestSpec.load(file_path)
        
        # Vérifier les attributs
        self.assertEqual(loaded_spec.test_id, "test_lru_throughput")
        self.assertEqual(loaded_spec.cache_type, "lru")
        self.assertEqual(loaded_spec.benchmark_type, "throughput")
        self.assertEqual(loaded_spec.dataset_size, 10000)
        self.assertEqual(loaded_spec.value_size, 1024)
    
    def test_from_dict(self):
        """Teste la création à partir d'un dictionnaire."""
        # Créer un dictionnaire
        test_dict = {
            "test_id": "test_lru_throughput",
            "cache_type": "lru",
            "benchmark_type": "throughput",
            "dataset_size": 10000,
            "value_size": 1024,
            "data_distribution": "uniform",
            "concurrency_level": 1,
            "duration_seconds": 60
        }
        
        # Créer une spécification à partir du dictionnaire
        test_spec = CacheTestSpec.from_dict(test_dict)
        
        # Vérifier les attributs
        self.assertEqual(test_spec.test_id, "test_lru_throughput")
        self.assertEqual(test_spec.cache_type, "lru")
        self.assertEqual(test_spec.benchmark_type, "throughput")
        self.assertEqual(test_spec.dataset_size, 10000)
        self.assertEqual(test_spec.value_size, 1024)
        self.assertEqual(test_spec.data_distribution, "uniform")
        self.assertEqual(test_spec.concurrency_level, 1)
        self.assertEqual(test_spec.duration_seconds, 60)
    
    def test_from_json(self):
        """Teste la création à partir d'une chaîne JSON."""
        # Créer une chaîne JSON
        test_json = json.dumps({
            "test_id": "test_lru_throughput",
            "cache_type": "lru",
            "benchmark_type": "throughput",
            "dataset_size": 10000,
            "value_size": 1024,
            "data_distribution": "uniform",
            "concurrency_level": 1,
            "duration_seconds": 60
        })
        
        # Créer une spécification à partir de la chaîne JSON
        test_spec = CacheTestSpec.from_json(test_json)
        
        # Vérifier les attributs
        self.assertEqual(test_spec.test_id, "test_lru_throughput")
        self.assertEqual(test_spec.cache_type, "lru")
        self.assertEqual(test_spec.benchmark_type, "throughput")
        self.assertEqual(test_spec.dataset_size, 10000)
        self.assertEqual(test_spec.value_size, 1024)
        self.assertEqual(test_spec.data_distribution, "uniform")
        self.assertEqual(test_spec.concurrency_level, 1)
        self.assertEqual(test_spec.duration_seconds, 60)
    
    def test_test_script(self):
        """Teste la génération d'un script de test."""
        # Créer une spécification de test
        test_spec = create_test_spec(
            test_id="test_lru_throughput",
            cache_type=CacheType.LRU,
            benchmark_type=BenchmarkType.THROUGHPUT,
            dataset_size=10000,
            value_size=1024
        )
        
        # Générer un script de test
        script = test_spec.test_script
        
        # Vérifier que le script contient les éléments attendus
        self.assertIn("#!/usr/bin/env python", script)
        self.assertIn("test_lru_throughput", script)
        self.assertIn("lru", script)
        self.assertIn("throughput", script)
        self.assertIn("10000", script)
        self.assertIn("1024", script)
        self.assertIn("run_benchmark", script)
        self.assertIn("generate_report", script)
    
    def test_create_standard_test_suite(self):
        """Teste la création d'une suite de tests standard."""
        # Créer une suite de tests standard
        test_suite = create_standard_test_suite()
        
        # Vérifier que la suite contient des tests
        self.assertGreater(len(test_suite), 0)
        
        # Vérifier que chaque élément est une spécification de test
        for test_spec in test_suite:
            self.assertIsInstance(test_spec, CacheTestSpec)


if __name__ == "__main__":
    unittest.main()
