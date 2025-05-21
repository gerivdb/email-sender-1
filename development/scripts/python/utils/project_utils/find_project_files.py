#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour rechercher des fichiers dans le projet
--------------------------------------------------
Ce script fournit des fonctionnalités avancées de recherche de fichiers.
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
import file_finder


def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Recherche des fichiers dans le projet.")
    parser.add_argument("--directory", default=".", help="Répertoire dans lequel rechercher les fichiers.")
    parser.add_argument("--patterns", nargs="+", default=["*"],
                      help="Modèle(s) de recherche pour les fichiers.")
    parser.add_argument("--recurse", action="store_true",
                      help="Recherche récursivement dans les sous-répertoires.")
    parser.add_argument("--exclude-directories", nargs="+", default=[],
                      help="Liste de noms de répertoires à exclure de la recherche.")
    parser.add_argument("--exclude-files", nargs="+", default=[],
                      help="Liste de noms de fichiers à exclure de la recherche.")
    parser.add_argument("--include-pattern", default="",
                      help="Modèle supplémentaire pour filtrer les fichiers inclus.")
    parser.add_argument("--relative-paths", action="store_true",
                      help="Retourne les chemins relatifs au répertoire de recherche.")
    parser.add_argument("--show-details", action="store_true",
                      help="Affiche les détails des fichiers trouvés.")
    parser.add_argument("--export-csv", action="store_true",
                      help="Exporte les résultats dans un fichier CSV.")
    parser.add_argument("--output-file", default="found_files.csv",
                      help="Chemin du fichier CSV de sortie.")
    
    args = parser.parse_args()
    
    # Afficher les paramètres
    print("=== Recherche de fichiers ===")
    print(f"Répertoire: {args.directory}")
    print(f"Modèle(s): {', '.join(args.patterns)}")
    print(f"Récursif: {args.recurse}")
    print(f"Répertoires exclus: {', '.join(args.exclude_directories)}")
    print(f"Fichiers exclus: {', '.join(args.exclude_files)}")
    print(f"Modèle d'inclusion: {args.include_pattern}")
    print(f"Chemins relatifs: {args.relative_paths}")
    print(f"Afficher les détails: {args.show_details}")
    print(f"Exporter en CSV: {args.export_csv}")
    print(f"Fichier de sortie: {args.output_file}")
    print()
    
    # Rechercher les fichiers
    results = file_finder.find_files(
        args.directory,
        args.patterns,
        args.recurse,
        args.exclude_directories,
        args.exclude_files,
        args.include_pattern,
        args.relative_paths
    )
    
    # Afficher le nombre de fichiers trouvés
    print(f"Nombre de fichiers trouvés: {len(results)}")
    
    # Si aucun fichier n'est trouvé, sortir
    if not results:
        print("Aucun fichier trouvé correspondant aux critères de recherche.")
        return
    
    # Afficher les résultats
    if args.show_details:
        # Afficher les détails des fichiers trouvés
        print("\nDétails des fichiers trouvés:")
        print("-" * 80)
        for result in results:
            print(f"Chemin: {result['relative_path'] if args.relative_paths else result['full_path']}")
            print(f"Nom: {result['name']}")
            print(f"Extension: {result['extension']}")
            print(f"Taille: {result['size']} octets")
            print(f"Dernière modification: {result['last_modified']}")
            print(f"Lecture seule: {result['is_readonly']}")
            print("-" * 80)
    else:
        # Afficher simplement les chemins des fichiers trouvés
        for result in results:
            print(result['relative_path'] if args.relative_paths else result['full_path'])
    
    # Exporter les résultats en CSV si demandé
    if args.export_csv:
        file_finder.export_to_csv(results, args.output_file)
        print(f"Résultats exportés dans le fichier: {args.output_file}")


if __name__ == "__main__":
    main()
