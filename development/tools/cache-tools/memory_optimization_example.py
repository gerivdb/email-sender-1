#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'exemple pour les optimisations de mémoire du cache.

Ce script montre comment utiliser les différentes stratégies d'éviction
et les outils de profilage pour optimiser l'utilisation de la mémoire du cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import random
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.eviction_strategies import (
    LRUStrategy, LFUStrategy, FIFOStrategy, SizeAwareStrategy, TTLAwareStrategy, CompositeStrategy
)
from scripts.utils.cache.memory_profiler import MemoryProfiler


def exemple_strategies_eviction():
    """Exemple d'utilisation des différentes stratégies d'éviction."""
    print("\n=== Exemple d'utilisation des différentes stratégies d'éviction ===")

    # Créer un répertoire temporaire pour les caches
    cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp_cache')
    os.makedirs(cache_dir, exist_ok=True)

    # Créer des caches avec différentes stratégies d'éviction
    lru_cache = LocalCache(os.path.join(cache_dir, 'lru_cache'), eviction_strategy=LRUStrategy())
    lfu_cache = LocalCache(os.path.join(cache_dir, 'lfu_cache'), eviction_strategy=LFUStrategy())
    fifo_cache = LocalCache(os.path.join(cache_dir, 'fifo_cache'), eviction_strategy=FIFOStrategy())
    size_cache = LocalCache(os.path.join(cache_dir, 'size_cache'), eviction_strategy=SizeAwareStrategy())
    ttl_cache = LocalCache(os.path.join(cache_dir, 'ttl_cache'), eviction_strategy=TTLAwareStrategy())

    # Créer une stratégie composite
    composite_strategy = CompositeStrategy({
        LRUStrategy(): 0.6,
        LFUStrategy(): 0.4
    })
    composite_cache = LocalCache(os.path.join(cache_dir, 'composite_cache'), eviction_strategy=composite_strategy)

    # Liste des caches à tester
    caches = [
        ("LRU", lru_cache),
        ("LFU", lfu_cache),
        ("FIFO", fifo_cache),
        ("Size-Aware", size_cache),
        ("TTL-Aware", ttl_cache),
        ("Composite", composite_cache)
    ]

    # Configurer les caches pour qu'ils soient plus petits pour le test
    for name, cache in caches:
        cache.config["MaxItems"] = 100
        cache.config["EvictionThreshold"] = 0.8
        cache.config["EvictionCount"] = 20
        cache.config["EnableEvictionLogging"] = True

    # Remplir les caches avec des données
    print("Remplissage des caches avec des données...")
    for i in range(80):
        for name, cache in caches:
            # Générer une valeur de taille variable
            value = "x" * random.randint(100, 10000)
            cache.set(f"key{i}", value)

    # Accéder à certaines clés plus fréquemment
    print("Accès à certaines clés plus fréquemment...")
    for _ in range(50):
        for name, cache in caches:
            # Accéder aux clés 10-19 plus fréquemment
            for i in range(10, 20):
                cache.get(f"key{i}")

    # Ajouter plus de données pour déclencher l'éviction
    print("Ajout de données supplémentaires pour déclencher l'éviction...")
    for i in range(80, 120):
        for name, cache in caches:
            # Générer une valeur de taille variable
            value = "x" * random.randint(100, 10000)
            cache.set(f"key{i}", value)

    # Vérifier quelles clés ont été évincées
    print("\nVérification des clés évincées:")
    for name, cache in caches:
        # Compter les clés restantes par plage
        ranges = {
            "0-9": 0,
            "10-19": 0,
            "20-79": 0,
            "80-119": 0
        }

        for i in range(120):
            key = f"key{i}"
            if cache.get(key) is not None:
                if i < 10:
                    ranges["0-9"] += 1
                elif i < 20:
                    ranges["10-19"] += 1
                elif i < 80:
                    ranges["20-79"] += 1
                else:
                    ranges["80-119"] += 1

        print(f"\nStratégie {name}:")
        print(f"  Clés 0-9: {ranges['0-9']}/10 restantes")
        print(f"  Clés 10-19 (accédées fréquemment): {ranges['10-19']}/10 restantes")
        print(f"  Clés 20-79: {ranges['20-79']}/60 restantes")
        print(f"  Clés 80-119 (ajoutées en dernier): {ranges['80-119']}/40 restantes")

        # Afficher les statistiques
        stats = cache.get_statistics()
        print(f"  Taux de succès: {stats['hit_ratio']:.2%}")
        print(f"  Évictions: {stats['evictions']}")

    # Nettoyer
    for name, cache in caches:
        cache.clear()
        cache.cache.close()


