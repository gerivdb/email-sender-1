#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester la robustesse du stockage de l'architecture cognitive.

Ce script teste la robustesse du stockage de l'architecture cognitive.
"""

import os
import sys
import tempfile
import shutil
import uuid
import random
import string
import json
import time
import threading
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent)
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.roadmap import (
        CognitiveManager, FileNodeStorageProvider,
        HierarchyLevel, NodeStatus
    )
    from src.mcp.core.roadmap.exceptions import (
        NodeNotFoundError, InvalidParentError, NodeHasChildrenError,
        StorageError, InvalidNodeDataError, CircularReferenceError
    )
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

def test_concurrent_access():
    """
    Teste l'accès concurrent au stockage.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test de l'accès concurrent au stockage ===")
        print(f"Répertoire temporaire: {temp_dir}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Créer un COSMOS
        cosmos_id = cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )
        print(f"COSMOS créé (ID: {cosmos_id})")
        
        # Créer une GALAXIE
        galaxy_id = cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )
        print(f"GALAXIE créée (ID: {galaxy_id})")
        
        # Fonction pour créer des SYSTEMES STELLAIRES en parallèle
        def create_system(i):
            try:
                system_id = cognitive_manager.create_stellar_system(
                    name=f"System {i}",
                    galaxy_id=galaxy_id,
                    description=f"System {i} description"
                )
                return system_id
            except Exception as e:
                return str(e)
        
        # Créer 10 SYSTEMES STELLAIRES en parallèle
        print("\n--- Test 1: Création parallèle de SYSTEMES STELLAIRES ---")
        with ThreadPoolExecutor(max_workers=10) as executor:
            results = list(executor.map(create_system, range(10)))
        
        print(f"Résultats: {results}")
        
        # Vérifier que tous les SYSTEMES STELLAIRES ont été créés
        systems = cognitive_manager.get_children(galaxy_id)
        print(f"Nombre de SYSTEMES STELLAIRES créés: {len(systems)}")
        
        if len(systems) == 10:
            print("Test réussi: Tous les SYSTEMES STELLAIRES ont été créés")
        else:
            print(f"Test échoué: Seulement {len(systems)} SYSTEMES STELLAIRES ont été créés sur 10")
        
        # Fonction pour mettre à jour des SYSTEMES STELLAIRES en parallèle
        def update_system(system_id):
            try:
                success = cognitive_manager.update_node(
                    node_id=system_id,
                    name=f"Updated System {system_id[-8:]}",
                    description=f"Updated description for System {system_id[-8:]}",
                    metadata={"updated": True, "timestamp": time.time()}
                )
                return success
            except Exception as e:
                return str(e)
        
        # Mettre à jour les SYSTEMES STELLAIRES en parallèle
        print("\n--- Test 2: Mise à jour parallèle de SYSTEMES STELLAIRES ---")
        system_ids = [system.node_id for system in systems]
        with ThreadPoolExecutor(max_workers=10) as executor:
            results = list(executor.map(update_system, system_ids))
        
        print(f"Résultats: {results}")
        
        # Vérifier que tous les SYSTEMES STELLAIRES ont été mis à jour
        updated_systems = cognitive_manager.get_children(galaxy_id)
        updated_count = sum(1 for system in updated_systems if system.name.startswith("Updated"))
        
        print(f"Nombre de SYSTEMES STELLAIRES mis à jour: {updated_count}")
        
        if updated_count == 10:
            print("Test réussi: Tous les SYSTEMES STELLAIRES ont été mis à jour")
        else:
            print(f"Test échoué: Seulement {updated_count} SYSTEMES STELLAIRES ont été mis à jour sur 10")
        
        # Fonction pour récupérer des SYSTEMES STELLAIRES en parallèle
        def get_system(system_id):
            try:
                system = cognitive_manager.get_node(system_id)
                return system.node_id if system else None
            except Exception as e:
                return str(e)
        
        # Récupérer les SYSTEMES STELLAIRES en parallèle
        print("\n--- Test 3: Récupération parallèle de SYSTEMES STELLAIRES ---")
        with ThreadPoolExecutor(max_workers=10) as executor:
            results = list(executor.map(get_system, system_ids))
        
        print(f"Résultats: {len(results)}")
        
        # Vérifier que tous les SYSTEMES STELLAIRES ont été récupérés
        retrieved_count = sum(1 for result in results if result in system_ids)
        
        print(f"Nombre de SYSTEMES STELLAIRES récupérés: {retrieved_count}")
        
        if retrieved_count == 10:
            print("Test réussi: Tous les SYSTEMES STELLAIRES ont été récupérés")
        else:
            print(f"Test échoué: Seulement {retrieved_count} SYSTEMES STELLAIRES ont été récupérés sur 10")

def test_storage_recovery():
    """
    Teste la récupération du stockage après une corruption.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test de la récupération du stockage ===")
        print(f"Répertoire temporaire: {temp_dir}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Créer un COSMOS
        cosmos_id = cognitive_manager.create_cosmos(
            name="Test Cosmos",
            description="Test description"
        )
        print(f"COSMOS créé (ID: {cosmos_id})")
        
        # Créer une GALAXIE
        galaxy_id = cognitive_manager.create_galaxy(
            name="Test Galaxy",
            cosmos_id=cosmos_id,
            description="Test description"
        )
        print(f"GALAXIE créée (ID: {galaxy_id})")
        
        # Créer un SYSTEME STELLAIRE
        system_id = cognitive_manager.create_stellar_system(
            name="Test System",
            galaxy_id=galaxy_id,
            description="Test description"
        )
        print(f"SYSTEME STELLAIRE créé (ID: {system_id})")
        
        # Créer une sauvegarde du fichier du SYSTEME STELLAIRE
        system_path = os.path.join(temp_dir, f"{system_id}.json")
        backup_path = f"{system_path}.bak"
        
        # Vérifier que le fichier existe
        if os.path.exists(system_path):
            # Créer une sauvegarde
            shutil.copy2(system_path, backup_path)
            print(f"Sauvegarde créée: {backup_path}")
            
            # Corrompre le fichier
            with open(system_path, "w", encoding="utf-8") as f:
                f.write('{"node_id": "' + system_id + '", "name": "Corrupted')
            print(f"Fichier corrompu: {system_path}")
            
            # Essayer de récupérer le SYSTEME STELLAIRE
            try:
                system = cognitive_manager.get_node(system_id)
                if system:
                    print(f"SYSTEME STELLAIRE récupéré depuis la sauvegarde: {system.name}")
                    print("Test réussi: Le SYSTEME STELLAIRE a été récupéré depuis la sauvegarde")
                else:
                    print("Test échoué: Le SYSTEME STELLAIRE n'a pas été récupéré")
            except Exception as e:
                print(f"Exception lors de la récupération: {e}")
                print("Test échoué: Une exception a été levée lors de la récupération")
        else:
            print(f"Fichier non trouvé: {system_path}")
            print("Test échoué: Le fichier du SYSTEME STELLAIRE n'existe pas")

if __name__ == "__main__":
    test_concurrent_access()
    test_storage_recovery()
