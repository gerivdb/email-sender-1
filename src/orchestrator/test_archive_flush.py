#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour le mécanisme d'archivage thématique avec flush.
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

def flush_print(message):
    """Affiche un message et force le flush de la sortie standard."""
    print(message)
    sys.stdout.flush()

def main():
    """Test pour le mécanisme d'archivage thématique avec flush."""
    flush_print("Test pour le mécanisme d'archivage thématique avec flush...")
    
    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    storage_path = os.path.join(temp_dir, "storage")
    archive_path = os.path.join(temp_dir, "archive")
    
    try:
        # Créer les répertoires
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        
        flush_print(f"Répertoires créés: {storage_path}, {archive_path}")
        
        # Importer la classe ThematicDeleteArchive
        flush_print("Importation de ThematicDeleteArchive...")
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        
        # Créer une instance de ThematicDeleteArchive
        flush_print("Création d'une instance de ThematicDeleteArchive...")
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)
        
        flush_print("Instance de ThematicDeleteArchive créée.")
        
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
        
        flush_print(f"Élément créé: {item_path}")
        
        # Créer un répertoire thématique
        theme_dir = os.path.join(storage_path, "test_theme")
        os.makedirs(theme_dir, exist_ok=True)
        
        # Sauvegarder l'élément dans le répertoire thématique
        theme_path = os.path.join(theme_dir, f"{item_id}.json")
        with open(theme_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)
        
        flush_print(f"Élément créé dans le répertoire thématique: {theme_path}")
        
        # Archiver l'élément
        flush_print("Archivage de l'élément...")
        result = delete_archive.archive_item(item_id, "Test d'archivage")
        flush_print(f"Résultat de l'archivage: {result}")
        
        # Vérifier que l'élément a été archivé
        archive_item_path = os.path.join(archive_path, f"{item_id}.json")
        if os.path.exists(archive_item_path):
            flush_print(f"L'élément a été archivé avec succès: {archive_item_path}")
            
            # Lire l'élément archivé
            with open(archive_item_path, 'r', encoding='utf-8') as f:
                archived_item = json.load(f)
            
            flush_print(f"Raison de l'archivage: {archived_item['metadata'].get('archive_reason', 'Non spécifiée')}")
        else:
            flush_print(f"ERREUR: L'élément n'a pas été archivé: {archive_item_path}")
        
        # Récupérer les éléments archivés
        flush_print("Récupération des éléments archivés...")
        archived_items = delete_archive.get_archived_items()
        flush_print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        # Récupérer les éléments archivés par thème
        flush_print("Récupération des éléments archivés par thème...")
        themed_items = delete_archive.get_archived_items_by_theme("test_theme")
        flush_print(f"Nombre d'éléments archivés du thème 'test_theme': {len(themed_items)}")
        
        flush_print("Test terminé avec succès!")
        return 0
    
    except Exception as e:
        flush_print(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return 1
    
    finally:
        # Supprimer le répertoire temporaire
        flush_print(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    sys.exit(main())
