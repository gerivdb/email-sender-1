#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Organisateur de dépôt GitHub
----------------------------
Ce script organise un dépôt selon les standards GitHub, en regroupant
les fichiers dans des répertoires appropriés et en maintenant la racine
du dépôt propre.
"""

import os
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Set, Tuple, Union

# Fichiers standards GitHub à conserver à la racine
GITHUB_STANDARD_FILES = {
    'README.md', 'LICENSE', 'CONTRIBUTING.md', 'CODE_OF_CONDUCT.md',
    '.gitignore', '.github', '.gitattributes', 'SECURITY.md',
    'CHANGELOG.md', 'CODEOWNERS', '.editorconfig'
}

# Fichiers à ne jamais déplacer automatiquement (exceptions personnalisées)
NEVER_MOVE_FILES = {
    'AGENT.md',  # Exception : ce fichier doit rester accessible à la racine
    # ...ajoutez d'autres exceptions ici si besoin...
}

# Extensions de fichiers à organiser par type
FILE_TYPE_DIRS = {
    '.md': 'docs',
    '.txt': 'docs',
    '.pdf': 'docs',
    '.cmd': 'scripts',
    '.bat': 'scripts',
    '.ps1': 'scripts',
    '.py': 'scripts',
    '.js': 'scripts',
    '.json': 'data',
    '.csv': 'data',
    '.xlsx': 'data',
    '.png': 'assets',
    '.jpg': 'assets',
    '.jpeg': 'assets',
    '.gif': 'assets',
    '.svg': 'assets'
}

def is_github_standard_file(file_path: Path) -> bool:
    """
    Vérifie si un fichier est un fichier standard GitHub.
    
    Args:
        file_path: Chemin du fichier
        
    Returns:
        True si le fichier est un fichier standard GitHub, False sinon
    """
    # Vérifier le nom du fichier
    if file_path.name in GITHUB_STANDARD_FILES:
        return True
        
    # Vérifier si le fichier est dans un répertoire standard
    for std_file in GITHUB_STANDARD_FILES:
        if std_file.startswith('.') and file_path.parts and file_path.parts[0] == std_file:
            return True
            
    return False

def organize_repo(repo_dir: Union[str, Path], 
                 create_backup: bool = True,
                 move_files: bool = True,
                 organize_workflows: bool = True) -> Dict[str, List[Path]]:
    """
    Organise un dépôt selon les standards GitHub.
    
    Args:
        repo_dir: Répertoire du dépôt
        create_backup: Si True, crée une sauvegarde avant modification
        move_files: Si True, déplace les fichiers; sinon, les copie
        organize_workflows: Si True, regroupe les dossiers de workflows
        
    Returns:
        Dictionnaire des fichiers organisés par catégorie
    """
    repo_dir = Path(repo_dir)
    
    # Créer une sauvegarde si demandé
    if create_backup:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir = repo_dir.parent / f"{repo_dir.name}_backup_{timestamp}"
        shutil.copytree(repo_dir, backup_dir)
        print(f"Sauvegarde créée: {backup_dir}")
    
    # Dictionnaire pour suivre les fichiers organisés
    organized_files = {}
    
    # Créer les répertoires nécessaires
    for dir_name in set(FILE_TYPE_DIRS.values()):
        (repo_dir / dir_name).mkdir(exist_ok=True)
    
    # Organiser les fichiers à la racine
    for file_path in repo_dir.glob("*"):
        # Ignorer les répertoires déjà créés
        if file_path.is_dir() and file_path.name in FILE_TYPE_DIRS.values():
            continue
            
        # Ignorer les fichiers standards GitHub
        if is_github_standard_file(file_path):
            continue
            
        # Ignorer les exceptions personnalisées
        if file_path.name in NEVER_MOVE_FILES:
            continue
            
        if file_path.is_file():
            # Déterminer le répertoire cible
            target_dir = FILE_TYPE_DIRS.get(file_path.suffix.lower())
            
            # Si l'extension n'est pas reconnue, utiliser 'misc'
            if target_dir is None:
                (repo_dir / 'misc').mkdir(exist_ok=True)
                target_dir = 'misc'
                
            # Créer le chemin cible
            target_path = repo_dir / target_dir / file_path.name
            
            # Éviter les conflits de noms
            if target_path.exists():
                timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
                target_path = repo_dir / target_dir / f"{file_path.stem}_{timestamp}{file_path.suffix}"
                
            # Déplacer ou copier le fichier
            if move_files:
                shutil.move(str(file_path), str(target_path))
                action = "Déplacé"
            else:
                shutil.copy2(str(file_path), str(target_path))
                action = "Copié"
                
            print(f"{action}: {file_path} -> {target_path}")
            
            # Ajouter à la liste des fichiers organisés
            if target_dir not in organized_files:
                organized_files[target_dir] = []
                
            organized_files[target_dir].append(target_path)
    
    # Organiser les dossiers de workflows si demandé
    if organize_workflows:
        workflow_dirs = []
        
        # Rechercher les dossiers de workflows
        for dir_path in repo_dir.glob("*"):
            if dir_path.is_dir() and "workflow" in dir_path.name.lower():
                workflow_dirs.append(dir_path)
                
        if workflow_dirs:
            # Créer le répertoire principal des workflows
            workflows_dir = repo_dir / "workflows"
            workflows_dir.mkdir(exist_ok=True)
            
            # Organiser chaque dossier de workflow
            for workflow_dir in workflow_dirs:
                # Extraire la version si présente dans le nom
                version_match = re.search(r'v(\d+(?:\.\d+)*)', workflow_dir.name, re.IGNORECASE)
                
                if version_match:
                    version = version_match.group(1)
                    target_dir = workflows_dir / f"v{version}"
                else:
                    target_dir = workflows_dir / workflow_dir.name
                    
                target_dir.mkdir(exist_ok=True)
                
                # Déplacer ou copier les fichiers
                for file_path in workflow_dir.glob("**/*"):
                    if file_path.is_file():
                        # Créer le chemin relatif
                        rel_path = file_path.relative_to(workflow_dir)
                        target_path = target_dir / rel_path
                        
                        # Créer les répertoires parents si nécessaires
                        target_path.parent.mkdir(parents=True, exist_ok=True)
                        
                        # Déplacer ou copier le fichier
                        if move_files:
                            shutil.move(str(file_path), str(target_path))
                            action = "Déplacé"
                        else:
                            shutil.copy2(str(file_path), str(target_path))
                            action = "Copié"
                            
                        print(f"{action}: {file_path} -> {target_path}")
                
                # Supprimer le répertoire source s'il est vide et si on a déplacé les fichiers
                if move_files and not any(workflow_dir.glob("*")):
                    workflow_dir.rmdir()
                    print(f"Supprimé le répertoire vide: {workflow_dir}")
            
            # Ajouter à la liste des fichiers organisés
            organized_files["workflows"] = list(workflows_dir.glob("**/*"))
    
    return organized_files

def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Organisateur de dépôt GitHub")
    parser.add_argument("--dir", "-d", default=".", help="Répertoire du dépôt")
    parser.add_argument("--no-backup", action="store_true", help="Ne pas créer de sauvegarde")
    parser.add_argument("--copy", action="store_true", help="Copier les fichiers au lieu de les déplacer")
    parser.add_argument("--no-workflows", action="store_true", help="Ne pas organiser les dossiers de workflows")
    
    args = parser.parse_args()
    
    print(f"Organisation du dépôt: {args.dir}")
    organized_files = organize_repo(
        args.dir, 
        create_backup=not args.no_backup,
        move_files=not args.copy,
        organize_workflows=not args.no_workflows
    )
    
    # Afficher un résumé
    print("\nRésumé de l'organisation:")
    for category, files in organized_files.items():
        print(f"  - {category}: {len(files)} fichiers")
    
    print("\nOrganisation terminée!")

if __name__ == "__main__":
    main()
