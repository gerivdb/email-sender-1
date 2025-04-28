#!/usr/bin/env python
"""
Script batch pour appliquer fix_markdown_v3.py à tous les fichiers Markdown d'un répertoire.
"""

import os
import sys
import argparse
import subprocess
import logging
from pathlib import Path
from typing import List, Optional, Set
import time

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("batch_fix_markdown.log", mode="w", encoding="utf-8")
    ]
)

def find_markdown_files(
    root_dir: Path,
    exclude_dirs: Optional[List[str]] = None,
    exclude_files: Optional[List[str]] = None,
    include_pattern: Optional[str] = None,
    recursive: bool = True
) -> List[Path]:
    """
    Trouve tous les fichiers Markdown dans le répertoire spécifié.
    
    Args:
        root_dir: Répertoire racine pour la recherche
        exclude_dirs: Liste de noms de répertoires à exclure
        exclude_files: Liste de noms de fichiers à exclure
        include_pattern: Motif pour filtrer les fichiers (ex: "phase")
        recursive: Si True, recherche récursivement dans les sous-répertoires
        
    Returns:
        Liste des chemins de fichiers Markdown trouvés
    """
    if exclude_dirs is None:
        exclude_dirs = []
    if exclude_files is None:
        exclude_files = []
    
    # Convertir les exclusions en ensembles pour une recherche plus rapide
    exclude_dirs_set = set(d.lower() for d in exclude_dirs)
    exclude_files_set = set(f.lower() for f in exclude_files)
    
    # Ajouter automatiquement les répertoires communs à exclure
    exclude_dirs_set.update(['.git', '.venv', 'node_modules', '__pycache__'])
    
    # Ajouter les fichiers restructurés à exclure
    exclude_patterns = ['-restructured.md', '-restructuré.md']
    
    markdown_files = []
    
    if recursive:
        # Recherche récursive
        for root, dirs, files in os.walk(root_dir):
            # Filtrer les répertoires exclus
            dirs[:] = [d for d in dirs if d.lower() not in exclude_dirs_set]
            
            for file in files:
                if file.lower().endswith('.md'):
                    # Vérifier si le fichier doit être exclu
                    if file.lower() in exclude_files_set:
                        continue
                        
                    # Vérifier si le fichier correspond à un motif d'exclusion
                    if any(pattern in file for pattern in exclude_patterns):
                        continue
                        
                    # Vérifier si le fichier correspond au motif d'inclusion
                    if include_pattern and include_pattern.lower() not in file.lower():
                        continue
                        
                    markdown_files.append(Path(root) / file)
    else:
        # Recherche non récursive (uniquement dans le répertoire racine)
        for file in os.listdir(root_dir):
            if file.lower().endswith('.md'):
                # Vérifier si le fichier doit être exclu
                if file.lower() in exclude_files_set:
                    continue
                    
                # Vérifier si le fichier correspond à un motif d'exclusion
                if any(pattern in file for pattern in exclude_patterns):
                    continue
                    
                # Vérifier si le fichier correspond au motif d'inclusion
                if include_pattern and include_pattern.lower() not in file.lower():
                    continue
                    
                markdown_files.append(root_dir / file)
    
    return sorted(markdown_files)

