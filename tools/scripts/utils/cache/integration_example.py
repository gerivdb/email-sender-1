#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'intégration du cache dans l'application.

Ce script montre comment utiliser les différentes fonctionnalités de cache
dans différents scénarios d'utilisation.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import json
import random
from pathlib import Path
from typing import Dict, List, Any, Optional

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent))

# Importer les modules de cache
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.integration import (
    get_cache_manager, cached_function, cached_http_request,
    cached_n8n_workflow, invalidate_cache, clear_all_caches,
    get_cache_statistics
)


def exemple_fonction_couteuse():
    """Exemple d'utilisation du cache pour une fonction coûteuse."""
    print("\n=== Exemple d'utilisation du cache pour une fonction coûteuse ===")
    
    # Définir une fonction coûteuse
    @cached_function(ttl=60)
    def fonction_couteuse(param1, param2):
        print(f"Exécution de la fonction coûteuse avec param1={param1}, param2={param2}")
        # Simuler un traitement coûteux
        time.sleep(1)
        return f"{param1}_{param2}".upper()
    
    # Premier appel (exécute la fonction)
    start_time = time.time()
    result1 = fonction_couteuse("test", "abc")
    elapsed1 = time.time() - start_time
    print(f"Premier appel: {result1} (temps: {elapsed1:.2f}s)")
    
    # Deuxième appel avec les mêmes paramètres (utilise le cache)
    start_time = time.time()
    result2 = fonction_couteuse("test", "abc")
    elapsed2 = time.time() - start_time
    print(f"Deuxième appel: {result2} (temps: {elapsed2:.2f}s)")
    
    # Troisième appel avec des paramètres différents (exécute la fonction)
    start_time = time.time()
    result3 = fonction_couteuse("test", "xyz")
    elapsed3 = time.time() - start_time
    print(f"Troisième appel: {result3} (temps: {elapsed3:.2f}s)")
    
    # Invalider le cache
    print("Invalidation du cache...")
    # Récupérer la clé de cache (pour l'exemple)
    cache_key = fonction_couteuse.get_cache_key("test", "abc")
    invalidate_cache(cache_key)
    
    # Quatrième appel (exécute à nouveau la fonction)
    start_time = time.time()
    result4 = fonction_couteuse("test", "abc")
    elapsed4 = time.time() - start_time
    print(f"Quatrième appel: {result4} (temps: {elapsed4:.2f}s)")


def exemple_requete_http():
    """Exemple d'utilisation du cache pour les requêtes HTTP."""
    print("\n=== Exemple d'utilisation du cache pour les requêtes HTTP ===")
    
    # Récupérer l'adaptateur HTTP
    cache_manager = get_cache_manager()
    http_adapter = cache_manager.get_http_adapter()
    
    # Première requête (exécute la requête)
    print("Première requête...")
    start_time = time.time()
    response1 = http_adapter.get("https://jsonplaceholder.typicode.com/todos/1")
    elapsed1 = time.time() - start_time
    print(f"Réponse: {response1.json()} (temps: {elapsed1:.2f}s)")
    
    # Deuxième requête (utilise le cache)
    print("Deuxième requête (utilise le cache)...")
    start_time = time.time()
    response2 = http_adapter.get("https://jsonplaceholder.typicode.com/todos/1")
    elapsed2 = time.time() - start_time
    print(f"Réponse: {response2.json()} (temps: {elapsed2:.2f}s)")
    
    # Troisième requête avec force_refresh=True (exécute à nouveau la requête)
    print("Troisième requête (force_refresh=True)...")
    start_time = time.time()
    response3 = http_adapter.get("https://jsonplaceholder.typicode.com/todos/1", force_refresh=True)
    elapsed3 = time.time() - start_time
    print(f"Réponse: {response3.json()} (temps: {elapsed3:.2f}s)")
    
    # Utiliser la fonction utilitaire cached_http_request
    print("Utilisation de cached_http_request...")
    start_time = time.time()
    response4 = cached_http_request("GET", "https://jsonplaceholder.typicode.com/todos/2")
    elapsed4 = time.time() - start_time
    print(f"Réponse: {response4.json()} (temps: {elapsed4:.2f}s)")
    
    # Deuxième appel à cached_http_request (utilise le cache)
    print("Deuxième appel à cached_http_request (utilise le cache)...")
    start_time = time.time()
    response5 = cached_http_request("GET", "https://jsonplaceholder.typicode.com/todos/2")
    elapsed5 = time.time() - start_time
    print(f"Réponse: {response5.json()} (temps: {elapsed5:.2f}s)")


