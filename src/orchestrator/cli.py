#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Interface de ligne de commande pour le système CRUD modulaire thématique.

Ce module fournit une interface de ligne de commande pour interagir avec
le système CRUD modulaire thématique.
"""

import os
import sys
import json
import argparse
from typing import Dict, List, Any, Optional
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
from src.orchestrator.utils.cache_manager import CacheManager

def create_parser() -> argparse.ArgumentParser:
    """
    Crée le parseur d'arguments pour l'interface de ligne de commande.
    
    Returns:
        Parseur d'arguments
    """
    parser = argparse.ArgumentParser(description="Interface de ligne de commande pour le système CRUD modulaire thématique.")
    
    # Paramètres globaux
    parser.add_argument("--storage-path", default="./data", help="Chemin vers le répertoire de stockage des données")
    parser.add_argument("--archive-path", help="Chemin vers le répertoire d'archivage")
    parser.add_argument("--themes-config", help="Chemin vers le fichier de configuration des thèmes")
    parser.add_argument("--cache-dir", help="Chemin vers le répertoire de cache")
    
    # Sous-commandes
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande: create
    create_parser = subparsers.add_parser("create", help="Créer un nouvel élément")
    create_parser.add_argument("--content", required=True, help="Contenu de l'élément")
    create_parser.add_argument("--title", required=True, help="Titre de l'élément")
    create_parser.add_argument("--author", help="Auteur de l'élément")
    create_parser.add_argument("--tags", help="Tags de l'élément (séparés par des virgules)")
    create_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: get
    get_parser = subparsers.add_parser("get", help="Récupérer un élément")
    get_parser.add_argument("--id", help="Identifiant de l'élément")
    get_parser.add_argument("--theme", help="Thème des éléments à récupérer")
    get_parser.add_argument("--limit", type=int, default=10, help="Nombre maximum d'éléments à récupérer")
    get_parser.add_argument("--offset", type=int, default=0, help="Décalage pour la pagination")
    get_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: search
    search_parser = subparsers.add_parser("search", help="Rechercher des éléments")
    search_parser.add_argument("--query", required=True, help="Requête textuelle")
    search_parser.add_argument("--themes", help="Thèmes à inclure dans la recherche (séparés par des virgules)")
    search_parser.add_argument("--author", help="Auteur des éléments à rechercher")
    search_parser.add_argument("--tags", help="Tags des éléments à rechercher (séparés par des virgules)")
    search_parser.add_argument("--limit", type=int, default=10, help="Nombre maximum d'éléments à récupérer")
    search_parser.add_argument("--offset", type=int, default=0, help="Décalage pour la pagination")
    search_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: update
    update_parser = subparsers.add_parser("update", help="Mettre à jour un élément")
    update_parser.add_argument("--id", required=True, help="Identifiant de l'élément")
    update_parser.add_argument("--content", help="Nouveau contenu de l'élément")
    update_parser.add_argument("--title", help="Nouveau titre de l'élément")
    update_parser.add_argument("--author", help="Nouvel auteur de l'élément")
    update_parser.add_argument("--tags", help="Nouveaux tags de l'élément (séparés par des virgules)")
    update_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: delete
    delete_parser = subparsers.add_parser("delete", help="Supprimer un élément")
    delete_parser.add_argument("--id", help="Identifiant de l'élément")
    delete_parser.add_argument("--theme", help="Thème des éléments à supprimer")
    delete_parser.add_argument("--permanent", action="store_true", help="Supprimer définitivement sans archiver")
    
    # Commande: archive
    archive_parser = subparsers.add_parser("archive", help="Archiver un élément")
    archive_parser.add_argument("--id", help="Identifiant de l'élément")
    archive_parser.add_argument("--theme", help="Thème des éléments à archiver")
    
    # Commande: restore
    restore_parser = subparsers.add_parser("restore", help="Restaurer un élément archivé")
    restore_parser.add_argument("--id", required=True, help="Identifiant de l'élément")
    
    # Commande: list-archived
    list_archived_parser = subparsers.add_parser("list-archived", help="Lister les éléments archivés")
    list_archived_parser.add_argument("--limit", type=int, default=10, help="Nombre maximum d'éléments à récupérer")
    list_archived_parser.add_argument("--offset", type=int, default=0, help="Décalage pour la pagination")
    list_archived_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: stats
    stats_parser = subparsers.add_parser("stats", help="Afficher des statistiques sur les thèmes")
    stats_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: analyze
    analyze_parser = subparsers.add_parser("analyze", help="Analyser un contenu et attribuer des thèmes")
    analyze_parser.add_argument("--content", required=True, help="Contenu à analyser")
    analyze_parser.add_argument("--title", help="Titre du contenu")
    analyze_parser.add_argument("--tags", help="Tags du contenu (séparés par des virgules)")
    analyze_parser.add_argument("--output", choices=["json", "text"], default="text", help="Format de sortie")
    
    # Commande: clear-cache
    clear_cache_parser = subparsers.add_parser("clear-cache", help="Vider le cache")
    clear_cache_parser.add_argument("--memory", action="store_true", help="Vider le cache en mémoire")
    clear_cache_parser.add_argument("--disk", action="store_true", help="Vider le cache sur disque")
    clear_cache_parser.add_argument("--all", action="store_true", help="Vider tous les caches")
    
    return parser

def format_output(data: Any, output_format: str) -> str:
    """
    Formate les données de sortie.
    
    Args:
        data: Données à formater
        output_format: Format de sortie (json ou text)
        
    Returns:
        Données formatées
    """
    if output_format == "json":
        return json.dumps(data, ensure_ascii=False, indent=2)
    
    if isinstance(data, dict):
        if "id" in data:
            # Formater un élément
            result = f"ID: {data['id']}\n"
            if "metadata" in data:
                metadata = data["metadata"]
                if "title" in metadata:
                    result += f"Titre: {metadata['title']}\n"
                if "author" in metadata:
                    result += f"Auteur: {metadata['author']}\n"
                if "tags" in metadata and isinstance(metadata["tags"], list):
                    result += f"Tags: {', '.join(metadata['tags'])}\n"
                if "themes" in metadata:
                    themes = metadata["themes"]
                    result += f"Thèmes: {', '.join([f'{t} ({s:.2f})' for t, s in themes.items()])}\n"
                if "created_at" in metadata:
                    result += f"Créé le: {metadata['created_at']}\n"
                if "updated_at" in metadata:
                    result += f"Mis à jour le: {metadata['updated_at']}\n"
            if "content" in data:
                result += f"\nContenu:\n{data['content']}\n"
            return result
        else:
            # Formater un dictionnaire générique
            return "\n".join([f"{k}: {v}" for k, v in data.items()])
    
    if isinstance(data, list):
        # Formater une liste d'éléments
        if not data:
            return "Aucun élément trouvé."
        
        if isinstance(data[0], dict) and "id" in data[0]:
            # Liste d'éléments
            result = f"Nombre d'éléments: {len(data)}\n\n"
            for i, item in enumerate(data):
                result += f"--- Élément {i+1} ---\n"
                result += format_output(item, "text") + "\n"
            return result
        else:
            # Liste générique
            return "\n".join([str(item) for item in data])
    
    # Valeur simple
    return str(data)

def main():
    """Point d'entrée principal de l'interface de ligne de commande."""
    parser = create_parser()
    args = parser.parse_args()
    
    # Initialiser le gestionnaire de cache
    if args.cache_dir:
        CacheManager.initialize(args.cache_dir)
    
    # Créer le gestionnaire CRUD
    manager = ThematicCRUDManager(
        storage_path=args.storage_path,
        archive_path=args.archive_path,
        themes_config_path=args.themes_config
    )
    
    # Exécuter la commande
    if args.command == "create":
        # Préparer les métadonnées
        metadata = {
            "title": args.title
        }
        
        if args.author:
            metadata["author"] = args.author
        
        if args.tags:
            metadata["tags"] = [tag.strip() for tag in args.tags.split(",")]
        
        # Créer l'élément
        item = manager.create_item(args.content, metadata)
        print(format_output(item, args.output))
    
    elif args.command == "get":
        if args.id:
            # Récupérer un élément par son identifiant
            item = manager.get_item(args.id)
            if item:
                print(format_output(item, args.output))
            else:
                print("Élément non trouvé.")
        elif args.theme:
            # Récupérer les éléments par thème
            items = manager.get_items_by_theme(args.theme, args.limit, args.offset)
            print(format_output(items, args.output))
        else:
            print("Erreur: Vous devez spécifier un identifiant ou un thème.")
    
    elif args.command == "search":
        # Préparer les filtres de métadonnées
        metadata_filters = {}
        
        if args.author:
            metadata_filters["author"] = args.author
        
        if args.tags:
            metadata_filters["tags"] = [tag.strip() for tag in args.tags.split(",")]
        
        # Préparer les thèmes
        themes = None
        if args.themes:
            themes = [theme.strip() for theme in args.themes.split(",")]
        
        # Rechercher les éléments
        items = manager.search_items(args.query, themes, metadata_filters, args.limit, args.offset)
        print(format_output(items, args.output))
    
    elif args.command == "update":
        # Préparer les métadonnées
        metadata = {}
        
        if args.title:
            metadata["title"] = args.title
        
        if args.author:
            metadata["author"] = args.author
        
        if args.tags:
            metadata["tags"] = [tag.strip() for tag in args.tags.split(",")]
        
        # Mettre à jour l'élément
        item = manager.update_item(args.id, args.content, metadata if metadata else None)
        if item:
            print(format_output(item, args.output))
        else:
            print("Élément non trouvé.")
    
    elif args.command == "delete":
        if args.id:
            # Supprimer un élément par son identifiant
            result = manager.delete_item(args.id, args.permanent)
            if result:
                print(f"Élément {args.id} supprimé avec succès.")
            else:
                print(f"Impossible de supprimer l'élément {args.id}.")
        elif args.theme:
            # Supprimer les éléments par thème
            count = manager.delete_items_by_theme(args.theme, args.permanent)
            print(f"{count} élément(s) supprimé(s) avec succès.")
        else:
            print("Erreur: Vous devez spécifier un identifiant ou un thème.")
    
    elif args.command == "archive":
        if args.id:
            # Archiver un élément par son identifiant
            result = manager.archive_item(args.id)
            if result:
                print(f"Élément {args.id} archivé avec succès.")
            else:
                print(f"Impossible d'archiver l'élément {args.id}.")
        elif args.theme:
            # Archiver les éléments par thème
            count = manager.archive_items_by_theme(args.theme)
            print(f"{count} élément(s) archivé(s) avec succès.")
        else:
            print("Erreur: Vous devez spécifier un identifiant ou un thème.")
    
    elif args.command == "restore":
        # Restaurer un élément archivé
        result = manager.restore_archived_item(args.id)
        if result:
            print(f"Élément {args.id} restauré avec succès.")
        else:
            print(f"Impossible de restaurer l'élément {args.id}.")
    
    elif args.command == "list-archived":
        # Lister les éléments archivés
        items = manager.get_archived_items(args.limit, args.offset)
        print(format_output(items, args.output))
    
    elif args.command == "stats":
        # Afficher des statistiques sur les thèmes
        statistics = manager.get_theme_statistics()
        print(format_output(statistics, args.output))
    
    elif args.command == "analyze":
        # Préparer les métadonnées
        metadata = {}
        
        if args.title:
            metadata["title"] = args.title
        
        if args.tags:
            metadata["tags"] = [tag.strip() for tag in args.tags.split(",")]
        
        # Analyser le contenu
        themes = manager.attribute_theme(args.content, metadata if metadata else None)
        print(format_output(themes, args.output))
    
    elif args.command == "clear-cache":
        if args.all:
            # Vider tous les caches
            CacheManager.clear_all_cache()
            print("Tous les caches ont été vidés.")
        elif args.memory:
            # Vider le cache en mémoire
            CacheManager.clear_memory_cache()
            print("Le cache en mémoire a été vidé.")
        elif args.disk:
            # Vider le cache sur disque
            CacheManager.clear_disk_cache()
            print("Le cache sur disque a été vidé.")
        else:
            print("Erreur: Vous devez spécifier le type de cache à vider (--memory, --disk ou --all).")
    
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
