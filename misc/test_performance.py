#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour tester les performances de l'architecture cognitive avec un grand nombre de nœuds.

Ce script teste les performances de l'architecture cognitive avec un grand nombre de nœuds.
"""

import os
import sys
import time
import tempfile
import shutil
import random
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
    print("Modules importés avec succès")
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

def test_performance(num_cosmos=5, num_galaxies=10, num_systems=20):
    """
    Teste les performances de l'architecture cognitive avec un grand nombre de nœuds.
    
    Args:
        num_cosmos (int): Nombre de COSMOS à créer
        num_galaxies (int): Nombre de GALAXIES par COSMOS
        num_systems (int): Nombre de SYSTEMES STELLAIRES par GALAXIE
    """
    # Créer un répertoire temporaire pour les tests
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"\n=== Test des performances avec un grand nombre de nœuds ===")
        print(f"Répertoire temporaire: {temp_dir}")
        print(f"Nombre de COSMOS: {num_cosmos}")
        print(f"Nombre de GALAXIES par COSMOS: {num_galaxies}")
        print(f"Nombre de SYSTEMES STELLAIRES par GALAXIE: {num_systems}")
        print(f"Nombre total de nœuds: {num_cosmos + num_cosmos * num_galaxies + num_cosmos * num_galaxies * num_systems}")
        
        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(temp_dir)
        
        # Créer le gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)
        
        # Test 1: Création des nœuds
        print("\n--- Test 1: Création des nœuds ---")
        start_time = time.time()
        
        # Créer les COSMOS
        cosmos_ids = []
        for i in range(num_cosmos):
            cosmos_id = cognitive_manager.create_cosmos(
                name=f"COSMOS {i+1}",
                description=f"Description du COSMOS {i+1}",
                metadata={"version": "1.0", "index": i}
            )
            cosmos_ids.append(cosmos_id)
        
        # Créer les GALAXIES
        galaxy_ids = []
        for cosmos_id in cosmos_ids:
            for i in range(num_galaxies):
                galaxy_id = cognitive_manager.create_galaxy(
                    name=f"GALAXIE {i+1} du COSMOS {cosmos_id[:8]}",
                    cosmos_id=cosmos_id,
                    description=f"Description de la GALAXIE {i+1} du COSMOS {cosmos_id[:8]}",
                    metadata={"priority": random.choice(["low", "medium", "high"]), "index": i}
                )
                galaxy_ids.append(galaxy_id)
        
        # Créer les SYSTEMES STELLAIRES
        system_ids = []
        for galaxy_id in galaxy_ids:
            for i in range(num_systems):
                system_id = cognitive_manager.create_stellar_system(
                    name=f"SYSTEME {i+1} de la GALAXIE {galaxy_id[:8]}",
                    galaxy_id=galaxy_id,
                    description=f"Description du SYSTEME {i+1} de la GALAXIE {galaxy_id[:8]}",
                    metadata={"status": random.choice(["planned", "in_progress", "completed"]), "index": i}
                )
                system_ids.append(system_id)
        
        end_time = time.time()
        elapsed_time = end_time - start_time
        
        print(f"Temps écoulé pour la création des nœuds: {elapsed_time:.2f} secondes")
        print(f"Nombre de nœuds créés: {len(cosmos_ids) + len(galaxy_ids) + len(system_ids)}")
        print(f"Temps moyen par nœud: {elapsed_time / (len(cosmos_ids) + len(galaxy_ids) + len(system_ids)):.4f} secondes")
        
        # Test 2: Récupération des nœuds
        print("\n--- Test 2: Récupération des nœuds ---")
        start_time = time.time()
        
        # Récupérer tous les nœuds
        all_ids = cosmos_ids + galaxy_ids + system_ids
        random.shuffle(all_ids)
        
        for node_id in all_ids:
            node = cognitive_manager.get_node(node_id)
        
        end_time = time.time()
        elapsed_time = end_time - start_time
        
        print(f"Temps écoulé pour la récupération des nœuds: {elapsed_time:.2f} secondes")
        print(f"Nombre de nœuds récupérés: {len(all_ids)}")
        print(f"Temps moyen par nœud: {elapsed_time / len(all_ids):.4f} secondes")
        
        # Test 3: Récupération des chemins
        print("\n--- Test 3: Récupération des chemins ---")
        start_time = time.time()
        
        # Récupérer les chemins de tous les SYSTEMES STELLAIRES
        random.shuffle(system_ids)
        sample_size = min(100, len(system_ids))
        sample_ids = system_ids[:sample_size]
        
        for node_id in sample_ids:
            path = cognitive_manager.get_path(node_id)
        
        end_time = time.time()
        elapsed_time = end_time - start_time
        
        print(f"Temps écoulé pour la récupération des chemins: {elapsed_time:.2f} secondes")
        print(f"Nombre de chemins récupérés: {len(sample_ids)}")
        print(f"Temps moyen par chemin: {elapsed_time / len(sample_ids):.4f} secondes")
        
        # Test 4: Vérification de la cohérence
        print("\n--- Test 4: Vérification de la cohérence ---")
        start_time = time.time()
        
        checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair=False)
        
        end_time = time.time()
        elapsed_time = end_time - start_time
        
        print(f"Temps écoulé pour la vérification de la cohérence: {elapsed_time:.2f} secondes")
        print(f"Nombre de nœuds vérifiés: {checked}")
        print(f"Nombre d'incohérences trouvées: {inconsistencies}")
        print(f"Temps moyen par nœud: {elapsed_time / checked:.4f} secondes")

if __name__ == "__main__":
    # Tester les performances avec un nombre raisonnable de nœuds
    test_performance(num_cosmos=2, num_galaxies=5, num_systems=10)
