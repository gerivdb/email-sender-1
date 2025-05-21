#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour normaliser les chemins dans un projet
-------------------------------------------------
Ce script recherche et normalise les chemins dans les fichiers du projet.
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Optional

# Ajouter le répertoire src/utils au chemin de recherche des modules
sys.path.append(str(Path(__file__).parent.parent.parent / "src" / "utils"))

# Importer les modules de gestion des chemins
import path_manager
import path_normalizer
import file_finder


def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Normalise les chemins dans les fichiers du projet.")
    parser.add_argument("--directory", default=".", help="Répertoire contenant les fichiers à normaliser.")
    parser.add_argument("--patterns", nargs="+", default=["*.json", "*.cmd", "*.ps1", "*.yaml", "*.md"],
                      help="Liste des modèles de fichiers à normaliser.")
    parser.add_argument("--recurse", action="store_true", help="Normalise récursivement les fichiers des sous-répertoires.")
    parser.add_argument("--no-fix-accents", action="store_true", help="Ne pas remplacer les caractères accentués.")
    parser.add_argument("--no-fix-spaces", action="store_true", help="Ne pas remplacer les espaces par des underscores.")
    parser.add_argument("--no-fix-paths", action="store_true", help="Ne pas normaliser les chemins absolus.")
    parser.add_argument("--dry-run", action="store_true", help="N'écrit pas les modifications dans les fichiers.")
    
    args = parser.parse_args()
    
    # Afficher les paramètres
    print("=== Normalisation des chemins dans les fichiers ===")
    print(f"Répertoire: {args.directory}")
    print(f"Types de fichiers: {', '.join(args.patterns)}")
    print(f"Récursif: {args.recurse}")
    print(f"Corriger les accents: {not args.no_fix_accents}")
    print(f"Corriger les espaces: {not args.no_fix_spaces}")
    print(f"Corriger les chemins: {not args.no_fix_paths}")
    print(f"Dry run: {args.dry_run}")
    print()
    
    # Normaliser les fichiers
    normalized_files = path_normalizer.normalize_directory(
        args.directory,
        args.patterns,
        args.recurse,
        not args.no_fix_accents,
        not args.no_fix_spaces,
        not args.no_fix_paths,
        args.dry_run
    )
    
    # Afficher les résultats
    if not normalized_files:
        print("✅ Aucun fichier n'a eu besoin d'être normalisé.")
    else:
        if args.dry_run:
            print(f"✅ Les fichiers suivants seraient normalisés ({len(normalized_files)}) :")
        else:
            print(f"✅ Les fichiers suivants ont été normalisés ({len(normalized_files)}) :")
        for file in normalized_files:
            print(f"   - {file}")


if __name__ == "__main__":
    main()
