#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour vérifier l'intégrité et la cohérence des données de l'architecture cognitive.

Ce script vérifie l'intégrité des fichiers de nœuds et la cohérence des relations parent-enfant.
"""

import os
import sys
import logging
import argparse
from pathlib import Path

# Ajouter le répertoire parent au chemin de recherche des modules
parent_dir = str(Path(__file__).parent.parent.parent.parent)
sys.path.append(parent_dir)

# Importer les modules nécessaires
try:
    from src.mcp.core.roadmap import (
        CognitiveManager, FileNodeStorageProvider
    )
except ImportError as e:
    print(f"Erreur lors de l'importation des modules: {e}")
    sys.exit(1)

# Configuration du logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("cognitive_integrity_check.log")
    ]
)
logger = logging.getLogger("check_cognitive_integrity")

def check_storage_integrity(storage_dir: str, repair: bool = False) -> bool:
    """
    Vérifie l'intégrité des fichiers de nœuds.
    
    Args:
        storage_dir (str): Répertoire de stockage des nœuds
        repair (bool, optional): Si True, tente de réparer les fichiers corrompus. Par défaut False.
    
    Returns:
        bool: True si tous les fichiers sont intègres, False sinon
    """
    logger.info(f"Vérification de l'intégrité des fichiers dans '{storage_dir}'...")
    
    # Créer le fournisseur de stockage
    storage_provider = FileNodeStorageProvider(storage_dir)
    
    # Vérifier l'intégrité des fichiers
    checked, corrupted, repaired = storage_provider.check_integrity(repair)
    
    # Afficher les résultats
    logger.info(f"Vérification terminée: {checked} fichiers vérifiés, {corrupted} fichiers corrompus, {repaired} fichiers réparés")
    
    # Retourner True si tous les fichiers sont intègres
    return corrupted == 0 or corrupted == repaired

def check_relationships_consistency(storage_dir: str, repair: bool = False) -> bool:
    """
    Vérifie la cohérence des relations parent-enfant.
    
    Args:
        storage_dir (str): Répertoire de stockage des nœuds
        repair (bool, optional): Si True, tente de réparer les incohérences. Par défaut False.
    
    Returns:
        bool: True si toutes les relations sont cohérentes, False sinon
    """
    logger.info(f"Vérification de la cohérence des relations parent-enfant dans '{storage_dir}'...")
    
    # Créer le fournisseur de stockage
    storage_provider = FileNodeStorageProvider(storage_dir)
    
    # Créer le gestionnaire cognitif
    cognitive_manager = CognitiveManager(storage_provider=storage_provider)
    
    # Vérifier la cohérence des relations
    checked, inconsistencies, repaired = cognitive_manager.check_consistency(repair)
    
    # Afficher les résultats
    logger.info(f"Vérification terminée: {checked} nœuds vérifiés, {inconsistencies} incohérences trouvées, {repaired} incohérences réparées")
    
    # Retourner True si toutes les relations sont cohérentes
    return inconsistencies == 0 or inconsistencies == repaired

def main():
    """
    Fonction principale.
    """
    # Analyser les arguments de la ligne de commande
    parser = argparse.ArgumentParser(description="Vérifier l'intégrité et la cohérence des données de l'architecture cognitive")
    parser.add_argument("--storage-dir", "-d", required=True, help="Répertoire de stockage des nœuds")
    parser.add_argument("--repair", "-r", action="store_true", help="Tenter de réparer les problèmes détectés")
    parser.add_argument("--integrity-only", "-i", action="store_true", help="Vérifier uniquement l'intégrité des fichiers")
    parser.add_argument("--consistency-only", "-c", action="store_true", help="Vérifier uniquement la cohérence des relations")
    args = parser.parse_args()
    
    # Vérifier que le répertoire de stockage existe
    if not os.path.isdir(args.storage_dir):
        logger.error(f"Le répertoire de stockage '{args.storage_dir}' n'existe pas")
        return 1
    
    # Vérifier l'intégrité des fichiers
    integrity_ok = True
    if not args.consistency_only:
        integrity_ok = check_storage_integrity(args.storage_dir, args.repair)
    
    # Vérifier la cohérence des relations
    consistency_ok = True
    if not args.integrity_only:
        consistency_ok = check_relationships_consistency(args.storage_dir, args.repair)
    
    # Afficher le résultat global
    if integrity_ok and consistency_ok:
        logger.info("Vérification terminée avec succès: aucun problème détecté ou tous les problèmes ont été réparés")
        return 0
    else:
        logger.error("Vérification terminée avec des problèmes non résolus")
        return 1

if __name__ == "__main__":
    sys.exit(main())
