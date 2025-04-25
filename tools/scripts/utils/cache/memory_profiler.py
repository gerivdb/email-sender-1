#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de profilage de la mémoire pour le cache.

Ce module fournit des outils pour mesurer et analyser la consommation mémoire
du cache, afin d'optimiser son utilisation et d'identifier les goulots d'étranglement.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import time
import json
import logging
import psutil
from typing import Dict, List, Any, Optional, Tuple
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

# Importer le module de cache local
from scripts.utils.cache.local_cache import LocalCache

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class MemoryProfiler:
    """
    Profileur de mémoire pour le cache.
    
    Cette classe permet de mesurer et d'analyser la consommation mémoire du cache,
    afin d'optimiser son utilisation et d'identifier les goulots d'étranglement.
    """
    
    def __init__(self, cache: LocalCache, output_dir: Optional[str] = None):
        """
        Initialise le profileur de mémoire.
        
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
            "peak_memory": 0,
            "peak_items": 0,
            "avg_memory_per_item": 0
        }
    
    def measure(self) -> Dict[str, Any]:
        """
        Mesure la consommation mémoire actuelle du cache.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les mesures.
        """
        # Récupérer les statistiques du cache
        cache_stats = self.cache.get_statistics()
        
        # Récupérer la consommation mémoire du processus
        process = psutil.Process(os.getpid())
        memory_info = process.memory_info()
        
        # Créer la mesure
        measurement = {
            "timestamp": time.time(),
            "cache_size": cache_stats.get("size", 0),  # Taille en octets
            "cache_count": cache_stats.get("count", 0),  # Nombre d'éléments
            "process_rss": memory_info.rss,  # Resident Set Size en octets
            "process_vms": memory_info.vms,  # Virtual Memory Size en octets
            "cache_hits": cache_stats.get("hits", 0),
            "cache_misses": cache_stats.get("misses", 0),
            "cache_sets": cache_stats.get("sets", 0),
            "cache_deletes": cache_stats.get("deletes", 0)
        }
        
        # Calculer la mémoire moyenne par élément
        if measurement["cache_count"] > 0:
            measurement["memory_per_item"] = measurement["cache_size"] / measurement["cache_count"]
        else:
            measurement["memory_per_item"] = 0
        
        # Mettre à jour les statistiques
        self.stats["measurements"] += 1
        self.stats["peak_memory"] = max(self.stats["peak_memory"], measurement["cache_size"])
        self.stats["peak_items"] = max(self.stats["peak_items"], measurement["cache_count"])
        
        # Calculer la mémoire moyenne par élément
        if self.stats["peak_items"] > 0:
            self.stats["avg_memory_per_item"] = self.stats["peak_memory"] / self.stats["peak_items"]
        
        # Ajouter la mesure à l'historique
        self.history.append(measurement)
        
        return measurement
    
    def start_monitoring(self, interval: int = 60, duration: Optional[int] = None) -> None:
        """
        Démarre la surveillance périodique de la consommation mémoire.
        
        Args:
            interval (int, optional): Intervalle entre les mesures en secondes. Par défaut: 60.
            duration (int, optional): Durée totale de la surveillance en secondes.
                Si None, la surveillance continue indéfiniment.
        """
        start_time = time.time()
        end_time = start_time + duration if duration else None
        
        try:
            while True:
                # Mesurer la consommation mémoire
                measurement = self.measure()
                
                # Afficher les informations
                logger.info(f"Cache: {measurement['cache_count']} éléments, "
                           f"{measurement['cache_size'] / 1024 / 1024:.2f} Mo, "
                           f"Hits: {measurement['cache_hits']}, "
                           f"Misses: {measurement['cache_misses']}")
                
                # Vérifier si la durée est écoulée
                if end_time and time.time() >= end_time:
                    break
                
                # Attendre l'intervalle
                time.sleep(interval)
        except KeyboardInterrupt:
            logger.info("Surveillance interrompue par l'utilisateur")
        finally:
            # Générer le rapport
            self.generate_report()
    
    def analyze_key_distribution(self) -> Dict[str, Any]:
        """
        Analyse la distribution des clés dans le cache.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats de l'analyse.
        """
        # Récupérer toutes les clés du cache
        keys = list(self.cache.cache)
        
        # Analyser les préfixes des clés
        prefixes = {}
        for key in keys:
            # Extraire le préfixe (avant le premier ':')
            prefix = key.split(':', 1)[0] if ':' in key else key
            prefixes[prefix] = prefixes.get(prefix, 0) + 1
        
        # Analyser la longueur des clés
        key_lengths = [len(key) for key in keys]
        
        # Calculer les statistiques
        result = {
            "total_keys": len(keys),
            "prefixes": prefixes,
            "key_length_min": min(key_lengths) if key_lengths else 0,
            "key_length_max": max(key_lengths) if key_lengths else 0,
            "key_length_avg": sum(key_lengths) / len(key_lengths) if key_lengths else 0
        }
        
        return result
    
    def analyze_value_sizes(self, sample_size: int = 100) -> Dict[str, Any]:
        """
        Analyse la taille des valeurs dans le cache.
        
        Args:
            sample_size (int, optional): Nombre d'éléments à échantillonner. Par défaut: 100.
        
        Returns:
            Dict[str, Any]: Dictionnaire contenant les résultats de l'analyse.
        """
        # Récupérer toutes les clés du cache
        keys = list(self.cache.cache)
        
        # Limiter l'échantillon
        if len(keys) > sample_size:
            import random
            keys = random.sample(keys, sample_size)
        
        # Mesurer la taille des valeurs
        value_sizes = []
        for key in keys:
            value = self.cache.get(key)
            if value is not None:
                # Estimer la taille en mémoire
                try:
                    import sys
                    size = sys.getsizeof(value)
                    value_sizes.append(size)
                except (TypeError, AttributeError):
                    # Ignorer les objets qui ne supportent pas getsizeof
                    pass
        
        # Calculer les statistiques
        result = {
            "sample_size": len(value_sizes),
            "value_size_min": min(value_sizes) if value_sizes else 0,
            "value_size_max": max(value_sizes) if value_sizes else 0,
            "value_size_avg": sum(value_sizes) / len(value_sizes) if value_sizes else 0,
            "value_size_total": sum(value_sizes) if value_sizes else 0
        }
        
        return result
    
    def generate_report(self) -> str:
        """
        Génère un rapport de profilage.
        
        Returns:
            str: Chemin vers le rapport généré.
        """
        # Créer le nom du fichier de rapport
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        report_file = os.path.join(self.output_dir, f"cache_profile_{timestamp}.json")
        
        # Analyser les données
        key_distribution = self.analyze_key_distribution()
        value_sizes = self.analyze_value_sizes()
        
        # Créer le rapport
        report = {
            "timestamp": timestamp,
            "duration": time.time() - self.stats["start_time"],
            "measurements": self.stats["measurements"],
            "peak_memory": self.stats["peak_memory"],
            "peak_items": self.stats["peak_items"],
            "avg_memory_per_item": self.stats["avg_memory_per_item"],
            "key_distribution": key_distribution,
            "value_sizes": value_sizes,
            "history": self.history
        }
        
        # Enregistrer le rapport
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2)
        
        # Générer des graphiques
        self._generate_charts(report, timestamp)
        
        logger.info(f"Rapport de profilage généré: {report_file}")
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
            times = [m["timestamp"] - report["history"][0]["timestamp"] for m in report["history"]]
            cache_sizes = [m["cache_size"] / (1024 * 1024) for m in report["history"]]  # En Mo
            cache_counts = [m["cache_count"] for m in report["history"]]
            hits = [m["cache_hits"] for m in report["history"]]
            misses = [m["cache_misses"] for m in report["history"]]
            
            # Graphique 1: Taille du cache et nombre d'éléments
            plt.figure(figsize=(10, 6))
            plt.subplot(2, 1, 1)
            plt.plot(times, cache_sizes, 'b-', label='Taille du cache (Mo)')
            plt.xlabel('Temps (s)')
            plt.ylabel('Taille (Mo)')
            plt.title('Évolution de la taille du cache')
            plt.grid(True)
            plt.legend()
            
            plt.subplot(2, 1, 2)
            plt.plot(times, cache_counts, 'r-', label='Nombre d\'éléments')
            plt.xlabel('Temps (s)')
            plt.ylabel('Nombre d\'éléments')
            plt.title('Évolution du nombre d\'éléments dans le cache')
            plt.grid(True)
            plt.legend()
            
            plt.tight_layout()
            plt.savefig(os.path.join(charts_dir, f"cache_size_{timestamp}.png"))
            plt.close()
            
            # Graphique 2: Hits et misses
            plt.figure(figsize=(10, 6))
            plt.plot(times, hits, 'g-', label='Hits')
            plt.plot(times, misses, 'r-', label='Misses')
            plt.xlabel('Temps (s)')
            plt.ylabel('Nombre')
            plt.title('Évolution des hits et misses du cache')
            plt.grid(True)
            plt.legend()
            
            plt.tight_layout()
            plt.savefig(os.path.join(charts_dir, f"cache_hits_misses_{timestamp}.png"))
            plt.close()
            
            # Graphique 3: Distribution des préfixes de clés
            if report["key_distribution"]["prefixes"]:
                plt.figure(figsize=(10, 6))
                prefixes = list(report["key_distribution"]["prefixes"].keys())
                counts = list(report["key_distribution"]["prefixes"].values())
                
                # Trier par nombre d'occurrences
                sorted_indices = np.argsort(counts)[::-1]
                prefixes = [prefixes[i] for i in sorted_indices]
                counts = [counts[i] for i in sorted_indices]
                
                # Limiter à 10 préfixes pour la lisibilité
                if len(prefixes) > 10:
                    other_count = sum(counts[10:])
                    prefixes = prefixes[:10] + ["Autres"]
                    counts = counts[:10] + [other_count]
                
                plt.bar(prefixes, counts)
                plt.xlabel('Préfixes de clés')
                plt.ylabel('Nombre d\'occurrences')
                plt.title('Distribution des préfixes de clés dans le cache')
                plt.xticks(rotation=45, ha='right')
                plt.tight_layout()
                plt.savefig(os.path.join(charts_dir, f"key_distribution_{timestamp}.png"))
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
        
        # Analyser les données
        key_distribution = self.analyze_key_distribution()
        value_sizes = self.analyze_value_sizes()
        
        # Vérifier la taille moyenne des valeurs
        if value_sizes["value_size_avg"] > 1024 * 10:  # Plus de 10 Ko
            recommendations.append("Les valeurs stockées sont volumineuses (moyenne > 10 Ko). "
                                  "Envisagez de compresser les données ou de stocker des références.")
        
        # Vérifier le ratio hits/misses
        if self.history:
            last_measurement = self.history[-1]
            total_requests = last_measurement["cache_hits"] + last_measurement["cache_misses"]
            if total_requests > 0:
                hit_ratio = last_measurement["cache_hits"] / total_requests
                if hit_ratio < 0.5:
                    recommendations.append(f"Le taux de succès du cache est faible ({hit_ratio:.2%}). "
                                          "Envisagez d'augmenter la durée de vie (TTL) des éléments.")
        
        # Vérifier la croissance du cache
        if len(self.history) > 2:
            first_size = self.history[0]["cache_size"]
            last_size = self.history[-1]["cache_size"]
            growth_rate = (last_size - first_size) / first_size if first_size > 0 else 0
            
            if growth_rate > 0.5:  # Croissance de plus de 50%
                recommendations.append(f"Le cache croît rapidement ({growth_rate:.2%}). "
                                      "Envisagez d'implémenter une stratégie d'éviction plus agressive.")
        
        # Vérifier la distribution des clés
        if key_distribution["prefixes"]:
            max_prefix = max(key_distribution["prefixes"].items(), key=lambda x: x[1])
            if max_prefix[1] > key_distribution["total_keys"] * 0.8:
                recommendations.append(f"Le préfixe '{max_prefix[0]}' représente {max_prefix[1]} clés "
                                      f"({max_prefix[1] / key_distribution['total_keys']:.2%} du total). "
                                      "Envisagez de segmenter ce préfixe pour une meilleure gestion.")
        
        # Recommandations générales
        if not recommendations:
            recommendations.append("Aucun problème majeur détecté. Le cache semble bien configuré.")
        
        return recommendations


# Fonction pour créer une instance du profileur de mémoire
def create_memory_profiler(cache: LocalCache, output_dir: Optional[str] = None) -> MemoryProfiler:
    """
    Crée une instance du profileur de mémoire.
    
    Args:
        cache (LocalCache): Instance du cache à profiler.
        output_dir (str, optional): Répertoire de sortie pour les rapports.
            Si None, utilise le répertoire courant.
            
    Returns:
        MemoryProfiler: Instance du profileur de mémoire.
    """
    return MemoryProfiler(cache, output_dir)


if __name__ == "__main__":
    # Exemple d'utilisation
    from scripts.utils.cache.local_cache import LocalCache
    
    # Créer une instance du cache
    cache = LocalCache()
    
    # Créer une instance du profileur de mémoire
    profiler = MemoryProfiler(cache)
    
    # Ajouter des données au cache
    for i in range(1000):
        cache.set(f"key:{i}", f"value:{i}" * 100)
    
    # Mesurer la consommation mémoire
    measurement = profiler.measure()
    print(f"Mesure: {measurement}")
    
    # Analyser la distribution des clés
    key_distribution = profiler.analyze_key_distribution()
    print(f"Distribution des clés: {key_distribution}")
    
    # Analyser la taille des valeurs
    value_sizes = profiler.analyze_value_sizes()
    print(f"Taille des valeurs: {value_sizes}")
    
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
