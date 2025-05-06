#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les seuils d'erreur acceptables pour les mesures de forme.
"""

from typing import Dict, Any, Optional, Literal

# Types de distribution
DistributionType = Literal["normal", "skewed", "multimodal", "heavy_tailed", "general"]

def define_shape_error_thresholds(measure: str = "skewness",
                                distribution_type: str = "normal",
                                sample_size: int = 100) -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de forme
    en fonction du type de distribution et de la taille de l'échantillon.
    
    Args:
        measure: Mesure de forme ('skewness', 'kurtosis')
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed', 'general')
        sample_size: Taille de l'échantillon
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de forme
    """
    # Définir les seuils par défaut
    default_thresholds = {
        "excellent": 0.10,  # Erreur relative < 10%
        "good": 0.15,       # Erreur relative < 15%
        "acceptable": 0.20,  # Erreur relative < 20%
        "poor": 0.30,       # Erreur relative < 30%
        "unacceptable": float('inf')  # Erreur relative >= 30%
    }
    
    # Ajuster les seuils en fonction de la mesure de forme
    if measure == "skewness":
        # Pour l'asymétrie, les seuils dépendent du type de distribution et de la taille de l'échantillon
        if distribution_type == "normal":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.08,  # Erreur relative < 8%
                    "good": 0.12,       # Erreur relative < 12%
                    "acceptable": 0.18,  # Erreur relative < 18%
                    "poor": 0.25,       # Erreur relative < 25%
                    "unacceptable": float('inf')  # Erreur relative >= 25%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.10,  # Erreur relative < 10%
                    "good": 0.15,       # Erreur relative < 15%
                    "acceptable": 0.20,  # Erreur relative < 20%
                    "poor": 0.30,       # Erreur relative < 30%
                    "unacceptable": float('inf')  # Erreur relative >= 30%
                }
            else:
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.20,       # Erreur relative < 20%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
        elif distribution_type == "skewed":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.06,  # Erreur relative < 6%
                    "good": 0.10,       # Erreur relative < 10%
                    "acceptable": 0.15,  # Erreur relative < 15%
                    "poor": 0.20,       # Erreur relative < 20%
                    "unacceptable": float('inf')  # Erreur relative >= 20%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.08,  # Erreur relative < 8%
                    "good": 0.12,       # Erreur relative < 12%
                    "acceptable": 0.18,  # Erreur relative < 18%
                    "poor": 0.25,       # Erreur relative < 25%
                    "unacceptable": float('inf')  # Erreur relative >= 25%
                }
            else:
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
        elif distribution_type == "multimodal":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.20,       # Erreur relative < 20%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            else:
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
        elif distribution_type == "heavy_tailed":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.20,       # Erreur relative < 20%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            else:
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
        else:
            # Utiliser les seuils par défaut pour les autres types de distribution
            thresholds = default_thresholds
    
    elif measure == "kurtosis":
        # Pour l'aplatissement, les seuils dépendent du type de distribution et de la taille de l'échantillon
        if distribution_type == "normal":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.10,  # Erreur relative < 10%
                    "good": 0.15,       # Erreur relative < 15%
                    "acceptable": 0.20,  # Erreur relative < 20%
                    "poor": 0.30,       # Erreur relative < 30%
                    "unacceptable": float('inf')  # Erreur relative >= 30%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
            else:
                thresholds = {
                    "excellent": 0.18,  # Erreur relative < 18%
                    "good": 0.25,       # Erreur relative < 25%
                    "acceptable": 0.35,  # Erreur relative < 35%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
        elif distribution_type == "skewed":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.22,       # Erreur relative < 22%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            else:
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
        elif distribution_type == "multimodal":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.22,       # Erreur relative < 22%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            else:
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
        elif distribution_type == "heavy_tailed":
            if sample_size >= 500:
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif sample_size >= 100:
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            else:
                thresholds = {
                    "excellent": 0.30,  # Erreur relative < 30%
                    "good": 0.40,       # Erreur relative < 40%
                    "acceptable": 0.60,  # Erreur relative < 60%
                    "poor": 0.80,       # Erreur relative < 80%
                    "unacceptable": float('inf')  # Erreur relative >= 80%
                }
        else:
            # Utiliser les seuils par défaut pour les autres types de distribution
            thresholds = default_thresholds
    else:
        # Utiliser les seuils par défaut pour les autres mesures de forme
        thresholds = default_thresholds
    
    return thresholds

def define_shape_error_thresholds_for_histogram(measure: str = "skewness",
                                              distribution_type: str = "normal",
                                              bin_count: int = 50) -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de forme
    estimées à partir d'histogrammes, en fonction du type de distribution et du nombre de bins.
    
    Args:
        measure: Mesure de forme ('skewness', 'kurtosis')
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'heavy_tailed', 'general')
        bin_count: Nombre de bins de l'histogramme
        
    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de forme
    """
    # Définir les seuils par défaut
    default_thresholds = {
        "excellent": 0.15,  # Erreur relative < 15%
        "good": 0.20,       # Erreur relative < 20%
        "acceptable": 0.30,  # Erreur relative < 30%
        "poor": 0.40,       # Erreur relative < 40%
        "unacceptable": float('inf')  # Erreur relative >= 40%
    }
    
    # Ajuster les seuils en fonction de la mesure de forme
    if measure == "skewness":
        # Pour l'asymétrie, les seuils dépendent du type de distribution et du nombre de bins
        if bin_count >= 100:  # Haute résolution
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.10,  # Erreur relative < 10%
                    "good": 0.15,       # Erreur relative < 15%
                    "acceptable": 0.20,  # Erreur relative < 20%
                    "poor": 0.30,       # Erreur relative < 30%
                    "unacceptable": float('inf')  # Erreur relative >= 30%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.08,  # Erreur relative < 8%
                    "good": 0.12,       # Erreur relative < 12%
                    "acceptable": 0.18,  # Erreur relative < 18%
                    "poor": 0.25,       # Erreur relative < 25%
                    "unacceptable": float('inf')  # Erreur relative >= 25%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.20,       # Erreur relative < 20%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
        elif bin_count >= 50:  # Résolution moyenne
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.20,       # Erreur relative < 20%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
        else:  # Faible résolution
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.18,  # Erreur relative < 18%
                    "good": 0.25,       # Erreur relative < 25%
                    "acceptable": 0.35,  # Erreur relative < 35%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.30,  # Erreur relative < 30%
                    "good": 0.40,       # Erreur relative < 40%
                    "acceptable": 0.60,  # Erreur relative < 60%
                    "poor": 0.80,       # Erreur relative < 80%
                    "unacceptable": float('inf')  # Erreur relative >= 80%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
    
    elif measure == "kurtosis":
        # Pour l'aplatissement, les seuils dépendent du type de distribution et du nombre de bins
        if bin_count >= 100:  # Haute résolution
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.12,  # Erreur relative < 12%
                    "good": 0.18,       # Erreur relative < 18%
                    "acceptable": 0.25,  # Erreur relative < 25%
                    "poor": 0.35,       # Erreur relative < 35%
                    "unacceptable": float('inf')  # Erreur relative >= 35%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.15,  # Erreur relative < 15%
                    "good": 0.22,       # Erreur relative < 22%
                    "acceptable": 0.30,  # Erreur relative < 30%
                    "poor": 0.40,       # Erreur relative < 40%
                    "unacceptable": float('inf')  # Erreur relative >= 40%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
        elif bin_count >= 50:  # Résolution moyenne
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.18,  # Erreur relative < 18%
                    "good": 0.25,       # Erreur relative < 25%
                    "acceptable": 0.35,  # Erreur relative < 35%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.20,  # Erreur relative < 20%
                    "good": 0.30,       # Erreur relative < 30%
                    "acceptable": 0.40,  # Erreur relative < 40%
                    "poor": 0.50,       # Erreur relative < 50%
                    "unacceptable": float('inf')  # Erreur relative >= 50%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.30,  # Erreur relative < 30%
                    "good": 0.40,       # Erreur relative < 40%
                    "acceptable": 0.60,  # Erreur relative < 60%
                    "poor": 0.80,       # Erreur relative < 80%
                    "unacceptable": float('inf')  # Erreur relative >= 80%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
        else:  # Faible résolution
            if distribution_type == "normal":
                thresholds = {
                    "excellent": 0.25,  # Erreur relative < 25%
                    "good": 0.35,       # Erreur relative < 35%
                    "acceptable": 0.50,  # Erreur relative < 50%
                    "poor": 0.70,       # Erreur relative < 70%
                    "unacceptable": float('inf')  # Erreur relative >= 70%
                }
            elif distribution_type == "skewed":
                thresholds = {
                    "excellent": 0.30,  # Erreur relative < 30%
                    "good": 0.40,       # Erreur relative < 40%
                    "acceptable": 0.60,  # Erreur relative < 60%
                    "poor": 0.80,       # Erreur relative < 80%
                    "unacceptable": float('inf')  # Erreur relative >= 80%
                }
            elif distribution_type == "multimodal":
                thresholds = {
                    "excellent": 0.35,  # Erreur relative < 35%
                    "good": 0.50,       # Erreur relative < 50%
                    "acceptable": 0.70,  # Erreur relative < 70%
                    "poor": 0.90,       # Erreur relative < 90%
                    "unacceptable": float('inf')  # Erreur relative >= 90%
                }
            elif distribution_type == "heavy_tailed":
                thresholds = {
                    "excellent": 0.40,  # Erreur relative < 40%
                    "good": 0.60,       # Erreur relative < 60%
                    "acceptable": 0.80,  # Erreur relative < 80%
                    "poor": 1.00,       # Erreur relative < 100%
                    "unacceptable": float('inf')  # Erreur relative >= 100%
                }
            else:
                # Utiliser les seuils par défaut pour les autres types de distribution
                thresholds = default_thresholds
    else:
        # Utiliser les seuils par défaut pour les autres mesures de forme
        thresholds = default_thresholds
    
    return thresholds