def exemple_profilage_memoire():
    """Exemple d'utilisation du profileur de mémoire."""
    print("\n=== Exemple d'utilisation du profileur de mémoire ===")

    # Créer un cache
    cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp_cache')
    os.makedirs(cache_dir, exist_ok=True)
    cache = LocalCache(os.path.join(cache_dir, 'profiled_cache'))

    # Créer un profileur de mémoire
    profiler = MemoryProfiler(cache)

    # Mesurer la consommation mémoire initiale
    print("Mesure de la consommation mémoire initiale...")
    initial_measurement = profiler.measure()
    print(f"  Taille du cache: {initial_measurement['cache_size'] / 1024:.2f} Ko")
    print(f"  Nombre d'éléments: {initial_measurement['cache_count']}")

    # Ajouter des données au cache
    print("\nAjout de données au cache...")
    for i in range(1000):
        # Générer une valeur de taille variable
        value = "x" * random.randint(100, 1000)
        cache.set(f"key{i}", value)

        # Mesurer périodiquement
        if i % 200 == 0:
            measurement = profiler.measure()
            print(f"  Après {i} éléments:")
            print(f"    Taille du cache: {measurement['cache_size'] / 1024:.2f} Ko")
            print(f"    Nombre d'éléments: {measurement['cache_count']}")

    # Mesurer la consommation mémoire finale
    print("\nMesure de la consommation mémoire finale...")
    final_measurement = profiler.measure()
    print(f"  Taille du cache: {final_measurement['cache_size'] / 1024:.2f} Ko")
    print(f"  Nombre d'éléments: {final_measurement['cache_count']}")

    # Analyser la distribution des clés
    print("\nAnalyse de la distribution des clés...")
    key_distribution = profiler.analyze_key_distribution()
    print(f"  Nombre total de clés: {key_distribution['total_keys']}")
    print(f"  Longueur moyenne des clés: {key_distribution['key_length_avg']:.2f} caractères")

    # Analyser la taille des valeurs
    print("\nAnalyse de la taille des valeurs...")
    value_sizes = profiler.analyze_value_sizes()
    print(f"  Taille moyenne des valeurs: {value_sizes['value_size_avg'] / 1024:.2f} Ko")
    print(f"  Taille minimale: {value_sizes['value_size_min'] / 1024:.2f} Ko")
    print(f"  Taille maximale: {value_sizes['value_size_max'] / 1024:.2f} Ko")

    # Générer un rapport
    print("\nGénération d'un rapport...")
    report_file = profiler.generate_report()
    print(f"  Rapport généré: {report_file}")

    # Afficher les recommandations
    print("\nRecommandations d'optimisation:")
    recommendations = profiler.recommend_optimizations()
    for i, recommendation in enumerate(recommendations, 1):
        print(f"  {i}. {recommendation}")

    # Nettoyer
    cache.clear()
    cache.cache.close()


def exemple_optimisation_taille():
    """Exemple d'optimisation de la taille des éléments du cache."""
    print("\n=== Exemple d'optimisation de la taille des éléments du cache ===")

    # Créer un cache
    cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp_cache')
    os.makedirs(cache_dir, exist_ok=True)
    cache = LocalCache(os.path.join(cache_dir, 'optimized_cache'))

    # Créer un profileur de mémoire
    profiler = MemoryProfiler(cache)

    # Fonction pour générer des données non optimisées
    def generate_unoptimized_data(count):
        data = []
        for i in range(count):
            item = {
                "id": i,
                "name": f"Item {i}",
                "description": f"This is a description for item {i}" + " " * random.randint(50, 200),
                "attributes": {
                    "color": random.choice(["red", "green", "blue", "yellow", "black", "white"]),
                    "size": random.choice(["small", "medium", "large", "extra large"]),
                    "weight": random.uniform(0.1, 10.0),
                    "dimensions": {
                        "width": random.uniform(1.0, 100.0),
                        "height": random.uniform(1.0, 100.0),
                        "depth": random.uniform(1.0, 100.0)
                    }
                },
                "tags": [f"tag{j}" for j in range(random.randint(1, 10))],
                "created_at": time.time(),
                "updated_at": time.time(),
                "extra_data": "x" * random.randint(100, 1000)
            }
            data.append(item)
        return data

    # Fonction pour générer des données optimisées
    def generate_optimized_data(count):
        # Définir des constantes pour les valeurs répétitives
        COLORS = ["red", "green", "blue", "yellow", "black", "white"]
        SIZES = ["small", "medium", "large", "extra large"]

        data = []
        for i in range(count):
            # Utiliser des types plus compacts
            item = {
                "i": i,  # Nom de clé plus court
                "n": f"Item {i}",  # Nom de clé plus court
                "d": f"Item {i} description",  # Description plus courte
                "a": {  # Nom de clé plus court
                    "c": COLORS.index(random.choice(COLORS)),  # Utiliser un index au lieu de la chaîne
                    "s": SIZES.index(random.choice(SIZES)),  # Utiliser un index au lieu de la chaîne
                    "w": round(random.uniform(0.1, 10.0), 1),  # Arrondir pour réduire la précision
                    "dim": [  # Tableau au lieu d'un objet
                        round(random.uniform(1.0, 100.0), 1),
                        round(random.uniform(1.0, 100.0), 1),
                        round(random.uniform(1.0, 100.0), 1)
                    ]
                },
                "t": [j for j in range(random.randint(1, 5))],  # Moins de tags, utiliser des nombres
                "ts": int(time.time())  # Utiliser un timestamp entier
            }
            data.append(item)
        return data

    # Générer et stocker des données non optimisées
    print("Génération et stockage de données non optimisées...")
    unoptimized_data = generate_unoptimized_data(100)
    for i, item in enumerate(unoptimized_data):
        cache.set(f"unoptimized:{i}", item)

    # Mesurer la consommation mémoire
    measurement1 = profiler.measure()
    print(f"  Taille du cache après données non optimisées: {measurement1['cache_size'] / 1024:.2f} Ko")
    print(f"  Nombre d'éléments: {measurement1['cache_count']}")

    # Vider le cache
    cache.clear()

    # Générer et stocker des données optimisées
    print("\nGénération et stockage de données optimisées...")
    optimized_data = generate_optimized_data(100)
    for i, item in enumerate(optimized_data):
        cache.set(f"optimized:{i}", item)

    # Mesurer la consommation mémoire
    measurement2 = profiler.measure()
    print(f"  Taille du cache après données optimisées: {measurement2['cache_size'] / 1024:.2f} Ko")
    print(f"  Nombre d'éléments: {measurement2['cache_count']}")

    # Calculer l'économie de mémoire
    if measurement1['cache_size'] > 0 and measurement2['cache_size'] > 0:
        memory_saving = 1 - (measurement2['cache_size'] / measurement1['cache_size'])
        print(f"\nÉconomie de mémoire: {memory_saving:.2%}")
    else:
        print("\nImpossible de calculer l'économie de mémoire: taille du cache nulle")

    # Nettoyer
    cache.clear()
    cache.cache.close()


