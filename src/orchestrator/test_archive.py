#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le mécanisme d'archivage thématique.
"""

import os
import sys
import tempfile
import shutil
import time
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

def run_archive_tests():
    """Exécute des tests pour le mécanisme d'archivage thématique."""
    print("Exécution des tests pour le mécanisme d'archivage thématique...")

    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    storage_path = os.path.join(temp_dir, "storage")
    archive_path = os.path.join(temp_dir, "archive")
    backup_path = os.path.join(temp_dir, "backup")

    try:
        # Créer les répertoires
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        os.makedirs(backup_path, exist_ok=True)

        # Créer un gestionnaire CRUD
        manager = ThematicCRUDManager(storage_path, archive_path)

        # Test 1: Créer des éléments pour les tests
        print("\nTest 1: Créer des éléments pour les tests")

        # Élément 1: Architecture
        content1 = "Ce document décrit l'architecture du système."
        metadata1 = {
            "title": "Architecture du système",
            "author": "John Doe",
            "tags": ["architecture", "conception", "système"]
        }

        # Élément 2: Développement
        content2 = "Ce document présente les pratiques de développement du système."
        metadata2 = {
            "title": "Guide de développement",
            "author": "Jane Smith",
            "tags": ["développement", "code", "pratiques"]
        }

        # Élément 3: Tests
        content3 = "Ce document décrit la stratégie de test du système."
        metadata3 = {
            "title": "Stratégie de test",
            "author": "John Doe",
            "tags": ["test", "qualité", "validation"]
        }

        # Créer les éléments
        item1 = manager.create_item(content1, metadata1)
        item2 = manager.create_item(content2, metadata2)
        item3 = manager.create_item(content3, metadata3)

        print(f"Éléments créés avec les IDs: {item1['id']}, {item2['id']}, {item3['id']}")

        # Test 2: Archiver un élément avec raison
        print("\nTest 2: Archiver un élément avec raison")

        # Archiver l'élément 1
        result = manager.archive_item(item1["id"])
        if not result:
            print("ÉCHEC: Impossible d'archiver l'élément.")
            return False

        # Vérifier que l'élément existe toujours
        item = manager.get_item(item1["id"])
        if not item:
            print("ÉCHEC: L'élément a été supprimé lors de l'archivage.")
            return False

        # Récupérer les éléments archivés
        archived_items = manager.get_archived_items()
        if not archived_items or archived_items[0]["id"] != item1["id"]:
            print("ÉCHEC: L'élément n'a pas été archivé correctement.")
            return False

        print("Élément archivé avec succès.")

        # Test 3: Archiver des éléments par thème
        print("\nTest 3: Archiver des éléments par thème")

        # Archiver les éléments du thème "development"
        count = manager.archive_items_by_theme("development")
        if count == 0:
            print("ÉCHEC: Aucun élément n'a été archivé par thème.")
            return False

        # Récupérer les éléments archivés
        archived_items = manager.get_archived_items()
        if len(archived_items) < 2:
            print("ÉCHEC: Les éléments n'ont pas été archivés correctement par thème.")
            return False

        print(f"{count} élément(s) archivé(s) par thème avec succès.")

        # Test 4: Récupérer les éléments archivés par thème
        print("\nTest 4: Récupérer les éléments archivés par thème")

        # Afficher les thèmes de l'élément 1
        print(f"Thèmes de l'élément 1: {item1['metadata'].get('themes', {})}")

        # Lister les répertoires dans le répertoire d'archivage
        print(f"Répertoires dans {archive_path}: {os.listdir(archive_path)}")

        # Récupérer les éléments archivés du thème "architecture"
        archived_items = manager.get_archived_items_by_theme("architecture")
        print(f"Éléments archivés du thème 'architecture': {len(archived_items)}")

        if not archived_items:
            print("ÉCHEC: Aucun élément archivé trouvé pour le thème 'architecture'.")
            return False

        if archived_items[0]["id"] != item1["id"]:
            print(f"ÉCHEC: L'élément archivé a l'ID {archived_items[0]['id']} au lieu de {item1['id']}.")
            return False

        print(f"Récupéré {len(archived_items)} élément(s) archivé(s) par thème.")

        # Test 5: Rechercher dans les archives
        print("\nTest 5: Rechercher dans les archives")

        # Rechercher les éléments archivés contenant "architecture"
        search_results = manager.search_archived_items("architecture")
        if not search_results or search_results[0]["id"] != item1["id"]:
            print("ÉCHEC: La recherche dans les archives n'a pas retourné les résultats attendus.")
            return False

        print(f"Recherche dans les archives: {len(search_results)} résultat(s).")

        # Test 6: Restaurer un élément archivé
        print("\nTest 6: Restaurer un élément archivé")

        # Supprimer l'élément 3 (pour l'archiver)
        manager.delete_item(item3["id"])

        # Vérifier que l'élément a été supprimé
        item = manager.get_item(item3["id"])
        if item:
            print("ÉCHEC: L'élément n'a pas été supprimé.")
            return False

        # Vérifier que l'élément a été archivé
        archived_items = manager.get_archived_items()
        archived_item3 = None
        for item in archived_items:
            if item["id"] == item3["id"]:
                archived_item3 = item
                break

        if not archived_item3:
            print("ÉCHEC: L'élément n'a pas été archivé lors de la suppression.")
            return False

        # Restaurer l'élément
        result = manager.restore_archived_item(item3["id"])
        if not result:
            print("ÉCHEC: Impossible de restaurer l'élément archivé.")
            return False

        # Vérifier que l'élément a été restauré
        item = manager.get_item(item3["id"])
        if not item:
            print("ÉCHEC: L'élément n'a pas été restauré correctement.")
            return False

        print("Élément restauré avec succès.")

        # Test 7: Obtenir des statistiques sur les archives
        print("\nTest 7: Obtenir des statistiques sur les archives")

        # Obtenir les statistiques
        stats = manager.get_archive_statistics()
        if not stats or "total_items" not in stats:
            print("ÉCHEC: Impossible d'obtenir les statistiques sur les archives.")
            return False

        print(f"Statistiques sur les archives: {stats['total_items']} élément(s) archivé(s).")

        # Test 8: Rotation des archives
        print("\nTest 8: Rotation des archives")

        # Effectuer une rotation des archives
        rotation_stats = manager.rotate_archives(max_age_days=0, max_items=1, backup_dir=backup_path)
        if not rotation_stats or "moved_count" not in rotation_stats:
            print("ÉCHEC: Impossible d'effectuer la rotation des archives.")
            return False

        print(f"Rotation des archives: {rotation_stats['moved_count']} élément(s) déplacé(s), {rotation_stats['deleted_count']} élément(s) supprimé(s).")

        print("\nTous les tests ont réussi!")
        return True

    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return False

    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    success = run_archive_tests()
    sys.exit(0 if success else 1)
