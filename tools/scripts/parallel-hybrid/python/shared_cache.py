#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Module de gestion du cache partagé pour l'architecture hybride PowerShell-Python.

Ce module fournit des fonctions pour gérer un cache partagé entre PowerShell et Python.

Auteur: Augment Agent
Date: 2025-04-10
Version: 1.0
"""

import os
import json
import time
import pickle
import hashlib
import threading
import multiprocessing
from datetime import datetime, timedelta
from collections import OrderedDict
from filelock import FileLock
from contextlib import contextmanager


class SharedCache:
    """Classe pour la gestion du cache partagé entre PowerShell et Python."""

    def __init__(self, cache_path=None, cache_type="hybrid", max_memory_size=100, max_disk_size=1000,
                 default_ttl=3600, eviction_policy="lru", partitions=4, preload_factor=0.2):
        """
        Initialise le cache partagé.

        Args:
            cache_path (str, optional): Chemin vers le répertoire du cache.
                Si None, utilise un répertoire temporaire.
            cache_type (str, optional): Type de cache à utiliser.
                Valeurs possibles: 'memory', 'disk', 'hybrid'. Par défaut: 'hybrid'.
            max_memory_size (int, optional): Taille maximale du cache en mémoire en Mo.
                Par défaut: 100.
            max_disk_size (int, optional): Taille maximale du cache sur disque en Mo.
                Par défaut: 1000.
            default_ttl (int, optional): Durée de vie par défaut des éléments du cache en secondes.
                Par défaut: 3600 (1 heure).
            eviction_policy (str, optional): Politique d'éviction des éléments du cache.
                Valeurs possibles: 'lru', 'lfu', 'fifo'. Par défaut: 'lru'.
            partitions (int, optional): Nombre de partitions pour le cache distribué.
                Par défaut: 4.
            preload_factor (float, optional): Facteur de préchargement (0.0 à 1.0).
                Par défaut: 0.2 (20%).
        """
        self.cache_path = cache_path
        if self.cache_path is None:
            self.cache_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cache")

        # Créer le répertoire du cache si nécessaire
        if not os.path.exists(self.cache_path):
            os.makedirs(self.cache_path)

        # Créer le répertoire des verrous si nécessaire
        self.locks_path = os.path.join(self.cache_path, "locks")
        if not os.path.exists(self.locks_path):
            os.makedirs(self.locks_path)

        # Charger la configuration du cache
        self.config = {
            "cache_type": cache_type.lower(),
            "max_memory_size": max_memory_size,
            "max_disk_size": max_disk_size,
            "default_ttl": default_ttl,
            "eviction_policy": eviction_policy.lower(),
            "partitions": partitions,
            "preload_factor": preload_factor
        }

        # Essayer de charger la configuration depuis le fichier
        config_path = os.path.join(self.cache_path, "cache_config.json")
        if os.path.exists(config_path):
            try:
                with open(config_path, "r", encoding="utf-8") as f:
                    config = json.load(f)

                    # Mettre à jour la configuration
                    if "CacheType" in config:
                        self.config["cache_type"] = config["CacheType"].lower()
                    if "MaxMemorySize" in config:
                        self.config["max_memory_size"] = config["MaxMemorySize"]
                    if "MaxDiskSize" in config:
                        self.config["max_disk_size"] = config["MaxDiskSize"]
                    if "DefaultTTL" in config:
                        self.config["default_ttl"] = config["DefaultTTL"]
                    if "EvictionPolicy" in config:
                        self.config["eviction_policy"] = config["EvictionPolicy"].lower()
                    if "Partitions" in config:
                        self.config["partitions"] = config["Partitions"]
                    if "PreloadFactor" in config:
                        self.config["preload_factor"] = config["PreloadFactor"]
            except Exception as e:
                print(f"Erreur lors du chargement de la configuration du cache : {e}")

        # Initialiser le cache mémoire (partitionné)
        self.memory_cache = []
        for _ in range(self.config["partitions"]):
            if self.config["eviction_policy"] == "lru":
                self.memory_cache.append(OrderedDict())
            else:
                self.memory_cache.append({})

        # Statistiques du cache
        self.stats = {
            "memory_hits": 0,
            "memory_misses": 0,
            "disk_hits": 0,
            "disk_misses": 0,
            "evictions": 0,
            "preloads": 0,
            "invalidations": 0,
            "lock_contentions": 0
        }

        # Verrous pour les opérations thread-safe
        self.locks = [threading.RLock() for _ in range(self.config["partitions"])]

        # Dictionnaire des accès pour le préchargement prédictif
        self.access_patterns = {}

        # Identifiant du processus pour le verrouillage distribué
        self.process_id = os.getpid()

        # Initialiser le gestionnaire de processus partagé si nécessaire
        if multiprocessing.current_process().name == "MainProcess":
            self.manager = multiprocessing.Manager()
            self.shared_dict = self.manager.dict()
        else:
            self.manager = None
            self.shared_dict = None

    @contextmanager
    def _distributed_lock(self, key):
        """
        Gestionnaire de contexte pour le verrouillage distribué.

        Args:
            key (str): Clé pour laquelle obtenir un verrou.

        Yields:
            bool: True si le verrou a été obtenu, False sinon.
        """
        # Déterminer la partition pour cette clé
        partition = self._get_partition(key)

        # Obtenir le verrou local (thread-safe)
        with self.locks[partition]:
            # Obtenir le verrou distribué (process-safe)
            lock_file = os.path.join(self.locks_path, f"{self._get_disk_key(key)}.lock")
            file_lock = FileLock(lock_file, timeout=1)  # Timeout de 1 seconde

            try:
                # Essayer d'obtenir le verrou
                file_lock.acquire()
                try:
                    yield True
                finally:
                    # Libérer le verrou
                    file_lock.release()
            except Exception:
                # Impossible d'obtenir le verrou
                self.stats["lock_contentions"] += 1
                yield False

    def _get_partition(self, key):
        """
        Détermine la partition pour une clé donnée.

        Args:
            key (str): Clé pour laquelle déterminer la partition.

        Returns:
            int: Indice de la partition.
        """
        # Utiliser un hachage pour distribuer les clés de manière uniforme
        hash_value = int(hashlib.md5(str(key).encode()).hexdigest(), 16)
        return hash_value % self.config["partitions"]

    def _update_access_pattern(self, key):
        """
        Met à jour les modèles d'accès pour le préchargement prédictif.

        Args:
            key (str): Clé accédée.
        """
        # Obtenir l'horodatage actuel
        current_time = time.time()

        # Mettre à jour le dernier accès pour cette clé
        if key not in self.access_patterns:
            self.access_patterns[key] = {
                "last_access": current_time,
                "access_count": 1,
                "related_keys": {}
            }
        else:
            # Mettre à jour les statistiques d'accès
            self.access_patterns[key]["access_count"] += 1

            # Trouver les clés accédées récemment (dans les 5 dernières secondes)
            recent_keys = [k for k, v in self.access_patterns.items()
                          if v["last_access"] > current_time - 5 and k != key]

            # Mettre à jour les relations entre les clés
            for recent_key in recent_keys:
                if recent_key not in self.access_patterns[key]["related_keys"]:
                    self.access_patterns[key]["related_keys"][recent_key] = 1
                else:
                    self.access_patterns[key]["related_keys"][recent_key] += 1

            # Mettre à jour l'horodatage du dernier accès
            self.access_patterns[key]["last_access"] = current_time

    def _preload_related_keys(self, key):
        """
        Précharge les clés liées en fonction des modèles d'accès.

        Args:
            key (str): Clé pour laquelle précharger les clés liées.
        """
        # Vérifier si le préchargement est activé
        if self.config["preload_factor"] <= 0:
            return

        # Vérifier si nous avons des informations sur cette clé
        if key not in self.access_patterns or not self.access_patterns[key]["related_keys"]:
            return

        # Obtenir les clés liées les plus fréquemment accédées
        related_keys = sorted(
            self.access_patterns[key]["related_keys"].items(),
            key=lambda x: x[1],
            reverse=True
        )

        # Déterminer le nombre de clés à précharger
        num_keys_to_preload = max(1, int(len(related_keys) * self.config["preload_factor"]))
        keys_to_preload = [k for k, _ in related_keys[:num_keys_to_preload]]

        # Précharger les clés
        for related_key in keys_to_preload:
            # Vérifier si la clé est déjà dans le cache mémoire
            partition = self._get_partition(related_key)
            if related_key in self.memory_cache[partition]:
                continue

            # Vérifier si la clé est dans le cache disque
            disk_key = self._get_disk_key(related_key)
            disk_path = os.path.join(self.cache_path, disk_key)

            if os.path.exists(disk_path):
                try:
                    with open(disk_path, "rb") as f:
                        item = pickle.load(f)

                    # Vérifier si l'élément est expiré
                    if item["expires_at"] > time.time():
                        # Ajouter l'élément au cache mémoire
                        self.memory_cache[partition][related_key] = item

                        # Mettre à jour l'ordre pour LRU
                        if self.config["eviction_policy"] == "lru":
                            self.memory_cache[partition].move_to_end(related_key)

                        self.stats["preloads"] += 1
                except Exception as e:
                    print(f"Erreur lors du préchargement de la clé '{related_key}' : {e}")

    def get(self, key, default=None):
        """
        Récupère un élément du cache.

        Args:
            key (str): Clé de l'élément à récupérer.
            default (any, optional): Valeur par défaut à retourner si l'élément n'est pas trouvé.
                Par défaut: None.

        Returns:
            any: La valeur de l'élément du cache ou la valeur par défaut si l'élément n'est pas trouvé.
        """
        # Déterminer la partition pour cette clé
        partition = self._get_partition(key)

        # Mettre à jour les modèles d'accès
        self._update_access_pattern(key)

        # Utiliser le verrou de la partition
        with self.locks[partition]:
            # Vérifier d'abord dans le cache mémoire
            if self.config["cache_type"] in ["memory", "hybrid"]:
                if key in self.memory_cache[partition]:
                    item = self.memory_cache[partition][key]

                    # Vérifier si l'élément est expiré
                    if item["expires_at"] > time.time():
                        # Mettre à jour l'ordre pour LRU
                        if self.config["eviction_policy"] == "lru":
                            self.memory_cache[partition].move_to_end(key)

                        # Mettre à jour le compteur d'accès pour LFU
                        if self.config["eviction_policy"] == "lfu":
                            item["access_count"] += 1

                        self.stats["memory_hits"] += 1

                        # Précharger les clés liées en arrière-plan
                        self._preload_related_keys(key)

                        return item["value"]
                    else:
                        # Supprimer l'élément expiré
                        del self.memory_cache[partition][key]

                self.stats["memory_misses"] += 1

            # Vérifier ensuite dans le cache disque
            if self.config["cache_type"] in ["disk", "hybrid"]:
                disk_key = self._get_disk_key(key)
                disk_path = os.path.join(self.cache_path, disk_key)

                if os.path.exists(disk_path):
                    try:
                        with open(disk_path, "rb") as f:
                            item = pickle.load(f)

                        # Vérifier si l'élément est expiré
                        if item["expires_at"] > time.time():
                            # Promouvoir l'élément dans le cache mémoire si le cache est de type hybrid
                            if self.config["cache_type"] == "hybrid":
                                self.memory_cache[partition][key] = item

                                # Mettre à jour l'ordre pour LRU
                                if self.config["eviction_policy"] == "lru":
                                    self.memory_cache[partition].move_to_end(key)

                            self.stats["disk_hits"] += 1

                            # Précharger les clés liées en arrière-plan
                            self._preload_related_keys(key)

                            return item["value"]
                        else:
                            # Supprimer l'élément expiré
                            os.remove(disk_path)
                    except Exception as e:
                        print(f"Erreur lors de la lecture du cache disque pour la clé '{key}' : {e}")

                self.stats["disk_misses"] += 1

            return default

    def set(self, key, value, ttl=None, dependencies=None):
        """
        Stocke un élément dans le cache.

        Args:
            key (str): Clé de l'élément à stocker.
            value (any): Valeur de l'élément à stocker.
            ttl (int, optional): Durée de vie de l'élément en secondes.
                Si None, utilise la durée de vie par défaut du cache.
            dependencies (list, optional): Liste des clés dont dépend cet élément.
                Si une de ces clés est invalidée, cet élément sera également invalidé.

        Returns:
            any: La valeur stockée dans le cache.
        """
        # Déterminer la partition pour cette clé
        partition = self._get_partition(key)

        # Utiliser le verrou distribué
        with self._distributed_lock(key) as lock_acquired:
            if not lock_acquired:
                # Si le verrou n'a pas pu être acquis, utiliser seulement le verrou local
                with self.locks[partition]:
                    return self._set_internal(key, value, ttl, dependencies, partition)
            else:
                # Si le verrou a été acquis, pas besoin de verrou local supplémentaire
                return self._set_internal(key, value, ttl, dependencies, partition)

    def _set_internal(self, key, value, ttl, dependencies, partition):
        """
        Implémentation interne de la méthode set.

        Args:
            key (str): Clé de l'élément à stocker.
            value (any): Valeur de l'élément à stocker.
            ttl (int): Durée de vie de l'élément en secondes.
            dependencies (list): Liste des clés dont dépend cet élément.
            partition (int): Partition pour cette clé.

        Returns:
            any: La valeur stockée dans le cache.
        """
        # Utiliser la durée de vie par défaut si non spécifiée
        if ttl is None:
            ttl = self.config["default_ttl"]

        # Normaliser les dépendances
        if dependencies is None:
            dependencies = []

        # Créer l'élément de cache
        expires_at = time.time() + ttl
        item = {
            "key": key,
            "value": value,
            "created_at": time.time(),
            "expires_at": expires_at,
            "ttl": ttl,
            "access_count": 0,
            "dependencies": dependencies
        }

        # Stocker dans le cache mémoire
        if self.config["cache_type"] in ["memory", "hybrid"]:
            # Vérifier si le cache mémoire est plein
            if len(self.memory_cache[partition]) >= self.config["max_memory_size"] // self.config["partitions"]:
                # Appliquer la politique d'éviction
                self._evict_from_memory(partition)

            self.memory_cache[partition][key] = item

            # Mettre à jour l'ordre pour LRU
            if self.config["eviction_policy"] == "lru":
                self.memory_cache[partition].move_to_end(key)

        # Stocker dans le cache disque
        if self.config["cache_type"] in ["disk", "hybrid"]:
            try:
                disk_key = self._get_disk_key(key)
                disk_path = os.path.join(self.cache_path, disk_key)

                with open(disk_path, "wb") as f:
                    pickle.dump(item, f)

                # Vérifier si le cache disque est plein
                self._check_disk_size()

                # Stocker les dépendances inverses pour l'invalidation sélective
                for dep_key in dependencies:
                    dep_disk_key = self._get_disk_key(f"dep:{dep_key}")
                    dep_disk_path = os.path.join(self.cache_path, dep_disk_key)

                    try:
                        if os.path.exists(dep_disk_path):
                            with open(dep_disk_path, "rb") as f:
                                dependent_keys = pickle.load(f)
                        else:
                            dependent_keys = []

                        if key not in dependent_keys:
                            dependent_keys.append(key)

                        with open(dep_disk_path, "wb") as f:
                            pickle.dump(dependent_keys, f)
                    except Exception as e:
                        print(f"Erreur lors de la gestion des dépendances pour la clé '{key}' : {e}")
            except Exception as e:
                print(f"Erreur lors de l'écriture dans le cache disque pour la clé '{key}' : {e}")

        return value

    def remove(self, key):
        """
        Supprime un élément du cache.

        Args:
            key (str): Clé de l'élément à supprimer.
        """
        # Déterminer la partition pour cette clé
        partition = self._get_partition(key)

        # Utiliser le verrou distribué
        with self._distributed_lock(key) as lock_acquired:
            if not lock_acquired:
                # Si le verrou n'a pas pu être acquis, utiliser seulement le verrou local
                with self.locks[partition]:
                    self._remove_internal(key, partition)
            else:
                # Si le verrou a été acquis, pas besoin de verrou local supplémentaire
                self._remove_internal(key, partition)

    def _remove_internal(self, key, partition):
        """
        Implémentation interne de la méthode remove.

        Args:
            key (str): Clé de l'élément à supprimer.
            partition (int): Partition pour cette clé.
        """
        # Supprimer du cache mémoire
        if key in self.memory_cache[partition]:
            del self.memory_cache[partition][key]

        # Supprimer du cache disque
        disk_key = self._get_disk_key(key)
        disk_path = os.path.join(self.cache_path, disk_key)
        if os.path.exists(disk_path):
            try:
                os.remove(disk_path)
            except Exception as e:
                print(f"Erreur lors de la suppression du cache disque pour la clé '{key}' : {e}")

    def invalidate(self, key):
        """
        Invalide un élément du cache et tous les éléments qui en dépendent.

        Args:
            key (str): Clé de l'élément à invalider.

        Returns:
            int: Nombre d'éléments invalidés.
        """
        # Déterminer la partition pour cette clé
        partition = self._get_partition(key)

        # Utiliser le verrou distribué
        with self._distributed_lock(key) as lock_acquired:
            if not lock_acquired:
                # Si le verrou n'a pas pu être acquis, utiliser seulement le verrou local
                with self.locks[partition]:
                    return self._invalidate_internal(key)
            else:
                # Si le verrou a été acquis, pas besoin de verrou local supplémentaire
                return self._invalidate_internal(key)

    def _invalidate_internal(self, key):
        """
        Implémentation interne de la méthode invalidate.

        Args:
            key (str): Clé de l'élément à invalider.

        Returns:
            int: Nombre d'éléments invalidés.
        """
        # Supprimer l'élément du cache
        self.remove(key)

        # Trouver les éléments qui dépendent de cette clé
        dep_disk_key = self._get_disk_key(f"dep:{key}")
        dep_disk_path = os.path.join(self.cache_path, dep_disk_key)

        invalidated_count = 1  # Compter l'élément lui-même

        if os.path.exists(dep_disk_path):
            try:
                with open(dep_disk_path, "rb") as f:
                    dependent_keys = pickle.load(f)

                # Invalider récursivement tous les éléments dépendants
                for dep_key in dependent_keys:
                    invalidated_count += self._invalidate_internal(dep_key)

                # Supprimer le fichier de dépendances
                os.remove(dep_disk_path)
            except Exception as e:
                print(f"Erreur lors de l'invalidation des dépendances pour la clé '{key}' : {e}")

        self.stats["invalidations"] += 1
        return invalidated_count

    def clear(self):
        """Vide le cache."""
        # Utiliser un verrou global pour cette opération
        global_lock_file = os.path.join(self.locks_path, "global.lock")
        with FileLock(global_lock_file, timeout=5):
            # Vider le cache mémoire
            for partition in range(self.config["partitions"]):
                with self.locks[partition]:
                    self.memory_cache[partition].clear()

            # Vider le cache disque
            for filename in os.listdir(self.cache_path):
                if filename.endswith(".cache"):
                    try:
                        os.remove(os.path.join(self.cache_path, filename))
                    except Exception as e:
                        print(f"Erreur lors de la suppression du fichier de cache '{filename}' : {e}")

            # Réinitialiser les statistiques
            self.stats = {
                "memory_hits": 0,
                "memory_misses": 0,
                "disk_hits": 0,
                "disk_misses": 0,
                "evictions": 0,
                "preloads": 0,
                "invalidations": 0,
                "lock_contentions": 0
            }

    def get_stats(self):
        """
        Récupère les statistiques du cache.

        Returns:
            dict: Les statistiques du cache.
        """
        # Utiliser un verrou global pour cette opération
        global_lock_file = os.path.join(self.locks_path, "stats.lock")
        with FileLock(global_lock_file, timeout=1):
            return self.stats.copy()

    def _get_disk_key(self, key):
        """
        Génère une clé pour le cache disque.

        Args:
            key (str): Clé originale.

        Returns:
            str: Clé pour le cache disque.
        """
        # Utiliser un hachage MD5 pour éviter les problèmes de caractères spéciaux dans les noms de fichiers
        return hashlib.md5(str(key).encode()).hexdigest() + ".cache"

    def _evict_from_memory(self, partition):
        """Applique la politique d'éviction pour le cache mémoire.

        Args:
            partition (int): Partition pour laquelle appliquer l'éviction.
        """
        if not self.memory_cache[partition]:
            return

        if self.config["eviction_policy"] == "lru":
            # Least Recently Used
            self.memory_cache[partition].popitem(last=False)
            self.stats["evictions"] += 1

        elif self.config["eviction_policy"] == "lfu":
            # Least Frequently Used
            min_count = float("inf")
            min_key = None

            for key, item in self.memory_cache[partition].items():
                if item["access_count"] < min_count:
                    min_count = item["access_count"]
                    min_key = key

            if min_key:
                del self.memory_cache[partition][min_key]
                self.stats["evictions"] += 1

        elif self.config["eviction_policy"] == "fifo":
            # First In First Out
            oldest_time = float("inf")
            oldest_key = None

            for key, item in self.memory_cache[partition].items():
                if item["created_at"] < oldest_time:
                    oldest_time = item["created_at"]
                    oldest_key = key

            if oldest_key:
                del self.memory_cache[partition][oldest_key]
                self.stats["evictions"] += 1

    def _check_disk_size(self):
        """Vérifie la taille du cache disque et applique la politique d'éviction si nécessaire."""
        # Utiliser un verrou global pour cette opération
        global_lock_file = os.path.join(self.locks_path, "disk_size.lock")

        try:
            with FileLock(global_lock_file, timeout=1):
                # Calculer la taille totale du cache disque
                total_size = 0
                cache_files = []

                for filename in os.listdir(self.cache_path):
                    if filename.endswith(".cache") and not filename.startswith("dep:"):
                        file_path = os.path.join(self.cache_path, filename)
                        file_size = os.path.getsize(file_path)
                        total_size += file_size

                        try:
                            cache_files.append({
                                "path": file_path,
                                "size": file_size,
                                "created_at": os.path.getctime(file_path),
                                "accessed_at": os.path.getatime(file_path)
                            })
                        except Exception:
                            pass

                # Convertir en Mo
                total_size_mb = total_size / (1024 * 1024)

                # Vérifier si le cache disque est plein
                if total_size_mb > self.config["max_disk_size"] and cache_files:
                    # Appliquer la politique d'éviction
                    if self.config["eviction_policy"] == "lru":
                        # Least Recently Used
                        cache_files.sort(key=lambda x: x["accessed_at"])
                    elif self.config["eviction_policy"] == "lfu":
                        # Least Frequently Used (approximation basée sur la taille du fichier)
                        cache_files.sort(key=lambda x: x["size"])
                    else:
                        # First In First Out
                        cache_files.sort(key=lambda x: x["created_at"])

                    # Supprimer les fichiers jusqu'à ce que la taille soit acceptable
                    target_size_mb = self.config["max_disk_size"] * 0.9  # Réduire à 90% de la taille maximale
                    current_size_mb = total_size_mb

                    for file_info in cache_files:
                        if current_size_mb <= target_size_mb:
                            break

                        try:
                            # Extraire la clé du nom de fichier
                            file_key = os.path.splitext(os.path.basename(file_info["path"]))[0]

                            # Invalider l'élément plutôt que de simplement supprimer le fichier
                            # Cela permettra de gérer correctement les dépendances
                            self.invalidate(file_key)

                            current_size_mb -= file_info["size"] / (1024 * 1024)
                        except Exception as e:
                            print(f"Erreur lors de l'éviction du fichier de cache '{file_info['path']}' : {e}")
        except Exception as e:
            # En cas d'échec d'acquisition du verrou, ignorer cette vérification
            # Elle sera effectuée lors d'une prochaine opération d'écriture
            self.stats["lock_contentions"] += 1


