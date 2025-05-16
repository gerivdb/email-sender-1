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
import traceback
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

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
        
        print(f"Répertoires créés: {storage_path}, {archive_path}")
        
        # Importer la classe ThematicDeleteArchive
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        
        # Créer une instance de ThematicDeleteArchive
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)
        
        print("Instance de ThematicDeleteArchive créée.")
        
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
        with open(item_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)
        
        print(f"Élément créé: {item_path}")
        
        # Créer un répertoire thématique
        theme_dir = os.path.join(storage_path, "test_theme")
        os.makedirs(theme_dir, exist_ok=True)
        
        # Sauvegarder l'élément dans le répertoire thématique
        theme_path = os.path.join(theme_dir, f"{item_id}.json")
        with open(theme_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)
        
        print(f"Élément créé dans le répertoire thématique: {theme_path}")
        
        # Archiver l'élément
        result = delete_archive.archive_item(item_id, "Test d'archivage")
        print(f"Résultat de l'archivage: {result}")
        
        # Vérifier que l'élément a été archivé
        archive_item_path = os.path.join(archive_path, f"{item_id}.json")
        if os.path.exists(archive_item_path):
            print(f"L'élément a été archivé avec succès: {archive_item_path}")
            
            # Lire l'élément archivé
            with open(archive_item_path, 'r', encoding='utf-8') as f:
                archived_item = json.load(f)
            
            print(f"Raison de l'archivage: {archived_item['metadata'].get('archive_reason', 'Non spécifiée')}")
        else:
            print(f"ERREUR: L'élément n'a pas été archivé: {archive_item_path}")
        
        # Récupérer les éléments archivés
        archived_items = delete_archive.get_archived_items()
        print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        # Récupérer les éléments archivés par thème
        themed_items = delete_archive.get_archived_items_by_theme("test_theme")
        print(f"Nombre d'éléments archivés du thème 'test_theme': {len(themed_items)}")
        
        print("Test terminé avec succès!")
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
