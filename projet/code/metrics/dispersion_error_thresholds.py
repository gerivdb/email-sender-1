#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les seuils d'erreur acceptables pour les mesures de dispersion.
"""

from typing import Dict, Any, Optional, Literal

# Types de distribution
DistributionType = Literal["normal", "skewed", "multimodal", "heavy_tailed", "general"]

def define_dispersion_error_thresholds_normal(measure: str = "range") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des distributions normales.

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut
    default_thresholds = {
        "excellent": 0.02,  # Erreur relative < 2%
        "good": 0.05,       # Erreur relative < 5%
        "acceptable": 0.10,  # Erreur relative < 10%
        "poor": 0.20,       # Erreur relative < 20%
        "unacceptable": float('inf')  # Erreur relative >= 20%
    }

    # Ajuster les seuils en fonction de la mesure de dispersion
    if measure == "range":
        # L'étendue est très sensible aux valeurs extrêmes, même dans les distributions normales
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif measure == "variance":
        # La variance est sensible aux valeurs extrêmes, mais moins que l'étendue
        thresholds = {
            "excellent": 0.03,  # Erreur relative < 3%
            "good": 0.07,       # Erreur relative < 7%
            "acceptable": 0.12,  # Erreur relative < 12%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    elif measure == "std":
        # L'écart-type est plus robuste que la variance (racine carrée de la variance)
        thresholds = {
            "excellent": 0.015,  # Erreur relative < 1.5%
            "good": 0.035,       # Erreur relative < 3.5%
            "acceptable": 0.06,  # Erreur relative < 6%
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        }
    elif measure == "mad":
        # L'écart absolu médian est très robuste aux valeurs extrêmes
        thresholds = {
            "excellent": 0.02,  # Erreur relative < 2%
            "good": 0.04,       # Erreur relative < 4%
            "acceptable": 0.07,  # Erreur relative < 7%
            "poor": 0.12,       # Erreur relative < 12%
            "unacceptable": float('inf')  # Erreur relative >= 12%
        }
    elif measure == "iqr":
        # L'écart interquartile est également très robuste aux valeurs extrêmes
        thresholds = {
            "excellent": 0.02,  # Erreur relative < 2%
            "good": 0.04,       # Erreur relative < 4%
            "acceptable": 0.07,  # Erreur relative < 7%
            "poor": 0.12,       # Erreur relative < 12%
            "unacceptable": float('inf')  # Erreur relative >= 12%
        }
    else:
        # Utiliser les seuils par défaut pour les autres mesures
        thresholds = default_thresholds

    return thresholds

def define_dispersion_error_thresholds_skewed(measure: str = "range") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des distributions asymétriques.

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut pour les distributions asymétriques
    # Les seuils sont plus élevés que pour les distributions normales
    # car les mesures de dispersion sont plus difficiles à estimer
    default_thresholds = {
        "excellent": 0.04,  # Erreur relative < 4%
        "good": 0.08,       # Erreur relative < 8%
        "acceptable": 0.15,  # Erreur relative < 15%
        "poor": 0.25,       # Erreur relative < 25%
        "unacceptable": float('inf')  # Erreur relative >= 25%
    }

    # Ajuster les seuils en fonction de la mesure de dispersion
    if measure == "range":
        # L'étendue est très sensible aux valeurs extrêmes, encore plus dans les distributions asymétriques
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": 0.25,  # Erreur relative < 25%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif measure == "variance":
        # La variance est très sensible à l'asymétrie
        thresholds = {
            "excellent": 0.06,  # Erreur relative < 6%
            "good": 0.12,       # Erreur relative < 12%
            "acceptable": 0.20,  # Erreur relative < 20%
            "poor": 0.30,       # Erreur relative < 30%
            "unacceptable": float('inf')  # Erreur relative >= 30%
        }
    elif measure == "std":
        # L'écart-type est sensible à l'asymétrie, mais moins que la variance
        thresholds = {
            "excellent": 0.03,  # Erreur relative < 3%
            "good": 0.06,       # Erreur relative < 6%
            "acceptable": 0.10,  # Erreur relative < 10%
            "poor": 0.15,       # Erreur relative < 15%
            "unacceptable": float('inf')  # Erreur relative >= 15%
        }
    elif measure == "mad":
        # L'écart absolu médian est robuste à l'asymétrie
        thresholds = {
            "excellent": 0.025,  # Erreur relative < 2.5%
            "good": 0.05,       # Erreur relative < 5%
            "acceptable": 0.08,  # Erreur relative < 8%
            "poor": 0.15,       # Erreur relative < 15%
            "unacceptable": float('inf')  # Erreur relative >= 15%
        }
    elif measure == "iqr":
        # L'écart interquartile est également robuste à l'asymétrie
        thresholds = {
            "excellent": 0.025,  # Erreur relative < 2.5%
            "good": 0.05,       # Erreur relative < 5%
            "acceptable": 0.08,  # Erreur relative < 8%
            "poor": 0.15,       # Erreur relative < 15%
            "unacceptable": float('inf')  # Erreur relative >= 15%
        }
    else:
        # Utiliser les seuils par défaut pour les autres mesures
        thresholds = default_thresholds

    return thresholds

def define_dispersion_error_thresholds_multimodal(measure: str = "range") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des distributions multimodales.

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut pour les distributions multimodales
    # Les seuils sont plus élevés que pour les distributions normales et asymétriques
    # car les mesures de dispersion sont encore plus difficiles à estimer
    default_thresholds = {
        "excellent": 0.05,  # Erreur relative < 5%
        "good": 0.10,       # Erreur relative < 10%
        "acceptable": 0.20,  # Erreur relative < 20%
        "poor": 0.30,       # Erreur relative < 30%
        "unacceptable": float('inf')  # Erreur relative >= 30%
    }

    # Ajuster les seuils en fonction de la mesure de dispersion
    if measure == "range":
        # L'étendue est très sensible aux valeurs extrêmes et à la multimodalité
        thresholds = {
            "excellent": 0.10,  # Erreur relative < 10%
            "good": 0.20,       # Erreur relative < 20%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    elif measure == "variance":
        # La variance est très sensible à la multimodalité
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": 0.25,  # Erreur relative < 25%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif measure == "std":
        # L'écart-type est sensible à la multimodalité, mais moins que la variance
        thresholds = {
            "excellent": 0.04,  # Erreur relative < 4%
            "good": 0.08,       # Erreur relative < 8%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif measure == "mad":
        # L'écart absolu médian est relativement robuste à la multimodalité
        thresholds = {
            "excellent": 0.03,  # Erreur relative < 3%
            "good": 0.06,       # Erreur relative < 6%
            "acceptable": 0.10,  # Erreur relative < 10%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    elif measure == "iqr":
        # L'écart interquartile est également relativement robuste à la multimodalité
        thresholds = {
            "excellent": 0.03,  # Erreur relative < 3%
            "good": 0.06,       # Erreur relative < 6%
            "acceptable": 0.10,  # Erreur relative < 10%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    else:
        # Utiliser les seuils par défaut pour les autres mesures
        thresholds = default_thresholds

    return thresholds

def define_dispersion_error_thresholds_low_resolution_histogram(measure: str = "range") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des histogrammes à faible résolution (nombre de bins < 20).

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut pour les histogrammes à faible résolution
    # Les seuils sont plus élevés car la faible résolution entraîne une perte d'information
    default_thresholds = {
        "excellent": 0.05,  # Erreur relative < 5%
        "good": 0.10,       # Erreur relative < 10%
        "acceptable": 0.15,  # Erreur relative < 15%
        "poor": 0.25,       # Erreur relative < 25%
        "unacceptable": float('inf')  # Erreur relative >= 25%
    }

    # Ajuster les seuils en fonction de la mesure de dispersion
    if measure == "range":
        # L'étendue est très sensible à la résolution de l'histogramme
        thresholds = {
            "excellent": 0.10,  # Erreur relative < 10%
            "good": 0.20,       # Erreur relative < 20%
            "acceptable": 0.30,  # Erreur relative < 30%
            "poor": 0.50,       # Erreur relative < 50%
            "unacceptable": float('inf')  # Erreur relative >= 50%
        }
    elif measure == "variance":
        # La variance est sensible à la résolution de l'histogramme
        thresholds = {
            "excellent": 0.08,  # Erreur relative < 8%
            "good": 0.15,       # Erreur relative < 15%
            "acceptable": 0.25,  # Erreur relative < 25%
            "poor": 0.40,       # Erreur relative < 40%
            "unacceptable": float('inf')  # Erreur relative >= 40%
        }
    elif measure == "std":
        # L'écart-type est sensible à la résolution de l'histogramme, mais moins que la variance
        thresholds = {
            "excellent": 0.04,  # Erreur relative < 4%
            "good": 0.08,       # Erreur relative < 8%
            "acceptable": 0.12,  # Erreur relative < 12%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    elif measure == "mad":
        # L'écart absolu médian est sensible à la résolution de l'histogramme
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif measure == "iqr":
        # L'écart interquartile est sensible à la résolution de l'histogramme
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    else:
        # Utiliser les seuils par défaut pour les autres mesures
        thresholds = default_thresholds

    return thresholds

def define_dispersion_error_thresholds_high_resolution_histogram(measure: str = "range") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des histogrammes à haute résolution (nombre de bins >= 50).

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut pour les histogrammes à haute résolution
    # Les seuils sont plus bas car la haute résolution permet une meilleure estimation
    default_thresholds = {
        "excellent": 0.02,  # Erreur relative < 2%
        "good": 0.05,       # Erreur relative < 5%
        "acceptable": 0.10,  # Erreur relative < 10%
        "poor": 0.15,       # Erreur relative < 15%
        "unacceptable": float('inf')  # Erreur relative >= 15%
    }

    # Ajuster les seuils en fonction de la mesure de dispersion
    if measure == "range":
        # L'étendue reste sensible aux valeurs extrêmes, même avec une haute résolution
        thresholds = {
            "excellent": 0.05,  # Erreur relative < 5%
            "good": 0.10,       # Erreur relative < 10%
            "acceptable": 0.15,  # Erreur relative < 15%
            "poor": 0.25,       # Erreur relative < 25%
            "unacceptable": float('inf')  # Erreur relative >= 25%
        }
    elif measure == "variance":
        # La variance est mieux estimée avec une haute résolution
        thresholds = {
            "excellent": 0.03,  # Erreur relative < 3%
            "good": 0.06,       # Erreur relative < 6%
            "acceptable": 0.10,  # Erreur relative < 10%
            "poor": 0.15,       # Erreur relative < 15%
            "unacceptable": float('inf')  # Erreur relative >= 15%
        }
    elif measure == "std":
        # L'écart-type est bien estimé avec une haute résolution
        thresholds = {
            "excellent": 0.015,  # Erreur relative < 1.5%
            "good": 0.03,       # Erreur relative < 3%
            "acceptable": 0.05,  # Erreur relative < 5%
            "poor": 0.08,       # Erreur relative < 8%
            "unacceptable": float('inf')  # Erreur relative >= 8%
        }
    elif measure == "mad":
        # L'écart absolu médian est bien estimé avec une haute résolution
        thresholds = {
            "excellent": 0.02,  # Erreur relative < 2%
            "good": 0.04,       # Erreur relative < 4%
            "acceptable": 0.07,  # Erreur relative < 7%
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        }
    elif measure == "iqr":
        # L'écart interquartile est bien estimé avec une haute résolution
        thresholds = {
            "excellent": 0.02,  # Erreur relative < 2%
            "good": 0.04,       # Erreur relative < 4%
            "acceptable": 0.07,  # Erreur relative < 7%
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        }
    else:
        # Utiliser les seuils par défaut pour les autres mesures
        thresholds = default_thresholds

    return thresholds

def define_dispersion_error_thresholds_kde(measure: str = "range", resolution: str = "medium") -> Dict[str, float]:
    """
    Définit les seuils d'erreur relative acceptables pour les mesures de dispersion
    dans le cas des KDEs à différentes résolutions.

    Args:
        measure: Mesure de dispersion ('range', 'variance', 'std', 'mad', 'iqr')
        resolution: Résolution de la KDE ('low', 'medium', 'high')

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour la mesure de dispersion
    """
    # Définir les seuils par défaut pour les KDEs à résolution moyenne
    default_thresholds = {
        "excellent": 0.03,  # Erreur relative < 3%
        "good": 0.06,       # Erreur relative < 6%
        "acceptable": 0.10,  # Erreur relative < 10%
        "poor": 0.15,       # Erreur relative < 15%
        "unacceptable": float('inf')  # Erreur relative >= 15%
    }

    # Ajuster les seuils en fonction de la résolution
    if resolution == "low":  # Faible résolution (< 100 points)
        if measure == "range":
            # L'étendue est très sensible à la résolution de la KDE
            thresholds = {
                "excellent": 0.08,  # Erreur relative < 8%
                "good": 0.15,       # Erreur relative < 15%
                "acceptable": 0.25,  # Erreur relative < 25%
                "poor": 0.40,       # Erreur relative < 40%
                "unacceptable": float('inf')  # Erreur relative >= 40%
            }
        elif measure == "variance":
            # La variance est sensible à la résolution de la KDE
            thresholds = {
                "excellent": 0.06,  # Erreur relative < 6%
                "good": 0.12,       # Erreur relative < 12%
                "acceptable": 0.20,  # Erreur relative < 20%
                "poor": 0.30,       # Erreur relative < 30%
                "unacceptable": float('inf')  # Erreur relative >= 30%
            }
        elif measure == "std":
            # L'écart-type est sensible à la résolution de la KDE, mais moins que la variance
            thresholds = {
                "excellent": 0.03,  # Erreur relative < 3%
                "good": 0.06,       # Erreur relative < 6%
                "acceptable": 0.10,  # Erreur relative < 10%
                "poor": 0.15,       # Erreur relative < 15%
                "unacceptable": float('inf')  # Erreur relative >= 15%
            }
        elif measure == "mad":
            # L'écart absolu médian est sensible à la résolution de la KDE
            thresholds = {
                "excellent": 0.04,  # Erreur relative < 4%
                "good": 0.08,       # Erreur relative < 8%
                "acceptable": 0.12,  # Erreur relative < 12%
                "poor": 0.20,       # Erreur relative < 20%
                "unacceptable": float('inf')  # Erreur relative >= 20%
            }
        elif measure == "iqr":
            # L'écart interquartile est sensible à la résolution de la KDE
            thresholds = {
                "excellent": 0.04,  # Erreur relative < 4%
                "good": 0.08,       # Erreur relative < 8%
                "acceptable": 0.12,  # Erreur relative < 12%
                "poor": 0.20,       # Erreur relative < 20%
                "unacceptable": float('inf')  # Erreur relative >= 20%
            }
        else:
            # Utiliser les seuils par défaut pour les autres mesures
            thresholds = default_thresholds

    elif resolution == "high":  # Haute résolution (>= 500 points)
        if measure == "range":
            # L'étendue reste sensible aux valeurs extrêmes, même avec une haute résolution
            thresholds = {
                "excellent": 0.03,  # Erreur relative < 3%
                "good": 0.06,       # Erreur relative < 6%
                "acceptable": 0.10,  # Erreur relative < 10%
                "poor": 0.15,       # Erreur relative < 15%
                "unacceptable": float('inf')  # Erreur relative >= 15%
            }
        elif measure == "variance":
            # La variance est bien estimée avec une haute résolution
            thresholds = {
                "excellent": 0.02,  # Erreur relative < 2%
                "good": 0.04,       # Erreur relative < 4%
                "acceptable": 0.07,  # Erreur relative < 7%
                "poor": 0.10,       # Erreur relative < 10%
                "unacceptable": float('inf')  # Erreur relative >= 10%
            }
        elif measure == "std":
            # L'écart-type est très bien estimé avec une haute résolution
            thresholds = {
                "excellent": 0.01,  # Erreur relative < 1%
                "good": 0.02,       # Erreur relative < 2%
                "acceptable": 0.035,  # Erreur relative < 3.5%
                "poor": 0.05,       # Erreur relative < 5%
                "unacceptable": float('inf')  # Erreur relative >= 5%
            }
        elif measure == "mad":
            # L'écart absolu médian est très bien estimé avec une haute résolution
            thresholds = {
                "excellent": 0.015,  # Erreur relative < 1.5%
                "good": 0.03,       # Erreur relative < 3%
                "acceptable": 0.05,  # Erreur relative < 5%
                "poor": 0.08,       # Erreur relative < 8%
                "unacceptable": float('inf')  # Erreur relative >= 8%
            }
        elif measure == "iqr":
            # L'écart interquartile est très bien estimé avec une haute résolution
            thresholds = {
                "excellent": 0.015,  # Erreur relative < 1.5%
                "good": 0.03,       # Erreur relative < 3%
                "acceptable": 0.05,  # Erreur relative < 5%
                "poor": 0.08,       # Erreur relative < 8%
                "unacceptable": float('inf')  # Erreur relative >= 8%
            }
        else:
            # Utiliser les seuils par défaut pour les autres mesures
            thresholds = default_thresholds

    else:  # Résolution moyenne (100-500 points)
        if measure == "range":
            # L'étendue est sensible aux valeurs extrêmes
            thresholds = {
                "excellent": 0.05,  # Erreur relative < 5%
                "good": 0.10,       # Erreur relative < 10%
                "acceptable": 0.15,  # Erreur relative < 15%
                "poor": 0.25,       # Erreur relative < 25%
                "unacceptable": float('inf')  # Erreur relative >= 25%
            }
        elif measure == "variance":
            # La variance est moyennement bien estimée avec une résolution moyenne
            thresholds = {
                "excellent": 0.04,  # Erreur relative < 4%
                "good": 0.08,       # Erreur relative < 8%
                "acceptable": 0.12,  # Erreur relative < 12%
                "poor": 0.20,       # Erreur relative < 20%
                "unacceptable": float('inf')  # Erreur relative >= 20%
            }
        elif measure == "std":
            # L'écart-type est bien estimé avec une résolution moyenne
            thresholds = {
                "excellent": 0.02,  # Erreur relative < 2%
                "good": 0.04,       # Erreur relative < 4%
                "acceptable": 0.06,  # Erreur relative < 6%
                "poor": 0.10,       # Erreur relative < 10%
                "unacceptable": float('inf')  # Erreur relative >= 10%
            }
        elif measure == "mad":
            # L'écart absolu médian est bien estimé avec une résolution moyenne
            thresholds = {
                "excellent": 0.025,  # Erreur relative < 2.5%
                "good": 0.05,       # Erreur relative < 5%
                "acceptable": 0.08,  # Erreur relative < 8%
                "poor": 0.12,       # Erreur relative < 12%
                "unacceptable": float('inf')  # Erreur relative >= 12%
            }
        elif measure == "iqr":
            # L'écart interquartile est bien estimé avec une résolution moyenne
            thresholds = {
                "excellent": 0.025,  # Erreur relative < 2.5%
                "good": 0.05,       # Erreur relative < 5%
                "acceptable": 0.08,  # Erreur relative < 8%
                "poor": 0.12,       # Erreur relative < 12%
                "unacceptable": float('inf')  # Erreur relative >= 12%
            }
        else:
            # Utiliser les seuils par défaut pour les autres mesures
            thresholds = default_thresholds

    return thresholds
