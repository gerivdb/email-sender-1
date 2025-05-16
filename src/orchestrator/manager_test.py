#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de test du gestionnaire CRUD.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

print("Test du gestionnaire CRUD...")

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
    
    print("Test du gestionnaire CRUD terminé avec succès.")

except Exception as e:
    print(f"ERREUR: {str(e)}")
    import traceback
    traceback.print_exc()

finally:
    # Supprimer le répertoire temporaire
    print(f"Suppression du répertoire temporaire {temp_dir}...")
    shutil.rmtree(temp_dir)
