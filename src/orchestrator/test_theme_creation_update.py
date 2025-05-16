#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour les fonctionnalités de création et mise à jour thématique.
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

def print_result(test_name, success):
    """Affiche le résultat d'un test."""
    message = f"✅ {test_name}: SUCCÈS" if success else f"❌ {test_name}: ÉCHEC"
    print(message)
    sys.stdout.flush()

def test_advanced_attribution(storage_path):
    """Teste l'attribution thématique avancée."""
    print_header("Test d'attribution thématique avancée")

    from src.orchestrator.thematic_crud.advanced_attribution import AdvancedThemeAttributor

    # Créer un attributeur thématique avancé
    attributor = AdvancedThemeAttributor()

    # Test 1: Attribution simple
    print("Test 1: Attribution simple")
    content = "Ce document décrit l'architecture du système de gestion de contenu."
    metadata = {"title": "Architecture du système"}

    themes = attributor.attribute_theme(content, metadata)
    print(f"Thèmes attribués: {themes}")

    test1_success = "architecture" in themes and themes["architecture"] > 0.5
    print_result("Attribution simple", test1_success)

    # Test 2: Attribution avec contexte
    print("\nTest 2: Attribution avec contexte")
    content = "Ce document décrit les fonctionnalités du système."
    metadata = {"title": "Fonctionnalités du système"}
    context = {
        "navigation_context": {
            "current_section": "architecture",
            "parent_sections": ["technical"]
        }
    }

    themes = attributor.attribute_theme(content, metadata, context)
    print(f"Thèmes attribués avec contexte: {themes}")

    test2_success = "architecture" in themes and "technical" in themes
    print_result("Attribution avec contexte", test2_success)

    # Test 3: Ajout de retour utilisateur
    print("\nTest 3: Ajout de retour utilisateur")
    user_themes = {
        "architecture": 0.9,
        "documentation": 0.7
    }

    attributor.add_user_feedback("test_item_1", user_themes)
    stats = attributor.get_user_feedback_statistics()
    print(f"Statistiques de retour utilisateur: {stats}")

    test3_success = stats["total_feedback_count"] > 0
    print_result("Ajout de retour utilisateur", test3_success)

    return test1_success and test2_success and test3_success

def test_theme_change_detection(storage_path):
    """Teste la détection des changements thématiques."""
    print_header("Test de détection des changements thématiques")

    from src.orchestrator.thematic_crud.theme_change_detector import ThemeChangeDetector

    # Créer un détecteur de changements thématiques
    detector = ThemeChangeDetector()

    # Test 1: Détection de changements
    print("Test 1: Détection de changements")
    old_themes = {
        "architecture": 0.8,
        "documentation": 0.5,
        "technical": 0.3
    }

    new_themes = {
        "architecture": 0.6,
        "documentation": 0.7,
        "development": 0.4
    }

    changes = detector.detect_changes(old_themes, new_themes)
    print(f"Changements détectés: {changes}")

    test1_success = (
        changes["significance"] > 0 and
        any(item["theme"] == "development" for item in changes["added"]) and
        any(item["theme"] == "technical" for item in changes["removed"])
    )
    print_result("Détection de changements", test1_success)

    # Test 2: Analyse de l'évolution thématique
    print("\nTest 2: Analyse de l'évolution thématique")
    theme_history = [
        {
            "timestamp": (datetime.now() - timedelta(days=10)).isoformat(),
            "themes": {
                "architecture": 0.8,
                "documentation": 0.5,
                "technical": 0.3
            }
        },
        {
            "timestamp": (datetime.now() - timedelta(days=5)).isoformat(),
            "themes": {
                "architecture": 0.7,
                "documentation": 0.6,
                "development": 0.2
            }
        },
        {
            "timestamp": datetime.now().isoformat(),
            "themes": {
                "architecture": 0.6,
                "documentation": 0.7,
                "development": 0.4
            }
        }
    ]

    evolution = detector.analyze_theme_evolution(theme_history)
    print(f"Évolution thématique: {evolution}")

    test2_success = (
        evolution["trend"] in ["evolving", "gradual_change", "major_shift"] and
        "development" in evolution["emerging_themes"] and
        "technical" in evolution["declining_themes"]
    )
    print_result("Analyse de l'évolution thématique", test2_success)

    # Test 3: Suggestions de corrections
    print("\nTest 3: Suggestions de corrections")
    content = "Ce document décrit l'architecture et le développement du système."
    current_themes = {
        "architecture": 0.7,
        "documentation": 0.3
    }
    expected_themes = ["development", "technical"]

    suggestions = detector.suggest_theme_corrections(content, current_themes, expected_themes)
    print(f"Suggestions de corrections: {suggestions}")

    test3_success = (
        any(item["theme"] == "development" for item in suggestions["add"]) and
        any(item["theme"] == "technical" for item in suggestions["add"])
    )
    print_result("Suggestions de corrections", test3_success)

    return test1_success and test2_success and test3_success

