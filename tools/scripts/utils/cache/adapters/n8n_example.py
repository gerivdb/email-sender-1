#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'exemple pour l'adaptateur de cache n8n.

Ce script montre comment utiliser l'adaptateur de cache n8n
pour mettre en cache les résultats des requêtes à l'API n8n.

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
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter, create_n8n_adapter_from_config


def exemple_basique():
    """Exemple d'utilisation basique de l'adaptateur n8n."""
    print("\n=== Exemple d'utilisation basique de l'adaptateur n8n ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    # Afficher la configuration
    print("Configuration de l'adaptateur n8n:")
    print(f"  API URL: {adapter.config['api_url']}")
    print(f"  API Key: {'*****' if adapter.config['api_key'] else 'Non définie'}")
    print(f"  Default TTL: {adapter.config['default_ttl']} secondes")
    
    try:
        # Récupérer la liste des workflows
        print("\nRécupération de la liste des workflows...")
        
        # Première requête (mise en cache)
        debut = time.time()
        workflows1 = adapter.get_workflows()
        duree1 = time.time() - debut
        
        print(f"Première requête: {len(workflows1)} workflows récupérés")
        print(f"Durée: {duree1:.2f}s")
        
        # Deuxième requête (depuis le cache)
        debut = time.time()
        workflows2 = adapter.get_workflows()
        duree2 = time.time() - debut
        
        print(f"\nDeuxième requête: {len(workflows2)} workflows récupérés")
        print(f"Durée: {duree2:.2f}s")
        
        # Troisième requête (force_refresh=True)
        debut = time.time()
        workflows3 = adapter.get_workflows(force_refresh=True)
        duree3 = time.time() - debut
        
        print(f"\nTroisième requête (force_refresh=True): {len(workflows3)} workflows récupérés")
        print(f"Durée: {duree3:.2f}s")
        
        # Afficher les statistiques
        stats = adapter.get_statistics()
        print(f"\nStatistiques du cache: {stats}")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des workflows: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def exemple_avec_filtres():
    """Exemple d'utilisation avec des filtres."""
    print("\n=== Exemple d'utilisation avec des filtres ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    try:
        # Récupérer les workflows actifs
        print("Récupération des workflows actifs...")
        workflows_actifs = adapter.get_workflows(active=True)
        print(f"Workflows actifs: {len(workflows_actifs)}")
        
        # Récupérer les workflows avec un tag spécifique
        print("\nRécupération des workflows avec le tag 'email'...")
        workflows_email = adapter.get_workflows(tags=["email"])
        print(f"Workflows avec le tag 'email': {len(workflows_email)}")
        
        # Récupérer les workflows actifs avec un tag spécifique
        print("\nRécupération des workflows actifs avec le tag 'email'...")
        workflows_actifs_email = adapter.get_workflows(active=True, tags=["email"])
        print(f"Workflows actifs avec le tag 'email': {len(workflows_actifs_email)}")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des workflows: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def exemple_executions():
    """Exemple d'utilisation pour les exécutions."""
    print("\n=== Exemple d'utilisation pour les exécutions ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    try:
        # Récupérer les dernières exécutions
        print("Récupération des dernières exécutions...")
        executions = adapter.get_executions(limit=10)
        print(f"Dernières exécutions: {len(executions)}")
        
        if executions:
            # Afficher les détails de la première exécution
            execution = executions[0]
            print("\nDétails de la première exécution:")
            print(f"  ID: {execution.get('id')}")
            print(f"  Workflow ID: {execution.get('workflowId')}")
            print(f"  Status: {execution.get('status')}")
            print(f"  Started At: {execution.get('startedAt')}")
            print(f"  Finished At: {execution.get('finishedAt')}")
        
        # Récupérer les exécutions réussies
        print("\nRécupération des exécutions réussies...")
        executions_success = adapter.get_executions(status="success", limit=5)
        print(f"Exécutions réussies: {len(executions_success)}")
        
        # Récupérer les exécutions en erreur
        print("\nRécupération des exécutions en erreur...")
        executions_error = adapter.get_executions(status="error", limit=5)
        print(f"Exécutions en erreur: {len(executions_error)}")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des exécutions: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def exemple_tags():
    """Exemple d'utilisation pour les tags."""
    print("\n=== Exemple d'utilisation pour les tags ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    try:
        # Récupérer la liste des tags
        print("Récupération de la liste des tags...")
        
        # Première requête (mise en cache)
        debut = time.time()
        tags1 = adapter.get_tags()
        duree1 = time.time() - debut
        
        print(f"Première requête: {len(tags1)} tags récupérés")
        print(f"Durée: {duree1:.2f}s")
        
        # Deuxième requête (depuis le cache)
        debut = time.time()
        tags2 = adapter.get_tags()
        duree2 = time.time() - debut
        
        print(f"\nDeuxième requête: {len(tags2)} tags récupérés")
        print(f"Durée: {duree2:.2f}s")
        
        # Afficher les tags
        if tags1:
            print("\nListe des tags:")
            for tag in tags1:
                print(f"  {tag.get('name')}")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des tags: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def exemple_invalidation():
    """Exemple d'invalidation du cache."""
    print("\n=== Exemple d'invalidation du cache ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    try:
        # Récupérer la liste des workflows (mise en cache)
        print("Récupération de la liste des workflows...")
        workflows1 = adapter.get_workflows()
        print(f"Première requête: {len(workflows1)} workflows récupérés")
        
        # Récupérer la liste des workflows (depuis le cache)
        workflows2 = adapter.get_workflows()
        print(f"Deuxième requête: {len(workflows2)} workflows récupérés")
        
        # Invalider le cache des workflows
        print("\nInvalidation du cache des workflows...")
        adapter.invalidate_workflows_cache()
        
        # Récupérer la liste des workflows (après invalidation)
        workflows3 = adapter.get_workflows()
        print(f"Troisième requête (après invalidation): {len(workflows3)} workflows récupérés")
        
        # Invalider tout le cache
        print("\nInvalidation de tout le cache...")
        adapter.invalidate_all_cache()
        
        # Récupérer la liste des workflows (après invalidation complète)
        workflows4 = adapter.get_workflows()
        print(f"Quatrième requête (après invalidation complète): {len(workflows4)} workflows récupérés")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des workflows: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def exemple_avec_configuration():
    """Exemple d'utilisation avec un fichier de configuration."""
    print("\n=== Exemple d'utilisation avec un fichier de configuration ===")
    
    # Chemin vers le fichier de configuration
    config_path = os.path.join(os.path.dirname(__file__), "config.json")
    
    # Créer une instance de l'adaptateur n8n à partir de la configuration
    adapter = create_n8n_adapter_from_config(config_path)
    
    # Afficher la configuration
    print("Configuration chargée:")
    for key, value in adapter.config.items():
        if key == "api_key" and value:
            print(f"  {key}: *****")
        else:
            print(f"  {key}: {value}")
    
    try:
        # Récupérer la liste des workflows
        print("\nRécupération de la liste des workflows...")
        workflows = adapter.get_workflows()
        print(f"Workflows récupérés: {len(workflows)}")
    
    except Exception as e:
        print(f"Erreur lors de la récupération des workflows: {e}")
        print("Assurez-vous que n8n est en cours d'exécution et que l'API est accessible.")


def nettoyer():
    """Nettoie les fichiers de cache."""
    print("\n=== Nettoyage ===")
    
    # Créer une instance de l'adaptateur n8n
    adapter = N8nCacheAdapter()
    
    # Vider le cache
    adapter.clear()
    print("Cache vidé.")


def main():
    """Fonction principale."""
    print("=== Exemples d'utilisation de l'adaptateur de cache n8n ===")
    
    # Exécuter les exemples
    exemple_basique()
    exemple_avec_filtres()
    exemple_executions()
    exemple_tags()
    exemple_invalidation()
    exemple_avec_configuration()
    
    # Nettoyer
    nettoyer()
    
    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
