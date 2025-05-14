#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Interface en ligne de commande pour les outils de mémoire MCP.

Ce script fournit une interface en ligne de commande pour utiliser les outils de mémoire MCP.
"""

import os
import sys
import json
import argparse
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.memory.MemoryManager import MemoryManager
    from src.mcp.core.memory.tools import add_memories, search_memory, list_memories, delete_memories
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    traceback.print_exc()
    sys.exit(1)

def create_memory_manager():
    """Crée et retourne une instance de MemoryManager."""
    try:
        # Définir le chemin de stockage des mémoires
        user_home = os.path.expanduser("~")
        storage_path = os.path.join(user_home, ".mcp", "memory", "memories.json")
        print(f"Chemin de stockage des mémoires: {storage_path}")

        # Créer le dossier de stockage s'il n'existe pas
        os.makedirs(os.path.dirname(storage_path), exist_ok=True)

        # Créer le gestionnaire de mémoire
        memory_manager = MemoryManager(storage_path)
        return memory_manager
    except Exception as e:
        print(f"Erreur lors de la création du gestionnaire de mémoire: {e}")
        traceback.print_exc()
        sys.exit(1)

def add_memory_cmd(args):
    """Commande pour ajouter une mémoire."""
    memory_manager = create_memory_manager()

    # Préparer les paramètres
    content = args.content
    metadata = {}

    if args.metadata:
        try:
            metadata = json.loads(args.metadata)
        except json.JSONDecodeError:
            print("Erreur: Métadonnées JSON invalides")
            return

    # Appeler l'outil add_memories
    params = {
        "memories": [
            {
                "content": content,
                "metadata": metadata
            }
        ]
    }

    result = add_memories.add_memories(memory_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def list_memories_cmd(args):
    """Commande pour lister les mémoires."""
    memory_manager = create_memory_manager()

    # Préparer les paramètres
    params = {
        "page": args.page,
        "page_size": args.page_size
    }

    if args.filters:
        try:
            params["filters"] = json.loads(args.filters)
        except json.JSONDecodeError:
            print("Erreur: Filtres JSON invalides")
            return

    # Appeler l'outil list_memories
    result = list_memories.list_memories(memory_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def search_memory_cmd(args):
    """Commande pour rechercher des mémoires."""
    memory_manager = create_memory_manager()

    # Préparer les paramètres
    params = {
        "query": args.query,
        "limit": args.limit
    }

    if args.filters:
        try:
            params["filters"] = json.loads(args.filters)
        except json.JSONDecodeError:
            print("Erreur: Filtres JSON invalides")
            return

    # Appeler l'outil search_memory
    result = search_memory.search_memory(memory_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def delete_memory_cmd(args):
    """Commande pour supprimer une mémoire."""
    memory_manager = create_memory_manager()

    # Préparer les paramètres
    params = {}

    if args.id:
        params["memory_ids"] = [args.id]
    elif args.filters:
        try:
            params["filters"] = json.loads(args.filters)
            params["confirm"] = True
        except json.JSONDecodeError:
            print("Erreur: Filtres JSON invalides")
            return
    else:
        print("Erreur: Vous devez spécifier soit un ID soit des filtres")
        return

    # Appeler l'outil delete_memories
    result = delete_memories.delete_memories(memory_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Interface en ligne de commande pour les outils de mémoire MCP")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")

    # Commande add
    add_parser = subparsers.add_parser("add", help="Ajouter une mémoire")
    add_parser.add_argument("content", help="Contenu de la mémoire")
    add_parser.add_argument("--metadata", help="Métadonnées au format JSON")

    # Commande list
    list_parser = subparsers.add_parser("list", help="Lister les mémoires")
    list_parser.add_argument("--page", type=int, default=1, help="Numéro de page")
    list_parser.add_argument("--page-size", type=int, default=10, help="Nombre d'éléments par page")
    list_parser.add_argument("--filters", help="Filtres au format JSON")

    # Commande search
    search_parser = subparsers.add_parser("search", help="Rechercher des mémoires")
    search_parser.add_argument("query", help="Requête de recherche")
    search_parser.add_argument("--limit", type=int, default=5, help="Nombre maximum de résultats")
    search_parser.add_argument("--filters", help="Filtres au format JSON")

    # Commande delete
    delete_parser = subparsers.add_parser("delete", help="Supprimer une mémoire")
    delete_parser.add_argument("--id", help="ID de la mémoire à supprimer")
    delete_parser.add_argument("--filters", help="Filtres au format JSON pour supprimer plusieurs mémoires")

    # Analyser les arguments
    args = parser.parse_args()

    # Exécuter la commande appropriée
    if args.command == "add":
        add_memory_cmd(args)
    elif args.command == "list":
        list_memories_cmd(args)
    elif args.command == "search":
        search_memory_cmd(args)
    elif args.command == "delete":
        delete_memory_cmd(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
