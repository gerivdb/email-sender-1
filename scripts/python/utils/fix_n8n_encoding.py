#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Correcteur d'encodage pour workflows n8n
----------------------------------------
Ce script corrige les problèmes d'encodage des caractères accentués
dans les workflows n8n. Il recherche les fichiers JSON de workflow,
détecte les problèmes d'encodage et les corrige.
"""

import json
import os
import re
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Union

def fix_encoding_in_json(json_data: Dict) -> Dict:
    """
    Corrige les problèmes d'encodage dans les données JSON.
    
    Args:
        json_data: Données JSON à corriger
        
    Returns:
        Données JSON corrigées
    """
    # Convertir en chaîne pour effectuer les remplacements
    json_str = json.dumps(json_data)
    
    # Corrections courantes pour les caractères accentués mal encodés
    replacements = {
        'Ã©': 'é', 'Ã¨': 'è', 'Ã§': 'ç', 'Ãª': 'ê', 'Ã¢': 'â',
        'Ã´': 'ô', 'Ã»': 'û', 'Ã®': 'î', 'Ã¯': 'ï', 'Ã¤': 'ä',
        'Ã¶': 'ö', 'Ã¼': 'ü', 'Ã«': 'ë', 'Ã¿': 'ÿ', 'Ã±': 'ñ',
        'â€™': "'", 'â€œ': '"', 'â€': '"', 'â€"': '–', 'â€"': '—',
        'â€¦': '…', 'â€¢': '•', 'â€ ': ' ', 'â€‹': ' '
    }
    
    for bad_encoding, correct_char in replacements.items():
        json_str = json_str.replace(bad_encoding, correct_char)
    
    # Remplacer les caractères accentués par leurs équivalents non accentués
    accent_replacements = {
        'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
        'à': 'a', 'â': 'a', 'ä': 'a',
        'î': 'i', 'ï': 'i',
        'ô': 'o', 'ö': 'o',
        'ù': 'u', 'û': 'u', 'ü': 'u',
        'ç': 'c', 'ÿ': 'y',
        'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
        'À': 'A', 'Â': 'A', 'Ä': 'A',
        'Î': 'I', 'Ï': 'I',
        'Ô': 'O', 'Ö': 'O',
        'Ù': 'U', 'Û': 'U', 'Ü': 'U',
        'Ç': 'C', 'Ÿ': 'Y'
    }
    
    for accent, replacement in accent_replacements.items():
        json_str = json_str.replace(accent, replacement)
    
    # Reconvertir en objet JSON
    return json.loads(json_str)

def fix_workflow_files(directory: Union[str, Path], 
                      create_backup: bool = True,
                      recursive: bool = True) -> List[Dict]:
    """
    Corrige les problèmes d'encodage dans les fichiers de workflow n8n.
    
    Args:
        directory: Répertoire contenant les fichiers de workflow
        create_backup: Si True, crée une sauvegarde avant modification
        recursive: Si True, recherche récursivement dans les sous-répertoires
        
    Returns:
        Liste des fichiers corrigés avec leurs chemins
    """
    directory = Path(directory)
    fixed_files = []
    
    # Définir le motif de recherche
    pattern = "**/*.json" if recursive else "*.json"
    
    for file_path in directory.glob(pattern):
        try:
            # Vérifier si c'est un workflow n8n
            with open(file_path, 'r', encoding='utf-8') as f:
                try:
                    data = json.load(f)
                    
                    # Vérifier si c'est un workflow n8n (contient des nœuds)
                    if not isinstance(data, dict) or "nodes" not in data:
                        continue
                        
                    # Créer une sauvegarde si demandé
                    if create_backup:
                        backup_path = file_path.with_suffix(f"{file_path.suffix}.bak")
                        shutil.copy2(str(file_path), str(backup_path))
                        print(f"Sauvegarde créée: {backup_path}")
                    
                    # Corriger l'encodage
                    fixed_data = fix_encoding_in_json(data)
                    
                    # Écrire les données corrigées
                    with open(file_path, 'w', encoding='utf-8') as f:
                        json.dump(fixed_data, f, ensure_ascii=False, indent=2)
                    
                    print(f"Corrigé: {file_path}")
                    fixed_files.append({"path": str(file_path), "name": file_path.name})
                    
                except json.JSONDecodeError:
                    print(f"Erreur: {file_path} n'est pas un fichier JSON valide")
                    
        except Exception as e:
            print(f"Erreur lors du traitement de {file_path}: {str(e)}")
    
    return fixed_files

def main():
    """Fonction principale pour l'exécution en ligne de commande."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Correcteur d'encodage pour workflows n8n")
    parser.add_argument("--dir", "-d", default=".", help="Répertoire à analyser")
    parser.add_argument("--no-backup", action="store_true", help="Ne pas créer de sauvegarde")
    parser.add_argument("--no-recursive", action="store_true", help="Ne pas rechercher récursivement")
    
    args = parser.parse_args()
    
    print(f"Correction des problèmes d'encodage dans: {args.dir}")
    fixed_files = fix_workflow_files(
        args.dir, 
        create_backup=not args.no_backup,
        recursive=not args.no_recursive
    )
    
    print(f"\nNombre de fichiers corrigés: {len(fixed_files)}")
    
    if fixed_files:
        print("\nFichiers corrigés:")
        for file_info in fixed_files:
            print(f"  - {file_info['name']}")

if __name__ == "__main__":
    main()
