#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test simple pour le mécanisme d'archivage thématique.
"""

import os
import sys
import tempfile
import shutil
import json
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

def main():
    """Test simple pour le mécanisme d'archivage thématique."""
    print("Test simple pour le mécanisme d'archivage thématique...")
    
    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    storage_path = os.path.join(temp_dir, "storage")
    archive_path = os.path.join(temp_dir, "archive")
    
    try:
        # Créer les répertoires
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        
        # Créer un gestionnaire CRUD
        manager = ThematicCRUDManager(storage_path, archive_path)
        
        # Créer un élément
        content = "Ce document décrit l'architecture du système."
        metadata = {
            "title": "Architecture du système",
            "author": "John Doe",
            "tags": ["architecture", "conception", "système"]
        }
        
        item = manager.create_item(content, metadata)
        print(f"Élément créé avec l'ID: {item['id']}")
        print(f"Thèmes attribués: {item['metadata'].get('themes', {})}")
        
        # Archiver l'élément
        result = manager.archive_item(item["id"])
        print(f"Archivage de l'élément: {result}")
        
        # Récupérer les éléments archivés
        archived_items = manager.get_archived_items()
        print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        if archived_items:
            print(f"Premier élément archivé: {archived_items[0]['id']}")
            print(f"Thèmes de l'élément archivé: {archived_items[0]['metadata'].get('themes', {})}")
            
            # Récupérer les éléments archivés par thème
            for theme in archived_items[0]['metadata'].get('themes', {}):
                print(f"\nRécupération des éléments archivés pour le thème '{theme}'...")
                themed_items = manager.get_archived_items_by_theme(theme)
                print(f"Nombre d'éléments archivés pour le thème '{theme}': {len(themed_items)}")
                
                if themed_items:
                    print(f"Premier élément archivé pour le thème '{theme}': {themed_items[0]['id']}")
        
        # Obtenir des statistiques sur les archives
        stats = manager.get_archive_statistics()
        print(f"\nStatistiques sur les archives: {stats}")
        
        # Effectuer une rotation des archives
        backup_path = os.path.join(temp_dir, "backup")
        os.makedirs(backup_path, exist_ok=True)
        
        rotation_stats = manager.rotate_archives(max_age_days=0, max_items=0, backup_dir=backup_path)
        print(f"\nRotation des archives: {rotation_stats}")
        
        # Vérifier que les éléments ont été déplacés
        backup_files = os.listdir(backup_path)
        print(f"Fichiers dans le répertoire de sauvegarde: {backup_files}")
        
        print("\nTest terminé avec succès!")
        return 0
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return 1
    
    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    sys.exit(main())
