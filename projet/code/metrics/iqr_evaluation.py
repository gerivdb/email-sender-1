#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour évaluer la précision de l'estimation de l'IQR (écart interquartile)
à partir d'histogrammes et de KDEs.
"""

import numpy as np
import matplotlib.pyplot as plt
from typing import Dict, Optional, Any, List
import scipy.stats
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
from statistical_parameters_estimation import estimate_from_raw_data, estimate_from_histogram, estimate_from_kde

def define_iqr_precision_criteria(relative_error_threshold: float = 0.05,
                                confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de l'IQR.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)
        
    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de l'IQR
    """
    # Définir les critères de précision
    criteria = {
        "name": "iqr_precision",
        "description": "Critères de précision pour l'estimation de l'IQR",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.015,  # Erreur relative < 1.5%
            "good": 0.03,       # Erreur relative < 3%
            "acceptable": relative_error_threshold,  # Erreur relative < seuil défini (par défaut 5%)
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        },
        "confidence_interval_coverage": {
            "excellent": 0.99,  # Couverture de 99%
            "good": confidence_level,  # Couverture au niveau de confiance défini (par défaut 95%)
            "acceptable": 0.90,  # Couverture de 90%
            "poor": 0.80,       # Couverture de 80%
            "unacceptable": 0.0  # Couverture < 80%
        },
        "minimum_sample_sizes": {
            "excellent": 100,   # Au moins 100 échantillons
            "good": 50,         # Au moins 50 échantillons
            "acceptable": 30,   # Au moins 30 échantillons
            "poor": 10,         # Au moins 10 échantillons
            "unacceptable": 0   # Moins de 10 échantillons
        }
    }
    
    return criteria

