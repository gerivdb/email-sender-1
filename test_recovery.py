#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester la récupération après corruption de l'architecture cognitive.

Ce script teste la récupération après corruption de l'architecture cognitive.
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

def test_recovery_after_corruption():
    """
    Teste la récupération après corruption.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test de la récupération après corruption ===")
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
        
        # Corrompre le fichier du SYSTEME STELLAIRE
        system_path = os.path.join(temp_dir, f"{system_id}.json")
        
        # Vérifier que le fichier existe
        if os.path.exists(system_path):
            # Corrompre le fichier
            with open(system_path, "w", encoding="utf-8") as f:
                f.write('{"node_id": "' + system_id + '", "name": "Corrupted')
            print(f"Fichier corrompu: {system_path}")
            
            # Essayer de récupérer le SYSTEME STELLAIRE
            try:
                system = cognitive_manager.get_node(system_id)
                print(f"Récupération du SYSTEME STELLAIRE: {'réussie' if system else 'échouée'}")
            except Exception as e:
                print(f"Exception lors de la récupération: {e}")
            
            # Vérifier l'intégrité
            checked, corrupted, repaired = storage_provider.check_integrity(repair=False)
            print(f"Vérification de l'intégrité: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            # Réparer
            checked, corrupted, repaired = storage_provider.check_integrity(repair=True)
            print(f"Réparation: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
            
            # Essayer de récupérer le SYSTEME STELLAIRE après réparation
            try:
                system = cognitive_manager.get_node(system_id)
                print(f"Récupération du SYSTEME STELLAIRE après réparation: {'réussie' if system else 'échouée'}")
                
                if system:
                    print(f"Nom du SYSTEME STELLAIRE après réparation: {system.name}")
                    print(f"Description du SYSTEME STELLAIRE après réparation: {system.description}")
                    print(f"Parent du SYSTEME STELLAIRE après réparation: {system.parent_id}")
                    
                    # Vérifier que le parent existe
                    parent = cognitive_manager.get_node(system.parent_id)
                    print(f"Récupération du parent: {'réussie' if parent else 'échouée'}")
                    
                    if parent:
                        print(f"Nom du parent: {parent.name}")
                        print(f"Type du parent: {parent.level.name}")
                        
                        # Vérifier que le parent a bien l'enfant
                        children = cognitive_manager.get_children(parent.node_id)
                        print(f"Nombre d'enfants du parent: {len(children)}")
                        
                        if any(child.node_id == system_id for child in children):
                            print("Test réussi: Le parent a bien l'enfant")
                        else:
                            print("Test échoué: Le parent n'a pas l'enfant")
            except Exception as e:
                print(f"Exception lors de la récupération après réparation: {e}")
        else:
            print(f"Fichier non trouvé: {system_path}")
            print("Test échoué: Le fichier du SYSTEME STELLAIRE n'existe pas")

def test_recovery_after_circular_reference():
    """
    Teste la récupération après une référence circulaire.
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test de la récupération après une référence circulaire ===")
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
        
        # Créer une référence circulaire
        print("Création d'une référence circulaire...")
        
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
            
            print(f"Référence circulaire créée: {cosmos_id} -> {system_id}")
            
            # Essayer de récupérer le chemin du SYSTEME STELLAIRE
            try:
                path = cognitive_manager.get_path(system_id)
                print(f"Récupération du chemin: {'réussie' if path else 'échouée'}")
                print(f"Chemin: {path}")
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

if __name__ == "__main__":
    test_recovery_after_corruption()
    test_recovery_after_circular_reference()
