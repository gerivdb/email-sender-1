#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Normalisateur de chemins pour projets Python
--------------------------------------------
Ce module fournit des fonctions pour normaliser les chemins de fichiers,
en remplaçant les caractères accentués et les espaces, et en adaptant
les séparateurs de chemin selon le système d'exploitation.
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Optional, Set, Union

# Importer le gestionnaire de chemins
from path_manager import PathManager, path_manager


class PathNormalizer:
    """
    Classe pour normaliser les chemins de fichiers.
    
    Cette classe fournit des méthodes pour normaliser les chemins de fichiers,
    en remplaçant les caractères accentués et les espaces, et en adaptant
    les séparateurs de chemin selon le système d'exploitation.
    """
    
    def __init__(self, project_root: Optional[str] = None):
        """
        Initialise le normalisateur de chemins.
        
        Args:
            project_root: Chemin racine du projet. Si None, utilise le répertoire courant.
        """
        if project_root is None:
            self.path_manager = path_manager
        else:
            self.path_manager = PathManager(project_root)
    
    def normalize_file_content(self, file_path: Union[str, Path], fix_accents: bool = True,
                              fix_spaces: bool = True, fix_paths: bool = True,
                              dry_run: bool = False) -> bool:
        """
        Normalise le contenu d'un fichier.
        
        Args:
            file_path: Chemin du fichier à normaliser.
            fix_accents: Si True, remplace les caractères accentués.
            fix_spaces: Si True, remplace les espaces par des underscores.
            fix_paths: Si True, normalise les chemins absolus.
            dry_run: Si True, n'écrit pas les modifications dans le fichier.
            
        Returns:
            True si le fichier a été modifié, False sinon.
        """
        # Convertir en Path si nécessaire
        if isinstance(file_path, str):
            file_path = Path(file_path)
            
        # Vérifier que le fichier existe
        if not file_path.exists():
            print(f"Le fichier n'existe pas: {file_path}")
            return False
            
        # Lire le contenu du fichier
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            print(f"Erreur lors de la lecture du fichier {file_path}: {e}")
            return False
            
        # Initialiser le flag de modification
        modified = False
        new_content = content
        
        # Remplacer les caractères accentués si demandé
        if fix_accents:
            temp_content = self.path_manager.remove_path_accents(new_content)
            if temp_content != new_content:
                new_content = temp_content
                modified = True
                
        # Remplacer les espaces par des underscores si demandé
        if fix_spaces:
            temp_content = self.path_manager.replace_path_spaces(new_content)
            if temp_content != new_content:
                new_content = temp_content
                modified = True
                
        # Normaliser les chemins si demandé
        if fix_paths:
            # Ancien chemin (avec espaces et accents)
            old_path_variants = [
                r"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
                r"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
                r"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
            ]
            
            # Nouveau chemin (avec underscores)
            new_path = r"D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
            
            # Remplacer les anciens chemins par le nouveau chemin
            for variant in old_path_variants:
                # Échapper les caractères spéciaux pour la regex
                escaped_variant = re.escape(variant)
                if re.search(escaped_variant, new_content):
                    new_content = re.sub(escaped_variant, new_path, new_content)
                    modified = True
                    
        # Si le contenu a été modifié, écrire le nouveau contenu dans le fichier
        if modified:
            if dry_run:
                print(f"Dry run: Le fichier {file_path} serait modifié")
            else:
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Le fichier {file_path} a été modifié")
                except Exception as e:
                    print(f"Erreur lors de l'écriture du fichier {file_path}: {e}")
                    return False
                    
        return modified
    
    def normalize_directory(self, directory: Union[str, Path], patterns: List[str] = None,
                          recurse: bool = False, fix_accents: bool = True,
                          fix_spaces: bool = True, fix_paths: bool = True,
                          dry_run: bool = False) -> List[str]:
        """
        Normalise tous les fichiers d'un répertoire.
        
        Args:
            directory: Répertoire contenant les fichiers à normaliser.
            patterns: Liste des modèles de fichiers à normaliser.
            recurse: Si True, normalise récursivement les fichiers des sous-répertoires.
            fix_accents: Si True, remplace les caractères accentués.
            fix_spaces: Si True, remplace les espaces par des underscores.
            fix_paths: Si True, normalise les chemins absolus.
            dry_run: Si True, n'écrit pas les modifications dans les fichiers.
            
        Returns:
            Liste des chemins des fichiers modifiés.
        """
        # Convertir en Path si nécessaire
        if isinstance(directory, str):
            directory = Path(directory)
            
        # Vérifier que le répertoire existe
        if not directory.exists():
            print(f"Le répertoire n'existe pas: {directory}")
            return []
            
        # Utiliser des modèles par défaut si non spécifiés
        if patterns is None:
            patterns = ["*.json", "*.cmd", "*.ps1", "*.yaml", "*.md"]
            
        # Rechercher les fichiers à normaliser
        files = []
        for pattern in patterns:
            if recurse:
                files.extend(list(directory.glob(f"**/{pattern}")))
            else:
                files.extend(list(directory.glob(pattern)))
                
        print(f"Nombre de fichiers trouvés: {len(files)}")
        
        # Normaliser les fichiers
        normalized_files = []
        for file in files:
            if self.normalize_file_content(file, fix_accents, fix_spaces, fix_paths, dry_run):
                normalized_files.append(str(file))
                
        # Afficher les résultats
        if len(normalized_files) == 0:
            print("✅ Aucun fichier n'a eu besoin d'être normalisé.")
        else:
            if dry_run:
                print(f"✅ Les fichiers suivants seraient normalisés ({len(normalized_files)}):")
            else:
                print(f"✅ Les fichiers suivants ont été normalisés ({len(normalized_files)}):")
            for file in normalized_files:
                print(f"   - {file}")
                
        return normalized_files


