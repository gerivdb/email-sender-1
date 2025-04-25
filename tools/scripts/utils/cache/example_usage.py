#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation du module LocalCache.

Ce script montre comment utiliser le module LocalCache
dans différents scénarios d'utilisation.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))
from scripts.utils.cache.local_cache import LocalCache, create_cache_from_config


def exemple_basique():
    """Exemple d'utilisation basique du cache."""
    print("\n=== Exemple d'utilisation basique ===")
    
    # Créer une instance avec les paramètres par défaut
    cache = LocalCache(cache_dir='exemple_cache')
    
    # Stocker une valeur
    cache.set("ma_cle", "ma_valeur")
    print("Valeur stockée: ma_cle -> ma_valeur")
    
    # Récupérer une valeur
    valeur = cache.get("ma_cle")
    print(f"Valeur récupérée: {valeur}")
    
    # Récupérer une valeur inexistante
    valeur = cache.get("cle_inexistante", "valeur_par_defaut")
    print(f"Valeur inexistante avec défaut: {valeur}")
    
    # Supprimer une valeur
    cache.delete("ma_cle")
    print("Valeur supprimée")
    
    # Vérifier que la valeur a été supprimée
    valeur = cache.get("ma_cle")
    print(f"Après suppression: {valeur}")
    
    # Afficher les statistiques
    stats = cache.get_statistics()
    print(f"Statistiques: {stats}")
    
    # Fermer le cache
    cache.cache.close()


def exemple_ttl():
    """Exemple d'utilisation avec TTL."""
    print("\n=== Exemple d'utilisation avec TTL ===")
    
    # Créer une instance
    cache = LocalCache(cache_dir='exemple_cache')
    
    # Stocker une valeur avec un TTL court
    cache.set("cle_temporaire", "valeur_temporaire", ttl=2)
    print("Valeur stockée avec TTL de 2 secondes")
    
    # Récupérer la valeur immédiatement
    valeur = cache.get("cle_temporaire")
    print(f"Valeur récupérée immédiatement: {valeur}")
    
    # Attendre l'expiration
    print("Attente de l'expiration (2 secondes)...")
    time.sleep(2.1)
    
    # Récupérer la valeur après expiration
    valeur = cache.get("cle_temporaire")
    print(f"Valeur après expiration: {valeur}")
    
    # Fermer le cache
    cache.cache.close()


def exemple_memoisation():
    """Exemple d'utilisation de la mémoïsation."""
    print("\n=== Exemple d'utilisation de la mémoïsation ===")
    
    # Créer une instance
    cache = LocalCache(cache_dir='exemple_cache')
    
    # Définir une fonction coûteuse
    @cache.memoize(ttl=60)
    def fonction_couteuse(param):
        print(f"Exécution de la fonction coûteuse avec param={param}")
        # Simuler un traitement long
        time.sleep(1)
        return param.upper()
    
    # Premier appel (exécute la fonction)
    print("Premier appel:")
    debut = time.time()
    resultat1 = fonction_couteuse("test")
    duree1 = time.time() - debut
    print(f"Résultat: {resultat1}, Durée: {duree1:.2f}s")
    
    # Deuxième appel (utilise le cache)
    print("\nDeuxième appel (même paramètre):")
    debut = time.time()
    resultat2 = fonction_couteuse("test")
    duree2 = time.time() - debut
    print(f"Résultat: {resultat2}, Durée: {duree2:.2f}s")
    
    # Troisième appel (paramètre différent)
    print("\nTroisième appel (paramètre différent):")
    debut = time.time()
    resultat3 = fonction_couteuse("autre")
    duree3 = time.time() - debut
    print(f"Résultat: {resultat3}, Durée: {duree3:.2f}s")
    
    # Afficher les statistiques
    stats = cache.get_statistics()
    print(f"\nStatistiques: {stats}")
    
    # Fermer le cache
    cache.cache.close()


def exemple_configuration():
    """Exemple d'utilisation avec un fichier de configuration."""
    print("\n=== Exemple d'utilisation avec configuration ===")
    
    # Créer un fichier de configuration temporaire
    config = {
        "DefaultTTL": 1800,
        "MaxDiskSize": 500,
        "CachePath": "exemple_cache_config",
        "EvictionPolicy": "LRU"
    }
    
    config_path = "exemple_config.json"
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config, f)
    
    print(f"Fichier de configuration créé: {config_path}")
    print(f"Contenu: {json.dumps(config, indent=2)}")
    
    # Créer une instance à partir du fichier de configuration
    cache = create_cache_from_config(config_path)
    
    # Afficher la configuration
    print(f"\nConfiguration chargée:")
    for key, value in cache.config.items():
        print(f"  {key}: {value}")
    
    # Utiliser le cache
    cache.set("cle_config", "valeur_config")
    valeur = cache.get("cle_config")
    print(f"\nValeur récupérée: {valeur}")
    
    # Fermer le cache
    cache.cache.close()
    
    # Supprimer le fichier de configuration
    os.remove(config_path)
    print(f"Fichier de configuration supprimé")


def exemple_gestionnaire_contexte():
    """Exemple d'utilisation comme gestionnaire de contexte."""
    print("\n=== Exemple d'utilisation comme gestionnaire de contexte ===")
    
    # Utiliser avec with
    with LocalCache(cache_dir='exemple_cache') as cache:
        # Stocker une valeur
        cache.set("cle_contexte", "valeur_contexte")
        print("Valeur stockée dans le bloc with")
        
        # Récupérer la valeur
        valeur = cache.get("cle_contexte")
        print(f"Valeur récupérée dans le bloc with: {valeur}")
        
        # Afficher les statistiques
        stats = cache.get_statistics()
        print(f"Statistiques: {stats}")
    
    print("Sortie du bloc with (cache automatiquement fermé)")


def nettoyer():
    """Nettoie les fichiers d'exemple."""
    print("\n=== Nettoyage ===")
    
    # Supprimer les répertoires de cache d'exemple
    import shutil
    
    for dir_name in ['exemple_cache', 'exemple_cache_config']:
        if os.path.exists(dir_name):
            shutil.rmtree(dir_name)
            print(f"Répertoire supprimé: {dir_name}")


def main():
    """Fonction principale."""
    print("=== Exemples d'utilisation du module LocalCache ===")
    
    # Exécuter les exemples
    exemple_basique()
    exemple_ttl()
    exemple_memoisation()
    exemple_configuration()
    exemple_gestionnaire_contexte()
    
    # Nettoyer
    nettoyer()
    
    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
