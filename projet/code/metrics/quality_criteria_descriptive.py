#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les critères de qualité pour l'analyse descriptive,
notamment les critères de précision pour l'estimation des paramètres statistiques.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, Optional, Any, Union, List, Tuple
import scipy.stats
import pandas as pd

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
from statistical_parameters_estimation import estimate_from_raw_data, estimate_from_histogram, estimate_from_kde

def define_mean_precision_criteria(relative_error_threshold: float = 0.05,
                                 confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de la moyenne.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de la moyenne
    """
    # Définir les critères de précision
    criteria = {
        "name": "mean_precision",
        "description": "Critères de précision pour l'estimation de la moyenne",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.01,  # Erreur relative < 1%
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

def evaluate_mean_precision(true_mean: float,
                          estimated_mean: float,
                          sample_size: int,
                          std_dev: float,
                          criteria: Dict[str, Any]) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la moyenne selon les critères définis.

    Args:
        true_mean: Valeur réelle de la moyenne
        estimated_mean: Valeur estimée de la moyenne
        sample_size: Taille de l'échantillon
        std_dev: Écart-type de l'échantillon
        criteria: Critères de précision pour l'estimation de la moyenne

    Returns:
        Dict[str, Any]: Évaluation de la précision de l'estimation
    """
    # Calculer l'erreur absolue
    absolute_error = abs(estimated_mean - true_mean)

    # Calculer l'erreur relative (en évitant la division par zéro)
    if true_mean != 0:
        relative_error = absolute_error / abs(true_mean)
    else:
        # Si la vraie moyenne est zéro, utiliser l'écart-type comme référence
        relative_error = absolute_error / (std_dev if std_dev > 0 else 1.0)

    # Calculer l'erreur standard de la moyenne
    standard_error = std_dev / np.sqrt(sample_size)

    # Calculer l'intervalle de confiance
    z_value = scipy.stats.norm.ppf((1 + criteria["confidence_level"]) / 2)
    confidence_interval = (estimated_mean - z_value * standard_error,
                          estimated_mean + z_value * standard_error)

    # Vérifier si l'intervalle de confiance contient la vraie moyenne
    contains_true_mean = confidence_interval[0] <= true_mean <= confidence_interval[1]

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
        "true_mean": true_mean,
        "estimated_mean": estimated_mean,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "standard_error": standard_error,
        "confidence_interval": confidence_interval,
        "contains_true_mean": contains_true_mean,
        "sample_size": sample_size,
        "quality_by_error": quality_by_error,
        "quality_by_sample_size": quality_by_sample_size,
        "overall_quality": overall_quality
    }