def test_selective_update(storage_path):
    """Teste la mise à jour sélective par thème."""
    print_header("Test de mise à jour sélective par thème")

    from src.orchestrator.thematic_crud.selective_update import ThematicSelectiveUpdate, ThematicSectionExtractor

    # Créer un extracteur de sections thématiques
    extractor = ThematicSectionExtractor()

    # Test 1: Extraction de sections
    print("Test 1: Extraction de sections thématiques")
    content = """
    # Architecture du système

    Ce document décrit l'architecture du système de gestion de contenu.
    L'architecture est basée sur une approche modulaire.

    # Développement

    Le développement du système est réalisé en Python.
    Les tests sont effectués avec pytest.

    # Documentation

    La documentation est générée avec Sphinx.
    Elle est disponible en ligne.
    """

    sections = extractor.extract_sections(content)
    print(f"Sections extraites: {len(sections)} thèmes")
    for theme, theme_sections in sections.items():
        print(f"  - {theme}: {len(theme_sections)} sections")

    test1_success = (
        "architecture" in sections and
        "development" in sections and
        "documentation" in sections
    )
    print_result("Extraction de sections", test1_success)

    # Créer un gestionnaire de mise à jour sélective
    updater = ThematicSelectiveUpdate(storage_path)

    # Créer un élément de test
    item_id = "test_item_1"
    item = {
        "id": item_id,
        "content": content,
        "metadata": {
            "id": item_id,
            "title": "Document de test",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "themes": {
                "architecture": 0.8,
                "development": 0.6,
                "documentation": 0.4
            }
        }
    }

    # Sauvegarder l'élément
    item_path = os.path.join(storage_path, f"{item_id}.json")
    with open(item_path, 'w', encoding='utf-8') as f:
        json.dump(item, f, ensure_ascii=False, indent=2)

    # Test 2: Mise à jour d'une section thématique
    print("\nTest 2: Mise à jour d'une section thématique")
    new_content = """
    # Développement avancé

    Le développement du système est réalisé en Python avec des fonctionnalités avancées.
    Les tests sont effectués avec pytest et coverage.
    """

    updated_item = updater.update_theme_sections(item_id, "development", new_content)
    print(f"Élément mis à jour: {updated_item is not None}")

    if updated_item:
        print(f"Nouveau contenu:\n{updated_item['content']}")

    test2_success = (
        updated_item is not None and
        "développement avancé" in updated_item['content'].lower() and
        "architecture du système" in updated_item['content'].lower() and
        "documentation" in updated_item['content'].lower()
    )
    print_result("Mise à jour d'une section thématique", test2_success)

    # Test 3: Fusion de contenu thématique
    print("\nTest 3: Fusion de contenu thématique")
    content_to_merge = """
    # Documentation supplémentaire

    Des tutoriels vidéo sont également disponibles.
    """

    updated_item = updater.merge_theme_content(item_id, "documentation", content_to_merge)
    print(f"Élément mis à jour: {updated_item is not None}")

    if updated_item:
        print(f"Nouveau contenu:\n{updated_item['content']}")

    test3_success = (
        updated_item is not None and
        "tutoriels vidéo" in updated_item['content'].lower()
    )
    print_result("Fusion de contenu thématique", test3_success)

    return test1_success and test2_success and test3_success