def main():
    """Fonction principale pour les tests."""
    import argparse

    parser = argparse.ArgumentParser(description='Module de gestion du cache partagé')
    parser.add_argument('--cache-path', help='Chemin vers le répertoire du cache')
    parser.add_argument('--cache-type', choices=['memory', 'disk', 'hybrid'], default='hybrid', help='Type de cache à utiliser')
    parser.add_argument('--max-memory-size', type=int, default=100, help='Taille maximale du cache en mémoire en Mo')
    parser.add_argument('--max-disk-size', type=int, default=1000, help='Taille maximale du cache sur disque en Mo')
    parser.add_argument('--default-ttl', type=int, default=3600, help='Durée de vie par défaut des éléments du cache en secondes')
    parser.add_argument('--eviction-policy', choices=['lru', 'lfu', 'fifo'], default='lru', help='Politique d\'éviction des éléments du cache')

    args = parser.parse_args()

    # Initialiser le cache
    cache = SharedCache(
        cache_path=args.cache_path,
        cache_type=args.cache_type,
        max_memory_size=args.max_memory_size,
        max_disk_size=args.max_disk_size,
        default_ttl=args.default_ttl,
        eviction_policy=args.eviction_policy
    )

    # Exemples d'utilisation
    print("Stockage d'éléments dans le cache...")
    cache.set("key1", "value1")
    cache.set("key2", {"name": "John", "age": 30})
    cache.set("key3", [1, 2, 3, 4, 5])

    print("Récupération d'éléments du cache...")
    print(f"key1: {cache.get('key1')}")
    print(f"key2: {cache.get('key2')}")
    print(f"key3: {cache.get('key3')}")
    print(f"key4 (inexistant): {cache.get('key4', 'valeur par défaut')}")

    print("Suppression d'un élément du cache...")
    cache.remove("key1")
    print(f"key1 après suppression: {cache.get('key1')}")

    print("Statistiques du cache:")
    stats = cache.get_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")

    print("Vidage du cache...")
    cache.clear()
    print(f"key2 après vidage: {cache.get('key2')}")
    print(f"key3 après vidage: {cache.get('key3')}")


if __name__ == "__main__":
    main()
