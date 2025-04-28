#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'exemple pour l'adaptateur de cache HTTP.

Ce script montre comment utiliser l'adaptateur de cache HTTP
pour mettre en cache les résultats des requêtes HTTP.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter, create_http_adapter_from_config


def exemple_basique():
    """Exemple d'utilisation basique de l'adaptateur HTTP."""
    print("\n=== Exemple d'utilisation basique de l'adaptateur HTTP ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Effectuer une requête GET
    url = "https://httpbin.org/get"
    print(f"Effectuer une requête GET vers {url}...")
    
    # Première requête (mise en cache)
    debut = time.time()
    response1 = adapter.get(url)
    duree1 = time.time() - debut
    
    print(f"Première requête: {response1.status_code} {response1.reason}")
    print(f"Durée: {duree1:.2f}s")
    print(f"Taille de la réponse: {len(response1.content)} octets")
    print(f"Depuis le cache: {getattr(response1, 'from_cache', False)}")
    
    # Deuxième requête (depuis le cache)
    debut = time.time()
    response2 = adapter.get(url)
    duree2 = time.time() - debut
    
    print(f"\nDeuxième requête: {response2.status_code} {response2.reason}")
    print(f"Durée: {duree2:.2f}s")
    print(f"Taille de la réponse: {len(response2.content)} octets")
    print(f"Depuis le cache: {getattr(response2, 'from_cache', False)}")
    
    # Troisième requête (force_refresh=True)
    debut = time.time()
    response3 = adapter.get(url, force_refresh=True)
    duree3 = time.time() - debut
    
    print(f"\nTroisième requête (force_refresh=True): {response3.status_code} {response3.reason}")
    print(f"Durée: {duree3:.2f}s")
    print(f"Taille de la réponse: {len(response3.content)} octets")
    print(f"Depuis le cache: {getattr(response3, 'from_cache', False)}")
    
    # Afficher les statistiques
    stats = adapter.get_statistics()
    print(f"\nStatistiques du cache: {stats}")


def exemple_avec_parametres():
    """Exemple d'utilisation avec des paramètres de requête."""
    print("\n=== Exemple d'utilisation avec des paramètres de requête ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Effectuer une requête GET avec des paramètres
    url = "https://httpbin.org/get"
    params = {"param1": "value1", "param2": "value2"}
    
    print(f"Effectuer une requête GET vers {url} avec params={params}...")
    
    # Première requête (mise en cache)
    debut = time.time()
    response1 = adapter.get(url, params=params)
    duree1 = time.time() - debut
    
    print(f"Première requête: {response1.status_code} {response1.reason}")
    print(f"Durée: {duree1:.2f}s")
    print(f"Depuis le cache: {getattr(response1, 'from_cache', False)}")
    
    # Deuxième requête avec les mêmes paramètres (depuis le cache)
    debut = time.time()
    response2 = adapter.get(url, params=params)
    duree2 = time.time() - debut
    
    print(f"\nDeuxième requête (mêmes paramètres): {response2.status_code} {response2.reason}")
    print(f"Durée: {duree2:.2f}s")
    print(f"Depuis le cache: {getattr(response2, 'from_cache', False)}")
    
    # Troisième requête avec des paramètres différents (nouvelle requête)
    params2 = {"param1": "value1", "param2": "value3"}
    debut = time.time()
    response3 = adapter.get(url, params=params2)
    duree3 = time.time() - debut
    
    print(f"\nTroisième requête (paramètres différents): {response3.status_code} {response3.reason}")
    print(f"Durée: {duree3:.2f}s")
    print(f"Depuis le cache: {getattr(response3, 'from_cache', False)}")


def exemple_avec_configuration():
    """Exemple d'utilisation avec un fichier de configuration."""
    print("\n=== Exemple d'utilisation avec un fichier de configuration ===")
    
    # Chemin vers le fichier de configuration
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    
    # Créer une instance de l'adaptateur HTTP à partir de la configuration
    adapter = create_http_adapter_from_config(config_path)
    
    # Afficher la configuration
    print("Configuration chargée:")
    for key, value in adapter.config.items():
        print(f"  {key}: {value}")
    
    # Effectuer une requête GET
    url = "https://httpbin.org/get"
    print(f"\nEffectuer une requête GET vers {url}...")
    
    # Première requête (mise en cache)
    debut = time.time()
    response = adapter.get(url)
    duree = time.time() - debut
    
    print(f"Requête: {response.status_code} {response.reason}")
    print(f"Durée: {duree:.2f}s")
    print(f"Depuis le cache: {getattr(response, 'from_cache', False)}")


def exemple_methodes_http():
    """Exemple d'utilisation avec différentes méthodes HTTP."""
    print("\n=== Exemple d'utilisation avec différentes méthodes HTTP ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Effectuer une requête GET
    url = "https://httpbin.org/get"
    print(f"Effectuer une requête GET vers {url}...")
    response = adapter.get(url)
    print(f"GET: {response.status_code} {response.reason}")
    print(f"Depuis le cache: {getattr(response, 'from_cache', False)}")
    
    # Effectuer une requête POST
    url = "https://httpbin.org/post"
    data = {"key1": "value1", "key2": "value2"}
    print(f"\nEffectuer une requête POST vers {url}...")
    response = adapter.post(url, json=data)
    print(f"POST: {response.status_code} {response.reason}")
    print(f"Depuis le cache: {getattr(response, 'from_cache', False)}")
    
    # Effectuer une requête PUT
    url = "https://httpbin.org/put"
    data = {"key1": "value1", "key2": "value2"}
    print(f"\nEffectuer une requête PUT vers {url}...")
    response = adapter.put(url, json=data)
    print(f"PUT: {response.status_code} {response.reason}")
    print(f"Depuis le cache: {getattr(response, 'from_cache', False)}")
    
    # Effectuer une requête DELETE
    url = "https://httpbin.org/delete"
    print(f"\nEffectuer une requête DELETE vers {url}...")
    response = adapter.delete(url)
    print(f"DELETE: {response.status_code} {response.reason}")
    print(f"Depuis le cache: {getattr(response, 'from_cache', False)}")


def exemple_invalidation():
    """Exemple d'invalidation du cache."""
    print("\n=== Exemple d'invalidation du cache ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Effectuer une requête GET
    url = "https://httpbin.org/get"
    print(f"Effectuer une requête GET vers {url}...")
    
    # Première requête (mise en cache)
    response1 = adapter.get(url)
    print(f"Première requête: {response1.status_code} {response1.reason}")
    print(f"Depuis le cache: {getattr(response1, 'from_cache', False)}")
    
    # Deuxième requête (depuis le cache)
    response2 = adapter.get(url)
    print(f"\nDeuxième requête: {response2.status_code} {response2.reason}")
    print(f"Depuis le cache: {getattr(response2, 'from_cache', False)}")
    
    # Invalider le cache
    print("\nInvalidation du cache...")
    adapter.invalidate_url(url)
    
    # Troisième requête (après invalidation)
    response3 = adapter.get(url)
    print(f"\nTroisième requête (après invalidation): {response3.status_code} {response3.reason}")
    print(f"Depuis le cache: {getattr(response3, 'from_cache', False)}")


def exemple_decorateur():
    """Exemple d'utilisation du décorateur cached."""
    print("\n=== Exemple d'utilisation du décorateur cached ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Définir une fonction qui effectue une requête HTTP
    @adapter.cached(ttl=60)
    def get_data(url, params=None):
        print(f"Exécution de la fonction get_data({url}, {params})")
        return adapter.get(url, params=params).json()
    
    # Appeler la fonction plusieurs fois
    url = "https://httpbin.org/get"
    
    print(f"Premier appel à get_data({url})...")
    data1 = get_data(url)
    print(f"Résultat: {type(data1)}")
    
    print(f"\nDeuxième appel à get_data({url})...")
    data2 = get_data(url)
    print(f"Résultat: {type(data2)}")
    
    print(f"\nTroisième appel à get_data({url}, params={{'q': 'test'}})...")
    data3 = get_data(url, params={"q": "test"})
    print(f"Résultat: {type(data3)}")


def nettoyer():
    """Nettoie les fichiers de cache."""
    print("\n=== Nettoyage ===")
    
    # Créer une instance de l'adaptateur HTTP
    adapter = HttpCacheAdapter()
    
    # Vider le cache
    adapter.clear()
    print("Cache vidé.")


def main():
    """Fonction principale."""
    print("=== Exemples d'utilisation de l'adaptateur de cache HTTP ===")
    
    # Exécuter les exemples
    exemple_basique()
    exemple_avec_parametres()
    exemple_avec_configuration()
    exemple_methodes_http()
    exemple_invalidation()
    exemple_decorateur()
    
    # Nettoyer
    nettoyer()
    
    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
