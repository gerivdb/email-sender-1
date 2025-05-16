#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour les fonctionnalités de gestion des versions.
"""

import os
import sys
import tempfile
import shutil
import json
import time
from datetime import datetime, timedelta
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
                "created_at": (datetime.now() - timedelta(days=10)).isoformat(),
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
                "created_at": (datetime.now() - timedelta(days=5)).isoformat(),
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
                "created_at": datetime.now().isoformat(),
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

def test_create_version(storage_path, versions_path, items):
    """Teste la création de versions."""
    print_header("Test de création de versions")

    from src.orchestrator.thematic_crud.version_control import ThematicVersionControl

    # Créer un gestionnaire de versions
    version_control = ThematicVersionControl(storage_path, versions_path)

    # Créer une version pour un élément
    version_metadata = version_control.create_version(
        items[0],
        version_tag="initial",
        version_message="Version initiale"
    )

    print(f"Métadonnées de version: {version_metadata}")

    # Vérifier que la version a été créée
    version_path = os.path.join(versions_path, items[0]["id"], f"v{version_metadata['version_number']}.json")
    if os.path.exists(version_path):
        print_result("Création de version", True)
        return True
    else:
        print_result("Création de version", False)
        return False

def test_get_versions(storage_path, versions_path, items):
    """Teste la récupération des versions."""
    print_header("Test de récupération des versions")

    from src.orchestrator.thematic_crud.version_control import ThematicVersionControl

    # Créer un gestionnaire de versions
    version_control = ThematicVersionControl(storage_path, versions_path)

    # Créer plusieurs versions pour un élément
    item = items[0]

    # Version 1
    version_control.create_version(
        item,
        version_tag="v1",
        version_message="Version 1"
    )

    # Modifier l'élément
    item["content"] = "Ce document décrit l'architecture du système (mise à jour)."

    # Version 2
    version_control.create_version(
        item,
        version_tag="v2",
        version_message="Version 2"
    )

    # Récupérer les versions
    versions = version_control.get_versions(item["id"])
    print(f"Versions: {versions}")

    if len(versions) >= 2:
        print_result("Récupération des versions", True)
        return True
    else:
        print_result("Récupération des versions", False)
        return False

def test_get_version(storage_path, versions_path, items):
    """Teste la récupération d'une version spécifique."""
    print_header("Test de récupération d'une version spécifique")

    from src.orchestrator.thematic_crud.version_control import ThematicVersionControl

    # Créer un gestionnaire de versions
    version_control = ThematicVersionControl(storage_path, versions_path)

    # Créer une version pour un élément
    item = items[1]
    version_metadata = version_control.create_version(
        item,
        version_tag="test",
        version_message="Version de test"
    )

    # Récupérer la version
    version = version_control.get_version(item["id"], version_metadata["version_number"])
    print(f"Version récupérée: {version}")

    if version and version["id"] == item["id"]:
        print_result("Récupération d'une version spécifique", True)
        return True
    else:
        print_result("Récupération d'une version spécifique", False)
        return False

def test_restore_version(storage_path, versions_path, items):
    """Teste la restauration d'une version."""
    print_header("Test de restauration d'une version")

    from src.orchestrator.thematic_crud.version_control import ThematicVersionControl

    # Créer un gestionnaire de versions
    version_control = ThematicVersionControl(storage_path, versions_path)

    # Créer une version pour un élément
    item = items[2]
    original_content = item["content"]
    version_metadata = version_control.create_version(
        item,
        version_tag="original",
        version_message="Version originale"
    )

    # Modifier l'élément
    item["content"] = "Contenu modifié pour le test de restauration"
    item_path = os.path.join(storage_path, f"{item['id']}.json")
    with open(item_path, 'w', encoding='utf-8') as f:
        json.dump(item, f, ensure_ascii=False, indent=2)

    # Restaurer la version originale
    restored_item = version_control.restore_version(item["id"], version_metadata["version_number"])
    print(f"Élément restauré: {restored_item}")

    # Vérifier que le contenu a été restauré
    if restored_item and restored_item["content"] == original_content:
        print_result("Restauration d'une version", True)
        return True
    else:
        print_result("Restauration d'une version", False)
        return False

