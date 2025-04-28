#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'exécution des benchmarks pour le système de cache.

Ce script permet d'exécuter une suite de benchmarks sur différentes
implémentations du système de cache et de générer des rapports comparatifs.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import argparse
from typing import List, Dict, Any, Optional

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))

# Importer les modules nécessaires
from scripts.utils.cache.benchmark.test_spec import (
    create_test_spec, create_standard_test_suite,
    CacheType, BenchmarkType, DataDistribution
)
from scripts.utils.cache.benchmark.runner import run_benchmark
from scripts.utils.cache.benchmark.reporting import generate_report, compare_reports

# Importer les implémentations de cache
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.optimized_algorithms import (
    OptimizedLRUCache, OptimizedLFUCache, OptimizedARCache,
    create_optimized_cache
)
from scripts.utils.cache.parallel_cache import (
    ThreadSafeCache, ShardedCache, AsyncCache, BatchCache,
    create_parallel_cache
)


def create_cache(cache_type: str, **kwargs) -> Any:
    """
    Crée une instance de cache du type spécifié.

    Args:
        cache_type (str): Type de cache à créer.
        **kwargs: Paramètres supplémentaires pour le cache.

    Returns:
        Any: Instance du cache.
    """
    # Extraire les paramètres spécifiques
    capacity = kwargs.pop('capacity', 1000)
    cache_dir = kwargs.pop('cache_dir', 'cache_dir')
    config_path = kwargs.pop('config_path', None)

    if cache_type in ["lru", "lfu", "arc"]:
        return create_optimized_cache(cache_type, capacity=capacity)
    elif cache_type == "thread_safe":
        return ThreadSafeCache(cache_dir=cache_dir, config_path=config_path)
    elif cache_type == "sharded":
        return ShardedCache(shards=kwargs.get('shards', 4), cache_dir=cache_dir, config_path=config_path)
    elif cache_type == "async":
        return AsyncCache(cache_dir=cache_dir, config_path=config_path, max_workers=kwargs.get('max_workers', 4))
    elif cache_type == "batch":
        return BatchCache(cache_dir=cache_dir, config_path=config_path, max_workers=kwargs.get('max_workers', 4))
    else:
        # Utiliser le cache local par défaut
        return LocalCache(cache_dir=cache_dir, config_path=config_path)


def run_single_benchmark(test_spec) -> str:
    """
    Exécute un benchmark unique et génère un rapport.

    Args:
        test_spec: Spécification du test (Dict[str, Any] ou CacheTestSpec).

    Returns:
        str: Chemin du fichier de rapport généré.
    """
    # Convertir CacheTestSpec en dictionnaire si nécessaire
    if hasattr(test_spec, 'to_dict'):
        test_dict = test_spec.to_dict()
    else:
        test_dict = test_spec

    print(f"Exécution du benchmark: {test_dict['test_id']}")
    print(f"Type de cache: {test_dict['cache_type']}")
    print(f"Type de benchmark: {test_dict['benchmark_type']}")

    # Créer le cache
    cache = create_cache(
        test_dict["cache_type"],
        capacity=test_dict.get("dataset_size", 1000),
        **test_dict.get("cache_params", {})
    )

    # Exécuter le benchmark
    start_time = time.time()
    results = run_benchmark(cache, test_dict)
    end_time = time.time()

    print(f"Benchmark terminé en {end_time - start_time:.2f} secondes")
    print(f"Opérations totales: {results['operations']['total']}")
    print(f"Débit: {results['throughput']['operations_per_second']:.2f} op/s")

    # Générer le rapport
    report_file = generate_report(results, test_dict)
    print(f"Rapport généré: {report_file}")

    # Nettoyer
    if hasattr(cache, "clear"):
        cache.clear()

    if hasattr(cache, "__exit__"):
        cache.__exit__(None, None, None)

    return report_file


def run_benchmark_suite(test_suite: List[Dict[str, Any]]) -> List[str]:
    """
    Exécute une suite de benchmarks et génère des rapports.

    Args:
        test_suite (List[Dict[str, Any]]): Liste des spécifications de test.

    Returns:
        List[str]: Liste des chemins des fichiers de rapport générés.
    """
    report_files = []

    for test_spec in test_suite:
        report_file = run_single_benchmark(test_spec)
        report_files.append(report_file)

    return report_files


def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Exécute des benchmarks sur le système de cache.")
    parser.add_argument(
        "--test-id", type=str, help="Identifiant du test à exécuter."
    )
    parser.add_argument(
        "--cache-type", type=str, choices=["lru", "lfu", "arc", "thread_safe", "sharded", "async", "batch"],
        help="Type de cache à tester."
    )
    parser.add_argument(
        "--benchmark-type", type=str,
        choices=["throughput", "latency", "memory", "hit_ratio", "concurrency", "durability", "resilience", "mixed"],
        help="Type de benchmark à exécuter."
    )
    parser.add_argument(
        "--dataset-size", type=int, default=10000,
        help="Taille du jeu de données (nombre d'éléments)."
    )
    parser.add_argument(
        "--value-size", type=int, default=1024,
        help="Taille moyenne des valeurs en octets."
    )
    parser.add_argument(
        "--data-distribution", type=str, choices=["uniform", "zipf", "sequential", "normal"],
        default="uniform", help="Distribution des données."
    )
    parser.add_argument(
        "--concurrency-level", type=int, default=1,
        help="Niveau de concurrence (nombre de threads/processus)."
    )
    parser.add_argument(
        "--duration", type=int, default=30,
        help="Durée du test en secondes."
    )
    parser.add_argument(
        "--suite", action="store_true",
        help="Exécuter la suite de tests standard."
    )
    parser.add_argument(
        "--output-dir", type=str,
        help="Répertoire de sortie pour les rapports."
    )

    args = parser.parse_args()

    if args.suite:
        # Exécuter la suite de tests standard
        print("Exécution de la suite de tests standard...")
        test_suite = create_standard_test_suite()

        if args.output_dir:
            # Mettre à jour le répertoire de sortie
            for test_spec in test_suite:
                test_spec["output_dir"] = args.output_dir

        report_files = run_benchmark_suite(test_suite)

        # Comparer les rapports
        comparison = compare_reports(report_files)
        print("Comparaison des rapports terminée.")
    else:
        # Exécuter un test unique
        if not args.test_id:
            args.test_id = f"benchmark_{int(time.time())}"

        if not args.cache_type:
            args.cache_type = "lru"

        if not args.benchmark_type:
            args.benchmark_type = "throughput"

        # Créer la spécification du test
        test_spec = {
            "test_id": args.test_id,
            "cache_type": args.cache_type,
            "benchmark_type": args.benchmark_type,
            "dataset_size": args.dataset_size,
            "value_size": args.value_size,
            "data_distribution": args.data_distribution,
            "concurrency_level": args.concurrency_level,
            "duration_seconds": args.duration,
            "operation_mix": {
                "get": 0.8,
                "set": 0.15,
                "delete": 0.05
            }
        }

        if args.output_dir:
            test_spec["output_dir"] = args.output_dir

        # Exécuter le benchmark
        report_file = run_single_benchmark(test_spec)
        print(f"Benchmark terminé. Rapport généré: {report_file}")


if __name__ == "__main__":
    main()
