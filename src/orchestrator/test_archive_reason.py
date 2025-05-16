#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour le mécanisme d'archivage thématique avec raisons.
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
    """Test pour le mécanisme d'archivage thématique avec raisons."""
    print("Test pour le mécanisme d'archivage thématique avec raisons...")
    
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
        
        # Archiver l'élément avec une raison
        reason = "Document obsolète"
        result = manager.archive_item(item["id"], reason)
        print(f"Archivage de l'élément avec raison '{reason}': {result}")
        
        # Récupérer les éléments archivés
        archived_items = manager.get_archived_items()
        print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        if archived_items:
            print(f"Premier élément archivé: {archived_items[0]['id']}")
            print(f"Raison de l'archivage: {archived_items[0]['metadata'].get('archive_reason', 'Non spécifiée')}")
            print(f"Historique d'archivage: {archived_items[0]['metadata'].get('archive_history', [])}")
        
        # Créer un autre élément
        content2 = "Ce document décrit le développement du système."
        metadata2 = {
            "title": "Guide de développement",
            "author": "Jane Smith",
            "tags": ["développement", "code", "pratiques"]
        }
        
        item2 = manager.create_item(content2, metadata2)
        print(f"\nÉlément 2 créé avec l'ID: {item2['id']}")
        print(f"Thèmes attribués: {item2['metadata'].get('themes', {})}")
        
        # Supprimer l'élément avec une raison
        reason2 = "Document remplacé"
        result2 = manager.delete_item(item2["id"], permanent=False, reason=reason2)
        print(f"Suppression de l'élément avec raison '{reason2}': {result2}")
        
        # Récupérer les éléments archivés
        archived_items = manager.get_archived_items()
        print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        # Trouver l'élément 2 dans les archives
        archived_item2 = None
        for item in archived_items:
            if item["id"] == item2["id"]:
                archived_item2 = item
                break
        
        if archived_item2:
            print(f"Élément 2 archivé: {archived_item2['id']}")
            print(f"Raison de l'archivage: {archived_item2['metadata'].get('archive_reason', 'Non spécifiée')}")
            print(f"Historique d'archivage: {archived_item2['metadata'].get('archive_history', [])}")
        
        # Créer un troisième élément
        content3 = "Ce document décrit les tests du système."
        metadata3 = {
            "title": "Stratégie de test",
            "author": "John Doe",
            "tags": ["test", "qualité", "validation"]
        }
        
        item3 = manager.create_item(content3, metadata3)
        print(f"\nÉlément 3 créé avec l'ID: {item3['id']}")
        
        # Archiver tous les éléments du thème "testing" avec une raison
        reason3 = "Thème obsolète"
        count = manager.archive_items_by_theme("testing", reason3)
        print(f"Archivage des éléments du thème 'testing' avec raison '{reason3}': {count} élément(s)")
        
        # Récupérer les éléments archivés par thème
        archived_items = manager.get_archived_items_by_theme("testing")
        print(f"Nombre d'éléments archivés du thème 'testing': {len(archived_items)}")
        
        if archived_items:
            print(f"Premier élément archivé du thème 'testing': {archived_items[0]['id']}")
            print(f"Raison de l'archivage: {archived_items[0]['metadata'].get('archive_reason', 'Non spécifiée')}")
            print(f"Historique d'archivage: {archived_items[0]['metadata'].get('archive_history', [])}")
        
        # Obtenir des statistiques sur les archives
        stats = manager.get_archive_statistics()
        print(f"\nStatistiques sur les archives:")
        print(f"Nombre total d'éléments archivés: {stats['total_items']}")
        print(f"Raisons d'archivage: {stats['archive_reasons']}")
        
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
