#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour évaluer la précision de l'estimation de l'IQR (écart interquartile)
à partir de KDEs.
"""

import numpy as np
from typing import Dict, Optional, Any, List
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
from statistical_parameters_estimation import estimate_from_raw_data, estimate_from_kde

def evaluate_kde_iqr_precision(data: np.ndarray,
                             kde_points: List[int],
                             criteria: Optional[Dict[str, Any]] = None,
                             distribution_type: str = "symmetric") -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'IQR à partir de KDEs
    avec différents nombres de points.
    
    Args:
        data: Données brutes
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
        distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')
        
    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de points
    """
    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_iqr = raw_params["iqr"]
    sample_size = len(data)
    
    # Initialiser les résultats
    results = {
        "kde_points": kde_points,
        "true_iqr": true_iqr,
        "sample_size": sample_size,
        "distribution_type": distribution_type,
        "estimated_iqrs": [],
        "absolute_errors": [],
        "relative_errors": [],
        "overall_qualities": []
    }
    
    # Évaluer la précision pour chaque nombre de points
    for num_points in kde_points:
        # Estimer les paramètres à partir de la KDE
        kde_params = estimate_from_kde(data, num_points=num_points)
        estimated_iqr = kde_params["iqr"]
        
        # Calculer l'erreur absolue
        absolute_error = abs(estimated_iqr - true_iqr)
        
        # Calculer l'erreur relative (en évitant la division par zéro)
        if true_iqr != 0:
            relative_error = absolute_error / abs(true_iqr)
        else:
            # Si le vrai IQR est zéro, l'erreur relative est infinie
            relative_error = float('inf') if absolute_error > 0 else 0.0
        
        # Déterminer la qualité de l'estimation en fonction de l'erreur relative
        if relative_error <= 0.015:  # Erreur relative < 1.5%
            quality = "excellent"
        elif relative_error <= 0.03:  # Erreur relative < 3%
            quality = "good"
        elif relative_error <= 0.05:  # Erreur relative < 5%
            quality = "acceptable"
        elif relative_error <= 0.10:  # Erreur relative < 10%
            quality = "poor"
        else:  # Erreur relative >= 10%
            quality = "unacceptable"
        
        # Stocker les résultats
        results["estimated_iqrs"].append(estimated_iqr)
        results["absolute_errors"].append(absolute_error)
        results["relative_errors"].append(relative_error)
        results["overall_qualities"].append(quality)
    
    return results
