#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests de base pour le système CRUD modulaire thématique.
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

def run_basic_tests():
    """Exécute des tests de base pour le système CRUD modulaire thématique."""
    print("Exécution des tests de base pour le système CRUD modulaire thématique...")
    
    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    
    try:
        # Créer un gestionnaire CRUD modulaire thématique
        manager = ThematicCRUDManager(temp_dir)
        
        # Test de création d'un élément
        print("\nTest de création d'un élément...")
        content = "Ce document décrit l'architecture du système."
        metadata = {
            "title": "Architecture du système",
            "author": "John Doe",
            "tags": ["architecture", "conception", "système"]
        }
        
        item = manager.create_item(content, metadata)
        if item is None:
            print("ÉCHEC: Impossible de créer un élément.")
            return False
        
        print(f"Élément créé avec l'ID: {item['id']}")
        print(f"Thèmes attribués: {item['metadata'].get('themes', {})}")
        
        # Test de récupération d'un élément
        print("\nTest de récupération d'un élément...")
        retrieved_item = manager.get_item(item["id"])
        if retrieved_item is None:
            print("ÉCHEC: Impossible de récupérer l'élément créé.")
            return False
        
        print(f"Élément récupéré avec l'ID: {retrieved_item['id']}")
        
        # Test de mise à jour d'un élément
        print("\nTest de mise à jour d'un élément...")
        updated_content = "Ce document décrit l'architecture et les tests du système."
        updated_item = manager.update_item(item["id"], content=updated_content)
        if updated_item is None:
            print("ÉCHEC: Impossible de mettre à jour l'élément.")
            return False
        
        print(f"Élément mis à jour avec l'ID: {updated_item['id']}")
        print(f"Nouveaux thèmes: {updated_item['metadata'].get('themes', {})}")
        
        # Test de recherche d'éléments
        print("\nTest de recherche d'éléments...")
        search_results = manager.search_items("architecture")
        if not search_results:
            print("ÉCHEC: Aucun résultat de recherche.")
            return False
        
        print(f"Nombre de résultats: {len(search_results)}")
        
        # Test de suppression d'un élément
        print("\nTest de suppression d'un élément...")
        delete_result = manager.delete_item(item["id"])
        if not delete_result:
            print("ÉCHEC: Impossible de supprimer l'élément.")
            return False
        
        print("Élément supprimé avec succès.")
        
        # Test de récupération des éléments archivés
        print("\nTest de récupération des éléments archivés...")
        archived_items = manager.get_archived_items()
        if not archived_items:
            print("ÉCHEC: Aucun élément archivé trouvé.")
            return False
        
        print(f"Nombre d'éléments archivés: {len(archived_items)}")
        
        # Test de restauration d'un élément archivé
        print("\nTest de restauration d'un élément archivé...")
        restore_result = manager.restore_archived_item(item["id"])
        if not restore_result:
            print("ÉCHEC: Impossible de restaurer l'élément archivé.")
            return False
        
        print("Élément restauré avec succès.")
        
        print("\nTous les tests ont réussi!")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return False
    
    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    success = run_basic_tests()
    sys.exit(0 if success else 1)
