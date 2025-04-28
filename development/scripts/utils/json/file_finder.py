#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Recherche de fichiers pour projets Python
-----------------------------------------
Ce module fournit des fonctions pour rechercher des fichiers dans un projet,
avec des options avancées de filtrage et d'exclusion.
"""

import os
import re
import sys
import csv
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Set, Union, Any
from datetime import datetime

# Importer le gestionnaire de chemins
from path_manager import PathManager, path_manager


class FileFinder:
    """
    Classe pour rechercher des fichiers dans un projet.
    
    Cette classe fournit des méthodes pour rechercher des fichiers dans un projet,
    avec des options avancées de filtrage et d'exclusion.
    """
    
    def __init__(self, project_root: Optional[str] = None):
        """
        Initialise le chercheur de fichiers.
        
        Args:
            project_root: Chemin racine du projet. Si None, utilise le répertoire courant.
        """
        if project_root is None:
            self.path_manager = path_manager
        else:
            self.path_manager = PathManager(project_root)
    
    def find_files(self, directory: Union[str, Path], patterns: Union[str, List[str]] = "*",
                 recurse: bool = False, exclude_directories: List[str] = None,
                 exclude_files: List[str] = None, include_pattern: str = "",
                 relative_paths: bool = False) -> List[Dict[str, Any]]:
        """
        Recherche des fichiers dans un répertoire avec des options avancées.
        
        Args:
            directory: Répertoire dans lequel rechercher les fichiers.
            patterns: Modèle(s) de recherche pour les fichiers.
            recurse: Si True, recherche récursivement dans les sous-répertoires.
            exclude_directories: Liste de noms de répertoires à exclure de la recherche.
            exclude_files: Liste de noms de fichiers à exclure de la recherche.
            include_pattern: Modèle supplémentaire pour filtrer les fichiers inclus.
            relative_paths: Si True, retourne les chemins relatifs au répertoire de recherche.
            
        Returns:
            Liste des informations sur les fichiers trouvés.
        """
        # Convertir en Path si nécessaire
        if isinstance(directory, str):
            directory = Path(directory)
            
        # Vérifier que le répertoire existe
        if not directory.exists():
            print(f"Le répertoire n'existe pas: {directory}")
            return []
            
        # Rechercher les fichiers
        file_paths = self.path_manager.find_files(
            directory, patterns, recurse, exclude_directories, exclude_files, include_pattern
        )
        
        # Préparer les résultats
        results = []
        for file_path in file_paths:
            file_info = Path(file_path)
            stat = file_info.stat()
            
            result = {
                "full_path": str(file_info),
                "relative_path": self.path_manager.get_relative_path(file_info, str(directory)) if relative_paths else str(file_info),
                "name": file_info.name,
                "extension": file_info.suffix,
                "size": stat.st_size,
                "last_modified": datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
                "is_readonly": not os.access(file_info, os.W_OK)
            }
            
            results.append(result)
            
        return results
    
    def export_to_csv(self, results: List[Dict[str, Any]], output_file: str) -> None:
        """
        Exporte les résultats de recherche dans un fichier CSV.
        
        Args:
            results: Liste des informations sur les fichiers trouvés.
            output_file: Chemin du fichier CSV de sortie.
        """
        if not results:
            print("Aucun résultat à exporter.")
            return
            
        # Définir les en-têtes du CSV
        fieldnames = ["full_path", "relative_path", "name", "extension", "size", "last_modified", "is_readonly"]
        
        # Écrire les résultats dans le fichier CSV
        try:
            with open(output_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(results)
                
            print(f"Résultats exportés dans le fichier: {output_file}")
        except Exception as e:
            print(f"Erreur lors de l'exportation des résultats: {e}")


# Créer une instance globale du chercheur de fichiers
file_finder = FileFinder()


def find_files(directory: Union[str, Path], patterns: Union[str, List[str]] = "*",
             recurse: bool = False, exclude_directories: List[str] = None,
             exclude_files: List[str] = None, include_pattern: str = "",
             relative_paths: bool = False) -> List[Dict[str, Any]]:
    """
    Recherche des fichiers dans un répertoire avec des options avancées.
    
    Args:
        directory: Répertoire dans lequel rechercher les fichiers.
        patterns: Modèle(s) de recherche pour les fichiers.
        recurse: Si True, recherche récursivement dans les sous-répertoires.
        exclude_directories: Liste de noms de répertoires à exclure de la recherche.
        exclude_files: Liste de noms de fichiers à exclure de la recherche.
        include_pattern: Modèle supplémentaire pour filtrer les fichiers inclus.
        relative_paths: Si True, retourne les chemins relatifs au répertoire de recherche.
        
    Returns:
        Liste des informations sur les fichiers trouvés.
    """
    return file_finder.find_files(
        directory, patterns, recurse, exclude_directories, exclude_files, include_pattern, relative_paths
    )


def export_to_csv(results: List[Dict[str, Any]], output_file: str) -> None:
    """
    Exporte les résultats de recherche dans un fichier CSV.
    
    Args:
        results: Liste des informations sur les fichiers trouvés.
        output_file: Chemin du fichier CSV de sortie.
    """
    file_finder.export_to_csv(results, output_file)


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    parser = argparse.ArgumentParser(description="Recherche des fichiers dans un répertoire.")
    parser.add_argument("directory", help="Répertoire dans lequel rechercher les fichiers.")
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
    
    # Rechercher les fichiers
    results = find_files(
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
        export_to_csv(results, args.output_file)


if __name__ == "__main__":
    main()
