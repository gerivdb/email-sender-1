#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de débogage pour les fonctionnalités de sélection.
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
    print(f"[DEBUG] {message}")
    sys.stdout.flush()

def main():
    """Point d'entrée principal du script de débogage."""
    print_step("Débogage des fonctionnalités de sélection...")
    
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
        
        # Créer un élément de test
        print_step("Création d'un élément de test...")
        item = {
            "id": "test_item",
            "content": "Contenu de test",
            "metadata": {
                "title": "Titre de test",
                "author": "Auteur de test",
                "tags": ["test", "debug"],
                "themes": {
                    "test_theme": 0.8
                }
            }
        }
        
        # Sauvegarder l'élément dans le stockage
        item_path = os.path.join(storage_path, f"{item['id']}.json")
        print_step(f"Sauvegarde de l'élément dans {item_path}...")
        with open(item_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)
        
        # Créer un répertoire thématique
        theme_dir = os.path.join(storage_path, "test_theme")
        print_step(f"Création du répertoire thématique {theme_dir}...")
        os.makedirs(theme_dir, exist_ok=True)
        
        # Sauvegarder l'élément dans le répertoire thématique
        theme_path = os.path.join(theme_dir, f"{item['id']}.json")
        print_step(f"Sauvegarde de l'élément dans {theme_path}...")
        with open(theme_path, 'w', encoding='utf-8') as f:
            json.dump(item, f, ensure_ascii=False, indent=2)
        
        # Importer la classe ThematicSelector
        print_step("Importation de ThematicSelector...")
        from src.orchestrator.thematic_crud.selection import ThematicSelector
        print_step("ThematicSelector importé avec succès.")
        
        # Créer une instance de ThematicSelector
        print_step("Création d'une instance de ThematicSelector...")
        selector = ThematicSelector(storage_path)
        print_step("Instance de ThematicSelector créée avec succès.")
        
        # Tester la sélection par ID
        print_step("Test de la sélection par ID...")
        selected_ids = selector.select_by_id("test_item")
        print_step(f"Éléments sélectionnés par ID: {selected_ids}")
        
        # Tester la sélection par thème
        print_step("Test de la sélection par thème...")
        selected_ids = selector.select_by_theme("test_theme")
        print_step(f"Éléments sélectionnés par thème: {selected_ids}")
        
        # Tester la sélection par contenu
        print_step("Test de la sélection par contenu...")
        selected_ids = selector.select_by_content("Contenu de test")
        print_step(f"Éléments sélectionnés par contenu: {selected_ids}")
        
        # Tester la sélection par métadonnées
        print_step("Test de la sélection par métadonnées...")
        selected_ids = selector.select_by_metadata({"author": "Auteur de test"})
        print_step(f"Éléments sélectionnés par métadonnées: {selected_ids}")
        
        # Importer la classe ThematicDeleteArchive
        print_step("Importation de ThematicDeleteArchive...")
        from src.orchestrator.thematic_crud.delete_archive import ThematicDeleteArchive
        print_step("ThematicDeleteArchive importé avec succès.")
        
        # Créer une instance de ThematicDeleteArchive
        print_step("Création d'une instance de ThematicDeleteArchive...")
        delete_archive = ThematicDeleteArchive(storage_path, archive_path)
        print_step("Instance de ThematicDeleteArchive créée avec succès.")
        
        # Tester l'archivage par sélection
        print_step("Test de l'archivage par sélection...")
        stats = delete_archive.archive_items_by_selection(
            "by_id",
            {"item_id": "test_item"},
            "Test d'archivage par sélection"
        )
        print_step(f"Statistiques d'archivage: {stats}")
        
        # Vérifier que l'élément a été archivé
        archive_item_path = os.path.join(archive_path, "test_item.json")
        print_step(f"Vérification de l'archivage dans {archive_item_path}...")
        if os.path.exists(archive_item_path):
            print_step("L'élément a été archivé avec succès.")
        else:
            print_step("ERREUR: L'élément n'a pas été archivé.")
        
        # Importer la classe ThematicCRUDManager
        print_step("Importation de ThematicCRUDManager...")
        from src.orchestrator.thematic_crud.manager import ThematicCRUDManager
        print_step("ThematicCRUDManager importé avec succès.")
        
        # Créer une instance de ThematicCRUDManager
        print_step("Création d'une instance de ThematicCRUDManager...")
        manager = ThematicCRUDManager(storage_path, archive_path)
        print_step("Instance de ThematicCRUDManager créée avec succès.")
        
        # Tester la suppression par sélection
        print_step("Test de la suppression par sélection...")
        stats = manager.delete_items_by_selection(
            "by_theme",
            {"theme": "test_theme"},
            permanent=True,
            reason="Test de suppression par sélection"
        )
        print_step(f"Statistiques de suppression: {stats}")
        
        print_step("Débogage terminé avec succès!")
        return 0
    
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
