#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester les cas limites extrêmes de l'architecture cognitive.

Ce script teste les cas limites extrêmes de l'architecture cognitive.
"""

import os
import sys
import tempfile
import shutil
import uuid
import random
import string
import json
from pathlib import Path

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

def generate_random_string(length):
    """Génère une chaîne aléatoire de la longueur spécifiée."""
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(length))

def test_extreme_cases():
    """
    Teste les cas limites extrêmes.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test des cas limites extrêmes ===")
        print(f"Répertoire temporaire: {temp_dir}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Test 1: Noms très longs
        print("\n--- Test 1: Noms très longs ---")
        try:
            # Créer un COSMOS avec un nom très long
            long_name = generate_random_string(10000)
            cosmos_id = cognitive_manager.create_cosmos(
                name=long_name,
                description="Test description"
            )
            print(f"COSMOS créé avec un nom de 10000 caractères (ID: {cosmos_id})")
            
            # Récupérer le COSMOS
            cosmos = cognitive_manager.get_node(cosmos_id)
            if cosmos and cosmos.name == long_name:
                print("Test réussi: Le COSMOS a été correctement stocké et récupéré avec un nom très long")
            else:
                print("Test échoué: Le COSMOS n'a pas été correctement stocké ou récupéré")
        except Exception as e:
            print(f"Exception: {e}")
        
        # Test 2: Métadonnées volumineuses
        print("\n--- Test 2: Métadonnées volumineuses ---")
        try:
            # Créer un COSMOS avec des métadonnées volumineuses
            large_metadata = {f"key_{i}": generate_random_string(1000) for i in range(100)}
            cosmos_id = cognitive_manager.create_cosmos(
                name="Test Cosmos",
                description="Test description",
                metadata=large_metadata
            )
            print(f"COSMOS créé avec des métadonnées volumineuses (ID: {cosmos_id})")
            
            # Récupérer le COSMOS
            cosmos = cognitive_manager.get_node(cosmos_id)
            if cosmos and len(cosmos.metadata) == 100:
                print("Test réussi: Le COSMOS a été correctement stocké et récupéré avec des métadonnées volumineuses")
            else:
                print("Test échoué: Le COSMOS n'a pas été correctement stocké ou récupéré")
        except Exception as e:
            print(f"Exception: {e}")
        
        # Test 3: Hiérarchie profonde
        print("\n--- Test 3: Hiérarchie profonde ---")
        try:
            # Créer une hiérarchie profonde
            cosmos_id = cognitive_manager.create_cosmos(
                name="Root Cosmos",
                description="Root description"
            )
            print(f"COSMOS racine créé (ID: {cosmos_id})")
            
            # Créer une chaîne de GALAXIES
            parent_id = cosmos_id
            for i in range(10):
                galaxy_id = cognitive_manager.create_galaxy(
                    name=f"Galaxy {i+1}",
                    cosmos_id=parent_id,
                    description=f"Galaxy {i+1} description"
                )
                print(f"GALAXIE {i+1} créée (ID: {galaxy_id})")
                
                # Créer une chaîne de SYSTEMES STELLAIRES
                for j in range(10):
                    system_id = cognitive_manager.create_stellar_system(
                        name=f"System {i+1}-{j+1}",
                        galaxy_id=galaxy_id,
                        description=f"System {i+1}-{j+1} description"
                    )
                    print(f"SYSTEME STELLAIRE {i+1}-{j+1} créé (ID: {system_id})")
                
                # Utiliser cette GALAXIE comme parent pour la prochaine
                parent_id = galaxy_id
            
            print("Test réussi: Hiérarchie profonde créée avec succès")
        except Exception as e:
            print(f"Exception: {e}")
        
        # Test 4: Corruption manuelle des fichiers
        print("\n--- Test 4: Corruption manuelle des fichiers ---")
        try:
            # Créer un COSMOS
            cosmos_id = cognitive_manager.create_cosmos(
                name="Test Cosmos",
                description="Test description"
            )
            print(f"COSMOS créé (ID: {cosmos_id})")
            
            # Corrompre manuellement le fichier
            node_path = os.path.join(temp_dir, f"{cosmos_id}.json")
            with open(node_path, "r+", encoding="utf-8") as f:
                data = json.load(f)
                f.seek(0)
                f.truncate()
                # Écrire des données partielles
                f.write('{"node_id": "' + cosmos_id + '", "name": "Corrupted')
            print(f"Fichier corrompu manuellement: {node_path}")
            
            # Essayer de récupérer le COSMOS
            try:
                cosmos = cognitive_manager.get_node(cosmos_id)
                print(f"Récupération du COSMOS: {'réussie' if cosmos else 'échouée'}")
            except Exception as e:
                print(f"Exception lors de la récupération: {e}")
            
            # Vérifier l'intégrité
            checked, corrupted, repaired = storage_provider.check_integrity(repair=False)
            print(f"Vérification de l'intégrité: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            # Réparer
            checked, corrupted, repaired = storage_provider.check_integrity(repair=True)
            print(f"Réparation: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            # Essayer de récupérer le COSMOS après réparation
            try:
                cosmos = cognitive_manager.get_node(cosmos_id)
                print(f"Récupération du COSMOS après réparation: {'réussie' if cosmos else 'échouée'}")
            except Exception as e:
                print(f"Exception lors de la récupération après réparation: {e}")
        except Exception as e:
            print(f"Exception: {e}")

if __name__ == "__main__":
    test_extreme_cases()
