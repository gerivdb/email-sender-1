#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module d'exécution de benchmarks pour le système de cache.

Ce module fournit les fonctions nécessaires pour exécuter des benchmarks
sur le système de cache et collecter des métriques de performance.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import random
import statistics
import threading
import multiprocessing
import numpy as np
import psutil
from typing import Dict, List, Any, Optional, Union, Callable
from concurrent.futures import ThreadPoolExecutor

# Constantes
BYTES_TO_MB = 1024 * 1024


def generate_key(dataset_size: int, distribution: str = "uniform") -> str:
    """
    Génère une clé selon la distribution spécifiée.

    Args:
        dataset_size (int): Taille du jeu de données.
        distribution (str): Type de distribution ('uniform', 'zipf', 'sequential', 'normal').

    Returns:
        str: Clé générée.
    """
    if distribution == "uniform":
        # Distribution uniforme
        key_id = random.randint(0, dataset_size - 1)
    elif distribution == "zipf":
        # Distribution Zipf (loi de puissance)
        # Les clés avec des IDs plus petits sont plus fréquemment accédées
        alpha = 1.2  # Paramètre de la distribution Zipf
        x = np.random.zipf(alpha, 1)[0] % dataset_size
        key_id = int(x)
    elif distribution == "sequential":
        # Accès séquentiel
        key_id = int(time.time() * 1000) % dataset_size
    elif distribution == "normal":
        # Distribution normale
        mu = dataset_size / 2
        sigma = dataset_size / 6
        key_id = int(np.random.normal(mu, sigma)) % dataset_size
    else:
        raise ValueError(f"Distribution non supportée: {distribution}")

    return f"key_{key_id}"


def generate_value(size: int) -> str:
    """
    Génère une valeur de la taille spécifiée.

    Args:
        size (int): Taille de la valeur en octets.

    Returns:
        str: Valeur générée.
    """
    # Générer une chaîne aléatoire de la taille spécifiée
    return "x" * size


def select_operation(operation_mix: Dict[str, float]) -> str:
    """
    Sélectionne une opération selon le mélange spécifié.

    Args:
        operation_mix (Dict[str, float]): Mélange d'opérations (pourcentage de chaque type).

    Returns:
        str: Opération sélectionnée.
    """
    # Convertir le mélange en liste d'opérations et de probabilités
    operations = list(operation_mix.keys())
    probabilities = list(operation_mix.values())

    # Sélectionner une opération selon les probabilités
    return np.random.choice(operations, p=probabilities)


def measure_memory_usage() -> float:
    """
    Mesure l'utilisation de la mémoire du processus actuel.

    Returns:
        float: Utilisation de la mémoire en Mo.
    """
    process = psutil.Process(os.getpid())
    memory_info = process.memory_info()
    return memory_info.rss / BYTES_TO_MB


