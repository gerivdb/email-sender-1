#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Interface en ligne de commande pour les outils de document MCP.

Ce script fournit une interface en ligne de commande pour utiliser les outils de document MCP.
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
    from src.mcp.core.document.DocumentManager import DocumentManager
    from src.mcp.core.document.tools import fetch_documentation, search_documentation, read_file
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    traceback.print_exc()
    sys.exit(1)

def create_document_manager():
    """Crée et retourne une instance de DocumentManager."""
    try:
        # Utiliser le répertoire courant comme base
        base_path = os.getcwd()
        print(f"Chemin de base pour les documents: {base_path}")
        
        # Créer le gestionnaire de documents
        document_manager = DocumentManager(base_path)
        return document_manager
    except Exception as e:
        print(f"Erreur lors de la création du gestionnaire de documents: {e}")
        traceback.print_exc()
        sys.exit(1)

def fetch_cmd(args):
    """Commande pour récupérer des documents."""
    document_manager = create_document_manager()
    
    # Préparer les paramètres
    params = {
        "path": args.path,
        "recursive": args.recursive,
        "include_content": args.include_content
    }
    
    if args.file_patterns:
        params["file_patterns"] = args.file_patterns.split(",")
    
    if args.max_files:
        params["max_files"] = args.max_files
    
    # Appeler l'outil fetch_documentation
    result = fetch_documentation.fetch_documentation(document_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def search_cmd(args):
    """Commande pour rechercher dans les documents."""
    document_manager = create_document_manager()
    
    # Préparer les paramètres
    params = {
        "query": args.query,
        "recursive": args.recursive,
        "include_content": args.include_content,
        "include_snippets": args.include_snippets
    }
    
    if args.paths:
        params["paths"] = args.paths.split(",")
    
    if args.file_patterns:
        params["file_patterns"] = args.file_patterns.split(",")
    
    if args.max_results:
        params["max_results"] = args.max_results
    
    if args.snippet_size:
        params["snippet_size"] = args.snippet_size
    
    # Appeler l'outil search_documentation
    result = search_documentation.search_documentation(document_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def read_cmd(args):
    """Commande pour lire un fichier."""
    document_manager = create_document_manager()
    
    # Préparer les paramètres
    params = {
        "file_path": args.file_path,
        "line_numbers": args.line_numbers
    }
    
    if args.encoding:
        params["encoding"] = args.encoding
    
    if args.start_line:
        params["start_line"] = args.start_line
    
    if args.end_line:
        params["end_line"] = args.end_line
    
    # Appeler l'outil read_file
    result = read_file.read_file(document_manager, params)
    
    # Afficher le résultat
    if result["success"]:
        if args.metadata:
            print("=== Métadonnées ===")
            print(json.dumps(result["metadata"], indent=2, ensure_ascii=False))
            print("\n=== Contenu ===")
        
        print(result["content"])
    else:
        print(f"Erreur: {result['error']}")

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Interface en ligne de commande pour les outils de document MCP")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande fetch
    fetch_parser = subparsers.add_parser("fetch", help="Récupérer des documents")
    fetch_parser.add_argument("path", help="Chemin du dossier ou du fichier à récupérer")
    fetch_parser.add_argument("--recursive", action="store_true", help="Recherche récursive dans les sous-dossiers")
    fetch_parser.add_argument("--file-patterns", help="Patterns de fichiers à inclure (séparés par des virgules)")
    fetch_parser.add_argument("--max-files", type=int, help="Nombre maximum de fichiers à récupérer")
    fetch_parser.add_argument("--include-content", action="store_true", help="Inclure le contenu des fichiers")
    
    # Commande search
    search_parser = subparsers.add_parser("search", help="Rechercher dans les documents")
    search_parser.add_argument("query", help="Requête de recherche")
    search_parser.add_argument("--paths", help="Chemins à rechercher (séparés par des virgules)")
    search_parser.add_argument("--recursive", action="store_true", help="Recherche récursive dans les sous-dossiers")
    search_parser.add_argument("--file-patterns", help="Patterns de fichiers à inclure (séparés par des virgules)")
    search_parser.add_argument("--max-results", type=int, help="Nombre maximum de résultats")
    search_parser.add_argument("--include-content", action="store_true", help="Inclure le contenu des fichiers")
    search_parser.add_argument("--include-snippets", action="store_true", default=True, help="Inclure des extraits de texte")
    search_parser.add_argument("--snippet-size", type=int, help="Taille des extraits")
    
    # Commande read
    read_parser = subparsers.add_parser("read", help="Lire un fichier")
    read_parser.add_argument("file_path", help="Chemin du fichier à lire")
    read_parser.add_argument("--encoding", help="Encodage du fichier")
    read_parser.add_argument("--line-numbers", action="store_true", help="Inclure les numéros de ligne")
    read_parser.add_argument("--start-line", type=int, help="Ligne de début")
    read_parser.add_argument("--end-line", type=int, help="Ligne de fin")
    read_parser.add_argument("--metadata", action="store_true", help="Afficher les métadonnées")
    
    # Analyser les arguments
    args = parser.parse_args()
    
    # Exécuter la commande appropriée
    if args.command == "fetch":
        fetch_cmd(args)
    elif args.command == "search":
        search_cmd(args)
    elif args.command == "read":
        read_cmd(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
