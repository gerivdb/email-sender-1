#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Tests pour l'interface de ligne de commande.
"""

import os
import sys
import tempfile
import shutil
import subprocess
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent)
sys.path.append(parent_dir)

def run_cli_tests():
    """Exécute des tests pour l'interface de ligne de commande."""
    print("Exécution des tests pour l'interface de ligne de commande...")
    
    # Créer un répertoire temporaire pour le stockage
    temp_dir = tempfile.mkdtemp()
    storage_path = os.path.join(temp_dir, "storage")
    archive_path = os.path.join(temp_dir, "archive")
    cache_dir = os.path.join(temp_dir, "cache")
    
    try:
        # Créer les répertoires
        os.makedirs(storage_path, exist_ok=True)
        os.makedirs(archive_path, exist_ok=True)
        os.makedirs(cache_dir, exist_ok=True)
        
        # Chemin vers le script CLI
        cli_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cli.py")
        
        # Test 1: Créer un élément
        print("\nTest 1: Créer un élément")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "create",
            "--content", "Ce document décrit l'architecture du système.",
            "--title", "Architecture du système",
            "--author", "John Doe",
            "--tags", "architecture,conception,système",
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        print("Élément créé avec succès.")
        
        # Extraire l'ID de l'élément créé
        import json
        item = json.loads(result.stdout)
        item_id = item["id"]
        print(f"ID de l'élément créé: {item_id}")
        
        # Test 2: Récupérer un élément
        print("\nTest 2: Récupérer un élément")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "get",
            "--id", item_id,
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        retrieved_item = json.loads(result.stdout)
        if retrieved_item["id"] != item_id:
            print("ÉCHEC: L'élément récupéré n'a pas le bon ID.")
            return False
        
        print("Élément récupéré avec succès.")
        
        # Test 3: Mettre à jour un élément
        print("\nTest 3: Mettre à jour un élément")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "update",
            "--id", item_id,
            "--content", "Ce document décrit l'architecture et les tests du système.",
            "--title", "Architecture et tests du système",
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        updated_item = json.loads(result.stdout)
        if updated_item["metadata"]["title"] != "Architecture et tests du système":
            print("ÉCHEC: L'élément n'a pas été mis à jour correctement.")
            return False
        
        print("Élément mis à jour avec succès.")
        
        # Test 4: Rechercher des éléments
        print("\nTest 4: Rechercher des éléments")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "search",
            "--query", "architecture",
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        search_results = json.loads(result.stdout)
        if not search_results or search_results[0]["id"] != item_id:
            print("ÉCHEC: La recherche n'a pas retourné les résultats attendus.")
            return False
        
        print("Recherche effectuée avec succès.")
        
        # Test 5: Analyser un contenu
        print("\nTest 5: Analyser un contenu")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "analyze",
            "--content", "Ce document décrit l'architecture du système.",
            "--title", "Architecture du système",
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        themes = json.loads(result.stdout)
        if "architecture" not in themes:
            print("ÉCHEC: L'analyse n'a pas détecté le thème 'architecture'.")
            return False
        
        print("Analyse effectuée avec succès.")
        
        # Test 6: Archiver un élément
        print("\nTest 6: Archiver un élément")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "archive",
            "--id", item_id
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        print("Élément archivé avec succès.")
        
        # Test 7: Lister les éléments archivés
        print("\nTest 7: Lister les éléments archivés")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "list-archived",
            "--output", "json"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        archived_items = json.loads(result.stdout)
        if not archived_items or archived_items[0]["id"] != item_id:
            print("ÉCHEC: La liste des éléments archivés n'a pas retourné les résultats attendus.")
            return False
        
        print("Liste des éléments archivés récupérée avec succès.")
        
        # Test 8: Restaurer un élément archivé
        print("\nTest 8: Restaurer un élément archivé")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "restore",
            "--id", item_id
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        print("Élément restauré avec succès.")
        
        # Test 9: Supprimer un élément
        print("\nTest 9: Supprimer un élément")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "delete",
            "--id", item_id
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        print("Élément supprimé avec succès.")
        
        # Test 10: Vider le cache
        print("\nTest 10: Vider le cache")
        cmd = [
            sys.executable, cli_path,
            "--storage-path", storage_path,
            "--archive-path", archive_path,
            "--cache-dir", cache_dir,
            "clear-cache",
            "--all"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ÉCHEC: La commande a échoué avec le code {result.returncode}.")
            print(f"Erreur: {result.stderr}")
            return False
        
        print("Cache vidé avec succès.")
        
        print("\nTous les tests ont réussi!")
        return True
    
    except Exception as e:
        print(f"ERREUR: {str(e)}")
        return False
    
    finally:
        # Supprimer le répertoire temporaire
        shutil.rmtree(temp_dir)

if __name__ == "__main__":
    success = run_cli_tests()
    sys.exit(0 if success else 1)