def define_iqr_error_thresholds_symmetric(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'IQR
    dans le cas des distributions symétriques.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'IQR
    """
    # Pour les distributions symétriques, l'IQR peut être estimé avec une bonne précision
    # car les quartiles sont bien définis et symétriques
    thresholds = {
        "excellent": 0.015,  # Erreur relative < 1.5%
        "good": 0.03,       # Erreur relative < 3%
        "acceptable": 0.05,  # Erreur relative < 5%
        "poor": 0.10,       # Erreur relative < 10%
        "unacceptable": float('inf')  # Erreur relative >= 10%
    }
    
    return thresholds

def define_iqr_error_thresholds_heavy_tailed(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'IQR
    dans le cas des distributions à queue lourde.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'IQR
    """
    # Pour les distributions à queue lourde, l'IQR est plus difficile à estimer
    # car les queues de la distribution peuvent avoir une influence importante sur les quartiles
    thresholds = {
        "excellent": 0.025,  # Erreur relative < 2.5%
        "good": 0.05,       # Erreur relative < 5%
        "acceptable": 0.08,  # Erreur relative < 8%
        "poor": 0.15,       # Erreur relative < 15%
        "unacceptable": float('inf')  # Erreur relative >= 15%
    }
    
    return thresholds

def define_iqr_error_thresholds_multimodal(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'IQR
    dans le cas des distributions multimodales.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'IQR
    """
    # Pour les distributions multimodales, l'IQR est très difficile à estimer
    # car il dépend fortement de la séparation entre les modes
    thresholds = {
        "excellent": 0.03,  # Erreur relative < 3%
        "good": 0.06,       # Erreur relative < 6%
        "acceptable": 0.10,  # Erreur relative < 10%
        "poor": 0.20,       # Erreur relative < 20%
        "unacceptable": float('inf')  # Erreur relative >= 20%
    }
    
    return thresholds

def evaluate_iqr_precision(true_iqr: float,
                         estimated_iqr: float,
                         sample_size: int,
                         criteria: Dict[str, Any]) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'IQR selon les critères définis.
    
    Args:
        true_iqr: Valeur réelle de l'IQR
        estimated_iqr: Valeur estimée de l'IQR
        sample_size: Taille de l'échantillon
        criteria: Critères de précision pour l'estimation de l'IQR
        
    Returns:
        Dict[str, Any]: Évaluation de la précision de l'estimation
    """
    # Calculer l'erreur absolue
    absolute_error = abs(estimated_iqr - true_iqr)
    
    # Calculer l'erreur relative (en évitant la division par zéro)
    if true_iqr != 0:
        relative_error = absolute_error / abs(true_iqr)
    else:
        # Si le vrai IQR est zéro, l'erreur relative est infinie
        relative_error = float('inf') if absolute_error > 0 else 0.0
    
    # Calculer l'erreur standard de l'IQR (approximation)
    # Formule basée sur la distribution asymptotique des quantiles
    # Pour l'IQR, on utilise une approximation basée sur la densité aux quartiles
    # Cette formule est une approximation et peut varier selon la distribution
    standard_error = 1.5 * true_iqr / np.sqrt(sample_size)
    
    # Calculer l'intervalle de confiance
    z_value = scipy.stats.norm.ppf((1 + criteria["confidence_level"]) / 2)
    confidence_interval = (estimated_iqr - z_value * standard_error, 
                          estimated_iqr + z_value * standard_error)
    
    # Vérifier si l'intervalle de confiance contient le vrai IQR
    contains_true_iqr = confidence_interval[0] <= true_iqr <= confidence_interval[1]
    
    # Déterminer la qualité de l'estimation en fonction de l'erreur relative
    quality_by_error = "unacceptable"
    for quality, threshold in sorted(criteria["absolute_error_thresholds"].items(), 
                                   key=lambda x: x[1]):
        if relative_error <= threshold:
            quality_by_error = quality
            break
    
    # Déterminer la qualité de l'estimation en fonction de la taille de l'échantillon
    quality_by_sample_size = "unacceptable"
    for quality, min_size in sorted(criteria["minimum_sample_sizes"].items(), 
                                  key=lambda x: x[1], reverse=True):
        if sample_size >= min_size:
            quality_by_sample_size = quality
            break
    
    # Déterminer la qualité globale (la plus basse des deux)
    quality_ranks = ["excellent", "good", "acceptable", "poor", "unacceptable"]
    quality_by_error_rank = quality_ranks.index(quality_by_error)
    quality_by_sample_size_rank = quality_ranks.index(quality_by_sample_size)
    overall_quality_rank = max(quality_by_error_rank, quality_by_sample_size_rank)
    overall_quality = quality_ranks[overall_quality_rank]
    
    # Résultats
    return {
        "true_iqr": true_iqr,
        "estimated_iqr": estimated_iqr,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "standard_error": standard_error,
        "confidence_interval": confidence_interval,
        "contains_true_iqr": contains_true_iqr,
        "sample_size": sample_size,
        "quality_by_error": quality_by_error,
        "quality_by_sample_size": quality_by_sample_size,
        "overall_quality": overall_quality
    }

def evaluate_histogram_iqr_precision(data: np.ndarray,
                                    bin_counts: List[int],
                                    criteria: Optional[Dict[str, Any]] = None,
                                    distribution_type: str = "symmetric") -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'IQR à partir d'histogrammes
    avec différents nombres de bins.
    
    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
        distribution_type: Type de distribution ('symmetric', 'heavy_tailed', 'multimodal', 'general')
        
    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de bins
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_iqr_precision_criteria()
    
    # Ajuster les seuils d'erreur en fonction du type de distribution
    if distribution_type == "symmetric":
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_symmetric()
    elif distribution_type == "heavy_tailed":
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_heavy_tailed()
    elif distribution_type == "multimodal":
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_multimodal()
    
    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_iqr = raw_params["iqr"]
    sample_size = len(data)
    
    # Initialiser les résultats
    results = {
        "bin_counts": bin_counts,
        "true_iqr": true_iqr,
        "sample_size": sample_size,
        "distribution_type": distribution_type,
        "estimated_iqrs": [],
        "absolute_errors": [],
        "relative_errors": [],
        "overall_qualities": []
    }
    
    # Évaluer la précision pour chaque nombre de bins
    for num_bins in bin_counts:
        # Calculer l'histogramme
        hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)
        
        # Estimer les paramètres à partir de l'histogramme
        hist_params = estimate_from_histogram(hist_counts, bin_edges)
        estimated_iqr = hist_params["iqr"]
        
        # Évaluer la précision
        evaluation = evaluate_iqr_precision(
            true_iqr=true_iqr,
            estimated_iqr=estimated_iqr,
            sample_size=sample_size,
            criteria=criteria
        )
        
        # Stocker les résultats
        results["estimated_iqrs"].append(estimated_iqr)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])
    
    return results