def test_create_update_integration(storage_path):
    """Teste l'intégration des fonctionnalités de création et mise à jour."""
    print_header("Test d'intégration des fonctionnalités de création et mise à jour")

    from src.orchestrator.thematic_crud.create_update import ThematicCreateUpdate

    # Créer un gestionnaire de création et mise à jour
    manager = ThematicCreateUpdate(storage_path, use_advanced_attribution=True)

    # Test 1: Création avec attribution avancée
    print("Test 1: Création avec attribution avancée")
    content = "Ce document décrit l'architecture et le développement du système de gestion de contenu."
    metadata = {"title": "Architecture et développement"}
    context = {
        "navigation_context": {
            "current_section": "technical",
            "parent_sections": []
        }
    }

    item = manager.create_item(content, metadata, context)
    print(f"Élément créé: {item['id']}")
    print(f"Thèmes attribués: {item['metadata']['themes']}")

    test1_success = (
        "architecture" in item['metadata']['themes'] and
        "development" in item['metadata']['themes'] and
        "technical" in item['metadata']['themes']
    )
    print_result("Création avec attribution avancée", test1_success)

    # Test 2: Mise à jour avec détection de changements
    print("\nTest 2: Mise à jour avec détection de changements")
    new_content = "Ce document décrit le développement et les tests du système de gestion de contenu."

    updated_item = manager.update_item(item['id'], content=new_content)
    if updated_item is None:
        print("Erreur: La mise à jour a échoué")
        test2_success = False
    else:
        print(f"Élément mis à jour: {updated_item['id']}")
        print(f"Nouveaux thèmes: {updated_item['metadata']['themes']}")

        if 'theme_changes' in updated_item['metadata']:
            print(f"Changements thématiques: {updated_item['metadata']['theme_changes']}")

        test2_success = (
            "development" in updated_item['metadata']['themes'] and
            'theme_changes' in updated_item['metadata']
        )
    print_result("Mise à jour avec détection de changements", test2_success)

    # Test 3: Mise à jour sélective
    print("\nTest 3: Mise à jour sélective")
    section_content = "# Tests\n\nLes tests sont effectués avec pytest et coverage."

    updated_item = manager.update_theme_sections(item['id'], "testing", section_content)
    print(f"Élément mis à jour: {updated_item is not None}")

    if updated_item:
        print(f"Nouveau contenu:\n{updated_item['content']}")

    test3_success = (
        updated_item is not None and
        "pytest" in updated_item['content'].lower()
    )
    print_result("Mise à jour sélective", test3_success)

    # Test 4: Analyse de l'évolution thématique
    print("\nTest 4: Analyse de l'évolution thématique")
    evolution = manager.analyze_theme_evolution(item['id'])
    print(f"Évolution thématique: {evolution}")

    test4_success = (
        evolution is not None and
        "trend" in evolution
    )
    print_result("Analyse de l'évolution thématique", test4_success)

    return test1_success and test2_success and test3_success and test4_success

def main():
    """Point d'entrée principal des tests."""

    print_header("Tests pour les fonctionnalités de création et mise à jour thématique")

    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")

    try:
        # Créer le répertoire de stockage
        storage_path = os.path.join(temp_dir, "storage")

        print(f"Création du répertoire {storage_path}...")
        os.makedirs(storage_path, exist_ok=True)

        # Tester les fonctionnalités
        tests = [
            lambda: test_advanced_attribution(storage_path),
            lambda: test_theme_change_detection(storage_path),
            lambda: test_selective_update(storage_path),
            lambda: test_create_update_integration(storage_path)
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
