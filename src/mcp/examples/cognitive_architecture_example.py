#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation de l'architecture cognitive des roadmaps.

Ce script montre comment utiliser l'architecture cognitive pour créer et naviguer
dans une hiérarchie de nœuds.
"""

import os
import sys
import json
import logging
import tempfile
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
print(f"Ajout du répertoire parent au chemin de recherche: {parent_dir}")
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

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("cognitive_architecture_example")

def main():
    """
    Fonction principale.
    """
    # Créer un répertoire temporaire pour le stockage
    with tempfile.TemporaryDirectory() as temp_dir:
        storage_dir = os.path.join(temp_dir, "nodes")

        # Créer le fournisseur de stockage
        storage_provider = FileNodeStorageProvider(storage_dir)

        # Créer une instance du gestionnaire cognitif
        cognitive_manager = CognitiveManager(storage_provider=storage_provider)

        # Créer un COSMOS
        logger.info("Création d'un COSMOS...")
        cosmos_id = cognitive_manager.create_cosmos(
            name="Système de Gestion des Roadmaps",
            description="Système global pour la gestion des roadmaps de développement",
            metadata={"version": "1.0", "author": "Augment"}
        )

        # Créer des GALAXIES
        logger.info("Création de GALAXIES...")
        galaxy_id1 = cognitive_manager.create_galaxy(
            name="Architecture Cognitive",
            cosmos_id=cosmos_id,
            description="Modèle hiérarchique à 10 niveaux pour l'organisation des roadmaps",
            metadata={"priority": "high", "tags": ["architecture", "cognitive"]}
        )

        galaxy_id2 = cognitive_manager.create_galaxy(
            name="Système de Stockage",
            cosmos_id=cosmos_id,
            description="Système de stockage et de récupération des nœuds cognitifs",
            metadata={"priority": "medium", "tags": ["storage", "persistence"]}
        )

        galaxy_id3 = cognitive_manager.create_galaxy(
            name="Interface Utilisateur",
            cosmos_id=cosmos_id,
            description="Interface utilisateur pour la visualisation et la navigation dans les roadmaps",
            metadata={"priority": "medium", "tags": ["ui", "visualization"]}
        )

        # Créer des SYSTEMES STELLAIRES
        logger.info("Création de SYSTEMES STELLAIRES...")
        system_id1 = cognitive_manager.create_stellar_system(
            name="Modèle Hiérarchique",
            galaxy_id=galaxy_id1,
            description="Implémentation du modèle hiérarchique à 10 niveaux",
            metadata={"status": "in_progress", "tags": ["model", "hierarchy"]}
        )

        system_id2 = cognitive_manager.create_stellar_system(
            name="Navigation Inter-niveaux",
            galaxy_id=galaxy_id1,
            description="Mécanismes de navigation entre les différents niveaux hiérarchiques",
            metadata={"status": "planned", "tags": ["navigation", "hierarchy"]}
        )

        system_id3 = cognitive_manager.create_stellar_system(
            name="Stockage Fichier",
            galaxy_id=galaxy_id2,
            description="Stockage des nœuds cognitifs dans des fichiers JSON",
            metadata={"status": "completed", "tags": ["file", "json"]}
        )

        system_id4 = cognitive_manager.create_stellar_system(
            name="Stockage Vectoriel",
            galaxy_id=galaxy_id2,
            description="Stockage des nœuds cognitifs dans une base de données vectorielle",
            metadata={"status": "planned", "tags": ["vector", "database"]}
        )

        # Récupérer et afficher un nœud
        logger.info(f"Récupération du COSMOS '{cosmos_id}'...")
        cosmos = cognitive_manager.get_node(cosmos_id)
        if cosmos:
            logger.info(f"COSMOS récupéré: {cosmos.name}")
            logger.info(f"Description: {cosmos.description}")
            logger.info(f"Métadonnées: {json.dumps(cosmos.metadata, indent=2)}")
            logger.info(f"Enfants: {cosmos.children_ids}")

        # Récupérer les enfants d'un nœud
        logger.info(f"Récupération des enfants du COSMOS '{cosmos_id}'...")
        children = cognitive_manager.get_children(cosmos_id)
        logger.info(f"Nombre d'enfants: {len(children)}")
        for child in children:
            logger.info(f"  - {child.name} (ID: {child.node_id}, Niveau: {child.level.name})")

        # Mettre à jour un nœud
        logger.info(f"Mise à jour de la GALAXIE '{galaxy_id1}'...")
        cognitive_manager.update_node(
            node_id=galaxy_id1,
            description="Modèle hiérarchique à 10 niveaux pour l'organisation des roadmaps, avec navigation inter-niveaux",
            metadata={"priority": "critical", "tags": ["architecture", "cognitive", "core"]},
            status=NodeStatus.IN_PROGRESS
        )

        # Récupérer le nœud mis à jour
        galaxy = cognitive_manager.get_node(galaxy_id1)
        if galaxy:
            logger.info(f"GALAXIE mise à jour: {galaxy.name}")
            logger.info(f"Description: {galaxy.description}")
            logger.info(f"Métadonnées: {json.dumps(galaxy.metadata, indent=2)}")
            logger.info(f"Statut: {galaxy.status.name}")

        # Récupérer le chemin d'un nœud
        logger.info(f"Récupération du chemin du SYSTEME STELLAIRE '{system_id1}'...")
        path = cognitive_manager.get_path(system_id1)
        logger.info(f"Chemin: {' > '.join([node.name for node in path])}")

        # Supprimer un nœud
        logger.info(f"Suppression du SYSTEME STELLAIRE '{system_id4}'...")
        try:
            cognitive_manager.delete_node(system_id4)
            logger.info(f"Suppression réussie")

            # Vérifier que le nœud a été supprimé
            system = cognitive_manager.get_node(system_id4)
            if system:
                logger.info(f"Le SYSTEME STELLAIRE '{system_id4}' existe encore")
            else:
                logger.info(f"Le SYSTEME STELLAIRE '{system_id4}' a été supprimé")
        except Exception as e:
            logger.error(f"Erreur lors de la suppression du SYSTEME STELLAIRE '{system_id4}': {e}")

        # Essayer de supprimer un nœud avec des enfants
        logger.info(f"Tentative de suppression de la GALAXIE '{galaxy_id1}' qui a des enfants...")
        try:
            cognitive_manager.delete_node(galaxy_id1)
            logger.info(f"Suppression réussie")
        except Exception as e:
            logger.error(f"Erreur lors de la suppression de la GALAXIE '{galaxy_id1}': {e}")
            logger.info("Cette erreur est attendue car la GALAXIE a des enfants")

if __name__ == "__main__":
    main()
