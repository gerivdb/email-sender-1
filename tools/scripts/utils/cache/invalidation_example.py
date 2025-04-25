#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'exemple pour les mécanismes d'invalidation du cache.

Ce script montre comment utiliser les mécanismes d'invalidation du cache
pour maintenir la cohérence des données en cache.

Auteur: Augment Agent
Date: 2025-04-17
Version: 1.0
"""

import os
import sys
import time
import logging
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
from scripts.utils.cache.local_cache import LocalCache
from scripts.utils.cache.dependency_manager import DependencyManager, get_default_manager
from scripts.utils.cache.invalidation import CacheInvalidator, get_default_invalidator
from scripts.utils.cache.purge_scheduler import PurgeScheduler, get_default_scheduler

# Configurer le logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def exemple_invalidation_manuelle():
    """Exemple d'invalidation manuelle du cache."""
    print("\n=== Exemple d'invalidation manuelle du cache ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Créer une instance du gestionnaire de dépendances
    dependency_manager = get_default_manager()
    
    # Créer une instance de l'invalidateur de cache
    invalidator = CacheInvalidator(cache, dependency_manager)
    
    # Ajouter des données au cache
    cache.set("user:1", {"id": 1, "name": "John Doe", "email": "john@example.com"})
    cache.set("user:2", {"id": 2, "name": "Jane Smith", "email": "jane@example.com"})
    cache.set("user:3", {"id": 3, "name": "Bob Johnson", "email": "bob@example.com"})
    
    # Ajouter des dépendances
    dependency_manager.add_dependency("user:1", "user")
    dependency_manager.add_dependency("user:2", "user")
    dependency_manager.add_dependency("user:3", "user")
    
    # Ajouter des tags
    dependency_manager.add_tag("user:1", "admin")
    dependency_manager.add_tag("user:2", "user")
    dependency_manager.add_tag("user:3", "user")
    
    # Afficher les données du cache
    print("Données du cache:")
    print(f"  user:1 = {cache.get('user:1')}")
    print(f"  user:2 = {cache.get('user:2')}")
    print(f"  user:3 = {cache.get('user:3')}")
    
    # Invalider une clé spécifique
    print("\nInvalidation de la clé 'user:1'...")
    invalidator.invalidate_key("user:1")
    
    # Vérifier que la clé a été invalidée
    print("Données du cache après invalidation:")
    print(f"  user:1 = {cache.get('user:1')}")
    print(f"  user:2 = {cache.get('user:2')}")
    print(f"  user:3 = {cache.get('user:3')}")
    
    # Invalider par dépendance
    print("\nInvalidation par dépendance 'user'...")
    invalidator.invalidate_by_dependency("user")
    
    # Vérifier que les clés ont été invalidées
    print("Données du cache après invalidation par dépendance:")
    print(f"  user:1 = {cache.get('user:1')}")
    print(f"  user:2 = {cache.get('user:2')}")
    print(f"  user:3 = {cache.get('user:3')}")
    
    # Ajouter à nouveau des données au cache
    cache.set("user:1", {"id": 1, "name": "John Doe", "email": "john@example.com"})
    cache.set("user:2", {"id": 2, "name": "Jane Smith", "email": "jane@example.com"})
    cache.set("user:3", {"id": 3, "name": "Bob Johnson", "email": "bob@example.com"})
    
    # Ajouter à nouveau des tags
    dependency_manager.add_tag("user:1", "admin")
    dependency_manager.add_tag("user:2", "user")
    dependency_manager.add_tag("user:3", "user")
    
    # Invalider par tag
    print("\nInvalidation par tag 'admin'...")
    invalidator.invalidate_by_tag("admin")
    
    # Vérifier que les clés ont été invalidées
    print("Données du cache après invalidation par tag:")
    print(f"  user:1 = {cache.get('user:1')}")
    print(f"  user:2 = {cache.get('user:2')}")
    print(f"  user:3 = {cache.get('user:3')}")
    
    # Invalider par motif
    print("\nInvalidation par motif 'user:*'...")
    invalidator.invalidate_by_pattern("user:*")
    
    # Vérifier que les clés ont été invalidées
    print("Données du cache après invalidation par motif:")
    print(f"  user:1 = {cache.get('user:1')}")
    print(f"  user:2 = {cache.get('user:2')}")
    print(f"  user:3 = {cache.get('user:3')}")


def exemple_invalidation_ttl():
    """Exemple d'invalidation par TTL."""
    print("\n=== Exemple d'invalidation par TTL ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Ajouter des données au cache avec différents TTL
    cache.set("temp:1", "Donnée temporaire 1", ttl=2)  # 2 secondes
    cache.set("temp:2", "Donnée temporaire 2", ttl=5)  # 5 secondes
    cache.set("perm:1", "Donnée permanente 1")  # Pas de TTL
    
    # Afficher les données du cache
    print("Données du cache:")
    print(f"  temp:1 = {cache.get('temp:1')}")
    print(f"  temp:2 = {cache.get('temp:2')}")
    print(f"  perm:1 = {cache.get('perm:1')}")
    
    # Attendre que la première clé expire
    print("\nAttente de 3 secondes pour l'expiration de 'temp:1'...")
    time.sleep(3)
    
    # Vérifier que la première clé a expiré
    print("Données du cache après 3 secondes:")
    print(f"  temp:1 = {cache.get('temp:1')}")
    print(f"  temp:2 = {cache.get('temp:2')}")
    print(f"  perm:1 = {cache.get('perm:1')}")
    
    # Attendre que la deuxième clé expire
    print("\nAttente de 3 secondes supplémentaires pour l'expiration de 'temp:2'...")
    time.sleep(3)
    
    # Vérifier que la deuxième clé a expiré
    print("Données du cache après 6 secondes:")
    print(f"  temp:1 = {cache.get('temp:1')}")
    print(f"  temp:2 = {cache.get('temp:2')}")
    print(f"  perm:1 = {cache.get('perm:1')}")


def exemple_invalidation_programmee():
    """Exemple d'invalidation programmée."""
    print("\n=== Exemple d'invalidation programmée ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Créer une instance de l'invalidateur de cache
    invalidator = get_default_invalidator(cache)
    
    # Ajouter des données au cache
    cache.set("scheduled:1", "Donnée programmée 1")
    cache.set("scheduled:2", "Donnée programmée 2")
    cache.set("other:1", "Autre donnée 1")
    
    # Afficher les données du cache
    print("Données du cache:")
    print(f"  scheduled:1 = {cache.get('scheduled:1')}")
    print(f"  scheduled:2 = {cache.get('scheduled:2')}")
    print(f"  other:1 = {cache.get('other:1')}")
    
    # Planifier une invalidation par motif
    print("\nPlanification d'une invalidation pour le motif 'scheduled:*' dans 3 secondes...")
    invalidator.schedule_invalidation(3, invalidator.invalidate_by_pattern, "scheduled:*")
    
    # Attendre que l'invalidation se produise
    print("Attente de 4 secondes...")
    time.sleep(4)
    
    # Vérifier que les clés ont été invalidées
    print("Données du cache après invalidation programmée:")
    print(f"  scheduled:1 = {cache.get('scheduled:1')}")
    print(f"  scheduled:2 = {cache.get('scheduled:2')}")
    print(f"  other:1 = {cache.get('other:1')}")
    
    # Arrêter le planificateur
    invalidator.stop_scheduler()


def exemple_purge_scheduler():
    """Exemple d'utilisation du planificateur de purge."""
    print("\n=== Exemple d'utilisation du planificateur de purge ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Créer une instance de l'invalidateur de cache
    invalidator = get_default_invalidator(cache)
    
    # Créer une instance du planificateur de purge
    scheduler = PurgeScheduler(invalidator)
    
    # Configurer le planificateur
    scheduler.set_max_cache_size(1024 * 1024)  # 1 Mo
    scheduler.set_size_check_interval(60)  # 60 secondes
    scheduler.set_purge_expired_interval(30)  # 30 secondes
    
    # Ajouter des purges périodiques
    scheduler.add_pattern_purge("temp:*", 60)  # 60 secondes
    scheduler.add_tag_purge("temporary", 120)  # 120 secondes
    
    # Afficher la configuration
    print("Configuration du planificateur de purge:")
    print(f"  Activé: {scheduler.config['enabled']}")
    print(f"  Taille maximale du cache: {scheduler.config['max_cache_size']} octets")
    print(f"  Intervalle de vérification de la taille: {scheduler.config['size_check_interval']} secondes")
    print(f"  Intervalle de purge des clés expirées: {scheduler.config['purge_expired_interval']} secondes")
    print("  Purges périodiques par motif:")
    for pattern_config in scheduler.config["purge_patterns"]:
        print(f"    - {pattern_config['pattern']} (toutes les {pattern_config['interval']} secondes)")
    print("  Purges périodiques par tag:")
    for tag_config in scheduler.config["purge_tags"]:
        print(f"    - {tag_config['tag']} (toutes les {tag_config['interval']} secondes)")
    
    # Démarrer le planificateur
    print("\nDémarrage du planificateur de purge...")
    scheduler.start()
    
    # Ajouter des données au cache
    cache.set("temp:1", "Donnée temporaire 1")
    cache.set("temp:2", "Donnée temporaire 2")
    cache.set("perm:1", "Donnée permanente 1")
    
    # Ajouter des tags
    dependency_manager = get_default_manager()
    dependency_manager.add_tag("temp:1", "temporary")
    dependency_manager.add_tag("temp:2", "temporary")
    
    # Afficher les données du cache
    print("\nDonnées du cache:")
    print(f"  temp:1 = {cache.get('temp:1')}")
    print(f"  temp:2 = {cache.get('temp:2')}")
    print(f"  perm:1 = {cache.get('perm:1')}")
    
    # Attendre un peu pour voir les purges en action
    print("\nAttente de 5 secondes pour voir les purges en action...")
    time.sleep(5)
    
    # Arrêter le planificateur
    print("\nArrêt du planificateur de purge...")
    scheduler.stop()


def exemple_invalidation_dependances():
    """Exemple d'invalidation avec dépendances complexes."""
    print("\n=== Exemple d'invalidation avec dépendances complexes ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Créer une instance du gestionnaire de dépendances
    dependency_manager = get_default_manager()
    
    # Créer une instance de l'invalidateur de cache
    invalidator = CacheInvalidator(cache, dependency_manager)
    
    # Ajouter des données au cache pour un blog
    cache.set("blog:1", {"id": 1, "title": "Premier article", "content": "Contenu du premier article"})
    cache.set("blog:2", {"id": 2, "title": "Deuxième article", "content": "Contenu du deuxième article"})
    
    # Ajouter des données au cache pour les commentaires
    cache.set("comment:1:1", {"id": 1, "blog_id": 1, "text": "Premier commentaire sur l'article 1"})
    cache.set("comment:1:2", {"id": 2, "blog_id": 1, "text": "Deuxième commentaire sur l'article 1"})
    cache.set("comment:2:1", {"id": 1, "blog_id": 2, "text": "Premier commentaire sur l'article 2"})
    
    # Ajouter des données au cache pour les listes
    cache.set("blog:list", [1, 2])
    cache.set("comment:list:1", [1, 2])
    cache.set("comment:list:2", [1])
    
    # Ajouter des dépendances
    # Les commentaires dépendent de l'article
    dependency_manager.add_dependency("comment:1:1", "blog:1")
    dependency_manager.add_dependency("comment:1:2", "blog:1")
    dependency_manager.add_dependency("comment:2:1", "blog:2")
    
    # Les listes de commentaires dépendent de l'article
    dependency_manager.add_dependency("comment:list:1", "blog:1")
    dependency_manager.add_dependency("comment:list:2", "blog:2")
    
    # La liste des articles dépend de chaque article
    dependency_manager.add_dependency("blog:list", "blog:1")
    dependency_manager.add_dependency("blog:list", "blog:2")
    
    # Afficher les données du cache
    print("Données du cache:")
    print(f"  blog:1 = {cache.get('blog:1')}")
    print(f"  blog:2 = {cache.get('blog:2')}")
    print(f"  comment:1:1 = {cache.get('comment:1:1')}")
    print(f"  comment:1:2 = {cache.get('comment:1:2')}")
    print(f"  comment:2:1 = {cache.get('comment:2:1')}")
    print(f"  blog:list = {cache.get('blog:list')}")
    print(f"  comment:list:1 = {cache.get('comment:list:1')}")
    print(f"  comment:list:2 = {cache.get('comment:list:2')}")
    
    # Invalider un article
    print("\nInvalidation de l'article 'blog:1'...")
    invalidator.invalidate_key("blog:1")
    
    # Vérifier que l'article et ses dépendances ont été invalidés
    print("Données du cache après invalidation de l'article 1:")
    print(f"  blog:1 = {cache.get('blog:1')}")
    print(f"  blog:2 = {cache.get('blog:2')}")
    print(f"  comment:1:1 = {cache.get('comment:1:1')}")
    print(f"  comment:1:2 = {cache.get('comment:1:2')}")
    print(f"  comment:2:1 = {cache.get('comment:2:1')}")
    print(f"  blog:list = {cache.get('blog:list')}")
    print(f"  comment:list:1 = {cache.get('comment:list:1')}")
    print(f"  comment:list:2 = {cache.get('comment:list:2')}")
    
    # Ajouter à nouveau des données au cache
    cache.set("blog:1", {"id": 1, "title": "Premier article", "content": "Contenu du premier article"})
    cache.set("comment:1:1", {"id": 1, "blog_id": 1, "text": "Premier commentaire sur l'article 1"})
    cache.set("comment:1:2", {"id": 2, "blog_id": 1, "text": "Deuxième commentaire sur l'article 1"})
    cache.set("blog:list", [1, 2])
    cache.set("comment:list:1", [1, 2])
    
    # Ajouter à nouveau des dépendances
    dependency_manager.add_dependency("comment:1:1", "blog:1")
    dependency_manager.add_dependency("comment:1:2", "blog:1")
    dependency_manager.add_dependency("comment:list:1", "blog:1")
    dependency_manager.add_dependency("blog:list", "blog:1")
    
    # Invalider par dépendance inverse
    print("\nInvalidation des clés qui dépendent de 'blog:1'...")
    dependent_keys = dependency_manager.get_dependent_keys("blog:1")
    invalidator.invalidate_keys(list(dependent_keys))
    
    # Vérifier que les dépendances ont été invalidées
    print("Données du cache après invalidation des dépendances de l'article 1:")
    print(f"  blog:1 = {cache.get('blog:1')}")
    print(f"  blog:2 = {cache.get('blog:2')}")
    print(f"  comment:1:1 = {cache.get('comment:1:1')}")
    print(f"  comment:1:2 = {cache.get('comment:1:2')}")
    print(f"  comment:2:1 = {cache.get('comment:2:1')}")
    print(f"  blog:list = {cache.get('blog:list')}")
    print(f"  comment:list:1 = {cache.get('comment:list:1')}")
    print(f"  comment:list:2 = {cache.get('comment:list:2')}")


def nettoyer():
    """Nettoie les fichiers de cache."""
    print("\n=== Nettoyage ===")
    
    # Créer une instance du cache local
    cache = LocalCache()
    
    # Créer une instance du gestionnaire de dépendances
    dependency_manager = get_default_manager()
    
    # Vider le cache
    cache.clear()
    
    # Vider les dépendances
    dependency_manager.clear_all()
    
    print("Cache et dépendances vidés.")


def main():
    """Fonction principale."""
    print("=== Exemples d'utilisation des mécanismes d'invalidation du cache ===")
    
    # Exécuter les exemples
    exemple_invalidation_manuelle()
    exemple_invalidation_ttl()
    exemple_invalidation_programmee()
    exemple_purge_scheduler()
    exemple_invalidation_dependances()
    
    # Nettoyer
    nettoyer()
    
    print("\n=== Fin des exemples ===")


if __name__ == "__main__":
    main()
