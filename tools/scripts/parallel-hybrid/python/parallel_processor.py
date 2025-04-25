#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de traitement parallèle pour l'architecture hybride PowerShell-Python.

Ce module fournit des fonctions pour le traitement parallèle intensif en Python,
qui peuvent être appelées depuis PowerShell.

Auteur: Augment Agent
Date: 2025-04-10
Version: 1.0
"""

import os
import sys
import json
import time
import argparse
import multiprocessing
from multiprocessing import Pool, cpu_count
from functools import partial
import numpy as np
import psutil

# Import du module de cache partagé
try:
    from shared_cache import SharedCache
except ImportError:
    # Si le module n'est pas trouvé, utiliser un stub
    class SharedCache:
        def __init__(self, cache_path=None):
            self.cache_path = cache_path
            self.cache = {}
        
        def get(self, key, default=None):
            return self.cache.get(key, default)
        
        def set(self, key, value, ttl=3600):
            self.cache[key] = value
            return value
        
        def remove(self, key):
            if key in self.cache:
                del self.cache[key]
        
        def clear(self):
            self.cache.clear()


class ParallelProcessor:
    """Classe pour le traitement parallèle des données."""
    
    def __init__(self, cache_path=None, max_workers=None):
        """
        Initialise le processeur parallèle.
        
        Args:
            cache_path (str, optional): Chemin vers le répertoire du cache.
            max_workers (int, optional): Nombre maximum de processus parallèles.
                Si None, utilise le nombre de processeurs disponibles.
        """
        self.cache = SharedCache(cache_path)
        self.max_workers = max_workers if max_workers is not None else cpu_count()
    
    def process_batch(self, batch_data, process_func, **kwargs):
        """
        Traite un lot de données en parallèle.
        
        Args:
            batch_data (list): Données à traiter.
            process_func (callable): Fonction de traitement à appliquer à chaque élément.
            **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
        
        Returns:
            list: Résultats du traitement.
        """
        # Créer une fonction partielle avec les arguments supplémentaires
        partial_func = partial(process_func, **kwargs)
        
        # Traiter les données en parallèle
        with Pool(processes=self.max_workers) as pool:
            results = pool.map(partial_func, batch_data)
        
        return results
    
    def process_with_cache(self, batch_data, process_func, cache_key_func=None, ttl=3600, **kwargs):
        """
        Traite un lot de données en parallèle avec mise en cache des résultats.
        
        Args:
            batch_data (list): Données à traiter.
            process_func (callable): Fonction de traitement à appliquer à chaque élément.
            cache_key_func (callable, optional): Fonction pour générer la clé de cache.
                Si None, utilise str(item) comme clé.
            ttl (int, optional): Durée de vie des éléments du cache en secondes.
            **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
        
        Returns:
            list: Résultats du traitement.
        """
        results = []
        items_to_process = []
        cache_keys = []
        
        # Vérifier quels éléments sont dans le cache
        for item in batch_data:
            if cache_key_func is not None:
                cache_key = cache_key_func(item)
            else:
                cache_key = str(item)
            
            cached_result = self.cache.get(cache_key)
            if cached_result is not None:
                results.append(cached_result)
            else:
                items_to_process.append(item)
                cache_keys.append(cache_key)
        
        # Traiter les éléments non mis en cache
        if items_to_process:
            partial_func = partial(process_func, **kwargs)
            
            with Pool(processes=self.max_workers) as pool:
                processed_results = pool.map(partial_func, items_to_process)
            
            # Mettre en cache les résultats
            for i, result in enumerate(processed_results):
                self.cache.set(cache_keys[i], result, ttl)
                results.append(result)
        
        return results
    
    def process_chunks(self, data, process_func, chunk_size=None, **kwargs):
        """
        Divise les données en chunks et les traite en parallèle.
        
        Args:
            data (list): Données à traiter.
            process_func (callable): Fonction de traitement à appliquer à chaque chunk.
            chunk_size (int, optional): Taille des chunks. Si None, divise les données
                en fonction du nombre de processeurs.
            **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
        
        Returns:
            list: Résultats du traitement.
        """
        if not data:
            return []
        
        # Déterminer la taille des chunks
        if chunk_size is None:
            chunk_size = max(1, len(data) // self.max_workers)
        
        # Diviser les données en chunks
        chunks = [data[i:i + chunk_size] for i in range(0, len(data), chunk_size)]
        
        # Créer une fonction partielle avec les arguments supplémentaires
        partial_func = partial(process_func, **kwargs)
        
        # Traiter les chunks en parallèle
        with Pool(processes=min(self.max_workers, len(chunks))) as pool:
            results = pool.map(partial_func, chunks)
        
        return results
    
    def process_with_progress(self, data, process_func, callback=None, **kwargs):
        """
        Traite les données en parallèle avec suivi de la progression.
        
        Args:
            data (list): Données à traiter.
            process_func (callable): Fonction de traitement à appliquer à chaque élément.
            callback (callable, optional): Fonction de callback pour le suivi de la progression.
            **kwargs: Arguments supplémentaires à passer à la fonction de traitement.
        
        Returns:
            list: Résultats du traitement.
        """
        results = []
        total = len(data)
        processed = 0
        
        # Créer une file pour la communication entre les processus
        manager = multiprocessing.Manager()
        result_queue = manager.Queue()
        
        # Fonction de traitement avec mise à jour de la progression
        def process_with_update(item, **kwargs):
            result = process_func(item, **kwargs)
            result_queue.put(result)
            return result
        
        # Créer une fonction partielle avec les arguments supplémentaires
        partial_func = partial(process_with_update, **kwargs)
        
        # Traiter les données en parallèle
        with Pool(processes=self.max_workers) as pool:
            async_results = pool.map_async(partial_func, data)
            
            # Suivre la progression
            while not async_results.ready():
                # Récupérer les résultats disponibles
                while not result_queue.empty():
                    results.append(result_queue.get())
                    processed += 1
                    
                    # Appeler le callback avec la progression
                    if callback is not None:
                        callback(processed, total)
                
                time.sleep(0.1)
            
            # Récupérer les résultats restants
            while not result_queue.empty():
                results.append(result_queue.get())
                processed += 1
                
                # Appeler le callback avec la progression
                if callback is not None:
                    callback(processed, total)
        
        return results
    
    def monitor_resources(self, interval=1.0, callback=None):
        """
        Surveille l'utilisation des ressources système.
        
        Args:
            interval (float, optional): Intervalle de surveillance en secondes.
            callback (callable, optional): Fonction de callback pour le suivi des ressources.
        
        Returns:
            dict: Statistiques d'utilisation des ressources.
        """
        # Obtenir les informations sur le processus actuel
        process = psutil.Process(os.getpid())
        
        # Statistiques initiales
        stats = {
            'cpu_percent': 0,
            'memory_percent': 0,
            'memory_info': {
                'rss': 0,
                'vms': 0
            },
            'io_counters': {
                'read_count': 0,
                'write_count': 0,
                'read_bytes': 0,
                'write_bytes': 0
            },
            'num_threads': 0,
            'num_fds': 0,
            'system': {
                'cpu_percent': 0,
                'memory_percent': 0,
                'swap_percent': 0,
                'disk_usage': 0
            }
        }
        
        # Surveiller les ressources
        try:
            # Statistiques du processus
            stats['cpu_percent'] = process.cpu_percent(interval)
            stats['memory_percent'] = process.memory_percent()
            
            memory_info = process.memory_info()
            stats['memory_info']['rss'] = memory_info.rss
            stats['memory_info']['vms'] = memory_info.vms
            
            try:
                io_counters = process.io_counters()
                stats['io_counters']['read_count'] = io_counters.read_count
                stats['io_counters']['write_count'] = io_counters.write_count
                stats['io_counters']['read_bytes'] = io_counters.read_bytes
                stats['io_counters']['write_bytes'] = io_counters.write_bytes
            except (psutil.AccessDenied, AttributeError):
                pass
            
            stats['num_threads'] = process.num_threads()
            
            try:
                stats['num_fds'] = process.num_fds()
            except (psutil.AccessDenied, AttributeError):
                pass
            
            # Statistiques système
            stats['system']['cpu_percent'] = psutil.cpu_percent(interval)
            stats['system']['memory_percent'] = psutil.virtual_memory().percent
            stats['system']['swap_percent'] = psutil.swap_memory().percent
            stats['system']['disk_usage'] = psutil.disk_usage('/').percent
            
            # Appeler le callback avec les statistiques
            if callback is not None:
                callback(stats)
        
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
        
        return stats


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    parser = argparse.ArgumentParser(description='Processeur parallèle pour l\'architecture hybride PowerShell-Python')
    parser.add_argument('--input', required=True, help='Fichier d\'entrée JSON')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le répertoire du cache')
    parser.add_argument('--max-workers', type=int, help='Nombre maximum de processus parallèles')
    parser.add_argument('--chunk-size', type=int, help='Taille des chunks pour le traitement par lots')
    parser.add_argument('--use-cache', action='store_true', help='Utiliser le cache pour les résultats')
    parser.add_argument('--ttl', type=int, default=3600, help='Durée de vie des éléments du cache en secondes')
    
    args = parser.parse_args()
    
    # Charger les données d'entrée
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            input_data = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrée : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Initialiser le processeur parallèle
    processor = ParallelProcessor(cache_path=args.cache, max_workers=args.max_workers)
    
    # Fonction de traitement par défaut (à remplacer par une fonction spécifique)
    def default_process(item):
        # Exemple de traitement simple
        if isinstance(item, (int, float)):
            return item * 2
        elif isinstance(item, str):
            return item.upper()
        elif isinstance(item, list):
            return [default_process(x) for x in item]
        elif isinstance(item, dict):
            return {k: default_process(v) for k, v in item.items()}
        else:
            return item
    
    # Traiter les données
    try:
        if args.use_cache:
            results = processor.process_with_cache(input_data, default_process, ttl=args.ttl)
        elif args.chunk_size:
            results = processor.process_chunks(input_data, default_process, chunk_size=args.chunk_size)
        else:
            results = processor.process_batch(input_data, default_process)
    except Exception as e:
        print(f"Erreur lors du traitement des données : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Écrire les résultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'écriture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)


if __name__ == '__main__':
    main()
