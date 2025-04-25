#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Gestionnaire de chemins pour projets Python
-------------------------------------------
Ce module fournit des classes et fonctions pour gérer les chemins de fichiers
de manière cohérente dans un projet, en prenant en charge les chemins relatifs
et absolus, ainsi que la normalisation des chemins.
"""

import os
import re
import sys
import glob
from pathlib import Path
from typing import Dict, List, Optional, Set, Union


class PathManager:
    """
    Classe pour gérer les chemins de fichiers dans un projet.
    
    Cette classe fournit des méthodes pour convertir entre chemins relatifs et absolus,
    normaliser les chemins, et rechercher des fichiers.
    """
    
    def __init__(self, project_root: Optional[str] = None):
        """
        Initialise le gestionnaire de chemins.
        
        Args:
            project_root: Chemin racine du projet. Si None, utilise le répertoire courant.
        """
        if project_root is None:
            self.project_root = Path.cwd()
        else:
            self.project_root = Path(project_root).resolve()
            
        if not self.project_root.exists():
            raise FileNotFoundError(f"Le répertoire racine du projet n'existe pas: {self.project_root}")
            
        # Créer les mappages de chemins pour les répertoires principaux du projet
        self.path_mappings = {
            "root": self.project_root,
            "scripts": self.project_root / "scripts",
            "tools": self.project_root / "tools",
            "src": self.project_root / "src",
            "docs": self.project_root / "docs",
            "workflows": self.project_root / "workflows",
            "config": self.project_root / "config",
            "logs": self.project_root / "logs",
            "tests": self.project_root / "tests",
            "assets": self.project_root / "assets",
            "journal": self.project_root / "journal",
            "mcp": self.project_root / "mcp",
            "mcp-servers": self.project_root / "mcp-servers",
            "node_modules": self.project_root / "node_modules"
        }
        
        # Ajouter des sous-répertoires importants
        self.path_mappings["scripts-utils"] = self.path_mappings["scripts"] / "utils"
        self.path_mappings["scripts-maintenance"] = self.path_mappings["scripts"] / "maintenance"
        self.path_mappings["scripts-python"] = self.path_mappings["scripts"] / "python"
        self.path_mappings["docs-journal"] = self.path_mappings["docs"] / "journal_de_bord"
        self.path_mappings["docs-reference"] = self.path_mappings["docs"] / "reference"
        self.path_mappings["tools-roadmap"] = self.path_mappings["tools"] / "roadmap"
    
    def get_project_path(self, relative_path: str, base_path: str = "") -> Path:
        """
        Obtient le chemin absolu à partir d'un chemin relatif au répertoire racine du projet.
        
        Args:
            relative_path: Chemin relatif au répertoire racine du projet.
            base_path: Chemin de base à utiliser pour la résolution. Par défaut, utilise le répertoire racine du projet.
            
        Returns:
            Chemin absolu.
        """
        # Si le base_path est une clé dans path_mappings, utiliser le chemin correspondant
        if base_path in self.path_mappings:
            base_path_resolved = self.path_mappings[base_path]
        # Sinon, si base_path est spécifié, le joindre au répertoire racine
        elif base_path:
            base_path_resolved = self.project_root / base_path
        # Sinon, utiliser le répertoire racine
        else:
            base_path_resolved = self.project_root
            
        # Joindre le chemin relatif au chemin de base
        absolute_path = base_path_resolved / relative_path
        
        return absolute_path
    
    def get_relative_path(self, absolute_path: Union[str, Path], base_path: str = "") -> str:
        """
        Obtient le chemin relatif à partir d'un chemin absolu.
        
        Args:
            absolute_path: Chemin absolu à convertir.
            base_path: Chemin de base à utiliser pour la conversion. Par défaut, utilise le répertoire racine du projet.
            
        Returns:
            Chemin relatif.
        """
        # Convertir en Path si nécessaire
        if isinstance(absolute_path, str):
            absolute_path = Path(absolute_path)
            
        # Si le base_path est une clé dans path_mappings, utiliser le chemin correspondant
        if base_path in self.path_mappings:
            base_path_resolved = self.path_mappings[base_path]
        # Sinon, si base_path est spécifié, le joindre au répertoire racine
        elif base_path:
            base_path_resolved = self.project_root / base_path
        # Sinon, utiliser le répertoire racine
        else:
            base_path_resolved = self.project_root
            
        # Obtenir le chemin relatif
        try:
            relative_path = absolute_path.relative_to(base_path_resolved)
            return str(relative_path)
        except ValueError:
            # Si le chemin absolu n'est pas relatif au chemin de base, retourner le chemin absolu
            return str(absolute_path)
    
    def add_path_mapping(self, name: str, path: Union[str, Path]) -> None:
        """
        Ajoute un nouveau mapping de chemin au gestionnaire de chemins.
        
        Args:
            name: Nom du mapping de chemin.
            path: Chemin à mapper. Peut être un chemin absolu ou relatif au répertoire racine du projet.
        """
        # Convertir en Path si nécessaire
        if isinstance(path, str):
            path = Path(path)
            
        # Si le chemin est relatif, le convertir en chemin absolu
        if not path.is_absolute():
            path = self.project_root / path
            
        # Ajouter le mapping de chemin
        self.path_mappings[name] = path
    
    def get_path_mappings(self) -> Dict[str, Path]:
        """
        Obtient tous les mappings de chemins définis dans le gestionnaire de chemins.
        
        Returns:
            Dictionnaire des mappings de chemins.
        """
        return self.path_mappings
    
    def is_relative_path(self, path: Union[str, Path]) -> bool:
        """
        Vérifie si un chemin est relatif.
        
        Args:
            path: Chemin à vérifier.
            
        Returns:
            True si le chemin est relatif, False sinon.
        """
        # Convertir en Path si nécessaire
        if isinstance(path, str):
            path = Path(path)
            
        return not path.is_absolute()
    
    @staticmethod
    def normalize_path(path: Union[str, Path], force_windows_style: bool = False, force_unix_style: bool = False) -> str:
        """
        Normalise un chemin en fonction du système d'exploitation.
        
        Args:
            path: Chemin à normaliser.
            force_windows_style: Si True, force l'utilisation du style Windows (backslashes).
            force_unix_style: Si True, force l'utilisation du style Unix (forward slashes).
            
        Returns:
            Chemin normalisé.
        """
        # Convertir en str si nécessaire
        if isinstance(path, Path):
            path = str(path)
            
        # Normaliser le chemin en fonction du système d'exploitation
        if force_windows_style:
            normalized_path = path.replace('/', '\\')
        elif force_unix_style:
            normalized_path = path.replace('\\', '/')
        else:
            # Utiliser le séparateur de chemin du système d'exploitation
            normalized_path = path.replace('/', os.path.sep).replace('\\', os.path.sep)
            
        # Supprimer les séparateurs de chemin consécutifs
        normalized_path = re.sub(r'\\{2,}', '\\', normalized_path)
        normalized_path = re.sub(r'/{2,}', '/', normalized_path)
            
        return normalized_path
    
    @staticmethod
    def remove_path_accents(path: str) -> str:
        """
        Convertit un chemin avec des caractères accentués en chemin sans accents.
        
        Args:
            path: Chemin à convertir.
            
        Returns:
            Chemin sans accents.
        """
        # Tableau de correspondance des caractères accentués
        accent_map = {
            'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
            'à': 'a', 'â': 'a', 'ä': 'a',
            'î': 'i', 'ï': 'i',
            'ô': 'o', 'ö': 'o',
            'ù': 'u', 'û': 'u', 'ü': 'u',
            'ÿ': 'y', 'ç': 'c',
            'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
            'À': 'A', 'Â': 'A', 'Ä': 'A',
            'Î': 'I', 'Ï': 'I',
            'Ô': 'O', 'Ö': 'O',
            'Ù': 'U', 'Û': 'U', 'Ü': 'U',
            'Ÿ': 'Y', 'Ç': 'C'
        }
        
        # Remplacer les caractères accentués
        result = path
        for key, value in accent_map.items():
            result = result.replace(key, value)
            
        return result
    
    @staticmethod
    def replace_path_spaces(path: str) -> str:
        """
        Convertit un chemin avec des espaces en chemin avec des underscores.
        
        Args:
            path: Chemin à convertir.
            
        Returns:
            Chemin avec des underscores.
        """
        # Remplacer les espaces par des underscores
        return path.replace(' ', '_')
    
    @staticmethod
    def normalize_path_full(path: str) -> str:
        """
        Normalise un chemin en remplaçant les caractères accentués et les espaces.
        
        Args:
            path: Chemin à normaliser.
            
        Returns:
            Chemin normalisé.
        """
        # Normaliser le chemin
        result = path
        result = PathManager.remove_path_accents(result)
        result = PathManager.replace_path_spaces(result)
        result = PathManager.normalize_path(result)
            
        return result
    
    @staticmethod
    def has_path_accents(path: str) -> bool:
        """
        Vérifie si un chemin contient des caractères accentués.
        
        Args:
            path: Chemin à vérifier.
            
        Returns:
            True si le chemin contient des caractères accentués, False sinon.
        """
        # Vérifier si le chemin contient des caractères accentués
        accent_pattern = r'[àáâäæãåāèéêëēėęîïíīįìôöòóœøōõûüùúūÿçÀÁÂÄÆÃÅĀÈÉÊËĒĖĘÎÏÍĪĮÌÔÖÒÓŒØŌÕÛÜÙÚŪŸÇ]'
        return bool(re.search(accent_pattern, path))
    
    @staticmethod
    def has_path_spaces(path: str) -> bool:
        """
        Vérifie si un chemin contient des espaces.
        
        Args:
            path: Chemin à vérifier.
            
        Returns:
            True si le chemin contient des espaces, False sinon.
        """
        # Vérifier si le chemin contient des espaces
        return ' ' in path
    
    def find_files(self, directory: Union[str, Path], pattern: Union[str, List[str]] = "*",
                  recurse: bool = False, exclude_directories: List[str] = None,
                  exclude_files: List[str] = None, include_pattern: str = "") -> List[str]:
        """
        Recherche des fichiers dans un répertoire avec des options avancées.
        
        Args:
            directory: Répertoire dans lequel rechercher les fichiers.
            pattern: Modèle de recherche pour les fichiers. Peut être une chaîne ou un tableau de chaînes.
            recurse: Si True, recherche récursivement dans les sous-répertoires.
            exclude_directories: Liste de noms de répertoires à exclure de la recherche.
            exclude_files: Liste de noms de fichiers à exclure de la recherche.
            include_pattern: Modèle supplémentaire pour filtrer les fichiers inclus.
            
        Returns:
            Liste des chemins de fichiers trouvés.
        """
        # Convertir en Path si nécessaire
        if isinstance(directory, str):
            directory = Path(directory)
            
        # Vérifier que le répertoire existe
        if not directory.exists():
            raise FileNotFoundError(f"Le répertoire n'existe pas: {directory}")
            
        # Initialiser les listes d'exclusion
        if exclude_directories is None:
            exclude_directories = []
        if exclude_files is None:
            exclude_files = []
            
        # Convertir les listes en ensembles pour une recherche plus rapide
        exclude_dirs_set = set(exclude_directories)
        exclude_files_set = set(exclude_files)
        
        # Convertir pattern en liste si nécessaire
        if isinstance(pattern, str):
            patterns = [pattern]
        else:
            patterns = pattern
            
        # Fonction récursive pour rechercher des fichiers
        def find_files_recursive(current_dir: Path, file_patterns: List[str], exclude_dirs: Set[str],
                               exclude_files: Set[str], include_pat: str) -> List[str]:
            results = []
            
            # Obtenir tous les fichiers correspondant aux modèles dans le répertoire courant
            for file_pattern in file_patterns:
                for file_path in current_dir.glob(file_pattern):
                    if not file_path.is_file():
                        continue
                        
                    # Vérifier si le fichier doit être exclu
                    if file_path.name in exclude_files:
                        continue
                        
                    # Vérifier si le fichier correspond au modèle d'inclusion
                    if include_pat and include_pat not in file_path.name:
                        continue
                        
                    results.append(str(file_path))
            
            # Si récursif, rechercher dans les sous-répertoires
            if recurse:
                for subdir in current_dir.iterdir():
                    if not subdir.is_dir():
                        continue
                        
                    # Vérifier si le répertoire doit être exclu
                    if subdir.name in exclude_dirs:
                        continue
                        
                    results.extend(find_files_recursive(subdir, file_patterns, exclude_dirs, exclude_files, include_pat))
                    
            return results
        
        # Rechercher les fichiers
        files = find_files_recursive(directory, patterns, exclude_dirs_set, exclude_files_set, include_pattern)
        
        return files


# Créer une instance globale du gestionnaire de chemins
path_manager = PathManager()


def get_project_path(relative_path: str, base_path: str = "") -> Path:
    """
    Obtient le chemin absolu à partir d'un chemin relatif au répertoire racine du projet.
    
    Args:
        relative_path: Chemin relatif au répertoire racine du projet.
        base_path: Chemin de base à utiliser pour la résolution. Par défaut, utilise le répertoire racine du projet.
        
    Returns:
        Chemin absolu.
    """
    return path_manager.get_project_path(relative_path, base_path)


def get_relative_path(absolute_path: Union[str, Path], base_path: str = "") -> str:
    """
    Obtient le chemin relatif à partir d'un chemin absolu.
    
    Args:
        absolute_path: Chemin absolu à convertir.
        base_path: Chemin de base à utiliser pour la conversion. Par défaut, utilise le répertoire racine du projet.
        
    Returns:
        Chemin relatif.
    """
    return path_manager.get_relative_path(absolute_path, base_path)


def normalize_path(path: Union[str, Path], force_windows_style: bool = False, force_unix_style: bool = False) -> str:
    """
    Normalise un chemin en fonction du système d'exploitation.
    
    Args:
        path: Chemin à normaliser.
        force_windows_style: Si True, force l'utilisation du style Windows (backslashes).
        force_unix_style: Si True, force l'utilisation du style Unix (forward slashes).
        
    Returns:
        Chemin normalisé.
    """
    return PathManager.normalize_path(path, force_windows_style, force_unix_style)


def remove_path_accents(path: str) -> str:
    """
    Convertit un chemin avec des caractères accentués en chemin sans accents.
    
    Args:
        path: Chemin à convertir.
        
    Returns:
        Chemin sans accents.
    """
    return PathManager.remove_path_accents(path)


def replace_path_spaces(path: str) -> str:
    """
    Convertit un chemin avec des espaces en chemin avec des underscores.
    
    Args:
        path: Chemin à convertir.
        
    Returns:
        Chemin avec des underscores.
    """
    return PathManager.replace_path_spaces(path)


def normalize_path_full(path: str) -> str:
    """
    Normalise un chemin en remplaçant les caractères accentués et les espaces.
    
    Args:
        path: Chemin à normaliser.
        
    Returns:
        Chemin normalisé.
    """
    return PathManager.normalize_path_full(path)


def has_path_accents(path: str) -> bool:
    """
    Vérifie si un chemin contient des caractères accentués.
    
    Args:
        path: Chemin à vérifier.
        
    Returns:
        True si le chemin contient des caractères accentués, False sinon.
    """
    return PathManager.has_path_accents(path)


def has_path_spaces(path: str) -> bool:
    """
    Vérifie si un chemin contient des espaces.
    
    Args:
        path: Chemin à vérifier.
        
    Returns:
        True si le chemin contient des espaces, False sinon.
    """
    return PathManager.has_path_spaces(path)


def find_files(directory: Union[str, Path], pattern: Union[str, List[str]] = "*",
              recurse: bool = False, exclude_directories: List[str] = None,
              exclude_files: List[str] = None, include_pattern: str = "") -> List[str]:
    """
    Recherche des fichiers dans un répertoire avec des options avancées.
    
    Args:
        directory: Répertoire dans lequel rechercher les fichiers.
        pattern: Modèle de recherche pour les fichiers. Peut être une chaîne ou un tableau de chaînes.
        recurse: Si True, recherche récursivement dans les sous-répertoires.
        exclude_directories: Liste de noms de répertoires à exclure de la recherche.
        exclude_files: Liste de noms de fichiers à exclure de la recherche.
        include_pattern: Modèle supplémentaire pour filtrer les fichiers inclus.
        
    Returns:
        Liste des chemins de fichiers trouvés.
    """
    return path_manager.find_files(directory, pattern, recurse, exclude_directories, exclude_files, include_pattern)


if __name__ == "__main__":
    # Exemple d'utilisation
    print(f"Répertoire racine du projet: {path_manager.project_root}")
    print(f"Chemin absolu de 'scripts/utils': {get_project_path('scripts/utils')}")
    print(f"Chemin relatif de '{path_manager.project_root}/scripts/utils': {get_relative_path(path_manager.project_root / 'scripts' / 'utils')}")
    print(f"Normalisation de 'scripts/utils': {normalize_path('scripts/utils')}")
    print(f"Normalisation de 'scripts\\utils': {normalize_path('scripts\\utils')}")
    print(f"Normalisation de 'scripts/utils' (style Windows): {normalize_path('scripts/utils', force_windows_style=True)}")
    print(f"Normalisation de 'scripts\\utils' (style Unix): {normalize_path('scripts\\utils', force_unix_style=True)}")
    print(f"Suppression des accents de 'scripts/utilitès': {remove_path_accents('scripts/utilitès')}")
    print(f"Remplacement des espaces de 'scripts/utils test': {replace_path_spaces('scripts/utils test')}")
    print(f"Normalisation complète de 'scripts/utilitès test': {normalize_path_full('scripts/utilitès test')}")
    print(f"'scripts/utilitès' contient des accents: {has_path_accents('scripts/utilitès')}")
    print(f"'scripts/utils test' contient des espaces: {has_path_spaces('scripts/utils test')}")
    print(f"Recherche de fichiers '*.py' dans 'scripts': {find_files('scripts', '*.py', recurse=True)}")
