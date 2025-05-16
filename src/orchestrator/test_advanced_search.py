#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour les fonctionnalités de recherche avancée.
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
    message = "\n" + "=" * 80 + "\n" + f" {title} ".center(80, "=") + "\n" + "=" * 80
    print(message)
    sys.stdout.flush()
    with open("test_advanced_search.log", "a", encoding="utf-8") as f:
        f.write(message + "\n")

def print_result(test_name, success):
    """Affiche le résultat d'un test."""
    message = f"✅ {test_name}: SUCCÈS" if success else f"❌ {test_name}: ÉCHEC"
    print(message)
    sys.stdout.flush()
    with open("test_advanced_search.log", "a", encoding="utf-8") as f:
        f.write(message + "\n")

def create_test_data(storage_path):
    """Crée des données de test."""
    # Créer des éléments de test
    items = [
        {
            "id": "item1",
            "content": "Ce document décrit l'architecture du système de gestion de contenu thématique.",
            "metadata": {
                "title": "Architecture du système",
                "author": "John Doe",
                "tags": ["architecture", "conception", "système"],
                "created_at": (datetime.now() - timedelta(days=10)).isoformat(),
                "themes": {
                    "architecture": 0.8,
                    "conception": 0.6,
                    "documentation": 0.4
                }
            }
        },
        {
            "id": "item2",
            "content": "Ce document décrit le développement du système de gestion de contenu thématique.",
            "metadata": {
                "title": "Guide de développement",
                "author": "Jane Smith",
                "tags": ["développement", "code", "pratiques"],
                "created_at": (datetime.now() - timedelta(days=5)).isoformat(),
                "themes": {
                    "développement": 0.9,
                    "code": 0.7,
                    "documentation": 0.5
                }
            }
        },
        {
            "id": "item3",
            "content": "Ce document décrit les tests du système de gestion de contenu thématique.",
            "metadata": {
                "title": "Stratégie de test",
                "author": "John Doe",
                "tags": ["test", "qualité", "validation"],
                "created_at": datetime.now().isoformat(),
                "themes": {
                    "test": 0.9,
                    "qualité": 0.8,
                    "développement": 0.3
                }
            }
        },
        {
            "id": "item4",
            "content": "Ce document décrit l'architecture de la base de données du système.",
            "metadata": {
                "title": "Architecture de la base de données",
                "author": "Alice Johnson",
                "tags": ["base de données", "architecture", "conception"],
                "created_at": (datetime.now() - timedelta(days=8)).isoformat(),
                "themes": {
                    "architecture": 0.7,
                    "base_de_données": 0.9,
                    "conception": 0.5
                }
            }
        },
        {
            "id": "item5",
            "content": "Ce document décrit les bonnes pratiques de développement pour le système.",
            "metadata": {
                "title": "Bonnes pratiques de développement",
                "author": "Jane Smith",
                "tags": ["développement", "pratiques", "qualité"],
                "created_at": (datetime.now() - timedelta(days=3)).isoformat(),
                "themes": {
                    "développement": 0.8,
                    "qualité": 0.7,
                    "code": 0.6
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
        for theme, weight in item["metadata"]["themes"].items():
            theme_dir = os.path.join(storage_path, theme)
            os.makedirs(theme_dir, exist_ok=True)

            theme_path = os.path.join(theme_dir, f"{item['id']}.json")
            with open(theme_path, 'w', encoding='utf-8') as f:
                json.dump(item, f, ensure_ascii=False, indent=2)

    return items

def test_multi_criteria_search(storage_path, items):
    """Teste la recherche multi-critères."""
    print_header("Test de recherche multi-critères")

    from src.orchestrator.thematic_crud.advanced_search import ThematicAdvancedSearch

    # Créer un moteur de recherche avancée
    search_engine = ThematicAdvancedSearch(storage_path)

    # Test 1: Recherche par thème
    print("Test 1: Recherche par thème 'architecture'")
    results = search_engine.search_by_multi_criteria(themes=["architecture"])
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test1_success = len(results) >= 2
    print_result("Recherche par thème", test1_success)

    # Test 2: Recherche par contenu
    print("\nTest 2: Recherche par contenu 'base de données'")
    results = search_engine.search_by_multi_criteria(content_query="base de données")
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test2_success = len(results) >= 1
    print_result("Recherche par contenu", test2_success)

    # Test 3: Recherche par métadonnées
    print("\nTest 3: Recherche par auteur 'Jane Smith'")
    results = search_engine.search_by_multi_criteria(metadata_filters={"author": "Jane Smith"})
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test3_success = len(results) >= 2
    print_result("Recherche par métadonnées", test3_success)

    # Test 4: Recherche combinée
    print("\nTest 4: Recherche combinée (thème 'développement' + contenu 'pratiques')")
    results = search_engine.search_by_multi_criteria(
        themes=["développement"],
        content_query="pratiques"
    )
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test4_success = len(results) >= 1
    print_result("Recherche combinée", test4_success)

    return test1_success and test2_success and test3_success and test4_success

def test_theme_relationships_search(storage_path, items):
    """Teste la recherche par relations entre thèmes."""
    print_header("Test de recherche par relations entre thèmes")

    from src.orchestrator.thematic_crud.advanced_search import ThematicAdvancedSearch

    # Créer un moteur de recherche avancée
    search_engine = ThematicAdvancedSearch(storage_path)

    # Test 1: Relation "any" (au moins un thème lié)
    print("Test 1: Relation 'any' (architecture + conception)")
    results = search_engine.search_by_theme_relationships(
        primary_theme="architecture",
        related_themes=["conception"],
        relationship_type="any"
    )
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test1_success = len(results) >= 2
    print_result("Relation 'any'", test1_success)

    # Test 2: Relation "all" (tous les thèmes liés)
    print("\nTest 2: Relation 'all' (développement + code)")
    results = search_engine.search_by_theme_relationships(
        primary_theme="développement",
        related_themes=["code"],
        relationship_type="all"
    )
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test2_success = len(results) >= 1
    print_result("Relation 'all'", test2_success)

    return test1_success and test2_success

def test_thematic_views(storage_path, items):
    """Teste les vues thématiques personnalisées."""
    print_header("Test des vues thématiques personnalisées")

    from src.orchestrator.thematic_crud.thematic_views import ThematicViewManager

    # Créer un gestionnaire de vues thématiques
    view_manager = ThematicViewManager(storage_path)

    # Test 1: Création d'une vue
    print("Test 1: Création d'une vue 'Documents d'architecture'")
    view = view_manager.create_view(
        name="Documents d'architecture",
        description="Vue des documents liés à l'architecture",
        search_criteria={
            "search_type": "multi_criteria",
            "themes": ["architecture"],
            "sort_by": "relevance"
        }
    )
    print(f"Vue créée: {view.to_dict()}")

    test1_success = view.id is not None and view.name == "Documents d'architecture"
    print_result("Création d'une vue", test1_success)

    # Test 2: Exécution d'une vue
    print("\nTest 2: Exécution de la vue 'Documents d'architecture'")
    results = view_manager.execute_view(view.id)
    print(f"Résultats: {len(results)} éléments trouvés")
    for item in results:
        print(f"  - {item['id']}: {item['metadata']['title']}")

    test2_success = len(results) >= 2
    print_result("Exécution d'une vue", test2_success)

    # Test 3: Mise à jour d'une vue
    print("\nTest 3: Mise à jour de la vue pour inclure le thème 'conception'")
    updated_view = view_manager.update_view(
        view.id,
        search_criteria={
            "search_type": "multi_criteria",
            "themes": ["architecture", "conception"],
            "sort_by": "relevance"
        }
    )

    if updated_view:
        print(f"Vue mise à jour: {updated_view.to_dict()}")

        # Exécuter la vue mise à jour
        results = view_manager.execute_view(view.id)
        print(f"Résultats après mise à jour: {len(results)} éléments trouvés")
        for item in results:
            print(f"  - {item['id']}: {item['metadata']['title']}")

        test3_success = len(results) >= 2
    else:
        print("Erreur: La mise à jour de la vue a échoué")
        test3_success = False

    print_result("Mise à jour d'une vue", test3_success)

    return test1_success and test2_success and test3_success

def main():
    """Point d'entrée principal des tests."""
    # Supprimer le fichier de log s'il existe
    if os.path.exists("test_advanced_search.log"):
        os.remove("test_advanced_search.log")

    print_header("Tests pour les fonctionnalités de recherche avancée")

    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")

    try:
        # Créer le répertoire de stockage
        storage_path = os.path.join(temp_dir, "storage")

        print(f"Création du répertoire {storage_path}...")
        os.makedirs(storage_path, exist_ok=True)

        # Créer des données de test
        items = create_test_data(storage_path)
        print(f"Données de test créées: {len(items)} éléments")

        # Tester les fonctionnalités de recherche avancée
        tests = [
            lambda: test_multi_criteria_search(storage_path, items),
            lambda: test_theme_relationships_search(storage_path, items),
            lambda: test_thematic_views(storage_path, items)
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
