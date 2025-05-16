#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le système de mise en cache.
"""

import os
import sys
import time
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.utils.cache_manager import CacheManager, cached
from src.orchestrator.thematic_crud.theme_attribution import ThemeAttributor

def run_cache_tests():
    """Exécute des tests pour le système de mise en cache."""
    print("Exécution des tests pour le système de mise en cache...")

    # Créer un répertoire temporaire pour le cache
    temp_dir = tempfile.mkdtemp()
    cache_dir = os.path.join(temp_dir, "cache")

    try:
        # Initialiser le gestionnaire de cache
        CacheManager.initialize(cache_dir)

        # Test 1: Cache en mémoire
        print("\nTest 1: Cache en mémoire")

        # Générer une clé de cache
        cache_key = CacheManager.get_cache_key("test_func", (1, 2), {"a": "b"})
        print(f"Clé de cache générée: {cache_key}")

        # Vérifier que la clé n'est pas dans le cache
        cached_value = CacheManager.get_from_memory_cache(cache_key)
        if cached_value is not None:
            print("ÉCHEC: La clé est déjà dans le cache.")
            return False

        # Ajouter une valeur au cache
        test_value = {"result": "test_value"}
        CacheManager.set_in_memory_cache(cache_key, test_value, ttl=5)

        # Vérifier que la valeur est dans le cache
        cached_value = CacheManager.get_from_memory_cache(cache_key)
        if cached_value is None or cached_value["result"] != "test_value":
            print("ÉCHEC: La valeur n'a pas été mise en cache correctement.")
            return False

        print("Valeur récupérée du cache en mémoire avec succès.")

        # Test 2: Cache sur disque
        print("\nTest 2: Cache sur disque")

        # Générer une clé de cache
        cache_key = CacheManager.get_cache_key("test_disk_func", (3, 4), {"c": "d"})
        print(f"Clé de cache générée: {cache_key}")

        # Vérifier que la clé n'est pas dans le cache
        cached_value = CacheManager.get_from_disk_cache(cache_key)
        if cached_value is not None:
            print("ÉCHEC: La clé est déjà dans le cache.")
            return False

        # Ajouter une valeur au cache
        test_value = {"result": "disk_value"}
        CacheManager.set_in_disk_cache(cache_key, test_value, ttl=5)

        # Vérifier que la valeur est dans le cache
        cached_value = CacheManager.get_from_disk_cache(cache_key)
        if cached_value is None or cached_value["result"] != "disk_value":
            print("ÉCHEC: La valeur n'a pas été mise en cache sur disque correctement.")
            return False

        print("Valeur récupérée du cache sur disque avec succès.")

        # Test 3: Décorateur @cached
        print("\nTest 3: Décorateur @cached")

        # Compteur d'appels
        call_count = [0]

        # Fonction de test avec cache
        @cached(ttl_memory=5, ttl_disk=10)
        def test_func(a, b):
            call_count[0] += 1
            return {"result": a + b}

        # Premier appel (non mis en cache)
        result1 = test_func(5, 6)
        if result1["result"] != 11 or call_count[0] != 1:
            print("ÉCHEC: La fonction n'a pas été exécutée correctement.")
            return False

        # Deuxième appel (depuis le cache mémoire)
        result2 = test_func(5, 6)
        if result2["result"] != 11 or call_count[0] != 1:
            print("ÉCHEC: La fonction a été exécutée à nouveau au lieu d'utiliser le cache.")
            return False

        print("Décorateur @cached fonctionne correctement.")

        # Test 4: Expiration du cache
        print("\nTest 4: Expiration du cache")

        # Ajouter une valeur au cache avec une courte durée de vie
        cache_key = CacheManager.get_cache_key("test_expiration", (), {})
        CacheManager.set_in_memory_cache(cache_key, "expiring_value", ttl=1)

        # Vérifier que la valeur est dans le cache
        cached_value = CacheManager.get_from_memory_cache(cache_key)
        if cached_value != "expiring_value":
            print("ÉCHEC: La valeur n'a pas été mise en cache correctement.")
            return False

        # Attendre que la valeur expire
        print("Attente de l'expiration du cache (2 secondes)...")
        time.sleep(2)

        # Vérifier que la valeur a expiré
        cached_value = CacheManager.get_from_memory_cache(cache_key)
        if cached_value is not None:
            print("ÉCHEC: La valeur n'a pas expiré.")
            return False

        print("Expiration du cache fonctionne correctement.")

        # Test 5: Mise en cache dans l'attribution thématique
        print("\nTest 5: Mise en cache dans l'attribution thématique")

        # Créer un attributeur de thèmes
        theme_attributor = ThemeAttributor()

        # Contenu de test
        content = "Ce document décrit l'architecture du système."

        # Premier appel (non mis en cache)
        start_time = time.time()
        themes1 = theme_attributor.attribute_theme(content)
        first_call_time = time.time() - start_time

        # Deuxième appel (depuis le cache)
        start_time = time.time()
        themes2 = theme_attributor.attribute_theme(content)
        second_call_time = time.time() - start_time

        # Vérifier que les résultats sont identiques
        if themes1 != themes2:
            print("ÉCHEC: Les résultats mis en cache sont différents.")
            return False

        # Vérifier que le deuxième appel est plus rapide
        print(f"Temps du premier appel: {first_call_time:.6f} secondes")
        print(f"Temps du deuxième appel: {second_call_time:.6f} secondes")

        if second_call_time >= first_call_time:
            print("AVERTISSEMENT: Le deuxième appel n'est pas plus rapide que le premier.")
        elif second_call_time > 0:
            print(f"Accélération: {first_call_time / second_call_time:.2f}x")
        else:
            print("Accélération: infinie (temps du deuxième appel trop court pour être mesuré)")

        # Test 6: Nettoyage du cache
        print("\nTest 6: Nettoyage du cache")

        # Ajouter des valeurs aux caches
        CacheManager.set_in_memory_cache("memory_key", "memory_value")
        CacheManager.set_in_disk_cache("disk_key", "disk_value")

        # Vider le cache en mémoire
        CacheManager.clear_memory_cache()

        # Vérifier que le cache en mémoire est vide
        cached_value = CacheManager.get_from_memory_cache("memory_key")
        if cached_value is not None:
            print("ÉCHEC: Le cache en mémoire n'a pas été vidé.")
            return False

        # Vérifier que le cache sur disque est toujours présent
        cached_value = CacheManager.get_from_disk_cache("disk_key")
        if cached_value is None:
            print("ÉCHEC: Le cache sur disque a été vidé par erreur.")
            return False

        # Vider tous les caches
        CacheManager.clear_all_cache()

        # Vérifier que le cache sur disque est vide
        cached_value = CacheManager.get_from_disk_cache("disk_key")
        if cached_value is not None:
            print("ÉCHEC: Le cache sur disque n'a pas été vidé.")
            return False

        print("Nettoyage du cache fonctionne correctement.")

        print("\nTous les tests ont réussi!")
        return True

    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return False

    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    success = run_cache_tests()
    sys.exit(0 if success else 1)
