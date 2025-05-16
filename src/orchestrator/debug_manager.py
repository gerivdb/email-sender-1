#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage pour le gestionnaire CRUD.
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

print("Débogage du gestionnaire CRUD...")

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
    print("Importation de ThematicCRUDManager...")
    from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
    print("ThematicCRUDManager importé.")
    
    # Créer un gestionnaire CRUD
    print("Création d'un gestionnaire CRUD...")
    manager = ThematicCRUDManager(storage_path, archive_path)
    print("Gestionnaire CRUD créé avec succès.")
    print(f"Chemin de stockage: {manager.storage_path}")
    print(f"Chemin d'archivage: {manager.archive_path}")
    
    # Créer un élément
    print("Création d'un élément...")
    content = "Ce document décrit l'architecture du système."
    metadata = {
        "title": "Architecture du système",
        "author": "John Doe",
        "tags": ["architecture", "conception", "système"]
    }
    
    item = manager.create_item(content, metadata)
    print(f"Élément créé avec l'ID: {item['id']}")
    print(f"Thèmes attribués: {item['metadata'].get('themes', {})}")
    
    # Récupérer l'élément
    print("Récupération de l'élément...")
    retrieved_item = manager.get_item(item["id"])
    if retrieved_item:
        print(f"Élément récupéré avec l'ID: {retrieved_item['id']}")
    else:
        print("ERREUR: Impossible de récupérer l'élément.")
    
    # Archiver l'élément
    print("Archivage de l'élément...")
    result = manager.archive_item(item["id"], "Test d'archivage")
    print(f"Résultat de l'archivage: {result}")
    
    # Récupérer les éléments archivés
    print("Récupération des éléments archivés...")
    archived_items = manager.get_archived_items()
    print(f"Nombre d'éléments archivés: {len(archived_items)}")
    
    if archived_items:
        print(f"Premier élément archivé: {archived_items[0]['id']}")
        print(f"Raison de l'archivage: {archived_items[0]['metadata'].get('archive_reason', 'Non spécifiée')}")
    
    # Récupérer les éléments archivés par thème
    print("Récupération des éléments archivés par thème...")
    for theme in item["metadata"].get("themes", {}):
        print(f"Récupération des éléments archivés du thème '{theme}'...")
        themed_items = manager.get_archived_items_by_theme(theme)
        print(f"Nombre d'éléments archivés du thème '{theme}': {len(themed_items)}")
        
        if themed_items:
            print(f"Premier élément archivé du thème '{theme}': {themed_items[0]['id']}")
    
    # Restaurer l'élément archivé
    print("Restauration de l'élément archivé...")
    result = manager.restore_archived_item(item["id"])
    print(f"Résultat de la restauration: {result}")
    
    # Vérifier que l'élément a été restauré
    print("Vérification de la restauration...")
    restored_item = manager.get_item(item["id"])
    if restored_item:
        print(f"Élément restauré avec l'ID: {restored_item['id']}")
    else:
        print("ERREUR: Impossible de récupérer l'élément restauré.")
    
    # Supprimer l'élément
    print("Suppression de l'élément...")
    result = manager.delete_item(item["id"], permanent=False, reason="Test de suppression")
    print(f"Résultat de la suppression: {result}")
    
    # Vérifier que l'élément a été supprimé
    print("Vérification de la suppression...")
    deleted_item = manager.get_item(item["id"])
    if deleted_item:
        print("ERREUR: L'élément n'a pas été supprimé.")
    else:
        print("L'élément a été supprimé avec succès.")
    
    # Vérifier que l'élément a été archivé lors de la suppression
    print("Vérification de l'archivage lors de la suppression...")
    archived_items = manager.get_archived_items()
    print(f"Nombre d'éléments archivés: {len(archived_items)}")
    
    if archived_items:
        print(f"Premier élément archivé: {archived_items[0]['id']}")
        print(f"Raison de l'archivage: {archived_items[0]['metadata'].get('archive_reason', 'Non spécifiée')}")
    
    print("Débogage du gestionnaire CRUD terminé avec succès.")

except Exception as e:
    print(f"ERREUR: {str(e)}")
    traceback.print_exc()

finally:
    # Supprimer le répertoire temporaire
    print(f"Suppression du répertoire temporaire {temp_dir}...")
    shutil.rmtree(temp_dir)