def exemple_classe_avec_cache():
    """Exemple d'utilisation du cache pour une classe."""
    print("\n=== Exemple d'utilisation du cache pour une classe ===")
    
    # Récupérer le gestionnaire de cache
    cache_manager = get_cache_manager()
    
    # Définir une classe avec des méthodes mises en cache
    class ExempleClasse:
        def __init__(self, name):
            self.name = name
            print(f"Initialisation de ExempleClasse avec name={name}")
        
        @cache_manager.cached(ttl=60)
        def methode_couteuse(self, param):
            print(f"Exécution de methode_couteuse pour {self.name} avec param={param}")
            # Simuler un traitement coûteux
            time.sleep(1)
            return f"{self.name}_{param}".upper()
        
        @cache_manager.cached_property(ttl=60)
        def propriete_couteuse(self):
            print(f"Calcul de propriete_couteuse pour {self.name}")
            # Simuler un traitement coûteux
            time.sleep(1)
            return f"{self.name}_PROP".upper()
    
    # Créer une instance de la classe
    instance = ExempleClasse("test")
    
    # Premier appel à la méthode (exécute la méthode)
    start_time = time.time()
    result1 = instance.methode_couteuse("abc")
    elapsed1 = time.time() - start_time
    print(f"Premier appel à methode_couteuse: {result1} (temps: {elapsed1:.2f}s)")
    
    # Deuxième appel à la méthode (utilise le cache)
    start_time = time.time()
    result2 = instance.methode_couteuse("abc")
    elapsed2 = time.time() - start_time
    print(f"Deuxième appel à methode_couteuse: {result2} (temps: {elapsed2:.2f}s)")
    
    # Premier accès à la propriété (exécute le calcul)
    start_time = time.time()
    result3 = instance.propriete_couteuse
    elapsed3 = time.time() - start_time
    print(f"Premier accès à propriete_couteuse: {result3} (temps: {elapsed3:.2f}s)")
    
    # Deuxième accès à la propriété (utilise le cache)
    start_time = time.time()
    result4 = instance.propriete_couteuse
    elapsed4 = time.time() - start_time
    print(f"Deuxième accès à propriete_couteuse: {result4} (temps: {elapsed4:.2f}s)")
    
    # Créer une deuxième instance avec le même nom
    instance2 = ExempleClasse("test")
    
    # Appel à la méthode sur la deuxième instance (utilise le cache)
    start_time = time.time()
    result5 = instance2.methode_couteuse("abc")
    elapsed5 = time.time() - start_time
    print(f"Appel à methode_couteuse sur instance2: {result5} (temps: {elapsed5:.2f}s)")


def exemple_classe_mise_en_cache():
    """Exemple d'utilisation du cache pour les instances d'une classe."""
    print("\n=== Exemple d'utilisation du cache pour les instances d'une classe ===")
    
    # Récupérer le gestionnaire de cache
    cache_manager = get_cache_manager()
    
    # Définir une classe mise en cache
    @cache_manager.cached_class(ttl=60)
    class ClasseMiseEnCache:
        def __init__(self, name, value):
            self.name = name
            self.value = value
            print(f"Initialisation de ClasseMiseEnCache avec name={name}, value={value}")
            # Simuler un traitement coûteux
            time.sleep(1)
        
        def get_data(self):
            return f"{self.name}_{self.value}".upper()
    
    # Première création d'instance (exécute le constructeur)
    print("Première création d'instance...")
    start_time = time.time()
    instance1 = ClasseMiseEnCache.get_instance("test", 123)
    elapsed1 = time.time() - start_time
    print(f"Instance créée: {instance1.get_data()} (temps: {elapsed1:.2f}s)")
    
    # Deuxième création d'instance avec les mêmes paramètres (utilise le cache)
    print("Deuxième création d'instance (utilise le cache)...")
    start_time = time.time()
    instance2 = ClasseMiseEnCache.get_instance("test", 123)
    elapsed2 = time.time() - start_time
    print(f"Instance récupérée: {instance2.get_data()} (temps: {elapsed2:.2f}s)")
    
    # Troisième création d'instance avec des paramètres différents (exécute le constructeur)
    print("Troisième création d'instance avec des paramètres différents...")
    start_time = time.time()
    instance3 = ClasseMiseEnCache.get_instance("test", 456)
    elapsed3 = time.time() - start_time
    print(f"Instance créée: {instance3.get_data()} (temps: {elapsed3:.2f}s)")
    
    # Invalider le cache pour la première instance
    print("Invalidation du cache pour la première instance...")
    instance1.invalidate_cache()
    
    # Quatrième création d'instance (exécute à nouveau le constructeur)
    print("Quatrième création d'instance après invalidation...")
    start_time = time.time()
    instance4 = ClasseMiseEnCache.get_instance("test", 123)
    elapsed4 = time.time() - start_time
    print(f"Instance créée: {instance4.get_data()} (temps: {elapsed4:.2f}s)")


