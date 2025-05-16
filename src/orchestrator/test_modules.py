#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester les modules du système CRUD thématique.
"""

import os
import sys
import importlib
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

def print_header(title):
    """Affiche un en-tête de section."""
    print("\n" + "=" * 80)
    print(f" {title} ".center(80, "="))
    print("=" * 80)

def print_result(test_name, success):
    """Affiche le résultat d'un test."""
    if success:
        print(f"✅ {test_name}: SUCCÈS")
    else:
        print(f"❌ {test_name}: ÉCHEC")

def test_module_import(module_path):
    """Teste l'importation d'un module."""
    try:
        module_name = module_path.replace("/", ".")
        if module_name.endswith(".py"):
            module_name = module_name[:-3]
        
        module = importlib.import_module(module_name)
        return True, module
    except Exception as e:
        print(f"Erreur lors de l'importation du module {module_path}: {str(e)}")
        return False, None

def test_hierarchical_themes():
    """Teste le module de thèmes hiérarchiques."""
    print_header("Test du module de thèmes hiérarchiques")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.hierarchical_themes")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence de la classe principale
    if not hasattr(module, "HierarchicalThemeManager"):
        print("Erreur: Classe HierarchicalThemeManager non trouvée")
        print_result("Vérification de la classe principale", False)
        return False
    
    print_result("Vérification de la classe principale", True)
    
    # Créer une instance de la classe
    try:
        manager = module.HierarchicalThemeManager()
        print_result("Création d'une instance", True)
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def test_advanced_attribution():
    """Teste le module d'attribution thématique avancée."""
    print_header("Test du module d'attribution thématique avancée")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.advanced_attribution")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence des classes principales
    if not hasattr(module, "AdvancedThemeAttributor"):
        print("Erreur: Classe AdvancedThemeAttributor non trouvée")
        print_result("Vérification des classes principales", False)
        return False
    
    if not hasattr(module, "ThematicAttributionHistory"):
        print("Erreur: Classe ThematicAttributionHistory non trouvée")
        print_result("Vérification des classes principales", False)
        return False
    
    print_result("Vérification des classes principales", True)
    
    # Créer une instance de la classe
    try:
        attributor = module.AdvancedThemeAttributor()
        print_result("Création d'une instance", True)
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def test_theme_change_detector():
    """Teste le module de détection des changements thématiques."""
    print_header("Test du module de détection des changements thématiques")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.theme_change_detector")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence de la classe principale
    if not hasattr(module, "ThemeChangeDetector"):
        print("Erreur: Classe ThemeChangeDetector non trouvée")
        print_result("Vérification de la classe principale", False)
        return False
    
    print_result("Vérification de la classe principale", True)
    
    # Créer une instance de la classe
    try:
        detector = module.ThemeChangeDetector()
        print_result("Création d'une instance", True)
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def test_selective_update():
    """Teste le module de mise à jour sélective par thème."""
    print_header("Test du module de mise à jour sélective par thème")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.selective_update")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence des classes principales
    if not hasattr(module, "ThematicSelectiveUpdate"):
        print("Erreur: Classe ThematicSelectiveUpdate non trouvée")
        print_result("Vérification des classes principales", False)
        return False
    
    if not hasattr(module, "ThematicSectionExtractor"):
        print("Erreur: Classe ThematicSectionExtractor non trouvée")
        print_result("Vérification des classes principales", False)
        return False
    
    print_result("Vérification des classes principales", True)
    
    # Créer une instance de la classe
    try:
        extractor = module.ThematicSectionExtractor()
        print_result("Création d'une instance d'extracteur", True)
        
        # Créer un répertoire temporaire pour le test
        import tempfile
        temp_dir = tempfile.mkdtemp()
        
        updater = module.ThematicSelectiveUpdate(temp_dir)
        print_result("Création d'une instance de mise à jour", True)
        
        # Nettoyer
        import shutil
        shutil.rmtree(temp_dir)
        
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def test_create_update():
    """Teste le module de création et mise à jour thématique."""
    print_header("Test du module de création et mise à jour thématique")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.create_update")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence de la classe principale
    if not hasattr(module, "ThematicCreateUpdate"):
        print("Erreur: Classe ThematicCreateUpdate non trouvée")
        print_result("Vérification de la classe principale", False)
        return False
    
    print_result("Vérification de la classe principale", True)
    
    # Créer une instance de la classe
    try:
        # Créer un répertoire temporaire pour le test
        import tempfile
        temp_dir = tempfile.mkdtemp()
        
        manager = module.ThematicCreateUpdate(temp_dir)
        print_result("Création d'une instance", True)
        
        # Nettoyer
        import shutil
        shutil.rmtree(temp_dir)
        
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def test_manager():
    """Teste le gestionnaire CRUD thématique."""
    print_header("Test du gestionnaire CRUD thématique")
    
    success, module = test_module_import("src.orchestrator.thematic_crud.manager")
    if not success:
        print_result("Importation du module", False)
        return False
    
    print_result("Importation du module", True)
    
    # Vérifier la présence de la classe principale
    if not hasattr(module, "ThematicCRUDManager"):
        print("Erreur: Classe ThematicCRUDManager non trouvée")
        print_result("Vérification de la classe principale", False)
        return False
    
    print_result("Vérification de la classe principale", True)
    
    # Créer une instance de la classe
    try:
        # Créer un répertoire temporaire pour le test
        import tempfile
        temp_dir = tempfile.mkdtemp()
        
        manager = module.ThematicCRUDManager(temp_dir)
        print_result("Création d'une instance", True)
        
        # Nettoyer
        import shutil
        shutil.rmtree(temp_dir)
        
        return True
    except Exception as e:
        print(f"Erreur lors de la création d'une instance: {str(e)}")
        print_result("Création d'une instance", False)
        return False

def main():
    """Point d'entrée principal des tests."""
    print_header("Tests des modules du système CRUD thématique")
    
    # Liste des tests à exécuter
    tests = [
        test_hierarchical_themes,
        test_advanced_attribution,
        test_theme_change_detector,
        test_selective_update,
        test_create_update,
        test_manager
    ]
    
    # Exécuter les tests
    results = []
    for test in tests:
        results.append(test())
    
    # Afficher le résumé
    print_header("Résumé des tests")
    
    success_count = sum(1 for result in results if result)
    total_count = len(results)
    
    print(f"Tests réussis: {success_count}/{total_count}")
    
    if success_count == total_count:
        print("\n✅ Tous les tests ont réussi!")
        return 0
    else:
        print("\n❌ Certains tests ont échoué!")
        return 1

if __name__ == "__main__":
    sys.exit(main())
