#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Test pour les fonctionnalités de sélection.
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

def test_selector_by_id(storage_path, items):
    """Teste la sélection par ID."""
    print_header("Test de sélection par ID")
    
    from src.orchestrator.thematic_crud.selection import ThematicSelector
    
    # Créer un sélecteur
    selector = ThematicSelector(storage_path)
    
    # Sélectionner un élément par ID
    selected_ids = selector.select_by_id("item1")
    print(f"Éléments sélectionnés par ID 'item1': {selected_ids}")
    
    if len(selected_ids) == 1 and selected_ids[0] == "item1":
        print_result("Sélection par ID", True)
        return True
    else:
        print_result("Sélection par ID", False)
        return False

def test_selector_by_theme(storage_path, items):
    """Teste la sélection par thème."""
    print_header("Test de sélection par thème")
    
    from src.orchestrator.thematic_crud.selection import ThematicSelector
    
    # Créer un sélecteur
    selector = ThematicSelector(storage_path)
    
    # Sélectionner des éléments par thème
    selected_ids = selector.select_by_theme("architecture")
    print(f"Éléments sélectionnés par thème 'architecture': {selected_ids}")
    
    if len(selected_ids) == 1 and "item1" in selected_ids:
        print_result("Sélection par thème", True)
        return True
    else:
        print_result("Sélection par thème", False)
        return False

def test_selector_by_content(storage_path, items):
    """Teste la sélection par contenu."""
    print_header("Test de sélection par contenu")
    
    from src.orchestrator.thematic_crud.selection import ThematicSelector
    
    # Créer un sélecteur
    selector = ThematicSelector(storage_path)
    
    # Sélectionner des éléments par contenu
    selected_ids = selector.select_by_content("développement")
    print(f"Éléments sélectionnés par contenu 'développement': {selected_ids}")
    
    if len(selected_ids) == 1 and "item2" in selected_ids:
        print_result("Sélection par contenu", True)
        return True
    else:
        print_result("Sélection par contenu", False)
        return False

def test_selector_by_metadata(storage_path, items):
    """Teste la sélection par métadonnées."""
    print_header("Test de sélection par métadonnées")
    
    from src.orchestrator.thematic_crud.selection import ThematicSelector
    
    # Créer un sélecteur
    selector = ThematicSelector(storage_path)
    
    # Sélectionner des éléments par métadonnées
    selected_ids = selector.select_by_metadata({"author": "John Doe"})
    print(f"Éléments sélectionnés par auteur 'John Doe': {selected_ids}")
    
    if len(selected_ids) == 2 and "item1" in selected_ids and "item3" in selected_ids:
        print_result("Sélection par métadonnées", True)
        return True
    else:
        print_result("Sélection par métadonnées", False)
        return False

def test_selector_combine(storage_path, items):
    """Teste la combinaison de sélections."""
    print_header("Test de combinaison de sélections")
    
    from src.orchestrator.thematic_crud.selection import ThematicSelector
    
    # Créer un sélecteur
    selector = ThematicSelector(storage_path)
    
    # Créer plusieurs sélections
    selection1 = selector.select_by_metadata({"author": "John Doe"})
    selection2 = selector.select_by_theme("test")
    
    # Combiner les sélections (intersection)
    combined_ids = selector.combine_selections([selection1, selection2], mode="intersection")
    print(f"Intersection des sélections: {combined_ids}")
    
    if len(combined_ids) == 1 and "item3" in combined_ids:
        print_result("Combinaison de sélections (intersection)", True)
        return True
    else:
        print_result("Combinaison de sélections (intersection)", False)
        return False

def test_manager_selection(storage_path, archive_path, items):
    """Teste les fonctionnalités de sélection du gestionnaire CRUD."""
    print_header("Test des fonctionnalités de sélection du gestionnaire CRUD")
    
    from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
    
    # Créer un gestionnaire CRUD
    manager = ThematicCRUDManager(storage_path, archive_path)
    
    # Archiver des éléments par sélection
    stats = manager.archive_items_by_selection(
        "by_metadata",
        {"metadata_filter": {"author": "Jane Smith"}},
        "Test d'archivage par sélection"
    )
    
    print(f"Statistiques d'archivage: {stats}")
    
    if stats["archived_count"] == 1:
        # Vérifier que l'élément a été archivé
        archived_items = manager.get_archived_items()
        if len(archived_items) == 1 and archived_items[0]["id"] == "item2":
            print_result("Archivage par sélection", True)
            return True
        else:
            print_result("Archivage par sélection", False)
            return False
    else:
        print_result("Archivage par sélection", False)
        return False

def main():
    """Point d'entrée principal des tests."""
    print_header("Tests pour les fonctionnalités de sélection")
    
    # Créer un répertoire temporaire
    temp_dir = tempfile.mkdtemp()
    print(f"Répertoire temporaire créé: {temp_dir}")
    
    try:
        # Créer les répertoires
        storage_path = os.path.join(temp_dir, "storage")
        archive_path = os.path.join(temp_dir, "archive")
        
        print(f"Création des répertoires {storage_path} et {archive_path}...")
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        
        # Créer des données de test
        items = create_test_data(storage_path)
        print(f"Données de test créées: {len(items)} éléments")
        
        # Tester les fonctionnalités de sélection
        tests = [
            lambda: test_selector_by_id(storage_path, items),
            lambda: test_selector_by_theme(storage_path, items),
            lambda: test_selector_by_content(storage_path, items),
            lambda: test_selector_by_metadata(storage_path, items),
            lambda: test_selector_combine(storage_path, items),
            lambda: test_manager_selection(storage_path, archive_path, items)
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
