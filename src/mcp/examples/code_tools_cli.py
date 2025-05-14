#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Interface en ligne de commande pour les outils de code MCP.

Ce script fournit une interface en ligne de commande pour utiliser les outils de code MCP.
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
    from src.mcp.core.code.CodeManager import CodeManager
    from src.mcp.core.code.tools import search_code, analyze_code, get_code_structure
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    traceback.print_exc()
    sys.exit(1)

def create_code_manager():
    """Crée et retourne une instance de CodeManager."""
    try:
        # Utiliser le répertoire courant comme base
        base_path = os.getcwd()
        print(f"Chemin de base pour le code: {base_path}")
        
        # Créer le gestionnaire de code
        code_manager = CodeManager(base_path)
        return code_manager
    except Exception as e:
        print(f"Erreur lors de la création du gestionnaire de code: {e}")
        traceback.print_exc()
        sys.exit(1)

def search_cmd(args):
    """Commande pour rechercher du code."""
    code_manager = create_code_manager()
    
    # Préparer les paramètres
    params = {
        "query": args.query,
        "recursive": args.recursive,
        "case_sensitive": args.case_sensitive,
        "whole_word": args.whole_word,
        "regex": args.regex
    }
    
    if args.paths:
        params["paths"] = args.paths.split(",")
    
    if args.languages:
        params["languages"] = args.languages.split(",")
    
    if args.max_results:
        params["max_results"] = args.max_results
    
    # Appeler l'outil search_code
    result = search_code.search_code(code_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def analyze_cmd(args):
    """Commande pour analyser du code."""
    code_manager = create_code_manager()
    
    # Préparer les paramètres
    params = {
        "file_path": args.file_path
    }
    
    if args.rules:
        params["rules"] = args.rules.split(",")
    
    # Appeler l'outil analyze_code
    result = analyze_code.analyze_code(code_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def structure_cmd(args):
    """Commande pour obtenir la structure du code."""
    code_manager = create_code_manager()
    
    # Préparer les paramètres
    params = {
        "file_path": args.file_path
    }
    
    # Appeler l'outil get_code_structure
    result = get_code_structure.get_code_structure(code_manager, params)
    print(json.dumps(result, indent=2, ensure_ascii=False))

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Interface en ligne de commande pour les outils de code MCP")
    subparsers = parser.add_subparsers(dest="command", help="Commande à exécuter")
    
    # Commande search
    search_parser = subparsers.add_parser("search", help="Rechercher du code")
    search_parser.add_argument("query", help="Requête de recherche")
    search_parser.add_argument("--paths", help="Chemins à rechercher (séparés par des virgules)")
    search_parser.add_argument("--languages", help="Langages à inclure (séparés par des virgules)")
    search_parser.add_argument("--recursive", action="store_true", help="Recherche récursive dans les sous-dossiers")
    search_parser.add_argument("--case-sensitive", action="store_true", help="Recherche sensible à la casse")
    search_parser.add_argument("--whole-word", action="store_true", help="Recherche de mots entiers")
    search_parser.add_argument("--regex", action="store_true", help="Interprète la requête comme une expression régulière")
    search_parser.add_argument("--max-results", type=int, help="Nombre maximum de résultats")
    
    # Commande analyze
    analyze_parser = subparsers.add_parser("analyze", help="Analyser du code")
    analyze_parser.add_argument("file_path", help="Chemin du fichier à analyser")
    analyze_parser.add_argument("--rules", help="Règles d'analyse à appliquer (séparées par des virgules)")
    
    # Commande structure
    structure_parser = subparsers.add_parser("structure", help="Obtenir la structure du code")
    structure_parser.add_argument("file_path", help="Chemin du fichier")
    
    # Analyser les arguments
    args = parser.parse_args()
    
    # Exécuter la commande appropriée
    if args.command == "search":
        search_cmd(args)
    elif args.command == "analyze":
        analyze_cmd(args)
    elif args.command == "structure":
        structure_cmd(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
