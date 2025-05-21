#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester les cas limites et les scénarios d'erreur de l'architecture cognitive.

Ce script teste les cas limites et les scénarios d'erreur de l'architecture cognitive.
"""

import os
import sys
import tempfile
import shutil
import uuid
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

def test_edge_cases():
    """
    Teste les cas limites et les scénarios d'erreur.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test des cas limites et des scénarios d'erreur ===")
        print(f"Répertoire temporaire: {temp_dir}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Test 1: Création d'un nœud avec un ID existant
        print("\n--- Test 1: Création d'un nœud avec un ID existant ---")
        try:
            # Créer un COSMOS
            cosmos_id = cognitive_manager.create_cosmos(
                name="Test Cosmos",
                description="Test description",
                node_id="test-cosmos-id"
            )
            print(f"COSMOS créé avec l'ID {cosmos_id}")
            
            # Essayer de créer un autre COSMOS avec le même ID
            cosmos_id2 = cognitive_manager.create_cosmos(
                name="Test Cosmos 2",
                description="Test description 2",
                node_id="test-cosmos-id"
            )
            print(f"COSMOS 2 créé avec l'ID {cosmos_id2}")
            
            # Vérifier que les deux COSMOS sont différents
            cosmos1 = cognitive_manager.get_node(cosmos_id)
            cosmos2 = cognitive_manager.get_node(cosmos_id2)
            
            print(f"COSMOS 1: {cosmos1.name}")
            print(f"COSMOS 2: {cosmos2.name}")
            
            if cosmos1.name != cosmos2.name:
                print("Test réussi: Les deux COSMOS sont différents")
            else:
                print("Test échoué: Les deux COSMOS sont identiques")
        except Exception as e:
            print(f"Exception: {e}")
        
        # Test 2: Création d'une GALAXIE avec un COSMOS inexistant
        print("\n--- Test 2: Création d'une GALAXIE avec un COSMOS inexistant ---")
        try:
            # Essayer de créer une GALAXIE avec un COSMOS inexistant
            galaxy_id = cognitive_manager.create_galaxy(
                name="Test Galaxy",
                cosmos_id="nonexistent-cosmos-id"
            )
            print(f"GALAXIE créée avec l'ID {galaxy_id}")
            print("Test échoué: La création de la GALAXIE aurait dû échouer")
        except NodeNotFoundError as e:
            print(f"Exception NodeNotFoundError: {e}")
            print("Test réussi: La création de la GALAXIE a échoué comme prévu")
        except Exception as e:
            print(f"Exception inattendue: {e}")
            print("Test échoué: Une exception inattendue a été levée")
        
        # Test 3: Suppression d'un nœud avec des enfants
        print("\n--- Test 3: Suppression d'un nœud avec des enfants ---")
        try:
            # Créer un COSMOS
            cosmos_id = cognitive_manager.create_cosmos(
                name="Test Cosmos",
                description="Test description"
            )
            print(f"COSMOS créé avec l'ID {cosmos_id}")
            
            # Créer une GALAXIE
            galaxy_id = cognitive_manager.create_galaxy(
                name="Test Galaxy",
                cosmos_id=cosmos_id,
                description="Test description"
            )
            print(f"GALAXIE créée avec l'ID {galaxy_id}")
            
            # Essayer de supprimer le COSMOS
            cognitive_manager.delete_node(cosmos_id)
            print("Test échoué: La suppression du COSMOS aurait dû échouer")
        except NodeHasChildrenError as e:
            print(f"Exception NodeHasChildrenError: {e}")
            print("Test réussi: La suppression du COSMOS a échoué comme prévu")
        except Exception as e:
            print(f"Exception inattendue: {e}")
            print("Test échoué: Une exception inattendue a été levée")
        
        # Test 4: Création d'une référence circulaire
        print("\n--- Test 4: Création d'une référence circulaire ---")
        try:
            # Créer un COSMOS
            cosmos_id = cognitive_manager.create_cosmos(
                name="Test Cosmos",
                description="Test description"
            )
            print(f"COSMOS créé avec l'ID {cosmos_id}")
            
            # Créer une GALAXIE
            galaxy_id = cognitive_manager.create_galaxy(
                name="Test Galaxy",
                cosmos_id=cosmos_id,
                description="Test description"
            )
            print(f"GALAXIE créée avec l'ID {galaxy_id}")
            
            # Créer un SYSTEME STELLAIRE
            system_id = cognitive_manager.create_stellar_system(
                name="Test System",
                galaxy_id=galaxy_id,
                description="Test description"
            )
            print(f"SYSTEME STELLAIRE créé avec l'ID {system_id}")
            
            # Créer une référence circulaire
            print("Création d'une référence circulaire...")
            
            # Récupérer le COSMOS
            cosmos = cognitive_manager.get_node(cosmos_id)
            
            # Modifier le parent du COSMOS pour créer une référence circulaire
            cosmos.parent_id = system_id
            
            # Stocker le COSMOS modifié
            storage_provider.store_node(cosmos.to_dict())
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE
            path = cognitive_manager.get_path(system_id)
            print(f"Chemin: {path}")
            print("Test échoué: La récupération du chemin aurait dû échouer")
        except CircularReferenceError as e:
            print(f"Exception CircularReferenceError: {e}")
            print("Test réussi: La récupération du chemin a échoué comme prévu")
        except Exception as e:
            print(f"Exception inattendue: {e}")
            print("Test échoué: Une exception inattendue a été levée")
        
        # Test 5: Vérification de l'intégrité et de la cohérence
        print("\n--- Test 5: Vérification de l'intégrité et de la cohérence ---")
        try:
            # Créer un fichier JSON invalide
            invalid_node_id = str(uuid.uuid4())
            invalid_node_path = os.path.join(temp_dir, f"{invalid_node_id}.json")
            with open(invalid_node_path, "w", encoding="utf-8") as f:
                f.write("{\"name\": \"Invalid JSON")
            print(f"Fichier JSON invalide créé: {invalid_node_path}")
            
            # Vérifier l'intégrité
            checked, corrupted, repaired = storage_provider.check_integrity(repair=False)
            print(f"Vérification de l'intégrité: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            if corrupted > 0:
                print("Test réussi: Des fichiers corrompus ont été détectés")
            else:
                print("Test échoué: Aucun fichier corrompu n'a été détecté")
            
            # Vérifier la cohérence
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=False)
            print(f"Vérification de la cohérence: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
            
            # Réparer les problèmes
            checked, corrupted, repaired = storage_provider.check_integrity(repair=True)
            print(f"Réparation de l'intégrité: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=True)
            print(f"Réparation de la cohérence: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
        except Exception as e:
            print(f"Exception inattendue: {e}")
            print("Test échoué: Une exception inattendue a été levée")

if __name__ == "__main__":
    test_edge_cases()
