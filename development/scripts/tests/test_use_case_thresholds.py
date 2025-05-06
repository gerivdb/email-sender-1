#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script de test pour vérifier que les seuils par cas d'utilisation fonctionnent correctement.
"""

import os
import sys
import json
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats
from typing import Dict, List, Any

# Ajouter le répertoire des métriques au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))

# Importer les modules nécessaires
from distribution_thresholds import DistributionThresholds

def test_use_case_thresholds() -> None:
    """
    Teste les seuils spécifiques par cas d'utilisation.
    """
    print("\n=== Test des seuils par cas d'utilisation ===")
    
    # Créer une instance du gestionnaire de seuils
    dist_thresholds = DistributionThresholds()
    
    # Obtenir les cas d'utilisation disponibles
    use_cases = dist_thresholds.get_use_cases()
    print(f"Cas d'utilisation disponibles: {', '.join(use_cases)}")
    
    # Tester les seuils pour chaque cas d'utilisation
    for use_case in use_cases:
        print(f"\n=== Test pour le cas d'utilisation '{use_case}' ===")
        print(f"Description: {dist_thresholds.get_use_case_description(use_case)}")
        
        # Tester les seuils pour différents types de distribution
        for dist_type in dist_thresholds.get_distribution_types():
            thresholds = dist_thresholds.get_thresholds(dist_type, use_case=use_case)
            if thresholds:
                print(f"\nSeuils pour le type de distribution '{dist_type}':")
                for metric, value in thresholds.items():
                    print(f"  {metric}: {value:.2f}")
                
                # Tester les seuils GMCI
                gmci_thresholds = dist_thresholds.get_gmci_thresholds(dist_type, use_case=use_case)
                if gmci_thresholds:
                    print(f"\nSeuils GMCI pour le type de distribution '{dist_type}':")
                    for level, value in gmci_thresholds.items():
                        print(f"  {level}: {value:.2f}")
    
    # Tester un cas d'utilisation inexistant
    print("\n=== Test pour un cas d'utilisation inexistant ===")
    thresholds = dist_thresholds.get_thresholds("normal", use_case="inexistant")
    print(f"Seuils pour un cas d'utilisation inexistant: {thresholds}")
    
    # Tester un type de distribution inexistant pour un cas d'utilisation existant
    print("\n=== Test pour un type de distribution inexistant dans un cas d'utilisation ===")
    thresholds = dist_thresholds.get_thresholds("inexistant", use_case=use_cases[0])
    print(f"Seuils pour un type de distribution inexistant: {thresholds}")

if __name__ == "__main__":
    test_use_case_thresholds()