def exemple_compression():
    """Exemple d'utilisation de la compression pour réduire la taille du cache."""
    print("\n=== Exemple d'utilisation de la compression ===")

    # Créer un cache
    cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp_cache')
    os.makedirs(cache_dir, exist_ok=True)
    cache = LocalCache(os.path.join(cache_dir, 'compressed_cache'))

    # Créer un profileur de mémoire
    profiler = MemoryProfiler(cache)

    # Générer des données à compresser
    data = "x" * 10000 + "y" * 10000 + "z" * 10000

    # Stocker les données non compressées
    print("Stockage de données non compressées...")
    cache.set("uncompressed", data)

    # Mesurer la consommation mémoire
    measurement1 = profiler.measure()
    print(f"  Taille du cache avec données non compressées: {measurement1['cache_size'] / 1024:.2f} Ko")

    # Vider le cache
    cache.clear()

    # Compresser les données
    import zlib
    compressed_data = zlib.compress(data.encode('utf-8'))

    # Stocker les données compressées
    print("\nStockage de données compressées...")
    cache.set("compressed", compressed_data)

    # Mesurer la consommation mémoire
    measurement2 = profiler.measure()
    print(f"  Taille du cache avec données compressées: {measurement2['cache_size'] / 1024:.2f} Ko")

    # Calculer le taux de compression
    original_size = len(data.encode('utf-8'))
    compressed_size = len(compressed_data)
    if original_size > 0:
        compression_ratio = 1 - (compressed_size / original_size)
        print(f"\nTaux de compression: {compression_ratio:.2%}")
    else:
        print("\nImpossible de calculer le taux de compression: taille originale nulle")

    # Récupérer et décompresser les données
    print("\nRécupération et décompression des données...")
    retrieved_data = cache.get("compressed")
    decompressed_data = zlib.decompress(retrieved_data).decode('utf-8')

    # Vérifier que les données sont identiques
    print(f"  Données identiques: {data == decompressed_data}")

    # Nettoyer
    cache.clear()
    cache.cache.close()


def nettoyer():
    """Nettoie les fichiers temporaires."""
    print("\n=== Nettoyage ===")

    # Supprimer le répertoire de cache temporaire
    cache_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp_cache')
    if os.path.exists(cache_dir):
        import shutil
        shutil.rmtree(cache_dir)
        print(f"Répertoire de cache temporaire supprimé: {cache_dir}")


def main():
    """Fonction principale."""
    print("=== Exemples d'optimisation de la mémoire du cache ===")

    # Exécuter les exemples
    exemple_strategies_eviction()
    exemple_profilage_memoire()
    exemple_optimisation_taille()
    exemple_compression()

    # Nettoyer
    nettoyer()

    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
