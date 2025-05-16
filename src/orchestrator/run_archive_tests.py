#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests complets pour le mécanisme d'archivage thématique.
"""

import os
import sys
import tempfile
import shutil
import json
import time
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

def print_header(title):
    """Affiche un en-tête de section."""
    print("\n" + "=" * 80)
    print(f" {title} ".center(80, "="))
    print("=" * 80)
    sys.stdout.flush()

def print_result(test_name, success):
    """Affiche le résultat d'un test."""
    if success:
        print(f"✅ {test_name}: SUCCÈS")
    else:
        print(f"❌ {test_name}: ÉCHEC")
    sys.stdout.flush()

def test_import():
    """Test d'importation des modules."""
    print_header("Test d'importation des modules")

    try:
        print("Importation de ThematicDeleteArchive...")
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        print("Importation réussie.")

        print("Importation de ThematicCRUDManager...")
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
        print("Importation réussie.")

        print_result("Test d'importation", True)
        return True
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        print_result("Test d'importation", False)
        return False

def test_create_instance(temp_dir):
    """Test de création d'instance."""
    print_header("Test de création d'instance")

    try:
        # Créer les répertoires
        storage_path = os.path.join(temp_dir, "storage")
        archive_path = os.path.join(temp_dir, "archive")

        print(f"Création des répertoires {storage_path} et {archive_path}...")
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)

        # Importer les classes
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

        # Créer une instance de ThematicDeleteArchive
        print("Création d'une instance de ThematicDeleteArchive...")
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)
        print(f"Instance de ThematicDeleteArchive créée avec succès.")
        print(f"Chemin de stockage: {delete_archive.storage_path}")
        print(f"Chemin d'archivage: {delete_archive.archive_path}")

        # Créer une instance de ThematicCRUDManager
        print("Création d'une instance de ThematicCRUDManager...")
        manager = ThematicCRUDManager(storage_path, archive_path)
        print(f"Instance de ThematicCRUDManager créée avec succès.")
        print(f"Chemin de stockage: {manager.storage_path}")
        # Note: ThematicCRUDManager n'expose pas directement archive_path
        print(f"Chemin d'archivage: {archive_path} (passé au constructeur)")

        print_result("Test de création d'instance", True)
        return True, storage_path, archive_path
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        print_result("Test de création d'instance", False)
        return False, None, None

def test_archive_item(storage_path, archive_path):
    """Test d'archivage d'un élément."""
    print_header("Test d'archivage d'un élément")

    try:
        # Importer les classes
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive

        # Créer une instance de ThematicDeleteArchive
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)

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
                    "test_theme": 0.8,
                    "another_theme": 0.5
                }
            }
        }

        # Sauvegarder l'élément dans le stockage
        item_path = os.path.join(storage_path, f"{item_id}.json")
        print(f"Sauvegarde de l'élément dans {item_path}...")
        with open(item_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)

        # Créer des répertoires thématiques
        for theme in item["metadata"]["themes"]:
            theme_dir = os.path.join(storage_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

            # Sauvegarder l'élément dans le répertoire thématique
            theme_path = os.path.join(theme_dir, f"{item_id}.json")
            print(f"Sauvegarde de l'élément dans {theme_path}...")
            with open(theme_path, 'w', encoding='utf-8') as f:
                json.dump(item, f, ensure_ascii=False, indent=2)

        # Archiver l'élément
        print("Archivage de l'élément...")
        result = delete_archive.archive_item(item_id, "Test d'archivage")
        print(f"Résultat de l'archivage: {result}")

        # Vérifier que l'élément a été archivé
        archive_item_path = os.path.join(archive_path, f"{item_id}.json")
        if not os.path.exists(archive_item_path):
            print(f"ERREUR: L'élément n'a pas été archivé dans {archive_item_path}.")
            print_result("Test d'archivage d'un élément", False)
            return False

        print(f"L'élément a été archivé avec succès dans {archive_item_path}.")

        # Lire l'élément archivé
        with open(archive_item_path, 'r', encoding='utf-8') as f:
            archived_item = json.load(f)

        # Vérifier les métadonnées d'archivage
        if "archived_at" not in archived_item["metadata"]:
            print("ERREUR: La date d'archivage n'a pas été ajoutée aux métadonnées.")
            print_result("Test d'archivage d'un élément", False)
            return False

        if "archive_status" not in archived_item["metadata"]:
            print("ERREUR: Le statut d'archivage n'a pas été ajouté aux métadonnées.")
            print_result("Test d'archivage d'un élément", False)
            return False

        if "archive_reason" not in archived_item["metadata"]:
            print("ERREUR: La raison d'archivage n'a pas été ajoutée aux métadonnées.")
            print_result("Test d'archivage d'un élément", False)
            return False

        if "archive_history" not in archived_item["metadata"]:
            print("ERREUR: L'historique d'archivage n'a pas été ajouté aux métadonnées.")
            print_result("Test d'archivage d'un élément", False)
            return False

        print(f"Date d'archivage: {archived_item['metadata']['archived_at']}")
        print(f"Statut d'archivage: {archived_item['metadata']['archive_status']}")
        print(f"Raison d'archivage: {archived_item['metadata']['archive_reason']}")
        print(f"Historique d'archivage: {archived_item['metadata']['archive_history']}")

        # Vérifier que l'élément a été archivé dans les répertoires thématiques
        for theme in item["metadata"]["themes"]:
            theme_dir = os.path.join(archive_path, theme)
            theme_path = os.path.join(theme_dir, f"{item_id}.json")

            if not os.path.exists(theme_path):
                print(f"ERREUR: L'élément n'a pas été archivé dans le répertoire thématique {theme_path}.")
                print_result("Test d'archivage d'un élément", False)
                return False

            print(f"L'élément a été archivé avec succès dans le répertoire thématique {theme_path}.")

        print_result("Test d'archivage d'un élément", True)
        return True
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        print_result("Test d'archivage d'un élément", False)
        return False

def test_get_archived_items(storage_path, archive_path):
    """Test de récupération des éléments archivés."""
    print_header("Test de récupération des éléments archivés")

    try:
        # Importer les classes
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive

        # Créer une instance de ThematicDeleteArchive
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)

        # Récupérer les éléments archivés
        print("Récupération des éléments archivés...")
        archived_items = delete_archive.get_archived_items()
        print(f"Nombre d'éléments archivés: {len(archived_items)}")

        if not archived_items:
            print("ERREUR: Aucun élément archivé n'a été trouvé.")
            print_result("Test de récupération des éléments archivés", False)
            return False

        # Afficher les informations sur le premier élément archivé
        print(f"Premier élément archivé: {archived_items[0]['id']}")
        print(f"Titre: {archived_items[0]['metadata']['title']}")
        print(f"Auteur: {archived_items[0]['metadata']['author']}")
        print(f"Tags: {archived_items[0]['metadata']['tags']}")
        print(f"Thèmes: {archived_items[0]['metadata']['themes']}")
        print(f"Date d'archivage: {archived_items[0]['metadata']['archived_at']}")
        print(f"Statut d'archivage: {archived_items[0]['metadata']['archive_status']}")
        print(f"Raison d'archivage: {archived_items[0]['metadata']['archive_reason']}")

        print_result("Test de récupération des éléments archivés", True)
        return True
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        print_result("Test de récupération des éléments archivés", False)
        return False

