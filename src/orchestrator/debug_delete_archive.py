#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage pour la classe ThematicDeleteArchive.
"""

import os
import sys
import tempfile
import shutil
import json
import copy
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Débogage de ThematicDeleteArchive...")

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
    
    # Créer un élément de test
    item_id = "test_item"
    item = {
        "id": item_id,
        "content": "Contenu de test",
        "metadata": {
            "title": "Titre de test",
            "author": "Auteur de test",
            "tags": ["test", "debug"],
            "themes": {
                "test_theme": 0.8
            }
        }
    }
    
    # Sauvegarder l'élément dans le stockage
    item_path = os.path.join(storage_path, f"{item_id}.json")
    print(f"Sauvegarde de l'élément dans {item_path}...")
    with open(item_path, 'w', encoding='utf-8') as f:
        json.dump(item, f, ensure_ascii=False, indent=2)
    
    # Créer un répertoire thématique
    theme_dir = os.path.join(storage_path, "test_theme")
    os.makedirs(theme_dir, exist_ok=True)
    
    # Sauvegarder l'élément dans le répertoire thématique
    theme_path = os.path.join(theme_dir, f"{item_id}.json")
    print(f"Sauvegarde de l'élément dans {theme_path}...")
    with open(theme_path, 'w', encoding='utf-8') as f:
        json.dump(item, f, ensure_ascii=False, indent=2)
    
    # Importer la classe ThematicDeleteArchive
    print("Importation de ThematicDeleteArchive...")
    from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
    print("ThematicDeleteArchive importé.")
    
    # Créer une instance de ThematicDeleteArchive
    print("Création d'une instance de ThematicDeleteArchive...")
    delete_archive = ThematicDeleteArchive(storage_path, archive_path)
    print("Instance de ThematicDeleteArchive créée.")
    
    # Tester la méthode _archive_item
    print("Test de la méthode _archive_item...")
    
    # Créer une copie de l'élément pour ne pas modifier l'original
    item_copy = copy.deepcopy(item)
    
    # Appeler la méthode _archive_item
    print("Appel de la méthode _archive_item...")
    delete_archive._archive_item(item_copy, "Test d'archivage")
    
    # Vérifier que l'élément a été archivé
    archive_path_item = os.path.join(archive_path, f"{item_id}.json")
    if os.path.exists(archive_path_item):
        print(f"L'élément a été archivé avec succès dans {archive_path_item}.")
    else:
        print(f"ERREUR: L'élément n'a pas été archivé dans {archive_path_item}.")
    
    # Vérifier que l'élément a été archivé dans le répertoire thématique
    archive_theme_dir = os.path.join(archive_path, "test_theme")
    archive_theme_path = os.path.join(archive_theme_dir, f"{item_id}.json")
    if os.path.exists(archive_theme_path):
        print(f"L'élément a été archivé avec succès dans {archive_theme_path}.")
    else:
        print(f"ERREUR: L'élément n'a pas été archivé dans {archive_theme_path}.")
    
    # Tester la méthode archive_item
    print("Test de la méthode archive_item...")
    result = delete_archive.archive_item(item_id, "Test d'archivage via archive_item")
    print(f"Résultat de archive_item: {result}")
    
    # Tester la méthode get_archived_items
    print("Test de la méthode get_archived_items...")
    archived_items = delete_archive.get_archived_items()
    print(f"Nombre d'éléments archivés: {len(archived_items)}")
    
    if archived_items:
        print(f"Premier élément archivé: {archived_items[0]['id']}")
        print(f"Raison de l'archivage: {archived_items[0]['metadata'].get('archive_reason', 'Non spécifiée')}")
    
    # Tester la méthode get_archived_items_by_theme
    print("Test de la méthode get_archived_items_by_theme...")
    themed_items = delete_archive.get_archived_items_by_theme("test_theme")
    print(f"Nombre d'éléments archivés du thème 'test_theme': {len(themed_items)}")
    
    if themed_items:
        print(f"Premier élément archivé du thème 'test_theme': {themed_items[0]['id']}")
    
    print("Débogage de ThematicDeleteArchive terminé avec succès.")

except Exception as e:
    print(f"ERREUR: {str(e)}")
    traceback.print_exc()

finally:
    # Supprimer le répertoire temporaire
    print(f"Suppression du répertoire temporaire {temp_dir}...")
    shutil.rmtree(temp_dir)