def run_benchmark(cache, config: Dict[str, Any]) -> Dict[str, Any]:
    """
    Exécute un benchmark sur le cache selon la configuration spécifiée.

    Args:
        cache: Instance du cache à tester.
        config (Dict[str, Any]): Configuration du benchmark.

    Returns:
        Dict[str, Any]: Résultats du benchmark.
    """
    # Extraire les paramètres de configuration
    benchmark_type = config["benchmark_type"]
    dataset_size = config["dataset_size"]
    value_size = config["value_size"]
    data_distribution = config["data_distribution"]
    operation_mix = config["operation_mix"]
    concurrency_level = config["concurrency_level"]
    duration_seconds = config["duration_seconds"]

    # Initialiser les résultats
    results = {
        "config": config,
        "start_time": time.time(),
        "end_time": None,
        "duration_seconds": None,
        "operations": {
            "total": 0,
            "get": 0,
            "set": 0,
            "delete": 0,
            "get_many": 0,
            "set_many": 0,
            "delete_many": 0
        },
        "latencies": {
            "get": [],
            "set": [],
            "delete": [],
            "get_many": [],
            "set_many": [],
            "delete_many": []
        },
        "hit_ratio": {
            "values": [],
            "avg": None,
            "min": None,
            "max": None
        },
        "memory_usage": {
            "values": [],
            "avg": None,
            "min": None,
            "max": None
        },
        "throughput": {
            "operations_per_second": None
        }
    }

    # Fonction pour exécuter le benchmark dans un thread
    def run_benchmark_thread(thread_id: int):
        local_results = {
            "operations": 0,
            "latencies": [],
            "hit_ratio": [],
            "memory_usage": []
        }

        start_time = time.time()
        end_time = start_time + duration_seconds

        # Exécuter le benchmark
        while time.time() < end_time:
            # Sélectionner une opération
            operation = select_operation(operation_mix)

            # Générer une clé
            key = generate_key(dataset_size, data_distribution)

            # Mesurer le temps d'exécution
            start_op = time.time()

            # Exécuter l'opération
            if operation == "get":
                value = cache.get(key)
                results["operations"]["get"] += 1
            elif operation == "set":
                value = generate_value(value_size)
                # Vérifier quelle méthode est disponible (set ou put)
                if hasattr(cache, "set"):
                    cache.set(key, value)
                elif hasattr(cache, "put"):
                    cache.put(key, value)
                else:
                    raise AttributeError(f"Le cache ne supporte ni 'set' ni 'put'")
                results["operations"]["set"] += 1
            elif operation == "delete":
                # Vérifier quelle méthode est disponible (delete ou remove)
                if hasattr(cache, "delete"):
                    cache.delete(key)
                elif hasattr(cache, "remove"):
                    cache.remove(key)
                else:
                    raise AttributeError(f"Le cache ne supporte ni 'delete' ni 'remove'")
                results["operations"]["delete"] += 1
            elif operation == "get_many":
                keys = [generate_key(dataset_size, data_distribution) for _ in range(10)]
                if hasattr(cache, "get_many"):
                    values = cache.get_many(keys)
                else:
                    values = {k: cache.get(k) for k in keys}
                results["operations"]["get_many"] += 1
            elif operation == "set_many":
                items = {generate_key(dataset_size, data_distribution): generate_value(value_size) for _ in range(10)}
                if hasattr(cache, "set_many"):
                    cache.set_many(items)
                else:
                    for k, v in items.items():
                        if hasattr(cache, "set"):
                            cache.set(k, v)
                        elif hasattr(cache, "put"):
                            cache.put(k, v)
                        else:
                            raise AttributeError(f"Le cache ne supporte ni 'set' ni 'put'")
                results["operations"]["set_many"] += 1
            elif operation == "delete_many":
                keys = [generate_key(dataset_size, data_distribution) for _ in range(10)]
                if hasattr(cache, "delete_many"):
                    cache.delete_many(keys)
                else:
                    for k in keys:
                        if hasattr(cache, "delete"):
                            cache.delete(k)
                        elif hasattr(cache, "remove"):
                            cache.remove(k)
                        else:
                            raise AttributeError(f"Le cache ne supporte ni 'delete' ni 'remove'")
                results["operations"]["delete_many"] += 1

            # Calculer la latence
            latency = (time.time() - start_op) * 1000  # en ms
            results["latencies"][operation].append(latency)

            # Incrémenter le compteur d'opérations
            local_results["operations"] += 1
            results["operations"]["total"] += 1

            # Mesurer l'utilisation de la mémoire
            if local_results["operations"] % 100 == 0:
                memory_usage = measure_memory_usage()
                local_results["memory_usage"].append(memory_usage)
                results["memory_usage"]["values"].append(memory_usage)

            # Mesurer le taux de succès du cache
            if local_results["operations"] % 100 == 0 and hasattr(cache, "get_statistics"):
                stats = cache.get_statistics()
                hit_ratio = stats.get("hit_ratio", 0)
                local_results["hit_ratio"].append(hit_ratio)
                results["hit_ratio"]["values"].append(hit_ratio)

        return local_results

    # Exécuter le benchmark en parallèle si nécessaire
    if concurrency_level > 1:
        with ThreadPoolExecutor(max_workers=concurrency_level) as executor:
            futures = [executor.submit(run_benchmark_thread, i) for i in range(concurrency_level)]
            thread_results = [future.result() for future in futures]
    else:
        thread_results = [run_benchmark_thread(0)]

    # Calculer les statistiques finales
    end_time = time.time()
    results["end_time"] = end_time
    results["duration_seconds"] = end_time - results["start_time"]

    # Calculer le débit
    results["throughput"]["operations_per_second"] = results["operations"]["total"] / results["duration_seconds"]

    # Calculer les statistiques de latence pour chaque opération
    for operation in results["latencies"]:
        if results["latencies"][operation]:
            results["latencies"][operation] = {
                "avg": statistics.mean(results["latencies"][operation]),
                "min": min(results["latencies"][operation]),
                "max": max(results["latencies"][operation]),
                "p50": np.percentile(results["latencies"][operation], 50),
                "p95": np.percentile(results["latencies"][operation], 95),
                "p99": np.percentile(results["latencies"][operation], 99)
            }
        else:
            results["latencies"][operation] = {
                "avg": None,
                "min": None,
                "max": None,
                "p50": None,
                "p95": None,
                "p99": None
            }

    # Calculer les statistiques du taux de succès
    if results["hit_ratio"]["values"]:
        results["hit_ratio"]["avg"] = statistics.mean(results["hit_ratio"]["values"])
        results["hit_ratio"]["min"] = min(results["hit_ratio"]["values"])
        results["hit_ratio"]["max"] = max(results["hit_ratio"]["values"])

    # Calculer les statistiques d'utilisation de la mémoire
    if results["memory_usage"]["values"]:
        results["memory_usage"]["avg"] = statistics.mean(results["memory_usage"]["values"])
        results["memory_usage"]["min"] = min(results["memory_usage"]["values"])
        results["memory_usage"]["max"] = max(results["memory_usage"]["values"])

    return results


if __name__ == "__main__":
    # Exemple d'utilisation
    from scripts.utils.cache.local_cache import LocalCache

    # Créer un cache
    cache = LocalCache()

    # Configurer le benchmark
    config = {
        "test_id": "test_lru_throughput",
        "cache_type": "lru",
        "benchmark_type": "throughput",
        "dataset_size": 1000,
        "value_size": 1024,
        "data_distribution": "uniform",
        "operation_mix": {
            "get": 0.8,
            "set": 0.15,
            "delete": 0.05
        },
        "concurrency_level": 1,
        "duration_seconds": 5
    }

    # Exécuter le benchmark
    results = run_benchmark(cache, config)

    # Afficher les résultats
    print(f"Benchmark terminé en {results['duration_seconds']:.2f} secondes")
    print(f"Opérations totales: {results['operations']['total']}")
    print(f"Débit: {results['throughput']['operations_per_second']:.2f} op/s")

    if results["latencies"]["get"]["avg"]:
        print(f"Latence moyenne (GET): {results['latencies']['get']['avg']:.2f} ms")

    if results["hit_ratio"]["avg"]:
        print(f"Taux de succès moyen: {results['hit_ratio']['avg']:.2%}")

    if results["memory_usage"]["avg"]:
        print(f"Utilisation mémoire moyenne: {results['memory_usage']['avg']:.2f} Mo")
