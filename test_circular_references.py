#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester la gestion des références circulaires de l'architecture cognitive.

Ce script teste la gestion des références circulaires de l'architecture cognitive.
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

def test_circular_references():
    """
    Teste la gestion des références circulaires.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test de la gestion des références circulaires ===")
        print(f"Répertoire temporaire: {temp_dir}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Test 1: Référence circulaire directe
        print("\n--- Test 1: Référence circulaire directe ---")
        
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
        
        # Créer une référence circulaire directe
        print("Création d'une référence circulaire directe...")
        
        # Récupérer le COSMOS
        cosmos_path = os.path.join(temp_dir, f"{cosmos_id}.json")
        
        # Vérifier que le fichier existe
        if os.path.exists(cosmos_path):
            # Lire le fichier
            with open(cosmos_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            # Modifier le parent du COSMOS pour créer une référence circulaire
            data["parent_id"] = system_id
            
            # Écrire les données modifiées
            with open(cosmos_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            
            print(f"Référence circulaire directe créée: {cosmos_id} -> {system_id}")
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE
            try:
                path = cognitive_manager.get_path(system_id)
                print(f"Récupération du chemin: {'réussie' if path else 'échouée'}")
                print(f"Chemin: {path}")
                print("Test échoué: La récupération du chemin aurait dû échouer")
            except CircularReferenceError as e:
                print(f"Exception CircularReferenceError: {e}")
                print("Test réussi: La récupération du chemin a échoué comme prévu")
            except Exception as e:
                print(f"Exception inattendue: {e}")
                print("Test échoué: Une exception inattendue a été levée")
            
            # Vérifier la cohérence
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=False)
            print(f"Vérification de la cohérence: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
            
            # Réparer
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=True)
            print(f"Réparation: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE après réparation
            try:
                path = cognitive_manager.get_path(system_id)
                print(f"Récupération du chemin après réparation: {'réussie' if path else 'échouée'}")
                print(f"Chemin après réparation: {path}")
                print("Test réussi: La récupération du chemin a réussi après réparation")
            except Exception as e:
                print(f"Exception lors de la récupération après réparation: {e}")
                print("Test échoué: Une exception a été levée lors de la récupération après réparation")
        else:
            print(f"Fichier non trouvé: {cosmos_path}")
            print("Test échoué: Le fichier du COSMOS n'existe pas")
        
        # Test 2: Référence circulaire indirecte
        print("\n--- Test 2: Référence circulaire indirecte ---")
        
        # Créer un nouveau COSMOS
        cosmos_id2 = cognitive_manager.create_cosmos(
            name="Test Cosmos 2",
            description="Test description 2"
        )
        print(f"COSMOS 2 créé (ID: {cosmos_id2})")
        
        # Créer une nouvelle GALAXIE
        galaxy_id2 = cognitive_manager.create_galaxy(
            name="Test Galaxy 2",
            cosmos_id=cosmos_id2,
            description="Test description 2"
        )
        print(f"GALAXIE 2 créée (ID: {galaxy_id2})")
        
        # Créer un nouveau SYSTEME STELLAIRE
        system_id2 = cognitive_manager.create_stellar_system(
            name="Test System 2",
            galaxy_id=galaxy_id2,
            description="Test description 2"
        )
        print(f"SYSTEME STELLAIRE 2 créé (ID: {system_id2})")
        
        # Créer une référence circulaire indirecte
        print("Création d'une référence circulaire indirecte...")
        
        # Récupérer le COSMOS 2
        cosmos_path2 = os.path.join(temp_dir, f"{cosmos_id2}.json")
        
        # Récupérer la GALAXIE 2
        galaxy_path2 = os.path.join(temp_dir, f"{galaxy_id2}.json")
        
        # Vérifier que les fichiers existent
        if os.path.exists(cosmos_path2) and os.path.exists(galaxy_path2):
            # Lire le fichier du COSMOS 2
            with open(cosmos_path2, "r", encoding="utf-8") as f:
                data_cosmos = json.load(f)
            
            # Lire le fichier de la GALAXIE 2
            with open(galaxy_path2, "r", encoding="utf-8") as f:
                data_galaxy = json.load(f)
            
            # Modifier le parent du COSMOS 2 pour créer une référence circulaire indirecte
            data_cosmos["parent_id"] = system_id2
            
            # Écrire les données modifiées du COSMOS 2
            with open(cosmos_path2, "w", encoding="utf-8") as f:
                json.dump(data_cosmos, f, ensure_ascii=False, indent=2)
            
            print(f"Référence circulaire indirecte créée: {cosmos_id2} -> {system_id2} -> {galaxy_id2} -> {cosmos_id2}")
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE 2
            try:
                path = cognitive_manager.get_path(system_id2)
                print(f"Récupération du chemin: {'réussie' if path else 'échouée'}")
                print(f"Chemin: {path}")
                print("Test échoué: La récupération du chemin aurait dû échouer")
            except CircularReferenceError as e:
                print(f"Exception CircularReferenceError: {e}")
                print("Test réussi: La récupération du chemin a échoué comme prévu")
            except Exception as e:
                print(f"Exception inattendue: {e}")
                print("Test échoué: Une exception inattendue a été levée")
            
            # Vérifier la cohérence
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=False)
            print(f"Vérification de la cohérence: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
            
            # Réparer
            checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=True)
            print(f"Réparation: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE 2 après réparation
            try:
                path = cognitive_manager.get_path(system_id2)
                print(f"Récupération du chemin après réparation: {'réussie' if path else 'échouée'}")
                print(f"Chemin après réparation: {path}")
                print("Test réussi: La récupération du chemin a réussi après réparation")
            except Exception as e:
                print(f"Exception lors de la récupération après réparation: {e}")
                print("Test échoué: Une exception a été levée lors de la récupération après réparation")
        else:
            print(f"Fichiers non trouvés: {cosmos_path2} ou {galaxy_path2}")
            print("Test échoué: Les fichiers du COSMOS 2 ou de la GALAXIE 2 n'existent pas")

if __name__ == "__main__":
    test_circular_references()