# Créer une instance globale du normalisateur de chemins
path_normalizer = PathNormalizer()


def normalize_file_content(file_path: Union[str, Path], fix_accents: bool = True,
                         fix_spaces: bool = True, fix_paths: bool = True,
                         dry_run: bool = False) -> bool:
    """
    Normalise le contenu d'un fichier.
    
    Args:
        file_path: Chemin du fichier à normaliser.
        fix_accents: Si True, remplace les caractères accentués.
        fix_spaces: Si True, remplace les espaces par des underscores.
        fix_paths: Si True, normalise les chemins absolus.
        dry_run: Si True, n'écrit pas les modifications dans le fichier.
        
    Returns:
        True si le fichier a été modifié, False sinon.
    """
    return path_normalizer.normalize_file_content(file_path, fix_accents, fix_spaces, fix_paths, dry_run)


def normalize_directory(directory: Union[str, Path], patterns: List[str] = None,
                      recurse: bool = False, fix_accents: bool = True,
                      fix_spaces: bool = True, fix_paths: bool = True,
                      dry_run: bool = False) -> List[str]:
    """
    Normalise tous les fichiers d'un répertoire.
    
    Args:
        directory: Répertoire contenant les fichiers à normaliser.
        patterns: Liste des modèles de fichiers à normaliser.
        recurse: Si True, normalise récursivement les fichiers des sous-répertoires.
        fix_accents: Si True, remplace les caractères accentués.
        fix_spaces: Si True, remplace les espaces par des underscores.
        fix_paths: Si True, normalise les chemins absolus.
        dry_run: Si True, n'écrit pas les modifications dans les fichiers.
        
    Returns:
        Liste des chemins des fichiers modifiés.
    """
    return path_normalizer.normalize_directory(directory, patterns, recurse, fix_accents, fix_spaces, fix_paths, dry_run)


def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    parser = argparse.ArgumentParser(description="Normalise les chemins dans les fichiers.")
    parser.add_argument("directory", help="Répertoire contenant les fichiers à normaliser.")
    parser.add_argument("--patterns", nargs="+", default=["*.json", "*.cmd", "*.ps1", "*.yaml", "*.md"],
                      help="Liste des modèles de fichiers à normaliser.")
    parser.add_argument("--recurse", action="store_true", help="Normalise récursivement les fichiers des sous-répertoires.")
    parser.add_argument("--no-fix-accents", action="store_true", help="Ne pas remplacer les caractères accentués.")
    parser.add_argument("--no-fix-spaces", action="store_true", help="Ne pas remplacer les espaces par des underscores.")
    parser.add_argument("--no-fix-paths", action="store_true", help="Ne pas normaliser les chemins absolus.")
    parser.add_argument("--dry-run", action="store_true", help="N'écrit pas les modifications dans les fichiers.")
    
    args = parser.parse_args()
    
    # Normaliser les fichiers
    normalize_directory(
        args.directory,
        args.patterns,
        args.recurse,
        not args.no_fix_accents,
        not args.no_fix_spaces,
        not args.no_fix_paths,
        args.dry_run
    )


if __name__ == "__main__":
    main()
