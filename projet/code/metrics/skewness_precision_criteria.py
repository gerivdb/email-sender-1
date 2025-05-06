#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les critères de précision pour l'estimation de l'asymétrie (skewness).
"""

from typing import Dict, Any, Optional

def define_skewness_precision_criteria(relative_error_threshold: float = 0.10,
                                     confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de l'asymétrie.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 10%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)
        
    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de l'asymétrie
    """
    # Définir les critères de précision
    criteria = {
        "name": "skewness_precision",
        "description": "Critères de précision pour l'estimation de l'asymétrie",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": relative_error_threshold,  # Erreur relative < seuil défini (par défaut 10%)
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        },
        "confidence_interval_coverage": {
            "excellent": 0.99,  # Couverture de 99%
            "good": confidence_level,  # Couverture au niveau de confiance défini (par défaut 95%)
            "acceptable": 0.90,  # Couverture de 90%
            "poor": 0.80,       # Couverture de 80%
            "unacceptable": 0.0  # Couverture < 80%
        },
        "minimum_sample_sizes": {
            "excellent": 200,   # Au moins 200 échantillons
            "good": 100,        # Au moins 100 échantillons
            "acceptable": 50,   # Au moins 50 échantillons
            "poor": 30,         # Au moins 30 échantillons
            "unacceptable": 0   # Moins de 30 échantillons
        }
    }
    
    return criteria

def define_skewness_error_thresholds_by_magnitude(skewness_magnitude: str = "medium") -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
    en fonction de l'amplitude de l'asymétrie.
    
    Args:
        skewness_magnitude: Amplitude de l'asymétrie ('low', 'medium', 'high')
            - 'low': |skewness| < 0.5
            - 'medium': 0.5 <= |skewness| < 1.0
            - 'high': |skewness| >= 1.0
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'asymétrie
    """
    # Définir les seuils par défaut (pour une asymétrie moyenne)
    default_thresholds = {
        "excellent": 0.10,  # Erreur relative < 10%
        "good": 0.15,       # Erreur relative < 15%
        "acceptable": 0.20,  # Erreur relative < 20%
        "poor": 0.30,       # Erreur relative < 30%
        "unacceptable": float('inf')  # Erreur relative >= 30%
    }
    
    # Ajuster les seuils en fonction de l'amplitude de l'asymétrie
    if skewness_magnitude == "low":
        # Pour une faible asymétrie, les erreurs relatives sont plus importantes
        # car une petite erreur absolue peut représenter un grand pourcentage
        thresholds = {
            "excellent": 0.20,  # Erreur relative < 20%
            "good": 0.30,       # Erreur relative < 30%
            "acceptable": 0.40,  # Erreur relative < 40%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    elif skewness_magnitude == "high":
        # Pour une forte asymétrie, les erreurs relatives sont moins importantes
        # car une petite erreur absolue représente un faible pourcentage
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    else:
        # Utiliser les seuils par défaut pour une asymétrie moyenne
        thresholds = default_thresholds
    
    return thresholds

def define_skewness_error_thresholds_by_distribution_type(distribution_type: str = "normal") -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
    en fonction du type de distribution.
    
    Args:
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed')
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'asymétrie
    """
    # Définir les seuils par défaut (pour une distribution normale)
    default_thresholds = {
        "excellent": 0.10,  # Erreur relative < 10%
        "good": 0.15,       # Erreur relative < 15%
        "acceptable": 0.20,  # Erreur relative < 20%
        "poor": 0.30,       # Erreur relative < 30%
        "unacceptable": float('inf')  # Erreur relative >= 30%
    }
    
    # Ajuster les seuils en fonction du type de distribution
    if distribution_type == "skewed":
        # Pour une distribution asymétrique, l'asymétrie est plus facile à estimer
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.12,       # Erreur relative < 12%
            "acceptable": 0.18,  # Erreur relative < 18%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif distribution_type == "multimodal":
        # Pour une distribution multimodale, l'asymétrie est plus difficile à estimer
        thresholds = {
            "excellent": 0.15,  # Erreur relative < 15%
            "good": 0.20,       # Erreur relative < 20%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif distribution_type == "heavy_tailed":
        # Pour une distribution à queue lourde, l'asymétrie est très difficile à estimer
        thresholds = {
            "excellent": 0.20,  # Erreur relative < 20%
            "good": 0.30,       # Erreur relative < 30%
            "acceptable": 0.40,  # Erreur relative < 40%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    else:
        # Utiliser les seuils par défaut pour une distribution normale
        thresholds = default_thresholds
    
    return thresholds

def define_skewness_error_thresholds_by_sample_size(sample_size: int = 100) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'asymétrie
    en fonction de la taille de l'échantillon.
    
    Args:
        sample_size: Taille de l'échantillon
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'asymétrie
    """
    # Définir les seuils en fonction de la taille de l'échantillon
    if sample_size >= 1000:
        # Pour un très grand échantillon, l'asymétrie est très bien estimée
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    elif sample_size >= 500:
        # Pour un grand échantillon, l'asymétrie est bien estimée
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.12,       # Erreur relative < 12%
            "acceptable": 0.18,  # Erreur relative < 18%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif sample_size >= 100:
        # Pour un échantillon moyen, l'asymétrie est moyennement bien estimée
        thresholds = {
            "excellent": 0.10,  # Erreur relative < 10%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": 0.20,  # Erreur relative < 20%
            "poor": 0.30,       # Erreur relative < 30%
            "unacceptable": float('inf')  # Erreur relative >= 30%
        }
    elif sample_size >= 50:
        # Pour un petit échantillon, l'asymétrie est mal estimée
        thresholds = {
            "excellent": 0.15,  # Erreur relative < 15%
            "good": 0.20,       # Erreur relative < 20%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    else:
        # Pour un très petit échantillon, l'asymétrie est très mal estimée
        thresholds = {
            "excellent": 0.20,  # Erreur relative < 20%
            "good": 0.30,       # Erreur relative < 30%
            "acceptable": 0.40,  # Erreur relative < 40%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    
    return thresholds
