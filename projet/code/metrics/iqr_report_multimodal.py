#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour créer un rapport complet sur la précision de l'estimation de l'IQR
pour les distributions multimodales.
"""

import numpy as np
from typing import Dict, Any, Optional, List
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
from iqr_histogram_evaluation import evaluate_histogram_iqr_precision
from iqr_kde_evaluation import evaluate_kde_iqr_precision
from iqr_visualization import plot_iqr_precision_evaluation
from iqr_optimization import determine_optimal_resolution_for_iqr

def create_iqr_precision_report_multimodal(data: np.ndarray,
                                         bin_counts: List[int] = [10, 20, 50, 100, 200],
                                         kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                         save_path: Optional[str] = None,
                                         show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'IQR
    pour les distributions multimodales.
    
    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
        
    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR
    """
    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_iqr_precision(
        data, bin_counts, distribution_type="multimodal"
    )
    
    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_iqr_precision(
        data, kde_points, distribution_type="multimodal"
    )
    
    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_iqr(histogram_results, kde_results)
    
    # Visualiser les résultats
    if save_path or show_plot:
        plot_iqr_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'IQR - Distribution multimodale",
            save_path=save_path,
            show_plot=show_plot
        )
    
    # Créer le rapport
    report = {
        "histogram_results": histogram_results,
        "kde_results": kde_results,
        "optimal_resolutions": optimal_resolutions,
        "recommendations": {
            "histogram": {
                "min_bins": optimal_resolutions["histogram"]["min_resolution"],
                "optimal_bins": optimal_resolutions["histogram"]["optimal_resolution"],
                "quality": optimal_resolutions["histogram"]["optimal_quality"]
            },
            "kde": {
                "min_points": optimal_resolutions["kde"]["min_resolution"],
                "optimal_points": optimal_resolutions["kde"]["optimal_resolution"],
                "quality": optimal_resolutions["kde"]["optimal_quality"]
            },
            "preferred_method": "kde" if optimal_resolutions["kde"]["optimal_quality"] > optimal_resolutions["histogram"]["optimal_quality"] else "histogram"
        }
    }
    
    return report