def exemple_n8n_workflow():
    """Exemple d'utilisation du cache pour les workflows n8n."""
    print("\n=== Exemple d'utilisation du cache pour les workflows n8n ===")
    
    # Récupérer l'adaptateur n8n
    cache_manager = get_cache_manager()
    n8n_adapter = cache_manager.get_n8n_adapter()
    
    # Simuler l'exécution d'un workflow n8n
    # Note: Ceci est une simulation car nous n'avons pas accès à un serveur n8n réel
    def simuler_execution_workflow(workflow_id, payload):
        print(f"Simulation de l'exécution du workflow {workflow_id} avec payload {payload}")
        # Simuler un traitement coûteux
        time.sleep(2)
        return {
            "success": True,
            "data": {
                "result": f"Résultat du workflow {workflow_id}",
                "input": payload,
                "timestamp": time.time()
            }
        }
    
    # Remplacer la méthode d'exécution de l'adaptateur n8n par notre simulation
    n8n_adapter._execute_workflow = simuler_execution_workflow
    
    # Premier appel (exécute le workflow)
    print("Premier appel...")
    start_time = time.time()
    result1 = n8n_adapter.execute_workflow("workflow1", {"param": "value1"})
    elapsed1 = time.time() - start_time
    print(f"Résultat: {result1} (temps: {elapsed1:.2f}s)")
    
    # Deuxième appel avec les mêmes paramètres (utilise le cache)
    print("Deuxième appel (utilise le cache)...")
    start_time = time.time()
    result2 = n8n_adapter.execute_workflow("workflow1", {"param": "value1"})
    elapsed2 = time.time() - start_time
    print(f"Résultat: {result2} (temps: {elapsed2:.2f}s)")
    
    # Troisième appel avec des paramètres différents (exécute le workflow)
    print("Troisième appel avec des paramètres différents...")
    start_time = time.time()
    result3 = n8n_adapter.execute_workflow("workflow1", {"param": "value2"})
    elapsed3 = time.time() - start_time
    print(f"Résultat: {result3} (temps: {elapsed3:.2f}s)")
    
    # Quatrième appel avec force_refresh=True (exécute à nouveau le workflow)
    print("Quatrième appel avec force_refresh=True...")
    start_time = time.time()
    result4 = n8n_adapter.execute_workflow("workflow1", {"param": "value1"}, force_refresh=True)
    elapsed4 = time.time() - start_time
    print(f"Résultat: {result4} (temps: {elapsed4:.2f}s)")
    
    # Utiliser la fonction utilitaire cached_n8n_workflow
    print("Utilisation de cached_n8n_workflow...")
    start_time = time.time()
    result5 = cached_n8n_workflow("workflow2", {"param": "value1"})
    elapsed5 = time.time() - start_time
    print(f"Résultat: {result5} (temps: {elapsed5:.2f}s)")
    
    # Deuxième appel à cached_n8n_workflow (utilise le cache)
    print("Deuxième appel à cached_n8n_workflow (utilise le cache)...")
    start_time = time.time()
    result6 = cached_n8n_workflow("workflow2", {"param": "value1"})
    elapsed6 = time.time() - start_time
    print(f"Résultat: {result6} (temps: {elapsed6:.2f}s)")


def exemple_statistiques_cache():
    """Exemple d'utilisation des statistiques du cache."""
    print("\n=== Exemple d'utilisation des statistiques du cache ===")
    
    # Vider le cache
    clear_all_caches()
    
    # Récupérer le gestionnaire de cache
    cache_manager = get_cache_manager()
    cache = cache_manager.get_cache()
    
    # Ajouter des données au cache
    for i in range(100):
        cache.set(f"key{i}", f"value{i}")
    
    # Accéder à certaines clés
    for i in range(50):
        cache.get(f"key{i}")
    
    # Accéder à des clés inexistantes
    for i in range(100, 120):
        cache.get(f"key{i}")
    
    # Supprimer certaines clés
    for i in range(20):
        cache.delete(f"key{i}")
    
    # Récupérer les statistiques
    stats = get_cache_statistics()
    
    # Afficher les statistiques
    print("Statistiques du cache:")
    for key, value in stats.items():
        print(f"  {key}: {value}")


def nettoyer():
    """Nettoie les fichiers temporaires."""
    print("\n=== Nettoyage ===")
    
    # Vider le cache
    clear_all_caches()
    print("Cache vidé.")


def main():
    """Fonction principale."""
    print("=== Exemples d'intégration du cache dans l'application ===")
    
    # Exécuter les exemples
    exemple_fonction_couteuse()
    exemple_requete_http()
    exemple_classe_avec_cache()
    exemple_classe_mise_en_cache()
    exemple_n8n_workflow()
    exemple_statistiques_cache()
    
    # Nettoyer
    nettoyer()
    
    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
