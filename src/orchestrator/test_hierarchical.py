#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour le système de thèmes hiérarchiques.
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

from src.orchestrator.thematic_crud.hierarchical_themes import HierarchicalThemeManager
from src.orchestrator.thematic_crud.theme_attribution import ThemeAttributor
from src.orchestrator.thematic_crud.manager import ThematicCRUDManager

def run_hierarchical_tests():
    """Exécute des tests pour le système de thèmes hiérarchiques."""
    print("Exécution des tests pour le système de thèmes hiérarchiques...")
    
    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    config_path = os.path.join(temp_dir, "themes_config.json")
    
    try:
        # Créer une configuration personnalisée pour les tests
        custom_config = {
            "themes": {
                "root": "Racine",
                "level1_a": "Niveau 1 A",
                "level1_b": "Niveau 1 B",
                "level2_a1": "Niveau 2 A1",
                "level2_a2": "Niveau 2 A2",
                "level2_b1": "Niveau 2 B1",
                "level3_a1_1": "Niveau 3 A1.1"
            },
            "theme_hierarchy": {
                "root": ["level1_a", "level1_b"],
                "level1_a": ["level2_a1", "level2_a2"],
                "level1_b": ["level2_b1"],
                "level2_a1": ["level3_a1_1"]
            },
            "theme_keywords": {
                "root": ["racine", "base", "principal"],
                "level1_a": ["niveau1", "a", "premier"],
                "level1_b": ["niveau1", "b", "premier"],
                "level2_a1": ["niveau2", "a1", "second"],
                "level2_a2": ["niveau2", "a2", "second"],
                "level2_b1": ["niveau2", "b1", "second"],
                "level3_a1_1": ["niveau3", "a1.1", "troisième"]
            }
        }
        
        # Sauvegarder la configuration
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(custom_config, f, ensure_ascii=False, indent=2)
        
        # Test 1: Gestionnaire de thèmes hiérarchiques
        print("\nTest 1: Gestionnaire de thèmes hiérarchiques")
        theme_manager = HierarchicalThemeManager(config_path)
        
        # Vérifier que les thèmes ont été chargés
        if "root" not in theme_manager.themes:
            print("ÉCHEC: Les thèmes n'ont pas été chargés correctement.")
            return False
        
        # Vérifier la récupération des parents
        parents = theme_manager.get_parent_themes("level3_a1_1")
        if len(parents) != 3 or "level2_a1" not in parents or "level1_a" not in parents or "root" not in parents:
            print("ÉCHEC: La récupération des parents ne fonctionne pas correctement.")
            return False
        
        print(f"Parents de level3_a1_1: {parents}")
        
        # Vérifier la récupération des enfants
        children = theme_manager.get_child_themes("level1_a")
        if len(children) != 3 or "level2_a1" not in children or "level2_a2" not in children or "level3_a1_1" not in children:
            print("ÉCHEC: La récupération des enfants ne fonctionne pas correctement.")
            return False
        
        print(f"Enfants de level1_a: {children}")
        
        # Vérifier la récupération du chemin
        path = theme_manager.get_theme_path("level3_a1_1")
        if len(path) != 4 or path[0] != "root" or path[1] != "level1_a" or path[2] != "level2_a1" or path[3] != "level3_a1_1":
            print("ÉCHEC: La récupération du chemin ne fonctionne pas correctement.")
            return False
        
        print(f"Chemin de level3_a1_1: {path}")
        
        # Vérifier la propagation des scores
        theme_scores = {"level3_a1_1": 1.0}
        propagated_scores = theme_manager.propagate_theme_scores(theme_scores)
        
        if "level2_a1" not in propagated_scores or "level1_a" not in propagated_scores or "root" not in propagated_scores:
            print("ÉCHEC: La propagation des scores ne fonctionne pas correctement.")
            return False
        
        print(f"Scores propagés: {propagated_scores}")
        
        # Test 2: Attribution thématique avec thèmes hiérarchiques
        print("\nTest 2: Attribution thématique avec thèmes hiérarchiques")
        theme_attributor = ThemeAttributor(config_path)
        
        # Attribuer des thèmes à un contenu
        content = "Ce document décrit le niveau 3 a1.1 du système."
        themes = theme_attributor.attribute_theme(content)
        
        if "level3_a1_1" not in themes:
            print("ÉCHEC: L'attribution thématique ne fonctionne pas correctement.")
            return False
        
        print(f"Thèmes attribués: {themes}")
        
        # Vérifier que les scores ont été propagés aux parents
        if "level2_a1" not in themes or "level1_a" not in themes or "root" not in themes:
            print("ÉCHEC: La propagation des scores dans l'attribution thématique ne fonctionne pas correctement.")
            return False
        
        # Test 3: Gestionnaire CRUD avec thèmes hiérarchiques
        print("\nTest 3: Gestionnaire CRUD avec thèmes hiérarchiques")
        crud_manager = ThematicCRUDManager(temp_dir, themes_config_path=config_path)
        
        # Créer un élément
        content = "Ce document décrit le niveau 3 a1.1 du système."
        metadata = {
            "title": "Document de niveau 3",
            "author": "Test User",
            "tags": ["niveau3", "a1.1"]
        }
        
        item = crud_manager.create_item(content, metadata)
        if item is None:
            print("ÉCHEC: Impossible de créer un élément.")
            return False
        
        print(f"Élément créé avec l'ID: {item['id']}")
        print(f"Thèmes attribués: {item['metadata'].get('themes', {})}")
        
        # Vérifier que les thèmes ont été attribués correctement
        if "level3_a1_1" not in item['metadata'].get('themes', {}):
            print("ÉCHEC: Les thèmes n'ont pas été attribués correctement.")
            return False
        
        # Vérifier que les scores ont été propagés aux parents
        if "level2_a1" not in item['metadata'].get('themes', {}) or "level1_a" not in item['metadata'].get('themes', {}) or "root" not in item['metadata'].get('themes', {}):
            print("ÉCHEC: La propagation des scores dans le gestionnaire CRUD ne fonctionne pas correctement.")
            return False
        
        # Récupérer les éléments par thème parent
        items = crud_manager.get_items_by_theme("level1_a")
        if not items or items[0]["id"] != item["id"]:
            print("ÉCHEC: La récupération des éléments par thème parent ne fonctionne pas correctement.")
            return False
        
        print(f"Nombre d'éléments récupérés par thème parent: {len(items)}")
        
        print("\nTous les tests ont réussi!")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return False
    
    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    success = run_hierarchical_tests()
    sys.exit(0 if success else 1)