def evaluate_histogram_mean_precision(data: np.ndarray,
                                    bin_counts: List[int],
                                    criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la moyenne à partir d'histogrammes
    avec différents nombres de bins.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        criteria: Critères de précision pour l'estimation de la moyenne (optionnel)

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de bins
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_mean_precision_criteria()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_mean = raw_params["mean"]
    std_dev = raw_params["std"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "bin_counts": bin_counts,
        "true_mean": true_mean,
        "std_dev": std_dev,
        "sample_size": sample_size,
        "estimated_means": [],
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
        estimated_mean = hist_params["mean"]

        # Évaluer la précision
        evaluation = evaluate_mean_precision(
            true_mean=true_mean,
            estimated_mean=estimated_mean,
            sample_size=sample_size,
            std_dev=std_dev,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_means"].append(estimated_mean)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def evaluate_kde_mean_precision(data: np.ndarray,
                              kde_points: List[int],
                              criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la moyenne à partir de KDEs
    avec différents nombres de points.

    Args:
        data: Données brutes
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de la moyenne (optionnel)

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de points
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_mean_precision_criteria()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_mean = raw_params["mean"]
    std_dev = raw_params["std"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "kde_points": kde_points,
        "true_mean": true_mean,
        "std_dev": std_dev,
        "sample_size": sample_size,
        "estimated_means": [],
        "absolute_errors": [],
        "relative_errors": [],
        "overall_qualities": []
    }

    # Évaluer la précision pour chaque nombre de points
    for num_points in kde_points:
        # Estimer les paramètres à partir de la KDE
        kde_params = estimate_from_kde(data, num_points=num_points)
        estimated_mean = kde_params["mean"]

        # Évaluer la précision
        evaluation = evaluate_mean_precision(
            true_mean=true_mean,
            estimated_mean=estimated_mean,
            sample_size=sample_size,
            std_dev=std_dev,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_means"].append(estimated_mean)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def plot_mean_precision_evaluation(histogram_results: Dict[str, Any],
                                 kde_results: Dict[str, Any],
                                 title: str = "Évaluation de la précision de l'estimation de la moyenne",
                                 save_path: Optional[str] = None,
                                 show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de la précision de l'estimation de la moyenne.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))

    # Tracer l'erreur relative en fonction du nombre de bins/points
    axes[0].plot(histogram_results["bin_counts"], histogram_results["relative_errors"],
               'o-', label='Histogramme')
    axes[0].plot(kde_results["kde_points"], kde_results["relative_errors"],
               's-', label='KDE')
    axes[0].axhline(y=0.05, color='r', linestyle='--', label='Seuil d\'erreur (5%)')
    axes[0].axhline(y=0.01, color='g', linestyle='--', label='Seuil d\'excellence (1%)')
    axes[0].set_xscale('log')
    axes[0].set_yscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('Erreur relative')
    axes[0].set_title('Erreur relative en fonction de la résolution')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # Tracer la qualité en fonction du nombre de bins/points
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    hist_quality_ranks = [quality_ranks[q] for q in histogram_results["overall_qualities"]]
    kde_quality_ranks = [quality_ranks[q] for q in kde_results["overall_qualities"]]

    axes[1].plot(histogram_results["bin_counts"], hist_quality_ranks,
               'o-', label='Histogramme')
    axes[1].plot(kde_results["kde_points"], kde_quality_ranks,
               's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_yticks(list(quality_ranks.values()))
    axes[1].set_yticklabels(list(quality_ranks.keys()))
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('Qualité globale')
    axes[1].set_title('Qualité de l\'estimation en fonction de la résolution')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    # Configurer le titre global
    fig.suptitle(title, fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def define_median_precision_criteria(relative_error_threshold: float = 0.05,
                                  confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de la médiane.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de la médiane
    """
    # Définir les critères de précision
    criteria = {
        "name": "median_precision",
        "description": "Critères de précision pour l'estimation de la médiane",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.01,  # Erreur relative < 1%
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
        },
        "bin_coverage_requirements": {
            "excellent": 0.01,  # Au moins 1% des échantillons par bin autour de la médiane
            "good": 0.02,       # Au moins 2% des échantillons par bin autour de la médiane
            "acceptable": 0.05, # Au moins 5% des échantillons par bin autour de la médiane
            "poor": 0.10,       # Au moins 10% des échantillons par bin autour de la médiane
            "unacceptable": 1.0 # Plus de 10% des échantillons par bin autour de la médiane
        }
    }

    return criteria

def evaluate_median_precision(true_median: float,
                            estimated_median: float,
                            sample_size: int,
                            iqr: float,
                            criteria: Dict[str, Any]) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la médiane selon les critères définis.

    Args:
        true_median: Valeur réelle de la médiane
        estimated_median: Valeur estimée de la médiane
        sample_size: Taille de l'échantillon
        iqr: Écart interquartile de l'échantillon
        criteria: Critères de précision pour l'estimation de la médiane

    Returns:
        Dict[str, Any]: Évaluation de la précision de l'estimation
    """
    # Calculer l'erreur absolue
    absolute_error = abs(estimated_median - true_median)

    # Calculer l'erreur relative (en évitant la division par zéro)
    if true_median != 0:
        relative_error = absolute_error / abs(true_median)
    else:
        # Si la vraie médiane est zéro, utiliser l'IQR comme référence
        relative_error = absolute_error / (iqr if iqr > 0 else 1.0)

    # Calculer l'erreur standard de la médiane (approximation)
    # Formule: 1.253 * std / sqrt(n), où std est approximé par IQR/1.35
    std_approx = iqr / 1.35
    standard_error = 1.253 * std_approx / np.sqrt(sample_size)

    # Calculer l'intervalle de confiance
    z_value = scipy.stats.norm.ppf((1 + criteria["confidence_level"]) / 2)
    confidence_interval = (estimated_median - z_value * standard_error,
                          estimated_median + z_value * standard_error)

    # Vérifier si l'intervalle de confiance contient la vraie médiane
    contains_true_median = confidence_interval[0] <= true_median <= confidence_interval[1]

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
        "true_median": true_median,
        "estimated_median": estimated_median,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "standard_error": standard_error,
        "confidence_interval": confidence_interval,
        "contains_true_median": contains_true_median,
        "sample_size": sample_size,
        "quality_by_error": quality_by_error,
        "quality_by_sample_size": quality_by_sample_size,
        "overall_quality": overall_quality
    }

def evaluate_histogram_median_precision(data: np.ndarray,
                                      bin_counts: List[int],
                                      criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la médiane à partir d'histogrammes
    avec différents nombres de bins.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        criteria: Critères de précision pour l'estimation de la médiane (optionnel)

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de bins
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_median_precision_criteria()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_median = raw_params["median"]
    iqr = raw_params["iqr"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "bin_counts": bin_counts,
        "true_median": true_median,
        "iqr": iqr,
        "sample_size": sample_size,
        "estimated_medians": [],
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
        estimated_median = hist_params["median"]

        # Évaluer la précision
        evaluation = evaluate_median_precision(
            true_median=true_median,
            estimated_median=estimated_median,
            sample_size=sample_size,
            iqr=iqr,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_medians"].append(estimated_median)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def evaluate_kde_median_precision(data: np.ndarray,
                                kde_points: List[int],
                                criteria: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de la médiane à partir de KDEs
    avec différents nombres de points.

    Args:
        data: Données brutes
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de la médiane (optionnel)

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de points
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_median_precision_criteria()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_median = raw_params["median"]
    iqr = raw_params["iqr"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "kde_points": kde_points,
        "true_median": true_median,
        "iqr": iqr,
        "sample_size": sample_size,
        "estimated_medians": [],
        "absolute_errors": [],
        "relative_errors": [],
        "overall_qualities": []
    }

    # Évaluer la précision pour chaque nombre de points
    for num_points in kde_points:
        # Estimer les paramètres à partir de la KDE
        kde_params = estimate_from_kde(data, num_points=num_points)
        estimated_median = kde_params["median"]

        # Évaluer la précision
        evaluation = evaluate_median_precision(
            true_median=true_median,
            estimated_median=estimated_median,
            sample_size=sample_size,
            iqr=iqr,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_medians"].append(estimated_median)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def plot_median_precision_evaluation(histogram_results: Dict[str, Any],
                                   kde_results: Dict[str, Any],
                                   title: str = "Évaluation de la précision de l'estimation de la médiane",
                                   save_path: Optional[str] = None,
                                   show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de la précision de l'estimation de la médiane.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))

    # Tracer l'erreur relative en fonction du nombre de bins/points
    axes[0].plot(histogram_results["bin_counts"], histogram_results["relative_errors"],
               'o-', label='Histogramme')
    axes[0].plot(kde_results["kde_points"], kde_results["relative_errors"],
               's-', label='KDE')
    axes[0].axhline(y=0.05, color='r', linestyle='--', label='Seuil d\'erreur (5%)')
    axes[0].axhline(y=0.01, color='g', linestyle='--', label='Seuil d\'excellence (1%)')
    axes[0].set_xscale('log')
    axes[0].set_yscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('Erreur relative')
    axes[0].set_title('Erreur relative en fonction de la résolution')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # Tracer la qualité en fonction du nombre de bins/points
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    hist_quality_ranks = [quality_ranks[q] for q in histogram_results["overall_qualities"]]
    kde_quality_ranks = [quality_ranks[q] for q in kde_results["overall_qualities"]]

    axes[1].plot(histogram_results["bin_counts"], hist_quality_ranks,
               'o-', label='Histogramme')
    axes[1].plot(kde_results["kde_points"], kde_quality_ranks,
               's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_yticks(list(quality_ranks.values()))
    axes[1].set_yticklabels(list(quality_ranks.keys()))
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('Qualité globale')
    axes[1].set_title('Qualité de l\'estimation en fonction de la résolution')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    # Configurer le titre global
    fig.suptitle(title, fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def determine_optimal_resolution_for_median(histogram_results: Dict[str, Any],
                                          kde_results: Dict[str, Any],
                                          quality_threshold: str = "good") -> Dict[str, Any]:
    """
    Détermine la résolution optimale pour l'estimation de la médiane.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

    Returns:
        Dict[str, Any]: Résolutions optimales pour l'estimation de la médiane
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

def define_std_precision_criteria(relative_error_threshold: float = 0.05,
                                confidence_level: float = 0.95) -> Dict[str, Any]:
    """
    Établit les critères de précision pour l'estimation de l'écart-type.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable (par défaut: 5%)
        confidence_level: Niveau de confiance pour les intervalles (par défaut: 95%)

    Returns:
        Dict[str, Any]: Critères de précision pour l'estimation de l'écart-type
    """
    # Définir les critères de précision
    criteria = {
        "name": "std_precision",
        "description": "Critères de précision pour l'estimation de l'écart-type",
        "relative_error_threshold": relative_error_threshold,
        "confidence_level": confidence_level,
        "absolute_error_thresholds": {
            "excellent": 0.01,  # Erreur relative < 1%
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

def define_std_error_thresholds_normal(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'écart-type
    dans le cas des distributions normales.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'écart-type
    """
    # Pour les distributions normales, l'écart-type peut être estimé avec une grande précision
    # car la distribution est symétrique et bien définie
    thresholds = {
        "excellent": 0.01,  # Erreur relative < 1%
        "good": 0.02,       # Erreur relative < 2%
        "acceptable": 0.04,  # Erreur relative < 4%
        "poor": 0.08,       # Erreur relative < 8%
        "unacceptable": float('inf')  # Erreur relative >= 8%
    }

    return thresholds

def define_std_error_thresholds_skewed(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'écart-type
    dans le cas des distributions asymétriques.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'écart-type
    """
    # Pour les distributions asymétriques, l'écart-type est plus difficile à estimer
    # car la queue de la distribution peut avoir une influence importante
    thresholds = {
        "excellent": 0.02,  # Erreur relative < 2%
        "good": 0.05,       # Erreur relative < 5%
        "acceptable": 0.08,  # Erreur relative < 8%
        "poor": 0.15,       # Erreur relative < 15%
        "unacceptable": float('inf')  # Erreur relative >= 15%
    }

    return thresholds

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





def define_std_error_thresholds_multimodal(relative_error_threshold: float = 0.05) -> Dict[str, float]:
    """
    Établit les seuils d'erreur relative pour l'estimation de l'écart-type
    dans le cas des distributions multimodales.

    Args:
        relative_error_threshold: Seuil d'erreur relative acceptable par défaut (5%)

    Returns:
        Dict[str, float]: Seuils d'erreur relative pour l'écart-type
    """
    # Pour les distributions multimodales, l'écart-type est très difficile à estimer
    # car il dépend fortement de la séparation entre les modes
    thresholds = {
        "excellent": 0.03,  # Erreur relative < 3%
        "good": 0.07,       # Erreur relative < 7%
        "acceptable": 0.12,  # Erreur relative < 12%
        "poor": 0.20,       # Erreur relative < 20%
        "unacceptable": float('inf')  # Erreur relative >= 20%
    }

    return thresholds





def evaluate_std_precision(true_std: float,
                         estimated_std: float,
                         sample_size: int,
                         criteria: Dict[str, Any]) -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'écart-type selon les critères définis.

    Args:
        true_std: Valeur réelle de l'écart-type
        estimated_std: Valeur estimée de l'écart-type
        sample_size: Taille de l'échantillon
        criteria: Critères de précision pour l'estimation de l'écart-type

    Returns:
        Dict[str, Any]: Évaluation de la précision de l'estimation
    """
    # Calculer l'erreur absolue
    absolute_error = abs(estimated_std - true_std)

    # Calculer l'erreur relative (en évitant la division par zéro)
    if true_std != 0:
        relative_error = absolute_error / abs(true_std)
    else:
        # Si le vrai écart-type est zéro, l'erreur relative est infinie
        relative_error = float('inf') if absolute_error > 0 else 0.0

    # Calculer l'erreur standard de l'écart-type (approximation)
    # Formule: std / sqrt(2n) pour une distribution normale
    standard_error = true_std / np.sqrt(2 * sample_size)

    # Calculer l'intervalle de confiance
    z_value = scipy.stats.norm.ppf((1 + criteria["confidence_level"]) / 2)
    confidence_interval = (estimated_std - z_value * standard_error,
                          estimated_std + z_value * standard_error)

    # Vérifier si l'intervalle de confiance contient le vrai écart-type
    contains_true_std = confidence_interval[0] <= true_std <= confidence_interval[1]

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
        "true_std": true_std,
        "estimated_std": estimated_std,
        "absolute_error": absolute_error,
        "relative_error": relative_error,
        "standard_error": standard_error,
        "confidence_interval": confidence_interval,
        "contains_true_std": contains_true_std,
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
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_iqr_precision_criteria()

    # Ajuster les seuils d'erreur en fonction du type de distribution
    if distribution_type == "symmetric":
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_symmetric()

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

def plot_iqr_precision_evaluation(histogram_results: Dict[str, Any],
                                kde_results: Dict[str, Any],
                                title: str = "Évaluation de la précision de l'estimation de l'IQR",
                                save_path: Optional[str] = None,
                                show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de la précision de l'estimation de l'IQR.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))

    # Tracer l'erreur relative en fonction du nombre de bins/points
    axes[0].plot(histogram_results["bin_counts"], histogram_results["relative_errors"],
               'o-', label='Histogramme')
    axes[0].plot(kde_results["kde_points"], kde_results["relative_errors"],
               's-', label='KDE')
    axes[0].axhline(y=0.05, color='r', linestyle='--', label='Seuil d\'erreur (5%)')
    axes[0].axhline(y=0.015, color='g', linestyle='--', label='Seuil d\'excellence (1.5%)')
    axes[0].set_xscale('log')
    axes[0].set_yscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('Erreur relative')
    axes[0].set_title(f'Erreur relative en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # Tracer la qualité en fonction du nombre de bins/points
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    hist_quality_ranks = [quality_ranks[q] for q in histogram_results["overall_qualities"]]
    kde_quality_ranks = [quality_ranks[q] for q in kde_results["overall_qualities"]]

    axes[1].plot(histogram_results["bin_counts"], hist_quality_ranks,
               'o-', label='Histogramme')
    axes[1].plot(kde_results["kde_points"], kde_quality_ranks,
               's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_yticks(list(quality_ranks.values()))
    axes[1].set_yticklabels(list(quality_ranks.keys()))
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('Qualité globale')
    axes[1].set_title(f'Qualité de l\'estimation en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    # Configurer le titre global
    fig.suptitle(title, fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

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

def create_iqr_precision_report_multimodal(data: np.ndarray,
                                        bin_counts: List[int] = [10, 20, 50, 100, 200],
                                        kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                        criteria: Optional[Dict[str, Any]] = None,
                                        save_path: Optional[str] = None,
                                        show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'IQR
    pour les distributions multimodales.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_iqr_precision_criteria()
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_multimodal()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_iqr_precision(
        data, bin_counts, criteria, distribution_type="multimodal"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_iqr_precision(
        data, kde_points, criteria, distribution_type="multimodal"
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
        "criteria": criteria,
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

def create_iqr_precision_report_heavy_tailed(data: np.ndarray,
                                        bin_counts: List[int] = [10, 20, 50, 100, 200],
                                        kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                        criteria: Optional[Dict[str, Any]] = None,
                                        save_path: Optional[str] = None,
                                        show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'IQR
    pour les distributions à queue lourde.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_iqr_precision_criteria()
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_heavy_tailed()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_iqr_precision(
        data, bin_counts, criteria, distribution_type="heavy_tailed"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_iqr_precision(
        data, kde_points, criteria, distribution_type="heavy_tailed"
    )

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_iqr(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_iqr_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'IQR - Distribution à queue lourde",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def create_iqr_precision_report_symmetric(data: np.ndarray,
                                        bin_counts: List[int] = [10, 20, 50, 100, 200],
                                        kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                        criteria: Optional[Dict[str, Any]] = None,
                                        save_path: Optional[str] = None,
                                        show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'IQR
    pour les distributions symétriques.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'IQR (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'IQR
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_iqr_precision_criteria()
        criteria["absolute_error_thresholds"] = define_iqr_error_thresholds_symmetric()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_iqr_precision(
        data, bin_counts, criteria, distribution_type="symmetric"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_iqr_precision(
        data, kde_points, criteria, distribution_type="symmetric"
    )

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_iqr(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_iqr_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'IQR - Distribution symétrique",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def evaluate_histogram_std_precision(data: np.ndarray,
                                   bin_counts: List[int],
                                   criteria: Optional[Dict[str, Any]] = None,
                                   distribution_type: str = "normal") -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'écart-type à partir d'histogrammes
    avec différents nombres de bins.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'general')

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de bins
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_std_precision_criteria()

    # Ajuster les seuils d'erreur en fonction du type de distribution
    if distribution_type == "normal":
        criteria["absolute_error_thresholds"] = define_std_error_thresholds_normal()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_std = raw_params["std"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "bin_counts": bin_counts,
        "true_std": true_std,
        "sample_size": sample_size,
        "distribution_type": distribution_type,
        "estimated_stds": [],
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
        estimated_std = hist_params["std"]

        # Évaluer la précision
        evaluation = evaluate_std_precision(
            true_std=true_std,
            estimated_std=estimated_std,
            sample_size=sample_size,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_stds"].append(estimated_std)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def evaluate_kde_std_precision(data: np.ndarray,
                             kde_points: List[int],
                             criteria: Optional[Dict[str, Any]] = None,
                             distribution_type: str = "normal") -> Dict[str, Any]:
    """
    Évalue la précision de l'estimation de l'écart-type à partir de KDEs
    avec différents nombres de points.

    Args:
        data: Données brutes
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
        distribution_type: Type de distribution ('normal', 'skewed', 'multimodal', 'general')

    Returns:
        Dict[str, Any]: Évaluation de la précision pour différents nombres de points
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_std_precision_criteria()

    # Ajuster les seuils d'erreur en fonction du type de distribution
    if distribution_type == "normal":
        criteria["absolute_error_thresholds"] = define_std_error_thresholds_normal()

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_std = raw_params["std"]
    sample_size = len(data)

    # Initialiser les résultats
    results = {
        "kde_points": kde_points,
        "true_std": true_std,
        "sample_size": sample_size,
        "distribution_type": distribution_type,
        "estimated_stds": [],
        "absolute_errors": [],
        "relative_errors": [],
        "overall_qualities": []
    }

    # Évaluer la précision pour chaque nombre de points
    for num_points in kde_points:
        # Estimer les paramètres à partir de la KDE
        kde_params = estimate_from_kde(data, num_points=num_points)
        estimated_std = kde_params["std"]

        # Évaluer la précision
        evaluation = evaluate_std_precision(
            true_std=true_std,
            estimated_std=estimated_std,
            sample_size=sample_size,
            criteria=criteria
        )

        # Stocker les résultats
        results["estimated_stds"].append(estimated_std)
        results["absolute_errors"].append(evaluation["absolute_error"])
        results["relative_errors"].append(evaluation["relative_error"])
        results["overall_qualities"].append(evaluation["overall_quality"])

    return results

def plot_std_precision_evaluation(histogram_results: Dict[str, Any],
                                kde_results: Dict[str, Any],
                                title: str = "Évaluation de la précision de l'estimation de l'écart-type",
                                save_path: Optional[str] = None,
                                show_plot: bool = True) -> None:
    """
    Visualise l'évaluation de la précision de l'estimation de l'écart-type.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(10, 12))

    # Tracer l'erreur relative en fonction du nombre de bins/points
    axes[0].plot(histogram_results["bin_counts"], histogram_results["relative_errors"],
               'o-', label='Histogramme')
    axes[0].plot(kde_results["kde_points"], kde_results["relative_errors"],
               's-', label='KDE')
    axes[0].axhline(y=0.05, color='r', linestyle='--', label='Seuil d\'erreur (5%)')
    axes[0].axhline(y=0.01, color='g', linestyle='--', label='Seuil d\'excellence (1%)')
    axes[0].set_xscale('log')
    axes[0].set_yscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('Erreur relative')
    axes[0].set_title(f'Erreur relative en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # Tracer la qualité en fonction du nombre de bins/points
    quality_ranks = {"excellent": 4, "good": 3, "acceptable": 2, "poor": 1, "unacceptable": 0}
    hist_quality_ranks = [quality_ranks[q] for q in histogram_results["overall_qualities"]]
    kde_quality_ranks = [quality_ranks[q] for q in kde_results["overall_qualities"]]

    axes[1].plot(histogram_results["bin_counts"], hist_quality_ranks,
               'o-', label='Histogramme')
    axes[1].plot(kde_results["kde_points"], kde_quality_ranks,
               's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_yticks(list(quality_ranks.values()))
    axes[1].set_yticklabels(list(quality_ranks.keys()))
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('Qualité globale')
    axes[1].set_title(f'Qualité de l\'estimation en fonction de la résolution - Distribution {histogram_results["distribution_type"]}')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    # Configurer le titre global
    fig.suptitle(title, fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def determine_optimal_resolution_for_std(histogram_results: Dict[str, Any],
                                       kde_results: Dict[str, Any],
                                       quality_threshold: str = "good") -> Dict[str, Any]:
    """
    Détermine la résolution optimale pour l'estimation de l'écart-type.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

    Returns:
        Dict[str, Any]: Résolutions optimales pour l'estimation de l'écart-type
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

def create_std_precision_report_multimodal(data: np.ndarray,
                                        bin_counts: List[int] = [10, 20, 50, 100, 200],
                                        kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                        criteria: Optional[Dict[str, Any]] = None,
                                        save_path: Optional[str] = None,
                                        show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'écart-type
    pour les distributions multimodales.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_std_precision_criteria()
        criteria["absolute_error_thresholds"] = define_std_error_thresholds_multimodal()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_std_precision(
        data, bin_counts, criteria, distribution_type="multimodal"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_std_precision(
        data, kde_points, criteria, distribution_type="multimodal"
    )

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_std(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_std_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'écart-type - Distribution multimodale",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def create_std_precision_report_skewed(data: np.ndarray,
                                     bin_counts: List[int] = [10, 20, 50, 100, 200],
                                     kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                     criteria: Optional[Dict[str, Any]] = None,
                                     save_path: Optional[str] = None,
                                     show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'écart-type
    pour les distributions asymétriques.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_std_precision_criteria()
        criteria["absolute_error_thresholds"] = define_std_error_thresholds_skewed()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_std_precision(
        data, bin_counts, criteria, distribution_type="skewed"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_std_precision(
        data, kde_points, criteria, distribution_type="skewed"
    )

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_std(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_std_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'écart-type - Distribution asymétrique",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def create_std_precision_report_normal(data: np.ndarray,
                                     bin_counts: List[int] = [10, 20, 50, 100, 200],
                                     kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                     criteria: Optional[Dict[str, Any]] = None,
                                     save_path: Optional[str] = None,
                                     show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de l'écart-type
    pour les distributions normales.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de l'écart-type (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de l'écart-type
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_std_precision_criteria()
        criteria["absolute_error_thresholds"] = define_std_error_thresholds_normal()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_std_precision(
        data, bin_counts, criteria, distribution_type="normal"
    )

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_std_precision(
        data, kde_points, criteria, distribution_type="normal"
    )

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_std(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_std_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de l'écart-type - Distribution normale",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def define_central_tendency_error_thresholds(distribution_type: str = "general") -> Dict[str, Dict[str, float]]:
    """
    Définit les seuils d'erreur acceptables pour les mesures de tendance centrale
    en fonction du type de distribution.

    Args:
        distribution_type: Type de distribution ('general', 'normal', 'skewed', 'multimodal')

    Returns:
        Dict[str, Dict[str, float]]: Seuils d'erreur acceptables pour les mesures de tendance centrale
    """
    # Définir les seuils d'erreur par défaut (cas général)
    thresholds = {
        "mean": {
            "excellent": 0.01,  # Erreur relative < 1%
            "good": 0.03,       # Erreur relative < 3%
            "acceptable": 0.05,  # Erreur relative < 5%
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        },
        "median": {
            "excellent": 0.01,  # Erreur relative < 1%
            "good": 0.03,       # Erreur relative < 3%
            "acceptable": 0.05,  # Erreur relative < 5%
            "poor": 0.10,       # Erreur relative < 10%
            "unacceptable": float('inf')  # Erreur relative >= 10%
        },
        "mode": {
            "excellent": 0.02,  # Erreur relative < 2%
            "good": 0.05,       # Erreur relative < 5%
            "acceptable": 0.10,  # Erreur relative < 10%
            "poor": 0.20,       # Erreur relative < 20%
            "unacceptable": float('inf')  # Erreur relative >= 20%
        }
    }

    # Ajuster les seuils en fonction du type de distribution
    if distribution_type == "normal":
        # Pour les distributions normales, la moyenne est plus robuste
        thresholds["mean"] = {
            "excellent": 0.005,  # Erreur relative < 0.5%
            "good": 0.02,        # Erreur relative < 2%
            "acceptable": 0.04,   # Erreur relative < 4%
            "poor": 0.08,        # Erreur relative < 8%
            "unacceptable": float('inf')
        }
    elif distribution_type == "skewed":
        # Pour les distributions asymétriques, la médiane est plus robuste
        thresholds["median"] = {
            "excellent": 0.005,  # Erreur relative < 0.5%
            "good": 0.02,        # Erreur relative < 2%
            "acceptable": 0.04,   # Erreur relative < 4%
            "poor": 0.08,        # Erreur relative < 8%
            "unacceptable": float('inf')
        }
        # La moyenne est moins fiable pour les distributions asymétriques
        thresholds["mean"] = {
            "excellent": 0.02,   # Erreur relative < 2%
            "good": 0.05,        # Erreur relative < 5%
            "acceptable": 0.10,   # Erreur relative < 10%
            "poor": 0.20,        # Erreur relative < 20%
            "unacceptable": float('inf')
        }
    elif distribution_type == "multimodal":
        # Pour les distributions multimodales, le mode est plus informatif
        thresholds["mode"] = {
            "excellent": 0.01,   # Erreur relative < 1%
            "good": 0.03,        # Erreur relative < 3%
            "acceptable": 0.07,   # Erreur relative < 7%
            "poor": 0.15,        # Erreur relative < 15%
            "unacceptable": float('inf')
        }
        # La moyenne peut être trompeuse pour les distributions multimodales
        thresholds["mean"] = {
            "excellent": 0.02,   # Erreur relative < 2%
            "good": 0.05,        # Erreur relative < 5%
            "acceptable": 0.10,   # Erreur relative < 10%
            "poor": 0.20,        # Erreur relative < 20%
            "unacceptable": float('inf')
        }

    return thresholds

def determine_distribution_type(data: np.ndarray) -> str:
    """
    Détermine le type de distribution des données.

    Args:
        data: Données brutes

    Returns:
        str: Type de distribution ('normal', 'skewed', 'multimodal', 'general')
    """
    # Calculer les paramètres statistiques
    params = estimate_from_raw_data(data)
    skewness = params["skewness"]
    kurtosis = params["kurtosis"]

    # Tester la normalité avec le test de Shapiro-Wilk
    if len(data) <= 5000:  # Le test de Shapiro-Wilk est limité à 5000 échantillons
        _, p_value = scipy.stats.shapiro(data)
        is_normal = p_value >= 0.05
    else:
        # Pour les grands échantillons, utiliser le test de D'Agostino-Pearson
        _, p_value = scipy.stats.normaltest(data)
        is_normal = p_value >= 0.05

    # Vérifier si la distribution est multimodale
    # Utiliser la méthode de détection des modes par KDE
    kde = scipy.stats.gaussian_kde(data)
    x = np.linspace(min(data), max(data), 1000)
    y = kde(x)

    # Trouver les maxima locaux (modes)
    try:
        from scipy.signal import find_peaks
        peaks, _ = find_peaks(y)
        num_modes = len(peaks)
    except:
        # En cas d'erreur, supposer une distribution unimodale
        num_modes = 1

    # Déterminer le type de distribution
    if num_modes > 1:
        return "multimodal"
    elif is_normal:
        return "normal"
    elif abs(skewness) > 0.5:  # Seuil arbitraire pour l'asymétrie
        return "skewed"
    else:
        return "general"

def get_recommended_error_thresholds(data: np.ndarray) -> Dict[str, Dict[str, float]]:
    """
    Obtient les seuils d'erreur recommandés pour les mesures de tendance centrale
    en fonction du type de distribution des données.

    Args:
        data: Données brutes

    Returns:
        Dict[str, Dict[str, float]]: Seuils d'erreur recommandés
    """
    # Déterminer le type de distribution
    distribution_type = determine_distribution_type(data)

    # Obtenir les seuils d'erreur correspondants
    thresholds = define_central_tendency_error_thresholds(distribution_type)

    # Ajouter le type de distribution aux résultats
    result = {
        "distribution_type": distribution_type,
        "thresholds": thresholds
    }

    return result

def create_central_tendency_error_report(data: np.ndarray,
                                       bin_counts: List[int] = [10, 20, 50, 100, 200],
                                       kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                       save_path: Optional[str] = None,
                                       show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur les seuils d'erreur acceptables pour les mesures de tendance centrale.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur les seuils d'erreur acceptables
    """
    # Obtenir les seuils d'erreur recommandés
    error_thresholds = get_recommended_error_thresholds(data)

    # Calculer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)
    true_mean = raw_params["mean"]
    true_median = raw_params["median"]

    # Initialiser les résultats
    results = {
        "distribution_type": error_thresholds["distribution_type"],
        "error_thresholds": error_thresholds["thresholds"],
        "bin_counts": bin_counts,
        "kde_points": kde_points,
        "true_mean": true_mean,
        "true_median": true_median,
        "histogram_mean_errors": [],
        "histogram_median_errors": [],
        "kde_mean_errors": [],
        "kde_median_errors": []
    }

    # Calculer les erreurs pour chaque nombre de bins
    for num_bins in bin_counts:
        # Calculer l'histogramme
        hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)

        # Estimer les paramètres à partir de l'histogramme
        hist_params = estimate_from_histogram(hist_counts, bin_edges)

        # Calculer les erreurs relatives
        mean_error = abs(hist_params["mean"] - true_mean) / abs(true_mean) if true_mean != 0 else 0
        median_error = abs(hist_params["median"] - true_median) / abs(true_median) if true_median != 0 else 0

        # Stocker les résultats
        results["histogram_mean_errors"].append(mean_error)
        results["histogram_median_errors"].append(median_error)

    # Calculer les erreurs pour chaque nombre de points KDE
    for num_points in kde_points:
        # Estimer les paramètres à partir de la KDE
        kde_params = estimate_from_kde(data, num_points=num_points)

        # Calculer les erreurs relatives
        mean_error = abs(kde_params["mean"] - true_mean) / abs(true_mean) if true_mean != 0 else 0
        median_error = abs(kde_params["median"] - true_median) / abs(true_median) if true_median != 0 else 0

        # Stocker les résultats
        results["kde_mean_errors"].append(mean_error)
        results["kde_median_errors"].append(median_error)

    # Visualiser les résultats
    if save_path or show_plot:
        # Créer la figure
        fig, axes = plt.subplots(2, 1, figsize=(10, 12))

        # Tracer les erreurs relatives pour la moyenne
        axes[0].plot(bin_counts, results["histogram_mean_errors"],
                   'o-', label='Histogramme')
        axes[0].plot(kde_points, results["kde_mean_errors"],
                   's-', label='KDE')

        # Ajouter les seuils d'erreur
        for quality, threshold in results["error_thresholds"]["mean"].items():
            if quality != "unacceptable":
                axes[0].axhline(y=threshold, linestyle='--',
                              label=f'Seuil {quality} ({threshold:.1%})')

        axes[0].set_xscale('log')
        axes[0].set_yscale('log')
        axes[0].set_xlabel('Nombre de bins / points')
        axes[0].set_ylabel('Erreur relative')
        axes[0].set_title(f'Erreur relative pour la moyenne - Distribution {results["distribution_type"]}')
        axes[0].grid(True, alpha=0.3)
        axes[0].legend()

        # Tracer les erreurs relatives pour la médiane
        axes[1].plot(bin_counts, results["histogram_median_errors"],
                   'o-', label='Histogramme')
        axes[1].plot(kde_points, results["kde_median_errors"],
                   's-', label='KDE')

        # Ajouter les seuils d'erreur
        for quality, threshold in results["error_thresholds"]["median"].items():
            if quality != "unacceptable":
                axes[1].axhline(y=threshold, linestyle='--',
                              label=f'Seuil {quality} ({threshold:.1%})')

        axes[1].set_xscale('log')
        axes[1].set_yscale('log')
        axes[1].set_xlabel('Nombre de bins / points')
        axes[1].set_ylabel('Erreur relative')
        axes[1].set_title(f'Erreur relative pour la médiane - Distribution {results["distribution_type"]}')
        axes[1].grid(True, alpha=0.3)
        axes[1].legend()

        # Configurer le titre global
        fig.suptitle(f'Seuils d\'erreur pour les mesures de tendance centrale - Distribution {results["distribution_type"]}',
                    fontsize=16)

        # Ajuster la mise en page
        plt.tight_layout(rect=(0, 0, 1, 0.95))

        # Sauvegarder la figure si un chemin est spécifié
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')

        # Afficher la figure si demandé
        if show_plot:
            plt.show()
        else:
            plt.close(fig)

    # Déterminer les résolutions minimales pour respecter les seuils d'erreur
    min_resolutions = {
        "mean": {
            "histogram": {},
            "kde": {}
        },
        "median": {
            "histogram": {},
            "kde": {}
        }
    }

    # Pour chaque niveau de qualité
    for quality in ["excellent", "good", "acceptable", "poor"]:
        # Seuil pour la moyenne
        mean_threshold = results["error_thresholds"]["mean"][quality]

        # Trouver la résolution minimale pour l'histogramme
        min_hist_bins = None
        for i, error in enumerate(results["histogram_mean_errors"]):
            if error <= mean_threshold:
                min_hist_bins = bin_counts[i]
                break

        # Trouver la résolution minimale pour la KDE
        min_kde_points = None
        for i, error in enumerate(results["kde_mean_errors"]):
            if error <= mean_threshold:
                min_kde_points = kde_points[i]
                break

        min_resolutions["mean"]["histogram"][quality] = min_hist_bins
        min_resolutions["mean"]["kde"][quality] = min_kde_points

        # Seuil pour la médiane
        median_threshold = results["error_thresholds"]["median"][quality]

        # Trouver la résolution minimale pour l'histogramme
        min_hist_bins = None
        for i, error in enumerate(results["histogram_median_errors"]):
            if error <= median_threshold:
                min_hist_bins = bin_counts[i]
                break

        # Trouver la résolution minimale pour la KDE
        min_kde_points = None
        for i, error in enumerate(results["kde_median_errors"]):
            if error <= median_threshold:
                min_kde_points = kde_points[i]
                break

        min_resolutions["median"]["histogram"][quality] = min_hist_bins
        min_resolutions["median"]["kde"][quality] = min_kde_points

    # Ajouter les résolutions minimales aux résultats
    results["min_resolutions"] = min_resolutions

    # Créer des recommandations
    recommendations = {
        "distribution_type": results["distribution_type"],
        "mean": {
            "histogram": {
                "min_bins_excellent": min_resolutions["mean"]["histogram"].get("excellent"),
                "min_bins_good": min_resolutions["mean"]["histogram"].get("good"),
                "min_bins_acceptable": min_resolutions["mean"]["histogram"].get("acceptable")
            },
            "kde": {
                "min_points_excellent": min_resolutions["mean"]["kde"].get("excellent"),
                "min_points_good": min_resolutions["mean"]["kde"].get("good"),
                "min_points_acceptable": min_resolutions["mean"]["kde"].get("acceptable")
            }
        },
        "median": {
            "histogram": {
                "min_bins_excellent": min_resolutions["median"]["histogram"].get("excellent"),
                "min_bins_good": min_resolutions["median"]["histogram"].get("good"),
                "min_bins_acceptable": min_resolutions["median"]["histogram"].get("acceptable")
            },
            "kde": {
                "min_points_excellent": min_resolutions["median"]["kde"].get("excellent"),
                "min_points_good": min_resolutions["median"]["kde"].get("good"),
                "min_points_acceptable": min_resolutions["median"]["kde"].get("acceptable")
            }
        }
    }

    # Ajouter les recommandations aux résultats
    results["recommendations"] = recommendations

    return results

def create_median_precision_report(data: np.ndarray,
                                 bin_counts: List[int] = [10, 20, 50, 100, 200],
                                 kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                 criteria: Optional[Dict[str, Any]] = None,
                                 save_path: Optional[str] = None,
                                 show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de la médiane.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de la médiane (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de la médiane
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_median_precision_criteria()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_median_precision(data, bin_counts, criteria)

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_median_precision(data, kde_points, criteria)

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_median(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_median_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de la médiane",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

def determine_optimal_resolution_for_mean(histogram_results: Dict[str, Any],
                                        kde_results: Dict[str, Any],
                                        quality_threshold: str = "good") -> Dict[str, Any]:
    """
    Détermine la résolution optimale pour l'estimation de la moyenne.

    Args:
        histogram_results: Résultats de l'évaluation pour les histogrammes
        kde_results: Résultats de l'évaluation pour les KDEs
        quality_threshold: Seuil de qualité minimal ('excellent', 'good', 'acceptable', 'poor')

    Returns:
        Dict[str, Any]: Résolutions optimales pour l'estimation de la moyenne
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

def create_mean_precision_report(data: np.ndarray,
                               bin_counts: List[int] = [10, 20, 50, 100, 200],
                               kde_points: List[int] = [100, 200, 500, 1000, 2000],
                               criteria: Optional[Dict[str, Any]] = None,
                               save_path: Optional[str] = None,
                               show_plot: bool = True) -> Dict[str, Any]:
    """
    Crée un rapport complet sur la précision de l'estimation de la moyenne.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester
        kde_points: Liste des nombres de points à tester
        criteria: Critères de précision pour l'estimation de la moyenne (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Rapport complet sur la précision de l'estimation de la moyenne
    """
    # Si les critères ne sont pas spécifiés, utiliser les critères par défaut
    if criteria is None:
        criteria = define_mean_precision_criteria()

    # Évaluer la précision pour les histogrammes
    histogram_results = evaluate_histogram_mean_precision(data, bin_counts, criteria)

    # Évaluer la précision pour les KDEs
    kde_results = evaluate_kde_mean_precision(data, kde_points, criteria)

    # Déterminer les résolutions optimales
    optimal_resolutions = determine_optimal_resolution_for_mean(histogram_results, kde_results)

    # Visualiser les résultats
    if save_path or show_plot:
        plot_mean_precision_evaluation(
            histogram_results,
            kde_results,
            title="Évaluation de la précision de l'estimation de la moyenne",
            save_path=save_path,
            show_plot=show_plot
        )

    # Créer le rapport
    report = {
        "criteria": criteria,
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

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Test des critères de précision pour l'estimation des paramètres statistiques ===")

    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité

    # Distribution gaussienne
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])

    # Distribution asymétrique (log-normale)
    lognormal_data = np.random.lognormal(mean=1.0, sigma=0.5, size=1000)

    # Tester les critères de précision sur différentes distributions
    for name, data in [("Gaussienne", gaussian_data),
                      ("Bimodale", bimodal_data),
                      ("Log-normale", lognormal_data)]:
        print(f"\nDistribution {name}:")

        # Test des critères de précision pour l'estimation de la moyenne
        print(f"  Précision de l'estimation de la moyenne:")

        # Définir les critères de précision pour la moyenne
        mean_criteria = define_mean_precision_criteria(relative_error_threshold=0.05)

        # Créer un rapport sur la précision de l'estimation de la moyenne
        mean_report = create_mean_precision_report(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            criteria=mean_criteria,
            save_path=f"mean_precision_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour la moyenne
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={mean_report['recommendations']['histogram']['min_bins']}, optimal_bins={mean_report['recommendations']['histogram']['optimal_bins']}, qualité={mean_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={mean_report['recommendations']['kde']['min_points']}, optimal_points={mean_report['recommendations']['kde']['optimal_points']}, qualité={mean_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {mean_report['recommendations']['preferred_method']}")

        # Test des critères de précision pour l'estimation de la médiane
        print(f"  Précision de l'estimation de la médiane:")

        # Définir les critères de précision pour la médiane
        median_criteria = define_median_precision_criteria(relative_error_threshold=0.05)

        # Créer un rapport sur la précision de l'estimation de la médiane
        median_report = create_median_precision_report(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            criteria=median_criteria,
            save_path=f"median_precision_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour la médiane
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={median_report['recommendations']['histogram']['min_bins']}, optimal_bins={median_report['recommendations']['histogram']['optimal_bins']}, qualité={median_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={median_report['recommendations']['kde']['min_points']}, optimal_points={median_report['recommendations']['kde']['optimal_points']}, qualité={median_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {median_report['recommendations']['preferred_method']}")

        # Test des seuils d'erreur acceptables pour les mesures de tendance centrale
        print(f"  Seuils d'erreur acceptables pour les mesures de tendance centrale:")

        # Créer un rapport sur les seuils d'erreur acceptables
        error_report = create_central_tendency_error_report(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"central_tendency_errors_{name.lower()}.png",
            show_plot=False
        )

        # Afficher le type de distribution
        print(f"    Type de distribution: {error_report['distribution_type']}")

        # Afficher les seuils d'erreur recommandés
        print(f"    Seuils d'erreur recommandés:")
        print(f"      Moyenne: excellent={error_report['error_thresholds']['mean']['excellent']:.1%}, good={error_report['error_thresholds']['mean']['good']:.1%}, acceptable={error_report['error_thresholds']['mean']['acceptable']:.1%}")
        print(f"      Médiane: excellent={error_report['error_thresholds']['median']['excellent']:.1%}, good={error_report['error_thresholds']['median']['good']:.1%}, acceptable={error_report['error_thresholds']['median']['acceptable']:.1%}")

        # Afficher les résolutions minimales recommandées
        print(f"    Résolutions minimales recommandées:")
        print(f"      Moyenne (histogramme): excellent={error_report['recommendations']['mean']['histogram']['min_bins_excellent']}, good={error_report['recommendations']['mean']['histogram']['min_bins_good']}, acceptable={error_report['recommendations']['mean']['histogram']['min_bins_acceptable']}")
        print(f"      Moyenne (KDE): excellent={error_report['recommendations']['mean']['kde']['min_points_excellent']}, good={error_report['recommendations']['mean']['kde']['min_points_good']}, acceptable={error_report['recommendations']['mean']['kde']['min_points_acceptable']}")
        print(f"      Médiane (histogramme): excellent={error_report['recommendations']['median']['histogram']['min_bins_excellent']}, good={error_report['recommendations']['median']['histogram']['min_bins_good']}, acceptable={error_report['recommendations']['median']['histogram']['min_bins_acceptable']}")
        print(f"      Médiane (KDE): excellent={error_report['recommendations']['median']['kde']['min_points_excellent']}, good={error_report['recommendations']['median']['kde']['min_points_good']}, acceptable={error_report['recommendations']['median']['kde']['min_points_acceptable']}")

        # Test des critères de précision pour l'estimation de l'écart-type (distributions normales)
        print(f"  Précision de l'estimation de l'écart-type (distribution normale):")

        # Créer un rapport sur la précision de l'estimation de l'écart-type
        std_report = create_std_precision_report_normal(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"std_precision_normal_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'écart-type
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={std_report['recommendations']['histogram']['min_bins']}, optimal_bins={std_report['recommendations']['histogram']['optimal_bins']}, qualité={std_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={std_report['recommendations']['kde']['min_points']}, optimal_points={std_report['recommendations']['kde']['optimal_points']}, qualité={std_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {std_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'écart-type
        print(f"    Seuils d'erreur pour l'écart-type (distribution normale):")
        thresholds = define_std_error_thresholds_normal()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

        # Test des critères de précision pour l'estimation de l'écart-type (distributions asymétriques)
        print(f"  Précision de l'estimation de l'écart-type (distribution asymétrique):")

        # Créer un rapport sur la précision de l'estimation de l'écart-type
        std_skewed_report = create_std_precision_report_skewed(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"std_precision_skewed_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'écart-type
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={std_skewed_report['recommendations']['histogram']['min_bins']}, optimal_bins={std_skewed_report['recommendations']['histogram']['optimal_bins']}, qualité={std_skewed_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={std_skewed_report['recommendations']['kde']['min_points']}, optimal_points={std_skewed_report['recommendations']['kde']['optimal_points']}, qualité={std_skewed_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {std_skewed_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'écart-type
        print(f"    Seuils d'erreur pour l'écart-type (distribution asymétrique):")
        thresholds = define_std_error_thresholds_skewed()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

        # Test des critères de précision pour l'estimation de l'écart-type (distributions multimodales)
        print(f"  Précision de l'estimation de l'écart-type (distribution multimodale):")

        # Créer un rapport sur la précision de l'estimation de l'écart-type
        std_multimodal_report = create_std_precision_report_multimodal(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"std_precision_multimodal_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'écart-type
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={std_multimodal_report['recommendations']['histogram']['min_bins']}, optimal_bins={std_multimodal_report['recommendations']['histogram']['optimal_bins']}, qualité={std_multimodal_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={std_multimodal_report['recommendations']['kde']['min_points']}, optimal_points={std_multimodal_report['recommendations']['kde']['optimal_points']}, qualité={std_multimodal_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {std_multimodal_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'écart-type
        print(f"    Seuils d'erreur pour l'écart-type (distribution multimodale):")
        thresholds = define_std_error_thresholds_multimodal()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

        # Test des critères de précision pour l'estimation de l'IQR (distributions symétriques)
        print(f"  Précision de l'estimation de l'IQR (distribution symétrique):")

        # Créer un rapport sur la précision de l'estimation de l'IQR
        iqr_symmetric_report = create_iqr_precision_report_symmetric(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"iqr_precision_symmetric_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'IQR
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={iqr_symmetric_report['recommendations']['histogram']['min_bins']}, optimal_bins={iqr_symmetric_report['recommendations']['histogram']['optimal_bins']}, qualité={iqr_symmetric_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={iqr_symmetric_report['recommendations']['kde']['min_points']}, optimal_points={iqr_symmetric_report['recommendations']['kde']['optimal_points']}, qualité={iqr_symmetric_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {iqr_symmetric_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'IQR
        print(f"    Seuils d'erreur pour l'IQR (distribution symétrique):")
        thresholds = define_iqr_error_thresholds_symmetric()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

        # Test des critères de précision pour l'estimation de l'IQR (distributions à queue lourde)
        print(f"  Précision de l'estimation de l'IQR (distribution à queue lourde):")

        # Créer un rapport sur la précision de l'estimation de l'IQR
        iqr_heavy_tailed_report = create_iqr_precision_report_heavy_tailed(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"iqr_precision_heavy_tailed_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'IQR
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={iqr_heavy_tailed_report['recommendations']['histogram']['min_bins']}, optimal_bins={iqr_heavy_tailed_report['recommendations']['histogram']['optimal_bins']}, qualité={iqr_heavy_tailed_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={iqr_heavy_tailed_report['recommendations']['kde']['min_points']}, optimal_points={iqr_heavy_tailed_report['recommendations']['kde']['optimal_points']}, qualité={iqr_heavy_tailed_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {iqr_heavy_tailed_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'IQR
        print(f"    Seuils d'erreur pour l'IQR (distribution à queue lourde):")
        thresholds = define_iqr_error_thresholds_heavy_tailed()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

        # Test des critères de précision pour l'estimation de l'IQR (distributions multimodales)
        print(f"  Précision de l'estimation de l'IQR (distribution multimodale):")

        # Créer un rapport sur la précision de l'estimation de l'IQR
        iqr_multimodal_report = create_iqr_precision_report_multimodal(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000],
            save_path=f"iqr_precision_multimodal_{name.lower()}.png",
            show_plot=False
        )

        # Afficher les recommandations pour l'IQR
        print(f"    Recommandations:")
        print(f"      Histogramme: min_bins={iqr_multimodal_report['recommendations']['histogram']['min_bins']}, optimal_bins={iqr_multimodal_report['recommendations']['histogram']['optimal_bins']}, qualité={iqr_multimodal_report['recommendations']['histogram']['quality']}")
        print(f"      KDE: min_points={iqr_multimodal_report['recommendations']['kde']['min_points']}, optimal_points={iqr_multimodal_report['recommendations']['kde']['optimal_points']}, qualité={iqr_multimodal_report['recommendations']['kde']['quality']}")
        print(f"      Méthode préférée: {iqr_multimodal_report['recommendations']['preferred_method']}")

        # Afficher les seuils d'erreur pour l'IQR
        print(f"    Seuils d'erreur pour l'IQR (distribution multimodale):")
        thresholds = define_iqr_error_thresholds_multimodal()
        print(f"      Excellent: {thresholds['excellent']:.1%}, Good: {thresholds['good']:.1%}, Acceptable: {thresholds['acceptable']:.1%}, Poor: {thresholds['poor']:.1%}")

    print("\nTest terminé avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")