def process_markdown_file(
    file_path: Path,
    fix_script_path: Path,
    additional_args: List[str] = None,
    dry_run: bool = False
) -> bool:
    """
    Applique le script fix_markdown_v3.py à un fichier Markdown.
    
    Args:
        file_path: Chemin du fichier Markdown à traiter
        fix_script_path: Chemin du script fix_markdown_v3.py
        additional_args: Arguments supplémentaires à passer au script
        dry_run: Si True, affiche la commande sans l'exécuter
        
    Returns:
        True si le traitement a réussi, False sinon
    """
    if not file_path.exists():
        logging.error(f"Fichier non trouvé: {file_path}")
        return False
        
    cmd = [sys.executable, str(fix_script_path), str(file_path)]
    
    if additional_args:
        cmd.extend(additional_args)
        
    cmd_str = " ".join(cmd)
    
    if dry_run:
        logging.info(f"[DRY RUN] Commande: {cmd_str}")
        return True
        
    logging.info(f"Traitement de {file_path}")
    logging.debug(f"Commande: {cmd_str}")
    
    try:
        start_time = time.time()
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        elapsed_time = time.time() - start_time
        
        if result.stdout:
            logging.debug(f"Sortie: {result.stdout}")
            
        logging.info(f"Traitement réussi en {elapsed_time:.2f}s: {file_path}")
        return True
        
    except subprocess.CalledProcessError as e:
        logging.error(f"Erreur lors du traitement de {file_path}: {e}")
        if e.stdout:
            logging.error(f"Sortie standard: {e.stdout}")
        if e.stderr:
            logging.error(f"Erreur standard: {e.stderr}")
        return False
        
    except Exception as e:
        logging.error(f"Exception lors du traitement de {file_path}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Applique fix_markdown_v3.py à tous les fichiers Markdown d'un répertoire."
    )
    parser.add_argument(
        "--dir",
        type=Path,
        default=Path("."),
        help="Répertoire racine contenant les fichiers Markdown (défaut: répertoire courant)"
    )
    parser.add_argument(
        "--script",
        type=Path,
        default=Path("development/scripts/fix_markdown_v3.py"),
        help="Chemin vers le script fix_markdown_v3.py (défaut: development/scripts/fix_markdown_v3.py)"
    )
    parser.add_argument(
        "--exclude-dir",
        action="append",
        default=[],
        help="Répertoire à exclure (peut être utilisé plusieurs fois)"
    )
    parser.add_argument(
        "--exclude-file",
        action="append",
        default=[],
        help="Fichier à exclure (peut être utilisé plusieurs fois)"
    )
    parser.add_argument(
        "--include",
        type=str,
        default=None,
        help="Motif pour filtrer les fichiers (ex: 'phase' pour ne traiter que les fichiers contenant 'phase')"
    )
    parser.add_argument(
        "--non-recursive",
        action="store_false",
        dest="recursive",
        help="Ne pas rechercher récursivement dans les sous-répertoires"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Afficher les commandes sans les exécuter"
    )
    parser.add_argument(
        "--script-args",
        nargs=argparse.REMAINDER,
        help="Arguments supplémentaires à passer au script fix_markdown_v3.py"
    )
    
    args = parser.parse_args()
    
    root_dir = args.dir.resolve()
    fix_script_path = args.script.resolve()
    
    if not root_dir.is_dir():
        logging.error(f"Le répertoire spécifié n'existe pas: {root_dir}")
        return 1
        
    if not fix_script_path.is_file():
        logging.error(f"Le script fix_markdown_v3.py n'existe pas: {fix_script_path}")
        return 1
        
    logging.info(f"Recherche de fichiers Markdown dans: {root_dir}")
    logging.info(f"Utilisation du script: {fix_script_path}")
    
    if args.exclude_dir:
        logging.info(f"Répertoires exclus: {', '.join(args.exclude_dir)}")
    if args.exclude_file:
        logging.info(f"Fichiers exclus: {', '.join(args.exclude_file)}")
    if args.include:
        logging.info(f"Filtre d'inclusion: {args.include}")
    if not args.recursive:
        logging.info("Mode non récursif: recherche uniquement dans le répertoire racine")
    if args.dry_run:
        logging.info("Mode dry-run: les commandes seront affichées mais non exécutées")
    if args.script_args:
        logging.info(f"Arguments supplémentaires: {' '.join(args.script_args)}")
        
    markdown_files = find_markdown_files(
        root_dir=root_dir,
        exclude_dirs=args.exclude_dir,
        exclude_files=args.exclude_file,
        include_pattern=args.include,
        recursive=args.recursive
    )
    
    if not markdown_files:
        logging.warning("Aucun fichier Markdown trouvé.")
        return 0
        
    logging.info(f"Nombre de fichiers Markdown trouvés: {len(markdown_files)}")
    
    success_count = 0
    failure_count = 0
    
    for file_path in markdown_files:
        if process_markdown_file(
            file_path=file_path,
            fix_script_path=fix_script_path,
            additional_args=args.script_args,
            dry_run=args.dry_run
        ):
            success_count += 1
        else:
            failure_count += 1
            
    logging.info(f"Traitement terminé. Succès: {success_count}, Échecs: {failure_count}")
    
    if failure_count > 0:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
