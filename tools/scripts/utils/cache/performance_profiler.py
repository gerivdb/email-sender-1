#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de profilage des performances pour le cache.

Ce module fournit des outils pour mesurer et analyser les performances
du cache, afin d'optimiser son utilisation et d'identifier les goulots d'étranglement.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import json
import logging
import statistics
import threading
import concurrent.futures
from typing import Dict, List, Any, Optional, Tuple, Callable
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

# Importer le module de cache local
from scripts.utils.cache.local_cache import LocalCache

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class PerformanceProfiler:
    """
    Profileur de performances pour le cache.
    
    Cette classe permet de mesurer et d'analyser les performances du cache,
    afin d'optimiser son utilisation et d'identifier les goulots d'étranglement.
    """
    
    def __init__(self, cache: LocalCache, output_dir: Optional[str] = None):
        """
        Initialise le profileur de performances.
        
        Args:
            cache (LocalCache): Instance du cache à profiler.
            output_dir (str, optional): Répertoire de sortie pour les rapports.
                Si None, utilise le répertoire courant.
        """
        self.cache = cache
        self.output_dir = output_dir or os.path.join(os.path.dirname(os.path.abspath(__file__)), 'reports')
        
        # Créer le répertoire de sortie s'il n'existe pas
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Historique des mesures
        self.history = []
        
        # Statistiques
        self.stats = {
            "start_time": time.time(),
            "measurements": 0,
            "total_operations": 0,
            "total_time": 0,
            "avg_time_per_operation": 0,
            "max_time": 0,
            "min_time": float('inf'),
            "operations": {
                "get": {"count": 0, "time": 0, "hits": 0, "misses": 0},
                "set": {"count": 0, "time": 0},
                "delete": {"count": 0, "time": 0}
            }
        }
    
    def measure_operation(self, operation: str, key: str, value: Any = None, ttl: Optional[int] = None) -> Dict[str, Any]:
        """
        Mesure les performances d'une opération sur le cache.
        
        Args:
            operation (str): Opération à mesurer ('get', 'set', 'delete').
            key (str): Clé de l'élément.
            value (Any, optional): Valeur à stocker (pour l'opération 'set').
            ttl (int, optional): Durée de vie de l'élément (pour l'opération 'set').
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les mesures.
        """
        # Récupérer les statistiques initiales
        initial_stats = self.cache.get_statistics()
        
        # Mesurer le temps d'exécution
        start_time = time.time()
        
        # Exécuter l'opération
        result = None
        if operation == 'get':
            result = self.cache.get(key)
        elif operation == 'set':
            self.cache.set(key, value, ttl)
        elif operation == 'delete':
            result = self.cache.delete(key)
        else:
            raise ValueError(f"Opération non supportée: {operation}")
        
        # Calculer le temps d'exécution
        execution_time = time.time() - start_time
        
        # Récupérer les statistiques finales
        final_stats = self.cache.get_statistics()
        
        # Créer la mesure
        measurement = {
            "timestamp": time.time(),
            "operation": operation,
            "key": key,
            "execution_time": execution_time,
            "result": result,
            "cache_size": final_stats.get("size", 0),
            "cache_count": final_stats.get("count", 0),
            "hits_delta": final_stats.get("hits", 0) - initial_stats.get("hits", 0),
            "misses_delta": final_stats.get("misses", 0) - initial_stats.get("misses", 0),
            "sets_delta": final_stats.get("sets", 0) - initial_stats.get("sets", 0),
            "deletes_delta": final_stats.get("deletes", 0) - initial_stats.get("deletes", 0)
        }
        
        # Mettre à jour les statistiques
        self.stats["measurements"] += 1
        self.stats["total_operations"] += 1
        self.stats["total_time"] += execution_time
        self.stats["avg_time_per_operation"] = self.stats["total_time"] / self.stats["total_operations"]
        self.stats["max_time"] = max(self.stats["max_time"], execution_time)
        self.stats["min_time"] = min(self.stats["min_time"], execution_time)
        
        # Mettre à jour les statistiques par opération
        if operation in self.stats["operations"]:
            self.stats["operations"][operation]["count"] += 1
            self.stats["operations"][operation]["time"] += execution_time
            
            if operation == 'get':
                self.stats["operations"][operation]["hits"] += measurement["hits_delta"]
                self.stats["operations"][operation]["misses"] += measurement["misses_delta"]
        
        # Ajouter la mesure à l'historique
        self.history.append(measurement)
        
        return measurement
    
    def benchmark_get(self, key: str, iterations: int = 100) -> Dict[str, Any]:
        """
        Effectue un benchmark de l'opération 'get'.
        
        Args:
            key (str): Clé de l'élément à récupérer.
            iterations (int, optional): Nombre d'itérations. Par défaut: 100.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats du benchmark.
        """
        times = []
        hits = 0
        misses = 0
        
        for _ in range(iterations):
            measurement = self.measure_operation('get', key)
            times.append(measurement["execution_time"])
            hits += measurement["hits_delta"]
            misses += measurement["misses_delta"]
        
        # Calculer les statistiques
        avg_time = statistics.mean(times)
        min_time = min(times)
        max_time = max(times)
        median_time = statistics.median(times)
        stdev_time = statistics.stdev(times) if len(times) > 1 else 0
        
        # Créer le résultat
        result = {
            "operation": "get",
            "key": key,
            "iterations": iterations,
            "avg_time": avg_time,
            "min_time": min_time,
            "max_time": max_time,
            "median_time": median_time,
            "stdev_time": stdev_time,
            "hits": hits,
            "misses": misses,
            "hit_ratio": hits / (hits + misses) if (hits + misses) > 0 else 0
        }
        
        return result
    
    def benchmark_set(self, key_prefix: str, value_generator: Callable[[], Any], ttl: Optional[int] = None, iterations: int = 100) -> Dict[str, Any]:
        """
        Effectue un benchmark de l'opération 'set'.
        
        Args:
            key_prefix (str): Préfixe pour les clés.
            value_generator (Callable[[], Any]): Fonction pour générer les valeurs.
            ttl (int, optional): Durée de vie des éléments.
            iterations (int, optional): Nombre d'itérations. Par défaut: 100.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats du benchmark.
        """
        times = []
        
        for i in range(iterations):
            key = f"{key_prefix}_{i}"
            value = value_generator()
            measurement = self.measure_operation('set', key, value, ttl)
            times.append(measurement["execution_time"])
        
        # Calculer les statistiques
        avg_time = statistics.mean(times)
        min_time = min(times)
        max_time = max(times)
        median_time = statistics.median(times)
        stdev_time = statistics.stdev(times) if len(times) > 1 else 0
        
        # Créer le résultat
        result = {
            "operation": "set",
            "key_prefix": key_prefix,
            "iterations": iterations,
            "avg_time": avg_time,
            "min_time": min_time,
            "max_time": max_time,
            "median_time": median_time,
            "stdev_time": stdev_time
        }
        
        return result
    
    def benchmark_delete(self, keys: List[str]) -> Dict[str, Any]:
        """
        Effectue un benchmark de l'opération 'delete'.
        
        Args:
            keys (List[str]): Liste des clés à supprimer.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats du benchmark.
        """
        times = []
        success_count = 0
        
        for key in keys:
            measurement = self.measure_operation('delete', key)
            times.append(measurement["execution_time"])
            if measurement["result"]:
                success_count += 1
        
        # Calculer les statistiques
        avg_time = statistics.mean(times) if times else 0
        min_time = min(times) if times else 0
        max_time = max(times) if times else 0
        median_time = statistics.median(times) if times else 0
        stdev_time = statistics.stdev(times) if len(times) > 1 else 0
        
        # Créer le résultat
        result = {
            "operation": "delete",
            "keys_count": len(keys),
            "success_count": success_count,
            "success_ratio": success_count / len(keys) if len(keys) > 0 else 0,
            "avg_time": avg_time,
            "min_time": min_time,
            "max_time": max_time,
            "median_time": median_time,
            "stdev_time": stdev_time
        }
        
        return result
    
    def benchmark_mixed_workload(self, operations: List[Dict[str, Any]], parallel: bool = False, threads: int = 4) -> Dict[str, Any]:
        """
        Effectue un benchmark avec une charge de travail mixte.
        
        Args:
            operations (List[Dict[str, Any]]): Liste des opérations à effectuer.
                Chaque opération est un dictionnaire avec les clés:
                - 'operation': 'get', 'set' ou 'delete'
                - 'key': Clé de l'élément (pour 'get' et 'delete')
                - 'value': Valeur à stocker (pour 'set')
                - 'ttl': Durée de vie de l'élément (pour 'set')
            parallel (bool, optional): Si True, exécute les opérations en parallèle.
                Par défaut: False.
            threads (int, optional): Nombre de threads à utiliser si parallel=True.
                Par défaut: 4.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats du benchmark.
        """
        start_time = time.time()
        
        if parallel:
            # Exécuter les opérations en parallèle
            with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
                futures = []
                
                for op in operations:
                    operation = op.get('operation')
                    key = op.get('key')
                    value = op.get('value')
                    ttl = op.get('ttl')
                    
                    if operation == 'get':
                        futures.append(executor.submit(self.measure_operation, operation, key))
                    elif operation == 'set':
                        futures.append(executor.submit(self.measure_operation, operation, key, value, ttl))
                    elif operation == 'delete':
                        futures.append(executor.submit(self.measure_operation, operation, key))
                
                # Récupérer les résultats
                measurements = [future.result() for future in futures]
        else:
            # Exécuter les opérations séquentiellement
            measurements = []
            
            for op in operations:
                operation = op.get('operation')
                key = op.get('key')
                value = op.get('value')
                ttl = op.get('ttl')
                
                if operation == 'get':
                    measurements.append(self.measure_operation(operation, key))
                elif operation == 'set':
                    measurements.append(self.measure_operation(operation, key, value, ttl))
                elif operation == 'delete':
                    measurements.append(self.measure_operation(operation, key))
        
        # Calculer le temps total
        total_time = time.time() - start_time
        
        # Calculer les statistiques
        times = [m["execution_time"] for m in measurements]
        avg_time = statistics.mean(times) if times else 0
        min_time = min(times) if times else 0
        max_time = max(times) if times else 0
        median_time = statistics.median(times) if times else 0
        stdev_time = statistics.stdev(times) if len(times) > 1 else 0
        
        # Compter les opérations par type
        op_counts = {
            "get": len([m for m in measurements if m["operation"] == "get"]),
            "set": len([m for m in measurements if m["operation"] == "set"]),
            "delete": len([m for m in measurements if m["operation"] == "delete"])
        }
        
        # Créer le résultat
        result = {
            "total_operations": len(measurements),
            "total_time": total_time,
            "operations_per_second": len(measurements) / total_time if total_time > 0 else 0,
            "avg_time_per_operation": avg_time,
            "min_time": min_time,
            "max_time": max_time,
            "median_time": median_time,
            "stdev_time": stdev_time,
            "operation_counts": op_counts,
            "parallel": parallel,
            "threads": threads if parallel else 1
        }
        
        return result
    
    def benchmark_concurrent_access(self, threads: int = 4, operations_per_thread: int = 100, read_ratio: float = 0.8) -> Dict[str, Any]:
        """
        Effectue un benchmark d'accès concurrent au cache.
        
        Args:
            threads (int, optional): Nombre de threads à utiliser. Par défaut: 4.
            operations_per_thread (int, optional): Nombre d'opérations par thread.
                Par défaut: 100.
            read_ratio (float, optional): Ratio de lectures (vs écritures).
                Par défaut: 0.8 (80% de lectures).
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats du benchmark.
        """
        # Préparer les opérations
        operations = []
        
        for i in range(threads):
            for j in range(operations_per_thread):
                # Déterminer l'opération (get ou set)
                if random.random() < read_ratio:
                    # Opération de lecture
                    operations.append({
                        'operation': 'get',
                        'key': f"concurrent_key_{random.randint(1, 100)}"
                    })
                else:
                    # Opération d'écriture
                    operations.append({
                        'operation': 'set',
                        'key': f"concurrent_key_{random.randint(1, 100)}",
                        'value': f"value_{i}_{j}",
                        'ttl': 3600
                    })
        
        # Exécuter le benchmark
        result = self.benchmark_mixed_workload(operations, parallel=True, threads=threads)
        
        # Ajouter des informations supplémentaires
        result["threads"] = threads
        result["operations_per_thread"] = operations_per_thread
        result["read_ratio"] = read_ratio
        
        return result
    
    def generate_report(self) -> str:
        """
        Génère un rapport de profilage des performances.
        
        Returns:
            str: Chemin vers le rapport généré.
        """
        # Créer le nom du fichier de rapport
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        report_file = os.path.join(self.output_dir, f"cache_performance_{timestamp}.json")
        
        # Créer le rapport
        report = {
            "timestamp": timestamp,
            "duration": time.time() - self.stats["start_time"],
            "measurements": self.stats["measurements"],
            "total_operations": self.stats["total_operations"],
            "total_time": self.stats["total_time"],
            "avg_time_per_operation": self.stats["avg_time_per_operation"],
            "max_time": self.stats["max_time"],
            "min_time": self.stats["min_time"],
            "operations": self.stats["operations"],
            "history": self.history
        }
        
        # Enregistrer le rapport
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2)
        
        # Générer des graphiques
        self._generate_charts(report, timestamp)
        
        logger.info(f"Rapport de performance généré: {report_file}")
        return report_file
    
    def _generate_charts(self, report: Dict[str, Any], timestamp: str) -> None:
        """
        Génère des graphiques à partir des données de profilage.
        
        Args:
            report (Dict[str, Any]): Données du rapport.
            timestamp (str): Horodatage pour les noms de fichiers.
        """
        try:
            # Créer le répertoire pour les graphiques
            charts_dir = os.path.join(self.output_dir, "charts")
            os.makedirs(charts_dir, exist_ok=True)
            
            # Extraire les données pour les graphiques
            history = report["history"]
            
            if not history:
                logger.warning("Pas de données d'historique pour générer des graphiques")
                return
            
            # Graphique 1: Temps d'exécution par opération
            plt.figure(figsize=(10, 6))
            
            # Extraire les données par opération
            get_times = [m["execution_time"] for m in history if m["operation"] == "get"]
            set_times = [m["execution_time"] for m in history if m["operation"] == "set"]
            delete_times = [m["execution_time"] for m in history if m["operation"] == "delete"]
            
            # Créer le boxplot
            plt.boxplot([get_times, set_times, delete_times], labels=["GET", "SET", "DELETE"])
            plt.ylabel("Temps d'exécution (s)")
            plt.title("Distribution des temps d'exécution par opération")
            plt.grid(True)
            
            plt.tight_layout()
            plt.savefig(os.path.join(charts_dir, f"execution_times_{timestamp}.png"))
            plt.close()
            
            # Graphique 2: Évolution des temps d'exécution
            plt.figure(figsize=(10, 6))
            
            # Extraire les données chronologiques
            timestamps = [m["timestamp"] - history[0]["timestamp"] for m in history]
            execution_times = [m["execution_time"] for m in history]
            operations = [m["operation"] for m in history]
            
            # Créer un scatter plot avec des couleurs différentes par opération
            colors = {"get": "blue", "set": "green", "delete": "red"}
            for op in ["get", "set", "delete"]:
                op_indices = [i for i, o in enumerate(operations) if o == op]
                if op_indices:
                    plt.scatter(
                        [timestamps[i] for i in op_indices],
                        [execution_times[i] for i in op_indices],
                        color=colors[op],
                        label=op.upper(),
                        alpha=0.7
                    )
            
            plt.xlabel("Temps (s)")
            plt.ylabel("Temps d'exécution (s)")
            plt.title("Évolution des temps d'exécution")
            plt.grid(True)
            plt.legend()
            
            plt.tight_layout()
            plt.savefig(os.path.join(charts_dir, f"execution_times_evolution_{timestamp}.png"))
            plt.close()
            
            # Graphique 3: Taux de succès du cache
            plt.figure(figsize=(10, 6))
            
            # Calculer le taux de succès cumulatif
            hits = 0
            misses = 0
            hit_ratios = []
            
            for m in history:
                if m["operation"] == "get":
                    hits += m["hits_delta"]
                    misses += m["misses_delta"]
                    total = hits + misses
                    hit_ratios.append(hits / total if total > 0 else 0)
                else:
                    # Maintenir la dernière valeur pour les opérations non-get
                    hit_ratios.append(hit_ratios[-1] if hit_ratios else 0)
            
            # Tracer le graphique
            plt.plot(timestamps, hit_ratios, 'g-')
            plt.xlabel("Temps (s)")
            plt.ylabel("Taux de succès")
            plt.title("Évolution du taux de succès du cache")
            plt.grid(True)
            
            plt.tight_layout()
            plt.savefig(os.path.join(charts_dir, f"hit_ratio_{timestamp}.png"))
            plt.close()
            
            logger.info(f"Graphiques générés dans: {charts_dir}")
        except Exception as e:
            logger.error(f"Erreur lors de la génération des graphiques: {e}")
    
    def recommend_optimizations(self) -> List[str]:
        """
        Recommande des optimisations basées sur les données de profilage.
        
        Returns:
            List[str]: Liste de recommandations.
        """
        recommendations = []
        
        # Vérifier le taux de succès du cache
        get_stats = self.stats["operations"]["get"]
        total_gets = get_stats["hits"] + get_stats["misses"]
        
        if total_gets > 0:
            hit_ratio = get_stats["hits"] / total_gets
            
            if hit_ratio < 0.5:
                recommendations.append(f"Le taux de succès du cache est faible ({hit_ratio:.2%}). "
                                      "Envisagez d'augmenter la durée de vie (TTL) des éléments "
                                      "ou de précharger les données fréquemment utilisées.")
        
        # Vérifier les temps d'exécution
        if self.stats["total_operations"] > 0:
            if self.stats["max_time"] > 0.1:  # Plus de 100 ms
                recommendations.append(f"Certaines opérations sont lentes (max: {self.stats['max_time']:.3f}s). "
                                      "Envisagez d'optimiser les stratégies d'éviction ou "
                                      "de réduire la taille des données stockées.")
            
            # Comparer les temps d'exécution par opération
            if get_stats["count"] > 0 and self.stats["operations"]["set"]["count"] > 0:
                avg_get_time = get_stats["time"] / get_stats["count"]
                avg_set_time = self.stats["operations"]["set"]["time"] / self.stats["operations"]["set"]["count"]
                
                if avg_get_time > 0.01:  # Plus de 10 ms
                    recommendations.append(f"Les opérations de lecture sont lentes (moyenne: {avg_get_time:.3f}s). "
                                          "Envisagez d'optimiser la stratégie d'éviction ou "
                                          "d'utiliser un cache en mémoire pour les données fréquemment utilisées.")
                
                if avg_set_time > 0.05:  # Plus de 50 ms
                    recommendations.append(f"Les opérations d'écriture sont lentes (moyenne: {avg_set_time:.3f}s). "
                                          "Envisagez de compresser les données ou "
                                          "d'utiliser un stockage plus rapide.")
        
        # Recommandations générales
        if not recommendations:
            recommendations.append("Les performances du cache semblent bonnes. "
                                  "Continuez à surveiller les performances pour détecter d'éventuels problèmes.")
        
        return recommendations