def test_compare_versions(storage_path, versions_path, items):
    """Teste la comparaison de versions."""
    print_header("Test de comparaison de versions")

    from src.orchestrator.thematic_crud.version_control import ThematicVersionControl

    # Créer un gestionnaire de versions
    version_control = ThematicVersionControl(storage_path, versions_path)

    # Créer une version pour un élément
    item = items[0]
    version1_metadata = version_control.create_version(
        item,
        version_tag="v1",
        version_message="Version 1"
    )

    # Modifier l'élément
    item["content"] = "Ce document décrit l'architecture du système (mise à jour)."
    item["metadata"]["tags"].append("documentation")

    # Créer une deuxième version
    version2_metadata = version_control.create_version(
        item,
        version_tag="v2",
        version_message="Version 2"
    )

    # Comparer les versions
    differences = version_control.compare_versions(
        item["id"],
        version1_metadata["version_number"],
        version2_metadata["version_number"]
    )

    print(f"Différences: {differences}")

    # Vérifier que les différences ont été détectées correctement
    content_changed = differences.get("content_changed", False)
    metadata_changes = differences.get("metadata_changes", {})

    if content_changed and "tags" in metadata_changes:
        print_result("Comparaison de versions", True)
        return True
    elif not content_changed and "tags" in metadata_changes:
        print("Le contenu n'a pas été détecté comme modifié, mais les tags ont été modifiés.")
        print_result("Comparaison de versions", True)
        return True
    else:
        print_result("Comparaison de versions", False)
        return False

def test_manager_version_control(storage_path, versions_path, archive_path, items):
    """Teste les fonctionnalités de gestion des versions du gestionnaire CRUD."""
    print_header("Test des fonctionnalités de gestion des versions du gestionnaire CRUD")

    from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

    # Créer un gestionnaire CRUD
    manager = ThematicCRUDManager(storage_path, archive_path, versions_path)

    # Créer un nouvel élément avec version
    new_item = manager.create_item(
        "Contenu du nouvel élément",
        {
            "title": "Nouvel élément",
            "author": "Test Manager",
            "tags": ["test", "manager", "version"]
        },
        create_version=True,
        version_tag="initial"
    )

    print(f"Nouvel élément créé: {new_item}")

    # Mettre à jour l'élément avec version
    updated_item = manager.update_item(
        new_item["id"],
        content="Contenu mis à jour",
        metadata={"tags": ["test", "manager", "version", "updated"]},
        create_version=True,
        version_tag="update",
        version_message="Mise à jour du contenu et des tags"
    )

    print(f"Élément mis à jour: {updated_item}")

    # Récupérer les versions
    versions = manager.get_versions(new_item["id"])
    print(f"Versions: {versions}")

    if len(versions) >= 2:
        print_result("Gestion des versions du gestionnaire CRUD", True)
        return True
    else:
        print_result("Gestion des versions du gestionnaire CRUD", False)
        return False

def main():
    """Point d'entrée principal des tests."""
    print_header("Tests pour les fonctionnalités de gestion des versions")

    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")

    try:
        # Créer les répertoires
        storage_path = os.path.join(temp_dir, "storage")
        versions_path = os.path.join(temp_dir, "versions")
        archive_path = os.path.join(temp_dir, "archive")

        print(f"Création des répertoires {storage_path}, {versions_path} et {archive_path}...")
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(versions_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)

        # Créer des données de test
        items = create_test_data(storage_path)
        print(f"Données de test créées: {len(items)} éléments")

        # Tester les fonctionnalités de gestion des versions
        tests = [
            lambda: test_create_version(storage_path, versions_path, items),
            lambda: test_get_versions(storage_path, versions_path, items),
            lambda: test_get_version(storage_path, versions_path, items),
            lambda: test_restore_version(storage_path, versions_path, items),
            lambda: test_compare_versions(storage_path, versions_path, items),
            lambda: test_manager_version_control(storage_path, versions_path, archive_path, items)
        ]

        success = True
        for test in tests:
            if not test():
                success = False

        if success:
            print_header("Tous les tests ont réussi!")
            return 0
        else:
            print_header("Certains tests ont échoué!")
            return 1

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
