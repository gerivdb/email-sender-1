#!/usr/bin/env python3
# diff_edit.py
"""
Script CLI minimal pour appliquer un patch diff Edit (SEARCH/REPLACE) sur un fichier texte.
Usage :
    python diff_edit.py --file <fichier> --patch <bloc_diff_edit.txt> [--dry-run]
"""
import argparse
import os
import sys
import shutil
from datetime import datetime


def parse_diff_edit_block(patch_path):
    with open(patch_path, encoding='utf-8') as f:
        lines = f.read().splitlines()
    try:
        start = lines.index('------- SEARCH') + 1
        sep = lines.index('=======')
        end = lines.index('+++++++ REPLACE')
        search = '\n'.join(lines[start:sep])
        replace = '\n'.join(lines[sep+1:end])
        return search, replace
    except ValueError:
        print('Erreur : format du bloc diff Edit invalide.')
        sys.exit(1)

def backup_file(file_path):
    backup_path = f"{file_path}.bak_{datetime.now().strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(file_path, backup_path)
    return backup_path

def main():
    parser = argparse.ArgumentParser(description='Applique un patch diff Edit SEARCH/REPLACE sur un fichier texte.')
    parser.add_argument('--file', required=True, help='Fichier cible à modifier')
    parser.add_argument('--patch', required=True, help='Fichier contenant le bloc diff Edit')
    parser.add_argument('--dry-run', action='store_true', help='Prévisualiser le diff sans appliquer la modification')
    args = parser.parse_args()

    # Lecture du fichier cible
    try:
        with open(args.file, encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Erreur de lecture du fichier cible : {e}")
        sys.exit(1)

    # Lecture du bloc diff Edit
    search, replace = parse_diff_edit_block(args.patch)

    # Vérification de la présence du bloc SEARCH
    if content.count(search) == 0:
        print('Erreur : bloc SEARCH non trouvé dans le fichier cible.')
        sys.exit(2)
    if content.count(search) > 1:
        print('Erreur : bloc SEARCH non unique dans le fichier cible.')
        sys.exit(3)

    new_content = content.replace(search, replace, 1)

    if args.dry_run:
        print('--- DIFF (dry-run) ---')
        print('--- AVANT ---')
        print(search)
        print('--- APRES ---')
        print(replace)
        print('Aucune modification appliquée (dry-run).')
        sys.exit(0)

    # Backup avant modification
    backup_path = backup_file(args.file)
    print(f'Backup créé : {backup_path}')

    # Application du patch
    try:
        with open(args.file, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print('Modification appliquée avec succès.')
    except Exception as e:
        print(f"Erreur lors de l'écriture du fichier : {e}")
        sys.exit(4)

    # Log
    print(f"Patch appliqué sur {args.file} à {datetime.now().isoformat()}")

if __name__ == '__main__':
    main()
