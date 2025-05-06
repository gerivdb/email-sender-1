#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour déterminer la résolution optimale pour l'estimation de l'IQR.
"""

from typing import Dict, Any

def determine_optimal_resolution_for_iqr(histogram_results: Dict[str, Any],
                                       kde_results: Dict[str, Any],
                                       quality_threshold: str = "good") -> Dict[str, Any]:
    """
    Détermine la résolution optimale pour l'estimation de l'IQR.
    
    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')
        
    Returns:
        Dict[str, Any]: Résolutions optimales pour l'estimation de l'IQR
    """
    # Définir les rangs de qualité
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    threshold_rank = quality_ranks[quality_threshold]
    
    # Trouver la résolution minimale pour l'histogramme qui atteint le seuil de qualité
    hist_min_resolution = None
    for i, quality in enumerate(histogram_results["overall_qualities"]):
        if quality_ranks[quality] >= threshold_rank:
            hist_min_resolution = histogram_results["bin_counts"][i]
            break
    
    # Trouver la résolution minimale pour la KDE qui atteint le seuil de qualité
    kde_min_resolution = None
    for i, quality in enumerate(kde_results["overall_qualities"]):
        if quality_ranks[quality] >= threshold_rank:
            kde_min_resolution = kde_results["kde_points"][i]
            break
    
    # Trouver la résolution optimale pour l'histogramme (meilleure qualité)
    hist_optimal_resolution = None
    hist_optimal_quality_rank = -1
    for i, quality in enumerate(histogram_results["overall_qualities"]):
        quality_rank = quality_ranks[quality]
        if quality_rank > hist_optimal_quality_rank:
            hist_optimal_quality_rank = quality_rank
            hist_optimal_resolution = histogram_results["bin_counts"][i]
    
    # Trouver la résolution optimale pour la KDE (meilleure qualité)
    kde_optimal_resolution = None
    kde_optimal_quality_rank = -1
    for i, quality in enumerate(kde_results["overall_qualities"]):
        quality_rank = quality_ranks[quality]
        if quality_rank > kde_optimal_quality_rank:
            kde_optimal_quality_rank = quality_rank
            kde_optimal_resolution = kde_results["kde_points"][i]
    
    # Résultats
    return {
        "histogram": {
            "min_resolution": hist_min_resolution,
            "optimal_resolution": hist_optimal_resolution,
            "optimal_quality": list(quality_ranks.keys())[list(quality_ranks.values()).index(hist_optimal_quality_rank)]
        },
        "kde": {
            "min_resolution": kde_min_resolution,
            "optimal_resolution": kde_optimal_resolution,
            "optimal_quality": list(quality_ranks.keys())[list(quality_ranks.values()).index(kde_optimal_quality_rank)]
        }
    }
