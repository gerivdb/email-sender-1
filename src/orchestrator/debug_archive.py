#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage pour le mécanisme d'archivage thématique.
"""

import os
import sys
import tempfile
import shutil
import json
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

def debug_file_operations():
    """Teste les opérations de base sur les fichiers."""
    print("Test des opérations de base sur les fichiers...")
    
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
            return False
        
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
            return False
        
        # Créer un sous-répertoire
        sub_dir = os.path.join(temp_dir, "subdir")
        print(f"Création du sous-répertoire {sub_dir}...")
        os.makedirs(sub_dir, exist_ok=True)
        
        # Vérifier que le sous-répertoire existe
        if os.path.exists(sub_dir) and os.path.isdir(sub_dir):
            print(f"Le sous-répertoire {sub_dir} a été créé avec succès.")
        else:
            print(f"ERREUR: Le sous-répertoire {sub_dir} n'a pas été créé.")
            return False
        
        # Créer un fichier dans le sous-répertoire
        sub_file = os.path.join(sub_dir, "test.json")
        print(f"Écriture dans le fichier {sub_file}...")
        with open(sub_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        # Vérifier que le fichier existe
        if os.path.exists(sub_file):
            print(f"Le fichier {sub_file} a été créé avec succès.")
        else:
            print(f"ERREUR: Le fichier {sub_file} n'a pas été créé.")
            return False
        
        # Supprimer le fichier
        print(f"Suppression du fichier {test_file}...")
        os.remove(test_file)
        
        # Vérifier que le fichier a été supprimé
        if not os.path.exists(test_file):
            print(f"Le fichier {test_file} a été supprimé avec succès.")
        else:
            print(f"ERREUR: Le fichier {test_file} n'a pas été supprimé.")
            return False
        
        print("Test des opérations de base sur les fichiers terminé avec succès.")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return False
    
    finally:
        # Supprimer le répertoire temporaire
        print(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

def debug_import_modules():
    """Teste l'importation des modules nécessaires."""
    print("Test de l'importation des modules nécessaires...")
    
    try:
        # Importer les modules
        print("Importation de ThematicCRUDManager...")
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
        print("Importation réussie.")
        
        print("Importation de ThematicDeleteArchive...")
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        print("Importation réussie.")
        
        print("Test de l'importation des modules terminé avec succès.")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return False

def debug_create_manager():
    """Teste la création d'un gestionnaire CRUD."""
    print("Test de la création d'un gestionnaire CRUD...")
    
    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")
    
    try:
        # Créer les répertoires
        storage_path = os.path.join(temp_dir, "storage")
        archive_path = os.path.join(temp_dir, "archive")
        
        print(f"Création des répertoires {storage_path} et {archive_path}...")
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        
        # Importer le gestionnaire CRUD
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
        
        # Créer un gestionnaire CRUD
        print("Création d'un gestionnaire CRUD...")
        manager = ThematicCRUDManager(storage_path, archive_path)
        
        print("Gestionnaire CRUD créé avec succès.")
        print(f"Chemin de stockage: {manager.storage_path}")
        print(f"Chemin d'archivage: {manager.archive_path}")
        
        print("Test de la création d'un gestionnaire CRUD terminé avec succès.")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return False
    
    finally:
        # Supprimer le répertoire temporaire
        print(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

def main():
    """Point d'entrée principal du script de débogage."""
    print("Débogage du mécanisme d'archivage thématique...")
    
    # Test des opérations de base sur les fichiers
    if not debug_file_operations():
        print("ÉCHEC: Test des opérations de base sur les fichiers.")
        return 1
    
    print("\n" + "-" * 80 + "\n")
    
    # Test de l'importation des modules
    if not debug_import_modules():
        print("ÉCHEC: Test de l'importation des modules.")
        return 1
    
    print("\n" + "-" * 80 + "\n")
    
    # Test de la création d'un gestionnaire CRUD
    if not debug_create_manager():
        print("ÉCHEC: Test de la création d'un gestionnaire CRUD.")
        return 1
    
    print("\nTous les tests de débogage ont réussi!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