# Fonction pour créer une instance du profileur de performances
def create_performance_profiler(cache: LocalCache, output_dir: Optional[str] = None) -> PerformanceProfiler:
    """
    Crée une instance du profileur de performances.
    
    Args:
        cache (LocalCache): Instance du cache à profiler.
        output_dir (str, optional): Répertoire de sortie pour les rapports.
            Si None, utilise le répertoire courant.
            
    Returns:
        PerformanceProfiler: Instance du profileur de performances.
    """
    return PerformanceProfiler(cache, output_dir)


if __name__ == "__main__":
    # Exemple d'utilisation
    import random
    from scripts.utils.cache.local_cache import LocalCache
    
    # Créer une instance du cache
    cache = LocalCache()
    
    # Créer une instance du profileur de performances
    profiler = PerformanceProfiler(cache)
    
    # Ajouter des données au cache
    for i in range(100):
        profiler.measure_operation('set', f"key{i}", f"value{i}")
    
    # Récupérer des données du cache
    for i in range(100):
        profiler.measure_operation('get', f"key{i}")
    
    # Effectuer un benchmark de l'opération 'get'
    get_benchmark = profiler.benchmark_get("key0", iterations=100)
    print(f"Benchmark GET: {get_benchmark}")
    
    # Effectuer un benchmark de l'opération 'set'
    set_benchmark = profiler.benchmark_set(
        "benchmark_key",
        lambda: f"value_{random.randint(1, 1000)}",
        iterations=100
    )
    print(f"Benchmark SET: {set_benchmark}")
    
    # Effectuer un benchmark d'accès concurrent
    concurrent_benchmark = profiler.benchmark_concurrent_access(
        threads=4,
        operations_per_thread=100,
        read_ratio=0.8
    )
    print(f"Benchmark concurrent: {concurrent_benchmark}")
    
    # Générer un rapport
    report_file = profiler.generate_report()
    print(f"Rapport généré: {report_file}")
    
    # Recommander des optimisations
    recommendations = profiler.recommend_optimizations()
    print("Recommandations:")
    for recommendation in recommendations:
        print(f"- {recommendation}")
    
    # Nettoyer
    cache.clear()
    cache.cache.close()
