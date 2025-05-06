#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les critères de précision pour l'estimation de l'aplatissement (kurtosis).
"""

from typing import Dict, Any, Optional

def define_kurtosis_precision_criteria(relative_error_threshold: float = 0.15,
                                     confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de l'aplatissement.
    
    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 15%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)
        
    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de l'aplatissement
    """
    # Définir les critères de précision
    criteria = {
        "name": "kurtosis_precision",
        "description": "Critères de précision pour l'estimation de l'aplatissement",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": relative_error_threshold,  # Erreur relative < seuil défini (par défaut 15%)
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        },
        "confidence_interval_coverage": {
            "excellent": 0.99,  # Couverture de 99%
            "good": confidence_level,  # Couverture au niveau de confiance défini (par défaut 95%)
            "acceptable": 0.90,  # Couverture de 90%
            "poor": 0.80,       # Couverture de 80%
            "unacceptable": 0.0  # Couverture < 80%
        },
        "minimum_sample_sizes": {
            "excellent": 300,   # Au moins 300 échantillons
            "good": 150,        # Au moins 150 échantillons
            "acceptable": 80,   # Au moins 80 échantillons
            "poor": 50,         # Au moins 50 échantillons
            "unacceptable": 0   # Moins de 50 échantillons
        }
    }
    
    return criteria

def define_kurtosis_error_thresholds_by_magnitude(kurtosis_magnitude: str = "medium") -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'aplatissement
    en fonction de l'amplitude de l'aplatissement.
    
    Args:
        kurtosis_magnitude: Amplitude de l'aplatissement ('low', 'medium', 'high')
            - 'low': |kurtosis - 3| < 1.0 (proche de la normale)
            - 'medium': 1.0 <= |kurtosis - 3| < 3.0
            - 'high': |kurtosis - 3| >= 3.0
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'aplatissement
    """
    # Définir les seuils par défaut (pour un aplatissement moyen)
    default_thresholds = {
        "excellent": 0.12,  # Erreur relative < 12%
        "good": 0.18,       # Erreur relative < 18%
        "acceptable": 0.25,  # Erreur relative < 25%
        "poor": 0.35,       # Erreur relative < 35%
        "unacceptable": float('inf')  # Erreur relative >= 35%
    }
    
    # Ajuster les seuils en fonction de l'amplitude de l'aplatissement
    if kurtosis_magnitude == "low":
        # Pour un faible aplatissement, les erreurs relatives sont plus importantes
        # car une petite erreur absolue peut représenter un grand pourcentage
        thresholds = {
            "excellent": 0.25,  # Erreur relative < 25%
            "good": 0.35,       # Erreur relative < 35%
            "acceptable": 0.45,  # Erreur relative < 45%
            "poor": 0.60,       # Erreur relative < 60%
            "unacceptable": float('inf')  # Erreur relative >= 60%
        }
    elif kurtosis_magnitude == "high":
        # Pour un fort aplatissement, les erreurs relatives sont moins importantes
        # car une petite erreur absolue représente un faible pourcentage
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.12,       # Erreur relative < 12%
            "acceptable": 0.18,  # Erreur relative < 18%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    else:
        # Utiliser les seuils par défaut pour un aplatissement moyen
        thresholds = default_thresholds
    
    return thresholds

def define_kurtosis_error_thresholds_by_distribution_type(distribution_type: str = "normal") -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'aplatissement
    en fonction du type de distribution.
    
    Args:
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed')
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'aplatissement
    """
    # Définir les seuils par défaut (pour une distribution normale)
    default_thresholds = {
        "excellent": 0.12,  # Erreur relative < 12%
        "good": 0.18,       # Erreur relative < 18%
        "acceptable": 0.25,  # Erreur relative < 25%
        "poor": 0.35,       # Erreur relative < 35%
        "unacceptable": float('inf')  # Erreur relative >= 35%
    }
    
    # Ajuster les seuils en fonction du type de distribution
    if distribution_type == "skewed":
        # Pour une distribution asymétrique, l'aplatissement est plus difficile à estimer
        thresholds = {
            "excellent": 0.15,  # Erreur relative < 15%
            "good": 0.22,       # Erreur relative < 22%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif distribution_type == "multimodal":
        # Pour une distribution multimodale, l'aplatissement est très difficile à estimer
        thresholds = {
            "excellent": 0.20,  # Erreur relative < 20%
            "good": 0.30,       # Erreur relative < 30%
            "acceptable": 0.40,  # Erreur relative < 40%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    elif distribution_type == "heavy_tailed":
        # Pour une distribution à queue lourde, l'aplatissement est extrêmement difficile à estimer
        thresholds = {
            "excellent": 0.25,  # Erreur relative < 25%
            "good": 0.35,       # Erreur relative < 35%
            "acceptable": 0.50,  # Erreur relative < 50%
            "poor": 0.70,       # Erreur relative < 70%
            "unacceptable": float('inf')  # Erreur relative >= 70%
        }
    else:
        # Utiliser les seuils par défaut pour une distribution normale
        thresholds = default_thresholds
    
    return thresholds

def define_kurtosis_error_thresholds_by_sample_size(sample_size: int = 100) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'aplatissement
    en fonction de la taille de l'échantillon.
    
    Args:
        sample_size: Taille de l'échantillon
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'aplatissement
    """
    # Définir les seuils en fonction de la taille de l'échantillon
    if sample_size >= 1000:
        # Pour un très grand échantillon, l'aplatissement est bien estimé
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.12,       # Erreur relative < 12%
            "acceptable": 0.18,  # Erreur relative < 18%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif sample_size >= 500:
        # Pour un grand échantillon, l'aplatissement est moyennement bien estimé
        thresholds = {
            "excellent": 0.10,  # Erreur relative < 10%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": 0.22,  # Erreur relative < 22%
            "poor": 0.30,       # Erreur relative < 30%
            "unacceptable": float('inf')  # Erreur relative >= 30%
        }
    elif sample_size >= 200:
        # Pour un échantillon moyen, l'aplatissement est mal estimé
        thresholds = {
            "excellent": 0.15,  # Erreur relative < 15%
            "good": 0.22,       # Erreur relative < 22%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif sample_size >= 100:
        # Pour un petit échantillon, l'aplatissement est très mal estimé
        thresholds = {
            "excellent": 0.20,  # Erreur relative < 20%
            "good": 0.30,       # Erreur relative < 30%
            "acceptable": 0.40,  # Erreur relative < 40%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    else:
        # Pour un très petit échantillon, l'aplatissement est extrêmement mal estimé
        thresholds = {
            "excellent": 0.25,  # Erreur relative < 25%
            "good": 0.35,       # Erreur relative < 35%
            "acceptable": 0.50,  # Erreur relative < 50%
            "poor": 0.70,       # Erreur relative < 70%
            "unacceptable": float('inf')  # Erreur relative >= 70%
        }
    
    return thresholds