def test_get_archived_items_by_theme(storage_path, archive_path):
    """Test de récupération des éléments archivés par thème."""
    print_header("Test de récupération des éléments archivés par thème")

    try:
        # Importer les classes
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive

        # Créer une instance de ThematicDeleteArchive
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)

        # Récupérer les éléments archivés par thème
        print("Récupération des éléments archivés par thème...")

        # Récupérer les éléments archivés du thème "test_theme"
        themed_items = delete_archive.get_archived_items_by_theme("test_theme")
        print(f"Nombre d'éléments archivés du thème 'test_theme': {len(themed_items)}")

        if not themed_items:
            print("ERREUR: Aucun élément archivé n'a été trouvé pour le thème 'test_theme'.")
            print_result("Test de récupération des éléments archivés par thème", False)
            return False

        # Afficher les informations sur le premier élément archivé du thème
        print(f"Premier élément archivé du thème 'test_theme': {themed_items[0]['id']}")
        print(f"Titre: {themed_items[0]['metadata']['title']}")
        print(f"Auteur: {themed_items[0]['metadata']['author']}")
        print(f"Tags: {themed_items[0]['metadata']['tags']}")
        print(f"Thèmes: {themed_items[0]['metadata']['themes']}")

        # Récupérer les éléments archivés du thème "another_theme"
        themed_items = delete_archive.get_archived_items_by_theme("another_theme")
        print(f"Nombre d'éléments archivés du thème 'another_theme': {len(themed_items)}")

        if not themed_items:
            print("ERREUR: Aucun élément archivé n'a été trouvé pour le thème 'another_theme'.")
            print_result("Test de récupération des éléments archivés par thème", False)
            return False

        print_result("Test de récupération des éléments archivés par thème", True)
        return True
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        print_result("Test de récupération des éléments archivés par thème", False)
        return False

def main():
    """Point d'entrée principal des tests."""
    print_header("Tests pour le mécanisme d'archivage thématique")

    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")

    try:
        # Test d'importation des modules
        if not test_import():
            return 1

        # Test de création d'instance
        success, storage_path, archive_path = test_create_instance(temp_dir)
        if not success:
            return 1

        # Test d'archivage d'un élément
        if not test_archive_item(storage_path, archive_path):
            return 1

        # Test de récupération des éléments archivés
        if not test_get_archived_items(storage_path, archive_path):
            return 1

        # Test de récupération des éléments archivés par thème
        if not test_get_archived_items_by_theme(storage_path, archive_path):
            return 1

        print_header("Tous les tests ont réussi!")
        return 0

    except Exception as e:
        print(f"ERREUR: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

    finally:
        # Supprimer le répertoire temporaire
        print(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    sys.exit(main())
