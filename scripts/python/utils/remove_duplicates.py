#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Détecteur et suppresseur de fichiers en double
----------------------------------------------
Ce script détecte et supprime les fichiers en double dans un répertoire.
Il utilise le hachage de contenu pour identifier les doublons exacts.
"""

import hashlib
import os
import shutil
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple, Union

def calculate_file_hash(file_path: Path, block_size: int = 65536) -> str:
    """
    Calcule le hachage SHA-256 d'un fichier.
    
    Args:
        file_path: Chemin du fichier
        block_size: Taille du bloc pour la lecture du fichier
        
    Returns:
        Hachage SHA-256 du fichier
    """
    hasher = hashlib.sha256()
    
    with open(file_path, 'rb') as f:
        buf = f.read(block_size)
        while buf:
            hasher.update(buf)
            buf = f.read(block_size)
            
    return hasher.hexdigest()

def find_duplicates(directory: Union[str, Path], 
                   recursive: bool = True,
                   ignore_extensions: List[str] = None) -> Dict[str, List[Path]]:
    """
    Trouve les fichiers en double dans un répertoire.
    
    Args:
        directory: Répertoire à analyser
        recursive: Si True, recherche récursivement dans les sous-répertoires
        ignore_extensions: Liste des extensions de fichiers à ignorer
        
    Returns:
        Dictionnaire des hachages de fichiers avec leurs chemins
    """
    directory = Path(directory)
    
    if ignore_extensions is None:
        ignore_extensions = []
    else:
        # Normaliser les extensions (ajouter un point si nécessaire)
        ignore_extensions = [ext if ext.startswith('.') else f'.{ext}' for ext in ignore_extensions]
    
    # Dictionnaire pour stocker les fichiers par taille
    files_by_size = defaultdict(list)
    
    # Motif de recherche
    pattern = "**/*" if recursive else "*"
    
    # Première passe : regrouper les fichiers par taille
    for file_path in directory.glob(pattern):
        if file_path.is_file():
            # Ignorer les fichiers avec des extensions spécifiées
            if file_path.suffix.lower() in ignore_extensions:
                continue
                
            # Ajouter le fichier à la liste des fichiers de cette taille
            size = file_path.stat().st_size
            files_by_size[size].append(file_path)
    
    # Deuxième passe : calculer les hachages pour les fichiers de même taille
    duplicates = defaultdict(list)
    
    for size, files in files_by_size.items():
        # Ignorer les tailles uniques
        if len(files) < 2:
            continue
            
        # Calculer les hachages pour les fichiers de cette taille
        for file_path in files:
            try:
                file_hash = calculate_file_hash(file_path)
                duplicates[file_hash].append(file_path)
            except Exception as e:
                print(f"Erreur lors du calcul du hachage de {file_path}: {str(e)}")
    
    # Filtrer pour ne garder que les hachages avec des doublons
    return {h: files for h, files in duplicates.items() if len(files) > 1}

def remove_duplicates(duplicates: Dict[str, List[Path]], 
                     keep_strategy: str = "newest",
                     move_to_dir: Union[str, Path, None] = None) -> Dict[str, List[Path]]:
    """
    Supprime les fichiers en double.
    
    Args:
        duplicates: Dictionnaire des hachages de fichiers avec leurs chemins
        keep_strategy: Stratégie pour choisir le fichier à conserver
                      ("newest", "oldest", "shortest_path", "longest_path")
        move_to_dir: Si spécifié, déplace les doublons dans ce répertoire au lieu de les supprimer
        
    Returns:
        Dictionnaire des fichiers supprimés par hachage
    """
    removed_files = defaultdict(list)
    
    if move_to_dir is not None:
        move_to_dir = Path(move_to_dir)
        move_to_dir.mkdir(parents=True, exist_ok=True)
    
    for file_hash, file_paths in duplicates.items():
        # Déterminer le fichier à conserver
        if keep_strategy == "newest":
            files_sorted = sorted(file_paths, key=lambda p: p.stat().st_mtime, reverse=True)
        elif keep_strategy == "oldest":
            files_sorted = sorted(file_paths, key=lambda p: p.stat().st_mtime)
        elif keep_strategy == "shortest_path":
            files_sorted = sorted(file_paths, key=lambda p: len(str(p)))
        elif keep_strategy == "longest_path":
            files_sorted = sorted(file_paths, key=lambda p: len(str(p)), reverse=True)
        else:
            raise ValueError(f"Stratégie non prise en charge: {keep_strategy}")
        
        # Le premier fichier est celui à conserver
        keep_file = files_sorted[0]
        
        # Supprimer ou déplacer les autres fichiers
        for file_path in files_sorted[1:]:
            try:
                if move_to_dir is not None:
                    # Créer un nom unique pour le fichier déplacé
                    dest_path = move_to_dir / f"{file_path.stem}_{file_hash[:8]}{file_path.suffix}"
                    shutil.move(str(file_path), str(dest_path))
                    action = f"Déplacé vers {dest_path}"
                else:
                    os.remove(str(file_path))
                    action = "Supprimé"
                    
                print(f"{action}: {file_path} (doublon de {keep_file})")
                removed_files[file_hash].append(file_path)
            except Exception as e:
                print(f"Erreur lors de la suppression de {file_path}: {str(e)}")
    
    return dict(removed_files)

def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Détecteur et suppresseur de fichiers en double")
    parser.add_argument("--dir", "-d", default=".", help="Répertoire à analyser")
    parser.add_argument("--no-recursive", action="store_true", help="Ne pas rechercher récursivement")
    parser.add_argument("--ignore-ext", nargs="+", help="Extensions de fichiers à ignorer")
    parser.add_argument("--keep", choices=["newest", "oldest", "shortest_path", "longest_path"],
                       default="newest", help="Stratégie pour choisir le fichier à conserver")
    parser.add_argument("--move-to", help="Déplacer les doublons dans ce répertoire au lieu de les supprimer")
    parser.add_argument("--dry-run", action="store_true", help="Afficher les doublons sans les supprimer")
    
    args = parser.parse_args()
    
    print(f"Recherche de doublons dans: {args.dir}")
    duplicates = find_duplicates(
        args.dir, 
        recursive=not args.no_recursive,
        ignore_extensions=args.ignore_ext
    )
    
    total_duplicates = sum(len(files) - 1 for files in duplicates.values())
    print(f"\nNombre de doublons trouvés: {total_duplicates}")
    
    if duplicates:
        print("\nGroupes de fichiers en double:")
        for file_hash, file_paths in duplicates.items():
            print(f"\nGroupe (hash: {file_hash[:8]}...):")
            for file_path in file_paths:
                size_mb = file_path.stat().st_size / (1024 * 1024)
                print(f"  - {file_path} ({size_mb:.2f} Mo)")
        
        if not args.dry_run:
            print("\nSuppression des doublons...")
            removed_files = remove_duplicates(
                duplicates, 
                keep_strategy=args.keep,
                move_to_dir=args.move_to
            )
            
            total_removed = sum(len(files) for files in removed_files.values())
            print(f"\nNombre de fichiers supprimés/déplacés: {total_removed}")
        else:
            print("\nMode simulation (dry-run) - Aucun fichier n'a été supprimé.")

if __name__ == "__main__":
    main()
