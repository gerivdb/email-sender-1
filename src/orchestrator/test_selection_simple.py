#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test simplifié pour les fonctionnalités de sélection.
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

def print_step(message):
    """Affiche un message d'étape et force le flush de la sortie standard."""
    print(f"[TEST] {message}")
    sys.stdout.flush()

def print_result(test_name, success):
    """Affiche le résultat d'un test."""
    if success:
        print(f"✅ {test_name}: SUCCÈS")
    else:
        print(f"❌ {test_name}: ÉCHEC")
    sys.stdout.flush()

def create_test_data(storage_path):
    """Crée des données de test."""
    # Créer des éléments de test
    items = [
        {
            "id": "item1",
            "content": "Ce document décrit l'architecture du système.",
            "metadata": {
                "title": "Architecture du système",
                "author": "John Doe",
                "tags": ["architecture", "conception", "système"],
                "themes": {
                    "architecture": 0.8,
                    "conception": 0.6
                }
            }
        },
        {
            "id": "item2",
            "content": "Ce document décrit le développement du système.",
            "metadata": {
                "title": "Guide de développement",
                "author": "Jane Smith",
                "tags": ["développement", "code", "pratiques"],
                "themes": {
                    "développement": 0.9,
                    "code": 0.7
                }
            }
        },
        {
            "id": "item3",
            "content": "Ce document décrit les tests du système.",
            "metadata": {
                "title": "Stratégie de test",
                "author": "John Doe",
                "tags": ["test", "qualité", "validation"],
                "themes": {
                    "test": 0.9,
                    "qualité": 0.8
                }
            }
        }
    ]

    # Sauvegarder les éléments dans le stockage
    for item in items:
        item_path = os.path.join(storage_path, f"{item['id']}.json")
        with open(item_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)

        # Créer des répertoires thématiques et y sauvegarder les éléments
        for theme in item["metadata"]["themes"]:
            theme_dir = os.path.join(storage_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

            theme_path = os.path.join(theme_dir, f"{item['id']}.json")
            with open(theme_path, 'w', encoding='utf-8') as f:
                json.dump(item, f, ensure_ascii=False, indent=2)

    return items

def main():
    """Point d'entrée principal des tests."""
    print_step("Tests pour les fonctionnalités de sélection...")

    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print_step(f"Répertoire temporaire créé: {temp_dir}")

    try:
        # Créer les répertoires
        storage_path = os.path.join(temp_dir, "storage")
        archive_path = os.path.join(temp_dir, "archive")

        print_step(f"Création des répertoires {storage_path} et {archive_path}...")
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)

        # Créer des données de test
        items = create_test_data(storage_path)
        print_step(f"Données de test créées: {len(items)} éléments")

        # Importer les classes nécessaires
        print_step("Importation des classes nécessaires...")
        from src.orchestrator.thematic_crud.selection import ThematicSelector
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
        print_step("Classes importées avec succès.")

        # Créer les instances nécessaires
        print_step("Création des instances nécessaires...")
        selector = ThematicSelector(storage_path)
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)
        manager = ThematicCRUDManager(storage_path, archive_path)
        print_step("Instances créées avec succès.")

        # Test 1: Sélection par ID
        print_step("Test 1: Sélection par ID...")
        selected_ids = selector.select_by_id("item1")
        success = len(selected_ids) == 1 and selected_ids[0] == "item1"
        print_result("Sélection par ID", success)

        # Test 2: Sélection par thème
        print_step("Test 2: Sélection par thème...")
        selected_ids = selector.select_by_theme("architecture")
        success = len(selected_ids) == 1 and "item1" in selected_ids
        print_result("Sélection par thème", success)

        # Test 3: Sélection par contenu
        print_step("Test 3: Sélection par contenu...")
        selected_ids = selector.select_by_content("développement")
        success = len(selected_ids) == 1 and "item2" in selected_ids
        print_result("Sélection par contenu", success)

        # Test 4: Sélection par métadonnées
        print_step("Test 4: Sélection par métadonnées...")
        selected_ids = selector.select_by_metadata({"author": "John Doe"})
        success = len(selected_ids) == 2 and "item1" in selected_ids and "item3" in selected_ids
        print_result("Sélection par métadonnées", success)

        # Test 5: Combinaison de sélections
        print_step("Test 5: Combinaison de sélections...")
        selection1 = selector.select_by_metadata({"author": "John Doe"})
        selection2 = selector.select_by_theme("test")
        combined_ids = selector.combine_selections([selection1, selection2], mode="intersection")
        success = len(combined_ids) == 1 and "item3" in combined_ids
        print_result("Combinaison de sélections", success)

        # Test 6: Archivage par sélection
        print_step("Test 6: Archivage par sélection...")
        stats = manager.archive_items_by_selection(
            "by_metadata",
            {"metadata_filter": {"author": "Jane Smith"}},
            "Test d'archivage par sélection"
        )
        success = stats["archived_count"] == 1
        print_result("Archivage par sélection", success)

        # Test 7: Récupération des éléments archivés
        print_step("Test 7: Récupération des éléments archivés...")
        archived_items = manager.get_archived_items()
        success = len(archived_items) == 1 and archived_items[0]["id"] == "item2"
        print_result("Récupération des éléments archivés", success)

        # Test 8: Suppression par sélection
        print_step("Test 8: Suppression par sélection...")
        stats = manager.delete_items_by_selection(
            "by_theme",
            {"theme": "test"},
            permanent=True,
            reason="Test de suppression par sélection"
        )
        success = stats["deleted_count"] == 1
        print_result("Suppression par sélection", success)

        # Vérifier les résultats globaux
        final_checks = [
            (len(selector.select_by_id("item1")) == 1, "Vérification finale: select_by_id('item1')"),
            (len(selector.select_by_theme("architecture")) == 1, "Vérification finale: select_by_theme('architecture')"),
            (len(selector.select_by_content("développement")) == 1, "Vérification finale: select_by_content('développement')"),  # L'archivage ne supprime pas les éléments
            (len(selector.select_by_metadata({"author": "John Doe"})) == 1, "Vérification finale: select_by_metadata({'author': 'John Doe'})"),
            (len(manager.get_archived_items()) == 1, "Vérification finale: get_archived_items()")
        ]

        # Afficher les résultats des vérifications finales
        print_step("Résultats des vérifications finales:")
        for success, description in final_checks:
            print_result(description, success)
            print_step(f"  - Résultat: {success}")

        all_success = all(success for success, _ in final_checks)

        if all_success:
            print_step("Tous les tests ont réussi!")
            return 0
        else:
            print_step("Certains tests ont échoué!")
            return 1

    except Exception as e:
        print_step(f"ERREUR: {str(e)}")
        traceback.print_exc()
        return 1

    finally:
        # Supprimer le répertoire temporaire
        print_step(f"Suppression du répertoire temporaire {temp_dir}...")
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    sys.exit(main())
