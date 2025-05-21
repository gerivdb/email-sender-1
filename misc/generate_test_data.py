#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour générer des données de test pour l'architecture cognitive.

Ce script génère une hiérarchie de nœuds cognitifs pour tester l'outil de vérification d'intégrité.
"""

import os
import sys
import json
import uuid
import random
from datetime import datetime
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

def generate_test_data(storage_dir, num_cosmos=2, num_galaxies=3, num_systems=4, corrupt_percentage=10):
    """
    Génère des données de test pour l'architecture cognitive.
    
    Args:
        storage_dir (str): Répertoire de stockage des nœuds
        num_cosmos (int): Nombre de COSMOS à créer
        num_galaxies (int): Nombre de GALAXIES par COSMOS
        num_systems (int): Nombre de SYSTEMES STELLAIRES par GALAXIE
        corrupt_percentage (int): Pourcentage de nœuds à corrompre
    """
    # Créer le répertoire de stockage s'il n'existe pas
    os.makedirs(storage_dir, exist_ok=True)
    
    # Créer le fournisseur de stockage
    storage_provider = FileNodeStorageProvider(storage_dir)
    
    # Créer le gestionnaire cognitif
    cognitive_manager = CognitiveManager(storage_provider=storage_provider)
    
    # Créer les COSMOS
    cosmos_ids = []
    for i in range(num_cosmos):
        cosmos_id = cognitive_manager.create_cosmos(
            name=f"COSMOS {i+1}",
            description=f"Description du COSMOS {i+1}",
            metadata={"version": "1.0", "index": i}
        )
        cosmos_ids.append(cosmos_id)
        print(f"COSMOS {i+1} créé avec l'ID {cosmos_id}")
    
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
            print(f"GALAXIE {i+1} créée avec l'ID {galaxy_id} dans le COSMOS {cosmos_id[:8]}")
    
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
            print(f"SYSTEME {i+1} créé avec l'ID {system_id} dans la GALAXIE {galaxy_id[:8]}")
    
    # Corrompre certains nœuds
    all_ids = cosmos_ids + galaxy_ids + system_ids
    num_to_corrupt = int(len(all_ids) * corrupt_percentage / 100)
    
    if num_to_corrupt > 0:
        print(f"\nCorruption de {num_to_corrupt} nœuds...")
        
        # Sélectionner des nœuds à corrompre
        to_corrupt = random.sample(all_ids, num_to_corrupt)
        
        for node_id in to_corrupt:
            # Récupérer le fichier du nœud
            node_path = os.path.join(storage_dir, f"{node_id}.json")
            
            if os.path.exists(node_path):
                # Lire le fichier
                with open(node_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                
                # Choisir un type de corruption
                corruption_type = random.choice([
                    "remove_field",
                    "change_parent",
                    "add_nonexistent_child",
                    "remove_child_reference",
                    "invalid_json"
                ])
                
                if corruption_type == "remove_field":
                    # Supprimer un champ important
                    field = random.choice(["name", "level", "level_value", "node_id"])
                    if field in data:
                        del data[field]
                        print(f"Champ '{field}' supprimé du nœud {node_id}")
                
                elif corruption_type == "change_parent":
                    # Changer le parent pour un ID inexistant
                    if "parent_id" in data:
                        data["parent_id"] = str(uuid.uuid4())
                        print(f"Parent du nœud {node_id} changé pour un ID inexistant")
                
                elif corruption_type == "add_nonexistent_child":
                    # Ajouter un enfant inexistant
                    if "children_ids" in data:
                        data["children_ids"].append(str(uuid.uuid4()))
                        print(f"Enfant inexistant ajouté au nœud {node_id}")
                
                elif corruption_type == "remove_child_reference":
                    # Supprimer la référence à un enfant existant
                    if "children_ids" in data and data["children_ids"]:
                        data["children_ids"].pop()
                        print(f"Référence à un enfant supprimée du nœud {node_id}")
                
                elif corruption_type == "invalid_json":
                    # Écrire un JSON invalide
                    with open(node_path, "w", encoding="utf-8") as f:
                        f.write("{\"name\": \"Invalid JSON")
                    print(f"JSON invalide écrit dans le nœud {node_id}")
                    continue
                
                # Écrire les données corrompues
                with open(node_path, "w", encoding="utf-8") as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("\nGénération des données de test terminée.")
    print(f"Nombre total de nœuds créés: {len(all_ids)}")
    print(f"Nombre de nœuds corrompus: {num_to_corrupt}")

if __name__ == "__main__":
    # Répertoire de stockage
    storage_dir = "test_nodes"
    
    # Générer les données de test
    generate_test_data(storage_dir, num_cosmos=2, num_galaxies=3, num_systems=4, corrupt_percentage=20)
