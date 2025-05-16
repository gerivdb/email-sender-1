#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage simple.
"""

import os
import sys
import tempfile
import shutil
import json
import traceback
from pathlib import Path

def main():
    """Point d'entrée principal du script de débogage simple."""
    print("Débogage simple...")
    
    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")
    
    try:
        # Créer un fichier
        test_file = os.path.join(temp_dir, "test.json")
        data = {"test": "value"}
        
        print(f"Écriture dans le fichier {test_file}...")
        with open(test_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Vérifier que le fichier existe
        if os.path.exists(test_file):
            print(f"Le fichier {test_file} a été créé avec succès.")
        else:
            print(f"ERREUR: Le fichier {test_file} n'a pas été créé.")
            return 1
        
        # Lire le fichier
        print(f"Lecture du fichier {test_file}...")
        with open(test_file, 'r', encoding='utf-8') as f:
            read_data = json.load(f)
        
        # Vérifier que les données sont correctes
        if read_data == data:
            print("Les données ont été lues correctement.")
        else:
            print(f"ERREUR: Les données lues ne correspondent pas aux données écrites.")
            print(f"Données écrites: {data}")
            print(f"Données lues: {read_data}")
            return 1
        
        print("Débogage simple terminé avec succès.")
        return 0
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return 1
    
    finally:
        # Supprimer le répertoire temporaire
        print(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    sys.exit(main())
