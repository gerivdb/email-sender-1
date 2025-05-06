#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'estimation des paramètres statistiques (moyenne, écart-type, asymétrie, aplatissement)
et l'analyse de l'impact de la résolution sur ces estimations.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, Optional, Any, Union, List, Tuple
import scipy.stats
from scipy.stats import shapiro, normaltest, anderson

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def estimate_from_raw_data(data: np.ndarray) -> Dict[str, float]:
    """
    Estime les paramètres statistiques à partir des données brutes.

    Args:
        data: Données brutes

    Returns:
        Dict[str, float]: Dictionnaire des paramètres statistiques
    """
    # Vérifier que les données ne sont pas vides
    if len(data) == 0:
        return {
            "mean": np.nan,
            "std": np.nan,
            "skewness": np.nan,
            "kurtosis": np.nan,
            "median": np.nan,
            "iqr": np.nan,
            "min": np.nan,
            "max": np.nan
        }

    # Calculer les paramètres statistiques
    mean = np.mean(data)
    std = np.std(data, ddof=1)  # ddof=1 pour l'estimateur non biaisé
    skewness = scipy.stats.skew(data)
    kurtosis = scipy.stats.kurtosis(data)  # Excès de kurtosis (0 pour une distribution normale)
    median = np.median(data)
    q1 = np.percentile(data, 25)
    q3 = np.percentile(data, 75)
    iqr = q3 - q1
    min_val = np.min(data)
    max_val = np.max(data)

    # Résultats
    return {
        "mean": mean,
        "std": std,
        "skewness": skewness,
        "kurtosis": kurtosis,
        "median": median,
        "iqr": iqr,
        "min": min_val,
        "max": max_val
    }

def estimate_from_histogram(hist_counts: np.ndarray,
                          bin_edges: np.ndarray) -> Dict[str, float]:
    """
    Estime les paramètres statistiques à partir d'un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme

    Returns:
        Dict[str, float]: Dictionnaire des paramètres statistiques
    """
    # Vérifier que les entrées sont valides
    if len(hist_counts) != len(bin_edges) - 1:
        raise ValueError("Le tableau hist_counts doit avoir une longueur égale à len(bin_edges) - 1")

    if np.sum(hist_counts) == 0:
        return {
            "mean": np.nan,
            "std": np.nan,
            "skewness": np.nan,
            "kurtosis": np.nan,
            "median": np.nan,
            "iqr": np.nan,
            "min": np.min(bin_edges),
            "max": np.max(bin_edges)
        }

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Normaliser les comptages si nécessaire
    if np.sum(hist_counts) != 1:
        hist_normalized = hist_counts / np.sum(hist_counts)
    else:
        hist_normalized = hist_counts

    # Calculer la moyenne
    mean = np.sum(bin_centers * hist_normalized)

    # Calculer l'écart-type
    variance = np.sum(hist_normalized * (bin_centers - mean) ** 2)
    std = np.sqrt(variance)

    # Calculer l'asymétrie (skewness)
    if std > 0:
        skewness = np.sum(hist_normalized * ((bin_centers - mean) / std) ** 3)
    else:
        skewness = np.nan

    # Calculer l'aplatissement (kurtosis)
    if std > 0:
        kurtosis = np.sum(hist_normalized * ((bin_centers - mean) / std) ** 4) - 3  # -3 pour l'excès de kurtosis
    else:
        kurtosis = np.nan

    # Calculer la médiane (approximation)
    cumsum = np.cumsum(hist_normalized)
    median_idx = np.searchsorted(cumsum, 0.5)
    if median_idx < len(bin_centers):
        median = bin_centers[median_idx]
    else:
        median = bin_centers[-1]

    # Calculer l'écart interquartile (IQR) (approximation)
    q1_idx = np.searchsorted(cumsum, 0.25)
    q3_idx = np.searchsorted(cumsum, 0.75)
    if q1_idx < len(bin_centers) and q3_idx < len(bin_centers):
        q1 = bin_centers[q1_idx]
        q3 = bin_centers[q3_idx]
        iqr = q3 - q1
    else:
        iqr = np.nan

    # Résultats
    return {
        "mean": mean,
        "std": std,
        "skewness": skewness,
        "kurtosis": kurtosis,
        "median": median,
        "iqr": iqr,
        "min": np.min(bin_edges),
        "max": np.max(bin_edges)
    }

def estimate_from_kde(data: np.ndarray,
                    num_points: int = 1000,
                    bandwidth_method: str = 'scott') -> Dict[str, float]:
    """
    Estime les paramètres statistiques à partir d'une estimation par noyau de la densité (KDE).

    Args:
        data: Données brutes
        num_points: Nombre de points pour l'évaluation de la KDE
        bandwidth_method: Méthode pour estimer la largeur de bande de la KDE

    Returns:
        Dict[str, float]: Dictionnaire des paramètres statistiques
    """
    # Vérifier que les données ne sont pas vides
    if len(data) == 0:
        return {
            "mean": np.nan,
            "std": np.nan,
            "skewness": np.nan,
            "kurtosis": np.nan,
            "median": np.nan,
            "iqr": np.nan,
            "min": np.nan,
            "max": np.nan
        }

    # Calculer la KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=bandwidth_method)

    # Créer une grille de points pour évaluer la KDE
    x_min, x_max = np.min(data), np.max(data)
    x_grid = np.linspace(x_min, x_max, num_points)

    # Évaluer la KDE sur la grille
    kde_values = kde(x_grid)

    # Normaliser les valeurs de la KDE
    kde_normalized = kde_values / np.sum(kde_values)

    # Calculer la moyenne
    mean = np.sum(x_grid * kde_normalized)

    # Calculer l'écart-type
    variance = np.sum(kde_normalized * (x_grid - mean) ** 2)
    std = np.sqrt(variance)

    # Calculer l'asymétrie (skewness)
    if std > 0:
        skewness = np.sum(kde_normalized * ((x_grid - mean) / std) ** 3)
    else:
        skewness = np.nan

    # Calculer l'aplatissement (kurtosis)
    if std > 0:
        kurtosis = np.sum(kde_normalized * ((x_grid - mean) / std) ** 4) - 3  # -3 pour l'excès de kurtosis
    else:
        kurtosis = np.nan

    # Calculer la médiane (approximation)
    cumsum = np.cumsum(kde_normalized)
    median_idx = np.searchsorted(cumsum, 0.5)
    if median_idx < len(x_grid):
        median = x_grid[median_idx]
    else:
        median = x_grid[-1]

    # Calculer l'écart interquartile (IQR) (approximation)
    q1_idx = np.searchsorted(cumsum, 0.25)
    q3_idx = np.searchsorted(cumsum, 0.75)
    if q1_idx < len(x_grid) and q3_idx < len(x_grid):
        q1 = x_grid[q1_idx]
        q3 = x_grid[q3_idx]
        iqr = q3 - q1
    else:
        iqr = np.nan

    # Résultats
    return {
        "mean": mean,
        "std": std,
        "skewness": skewness,
        "kurtosis": kurtosis,
        "median": median,
        "iqr": iqr,
        "min": x_min,
        "max": x_max
    }

def compare_estimation_methods(data: np.ndarray,
                             bin_counts: List[int] = [10, 20, 50, 100, 200],
                             kde_points: List[int] = [100, 200, 500, 1000, 2000]) -> Dict[str, Any]:
    """
    Compare les différentes méthodes d'estimation des paramètres statistiques.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester pour l'histogramme
        kde_points: Liste des nombres de points à tester pour la KDE

    Returns:
        Dict[str, Any]: Résultats de la comparaison
    """
    # Estimer les paramètres à partir des données brutes (référence)
    raw_params = estimate_from_raw_data(data)

    # Initialiser les résultats
    results = {
        "raw": raw_params,
        "histogram": {
            "bin_counts": bin_counts,
            "params": []
        },
        "kde": {
            "num_points": kde_points,
            "params": []
        }
    }

    # Estimer les paramètres à partir des histogrammes
    for num_bins in bin_counts:
        # Calculer l'histogramme
        hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)

        # Estimer les paramètres
        hist_params = estimate_from_histogram(hist_counts, bin_edges)

        # Stocker les résultats
        results["histogram"]["params"].append(hist_params)

    # Estimer les paramètres à partir des KDEs
    for num_points in kde_points:
        # Estimer les paramètres
        kde_params = estimate_from_kde(data, num_points=num_points)

        # Stocker les résultats
        results["kde"]["params"].append(kde_params)

    return results

def calculate_estimation_errors(results: Dict[str, Any]) -> Dict[str, Any]:
    """
    Calcule les erreurs d'estimation par rapport aux paramètres calculés à partir des données brutes.

    Args:
        results: Résultats de la comparaison des méthodes d'estimation

    Returns:
        Dict[str, Any]: Erreurs d'estimation
    """
    # Initialiser les erreurs
    errors = {
        "histogram": {
            "bin_counts": results["histogram"]["bin_counts"],
            "mean_error": [],
            "std_error": [],
            "skewness_error": [],
            "kurtosis_error": [],
            "median_error": [],
            "iqr_error": []
        },
        "kde": {
            "num_points": results["kde"]["num_points"],
            "mean_error": [],
            "std_error": [],
            "skewness_error": [],
            "kurtosis_error": [],
            "median_error": [],
            "iqr_error": []
        }
    }

    # Calculer les erreurs pour les histogrammes
    for hist_params in results["histogram"]["params"]:
        # Calculer les erreurs relatives
        mean_error = abs(hist_params["mean"] - results["raw"]["mean"]) / abs(results["raw"]["mean"]) if results["raw"]["mean"] != 0 else np.nan
        std_error = abs(hist_params["std"] - results["raw"]["std"]) / abs(results["raw"]["std"]) if results["raw"]["std"] != 0 else np.nan
        skewness_error = abs(hist_params["skewness"] - results["raw"]["skewness"]) / abs(results["raw"]["skewness"]) if results["raw"]["skewness"] != 0 else np.nan
        kurtosis_error = abs(hist_params["kurtosis"] - results["raw"]["kurtosis"]) / abs(results["raw"]["kurtosis"]) if results["raw"]["kurtosis"] != 0 else np.nan
        median_error = abs(hist_params["median"] - results["raw"]["median"]) / abs(results["raw"]["median"]) if results["raw"]["median"] != 0 else np.nan
        iqr_error = abs(hist_params["iqr"] - results["raw"]["iqr"]) / abs(results["raw"]["iqr"]) if results["raw"]["iqr"] != 0 else np.nan

        # Stocker les erreurs
        errors["histogram"]["mean_error"].append(mean_error)
        errors["histogram"]["std_error"].append(std_error)
        errors["histogram"]["skewness_error"].append(skewness_error)
        errors["histogram"]["kurtosis_error"].append(kurtosis_error)
        errors["histogram"]["median_error"].append(median_error)
        errors["histogram"]["iqr_error"].append(iqr_error)

    # Calculer les erreurs pour les KDEs
    for kde_params in results["kde"]["params"]:
        # Calculer les erreurs relatives
        mean_error = abs(kde_params["mean"] - results["raw"]["mean"]) / abs(results["raw"]["mean"]) if results["raw"]["mean"] != 0 else np.nan
        std_error = abs(kde_params["std"] - results["raw"]["std"]) / abs(results["raw"]["std"]) if results["raw"]["std"] != 0 else np.nan
        skewness_error = abs(kde_params["skewness"] - results["raw"]["skewness"]) / abs(results["raw"]["skewness"]) if results["raw"]["skewness"] != 0 else np.nan
        kurtosis_error = abs(kde_params["kurtosis"] - results["raw"]["kurtosis"]) / abs(results["raw"]["kurtosis"]) if results["raw"]["kurtosis"] != 0 else np.nan
        median_error = abs(kde_params["median"] - results["raw"]["median"]) / abs(results["raw"]["median"]) if results["raw"]["median"] != 0 else np.nan
        iqr_error = abs(kde_params["iqr"] - results["raw"]["iqr"]) / abs(results["raw"]["iqr"]) if results["raw"]["iqr"] != 0 else np.nan

        # Stocker les erreurs
        errors["kde"]["mean_error"].append(mean_error)
        errors["kde"]["std_error"].append(std_error)
        errors["kde"]["skewness_error"].append(skewness_error)
        errors["kde"]["kurtosis_error"].append(kurtosis_error)
        errors["kde"]["median_error"].append(median_error)
        errors["kde"]["iqr_error"].append(iqr_error)

    return errors

def plot_estimation_errors(errors: Dict[str, Any],
                         title: str = "Erreurs d'estimation des paramètres statistiques",
                         save_path: Optional[str] = None,
                         show_plot: bool = True) -> None:
    """
    Visualise les erreurs d'estimation des paramètres statistiques.

    Args:
        errors: Erreurs d'estimation
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(3, 2, figsize=(12, 15))

    # Paramètres à visualiser
    params = ["mean", "std", "skewness", "kurtosis", "median", "iqr"]

    # Pour chaque paramètre
    for i, param in enumerate(params):
        # Calculer l'indice du sous-graphique
        row = i // 2
        col = i % 2

        # Tracer les erreurs pour l'histogramme
        axes[row, col].plot(errors["histogram"]["bin_counts"],
                          errors["histogram"][f"{param}_error"],
                          'o-',
                          label='Histogramme')

        # Tracer les erreurs pour la KDE
        axes[row, col].plot(errors["kde"]["num_points"],
                          errors["kde"][f"{param}_error"],
                          's-',
                          label='KDE')

        # Configurer le sous-graphique
        axes[row, col].set_xscale('log')
        axes[row, col].set_yscale('log')
        axes[row, col].set_xlabel('Nombre de bins / points')
        axes[row, col].set_ylabel(f'Erreur relative ({param})')
        axes[row, col].set_title(f'Erreur d\'estimation de {param}')
        axes[row, col].grid(True, alpha=0.3)
        axes[row, col].legend()

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

def perform_normality_tests(data: np.ndarray) -> Dict[str, Any]:
    """
    Effectue des tests de normalité sur les données.

    Args:
        data: Données à tester

    Returns:
        Dict[str, Any]: Résultats des tests de normalité
    """
    # Vérifier que les données ne sont pas vides
    if len(data) < 3:
        return {
            "shapiro": {"statistic": np.nan, "p_value": np.nan},
            "dagostino": {"statistic": np.nan, "p_value": np.nan},
            "anderson": {"statistic": np.nan, "critical_values": np.nan, "significance_level": np.nan}
        }

    # Test de Shapiro-Wilk
    try:
        shapiro_stat, shapiro_p = shapiro(data)
    except:
        shapiro_stat, shapiro_p = np.nan, np.nan

    # Test de D'Agostino-Pearson
    try:
        dagostino_stat, dagostino_p = normaltest(data)
    except:
        dagostino_stat, dagostino_p = np.nan, np.nan

    # Test d'Anderson-Darling
    try:
        anderson_result = anderson(data)
        anderson_stat = anderson_result.statistic
        anderson_critical_values = anderson_result.critical_values
        anderson_significance_level = anderson_result.significance_level
    except:
        anderson_stat = np.nan
        anderson_critical_values = np.nan
        anderson_significance_level = np.nan

    # Résultats
    return {
        "shapiro": {"statistic": shapiro_stat, "p_value": shapiro_p},
        "dagostino": {"statistic": dagostino_stat, "p_value": dagostino_p},
        "anderson": {"statistic": anderson_stat, "critical_values": anderson_critical_values, "significance_level": anderson_significance_level}
    }

def perform_normality_tests_from_histogram(hist_counts: np.ndarray,
                                         bin_edges: np.ndarray,
                                         num_samples: int = 1000) -> Dict[str, Any]:
    """
    Effectue des tests de normalité à partir d'un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        num_samples: Nombre d'échantillons à générer pour les tests

    Returns:
        Dict[str, Any]: Résultats des tests de normalité
    """
    # Vérifier que les entrées sont valides
    if len(hist_counts) != len(bin_edges) - 1:
        raise ValueError("Le tableau hist_counts doit avoir une longueur égale à len(bin_edges) - 1")

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Normaliser les comptages si nécessaire
    if np.sum(hist_counts) != 1:
        hist_normalized = hist_counts / np.sum(hist_counts)
    else:
        hist_normalized = hist_counts

    # Générer des échantillons à partir de l'histogramme
    samples = np.random.choice(bin_centers, size=num_samples, p=hist_normalized)

    # Effectuer les tests de normalité
    return perform_normality_tests(samples)

def perform_normality_tests_from_kde(data: np.ndarray,
                                   num_points: int = 1000,
                                   num_samples: int = 1000,
                                   bandwidth_method: str = 'scott') -> Dict[str, Any]:
    """
    Effectue des tests de normalité à partir d'une estimation par noyau de la densité (KDE).

    Args:
        data: Données brutes
        num_points: Nombre de points pour l'évaluation de la KDE
        num_samples: Nombre d'échantillons à générer pour les tests
        bandwidth_method: Méthode pour estimer la largeur de bande de la KDE

    Returns:
        Dict[str, Any]: Résultats des tests de normalité
    """
    # Vérifier que les données ne sont pas vides
    if len(data) == 0:
        return {
            "shapiro": {"statistic": np.nan, "p_value": np.nan},
            "dagostino": {"statistic": np.nan, "p_value": np.nan},
            "anderson": {"statistic": np.nan, "critical_values": np.nan, "significance_level": np.nan}
        }

    # Calculer la KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=bandwidth_method)

    # Créer une grille de points pour évaluer la KDE
    x_min, x_max = np.min(data), np.max(data)
    x_grid = np.linspace(x_min, x_max, num_points)

    # Évaluer la KDE sur la grille
    kde_values = kde(x_grid)

    # Normaliser les valeurs de la KDE
    kde_normalized = kde_values / np.sum(kde_values)

    # Générer des échantillons à partir de la KDE
    samples = np.random.choice(x_grid, size=num_samples, p=kde_normalized)

    # Effectuer les tests de normalité
    return perform_normality_tests(samples)

def compare_normality_tests(data: np.ndarray,
                          bin_counts: List[int] = [10, 20, 50, 100, 200],
                          kde_points: List[int] = [100, 200, 500, 1000, 2000]) -> Dict[str, Any]:
    """
    Compare les résultats des tests de normalité pour différentes méthodes d'estimation.

    Args:
        data: Données brutes
        bin_counts: Liste des nombres de bins à tester pour l'histogramme
        kde_points: Liste des nombres de points à tester pour la KDE

    Returns:
        Dict[str, Any]: Résultats de la comparaison
    """
    # Effectuer les tests de normalité sur les données brutes (référence)
    raw_tests = perform_normality_tests(data)

    # Initialiser les résultats
    results = {
        "raw": raw_tests,
        "histogram": {
            "bin_counts": bin_counts,
            "shapiro_p": [],
            "dagostino_p": [],
            "anderson_stat": []
        },
        "kde": {
            "num_points": kde_points,
            "shapiro_p": [],
            "dagostino_p": [],
            "anderson_stat": []
        }
    }

    # Effectuer les tests de normalité pour les histogrammes
    for num_bins in bin_counts:
        # Calculer l'histogramme
        hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)

        # Effectuer les tests de normalité
        hist_tests = perform_normality_tests_from_histogram(hist_counts, bin_edges)

        # Stocker les résultats
        results["histogram"]["shapiro_p"].append(hist_tests["shapiro"]["p_value"])
        results["histogram"]["dagostino_p"].append(hist_tests["dagostino"]["p_value"])
        results["histogram"]["anderson_stat"].append(hist_tests["anderson"]["statistic"])

    # Effectuer les tests de normalité pour les KDEs
    for num_points in kde_points:
        # Effectuer les tests de normalité
        kde_tests = perform_normality_tests_from_kde(data, num_points=num_points)

        # Stocker les résultats
        results["kde"]["shapiro_p"].append(kde_tests["shapiro"]["p_value"])
        results["kde"]["dagostino_p"].append(kde_tests["dagostino"]["p_value"])
        results["kde"]["anderson_stat"].append(kde_tests["anderson"]["statistic"])

    return results

def plot_normality_tests_results(results: Dict[str, Any],
                               title: str = "Résultats des tests de normalité",
                               save_path: Optional[str] = None,
                               show_plot: bool = True) -> None:
    """
    Visualise les résultats des tests de normalité.

    Args:
        results: Résultats de la comparaison des tests de normalité
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(10, 15))

    # Tracer les p-values du test de Shapiro-Wilk
    axes[0].axhline(y=results["raw"]["shapiro"]["p_value"], color='r', linestyle='--', label='Données brutes')
    axes[0].axhline(y=0.05, color='k', linestyle=':', label='Seuil de signification (0.05)')
    axes[0].plot(results["histogram"]["bin_counts"], results["histogram"]["shapiro_p"], 'o-', label='Histogramme')
    axes[0].plot(results["kde"]["num_points"], results["kde"]["shapiro_p"], 's-', label='KDE')
    axes[0].set_xscale('log')
    axes[0].set_xlabel('Nombre de bins / points')
    axes[0].set_ylabel('p-value')
    axes[0].set_title('Test de Shapiro-Wilk')
    axes[0].grid(True, alpha=0.3)
    axes[0].legend()

    # Tracer les p-values du test de D'Agostino-Pearson
    axes[1].axhline(y=results["raw"]["dagostino"]["p_value"], color='r', linestyle='--', label='Données brutes')
    axes[1].axhline(y=0.05, color='k', linestyle=':', label='Seuil de signification (0.05)')
    axes[1].plot(results["histogram"]["bin_counts"], results["histogram"]["dagostino_p"], 'o-', label='Histogramme')
    axes[1].plot(results["kde"]["num_points"], results["kde"]["dagostino_p"], 's-', label='KDE')
    axes[1].set_xscale('log')
    axes[1].set_xlabel('Nombre de bins / points')
    axes[1].set_ylabel('p-value')
    axes[1].set_title('Test de D\'Agostino-Pearson')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()

    # Tracer les statistiques du test d'Anderson-Darling
    axes[2].axhline(y=results["raw"]["anderson"]["statistic"], color='r', linestyle='--', label='Données brutes')
    axes[2].plot(results["histogram"]["bin_counts"], results["histogram"]["anderson_stat"], 'o-', label='Histogramme')
    axes[2].plot(results["kde"]["num_points"], results["kde"]["anderson_stat"], 's-', label='KDE')
    axes[2].set_xscale('log')
    axes[2].set_xlabel('Nombre de bins / points')
    axes[2].set_ylabel('Statistique')
    axes[2].set_title('Test d\'Anderson-Darling')
    axes[2].grid(True, alpha=0.3)
    axes[2].legend()

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

def determine_critical_resolution(results: Dict[str, Any],
                                threshold: float = 0.05,
                                test_type: str = "shapiro") -> Dict[str, Any]:
    """
    Détermine la résolution critique pour la fiabilité des tests statistiques.

    Args:
        results: Résultats de la comparaison des tests de normalité
        threshold: Seuil de signification
        test_type: Type de test ('shapiro', 'dagostino')

    Returns:
        Dict[str, Any]: Résolutions critiques
    """
    # Vérifier que le type de test est valide
    if test_type not in ["shapiro", "dagostino"]:
        raise ValueError(f"Type de test inconnu: {test_type}")

    # Référence (p-value des données brutes)
    if test_type == "shapiro":
        reference_p = results["raw"]["shapiro"]["p_value"]
    else:  # dagostino
        reference_p = results["raw"]["dagostino"]["p_value"]

    # Déterminer si les données sont normales selon le test de référence
    is_normal = reference_p > threshold

    # Initialiser les résultats
    critical_resolution = {
        "histogram": {
            "min_bins": None,
            "optimal_bins": None
        },
        "kde": {
            "min_points": None,
            "optimal_points": None
        },
        "is_normal": is_normal,
        "reference_p": reference_p
    }

    # Déterminer la résolution critique pour l'histogramme
    for i, num_bins in enumerate(results["histogram"]["bin_counts"]):
        if test_type == "shapiro":
            p_value = results["histogram"]["shapiro_p"][i]
        else:  # dagostino
            p_value = results["histogram"]["dagostino_p"][i]

        # Si les données sont normales, on cherche la résolution minimale qui donne un résultat normal
        if is_normal and p_value > threshold and critical_resolution["histogram"]["min_bins"] is None:
            critical_resolution["histogram"]["min_bins"] = num_bins

        # Si les données ne sont pas normales, on cherche la résolution minimale qui donne un résultat non normal
        if not is_normal and p_value <= threshold and critical_resolution["histogram"]["min_bins"] is None:
            critical_resolution["histogram"]["min_bins"] = num_bins

        # Chercher la résolution qui donne la p-value la plus proche de la référence
        if critical_resolution["histogram"]["optimal_bins"] is None or abs(p_value - reference_p) < abs(results["histogram"]["shapiro_p" if test_type == "shapiro" else "dagostino_p"][results["histogram"]["bin_counts"].index(critical_resolution["histogram"]["optimal_bins"])] - reference_p):
            critical_resolution["histogram"]["optimal_bins"] = num_bins

    # Déterminer la résolution critique pour la KDE
    for i, num_points in enumerate(results["kde"]["num_points"]):
        if test_type == "shapiro":
            p_value = results["kde"]["shapiro_p"][i]
        else:  # dagostino
            p_value = results["kde"]["dagostino_p"][i]

        # Si les données sont normales, on cherche la résolution minimale qui donne un résultat normal
        if is_normal and p_value > threshold and critical_resolution["kde"]["min_points"] is None:
            critical_resolution["kde"]["min_points"] = num_points

        # Si les données ne sont pas normales, on cherche la résolution minimale qui donne un résultat non normal
        if not is_normal and p_value <= threshold and critical_resolution["kde"]["min_points"] is None:
            critical_resolution["kde"]["min_points"] = num_points

        # Chercher la résolution qui donne la p-value la plus proche de la référence
        if critical_resolution["kde"]["optimal_points"] is None or abs(p_value - reference_p) < abs(results["kde"]["shapiro_p" if test_type == "shapiro" else "dagostino_p"][results["kde"]["num_points"].index(critical_resolution["kde"]["optimal_points"])] - reference_p):
            critical_resolution["kde"]["optimal_points"] = num_points

    return critical_resolution

def plot_parameter_vs_resolution(results: Dict[str, Any],
                               parameter: str = "mean",
                               title: Optional[str] = None,
                               save_path: Optional[str] = None,
                               show_plot: bool = True) -> None:
    """
    Visualise l'évolution d'un paramètre statistique en fonction de la résolution.

    Args:
        results: Résultats de la comparaison des méthodes d'estimation
        parameter: Paramètre à visualiser ('mean', 'std', 'skewness', 'kurtosis', 'median', 'iqr')
        title: Titre du graphique (optionnel)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Vérifier que le paramètre est valide
    if parameter not in ["mean", "std", "skewness", "kurtosis", "median", "iqr"]:
        raise ValueError(f"Paramètre inconnu: {parameter}")

    # Créer la figure
    fig, ax = plt.subplots(figsize=(10, 6))

    # Extraire les valeurs du paramètre pour l'histogramme
    hist_values = [params[parameter] for params in results["histogram"]["params"]]

    # Extraire les valeurs du paramètre pour la KDE
    kde_values = [params[parameter] for params in results["kde"]["params"]]

    # Tracer la valeur de référence
    ax.axhline(y=results["raw"][parameter], color='r', linestyle='--', label='Valeur réelle')

    # Tracer les valeurs pour l'histogramme
    ax.plot(results["histogram"]["bin_counts"], hist_values, 'o-', label='Histogramme')

    # Tracer les valeurs pour la KDE
    ax.plot(results["kde"]["num_points"], kde_values, 's-', label='KDE')

    # Configurer le graphique
    ax.set_xscale('log')
    ax.set_xlabel('Nombre de bins / points')
    ax.set_ylabel(f'{parameter}')
    if title is None:
        title = f'Évolution de {parameter} en fonction de la résolution'
    ax.set_title(title)
    ax.grid(True, alpha=0.3)
    ax.legend()

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Test des fonctions d'estimation des paramètres statistiques ===")

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

    # Tester les fonctions d'estimation sur différentes distributions
    for name, data in [("Gaussienne", gaussian_data),
                      ("Bimodale", bimodal_data),
                      ("Log-normale", lognormal_data)]:
        print(f"\nDistribution {name}:")

        # Estimer les paramètres à partir des données brutes
        raw_params = estimate_from_raw_data(data)
        print(f"  Paramètres réels:")
        print(f"    Moyenne: {raw_params['mean']:.4f}")
        print(f"    Écart-type: {raw_params['std']:.4f}")
        print(f"    Asymétrie: {raw_params['skewness']:.4f}")
        print(f"    Aplatissement: {raw_params['kurtosis']:.4f}")
        print(f"    Médiane: {raw_params['median']:.4f}")
        print(f"    IQR: {raw_params['iqr']:.4f}")

        # Comparer les différentes méthodes d'estimation
        results = compare_estimation_methods(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000]
        )

        # Calculer les erreurs d'estimation
        errors = calculate_estimation_errors(results)

        # Visualiser les erreurs d'estimation
        plot_estimation_errors(
            errors,
            title=f"Erreurs d'estimation des paramètres statistiques - Distribution {name}",
            save_path=f"estimation_errors_{name.lower()}.png",
            show_plot=False
        )

        # Visualiser l'évolution des paramètres en fonction de la résolution
        for param in ["mean", "std", "skewness", "kurtosis"]:
            plot_parameter_vs_resolution(
                results,
                parameter=param,
                title=f"Évolution de {param} en fonction de la résolution - Distribution {name}",
                save_path=f"parameter_{param}_{name.lower()}.png",
                show_plot=False
            )

        # Effectuer les tests de normalité
        print(f"  Tests de normalité:")
        normality_results = compare_normality_tests(
            data,
            bin_counts=[10, 20, 50, 100, 200],
            kde_points=[100, 200, 500, 1000, 2000]
        )

        # Afficher les résultats des tests de normalité
        print(f"    Test de Shapiro-Wilk (données brutes): p-value = {normality_results['raw']['shapiro']['p_value']:.4f}")
        print(f"    Test de D'Agostino-Pearson (données brutes): p-value = {normality_results['raw']['dagostino']['p_value']:.4f}")
        print(f"    Test d'Anderson-Darling (données brutes): statistique = {normality_results['raw']['anderson']['statistic']:.4f}")

        # Visualiser les résultats des tests de normalité
        plot_normality_tests_results(
            normality_results,
            title=f"Résultats des tests de normalité - Distribution {name}",
            save_path=f"normality_tests_{name.lower()}.png",
            show_plot=False
        )

        # Déterminer les résolutions critiques
        critical_resolution_shapiro = determine_critical_resolution(
            normality_results,
            threshold=0.05,
            test_type="shapiro"
        )

        critical_resolution_dagostino = determine_critical_resolution(
            normality_results,
            threshold=0.05,
            test_type="dagostino"
        )

        # Afficher les résolutions critiques
        print(f"    Résolutions critiques (Shapiro-Wilk):")
        print(f"      Les données sont {'normales' if critical_resolution_shapiro['is_normal'] else 'non normales'} selon le test de référence (p-value = {critical_resolution_shapiro['reference_p']:.4f})")
        print(f"      Histogramme: min_bins = {critical_resolution_shapiro['histogram']['min_bins']}, optimal_bins = {critical_resolution_shapiro['histogram']['optimal_bins']}")
        print(f"      KDE: min_points = {critical_resolution_shapiro['kde']['min_points']}, optimal_points = {critical_resolution_shapiro['kde']['optimal_points']}")

        print(f"    Résolutions critiques (D'Agostino-Pearson):")
        print(f"      Les données sont {'normales' if critical_resolution_dagostino['is_normal'] else 'non normales'} selon le test de référence (p-value = {critical_resolution_dagostino['reference_p']:.4f})")
        print(f"      Histogramme: min_bins = {critical_resolution_dagostino['histogram']['min_bins']}, optimal_bins = {critical_resolution_dagostino['histogram']['optimal_bins']}")
        print(f"      KDE: min_points = {critical_resolution_dagostino['kde']['min_points']}, optimal_points = {critical_resolution_dagostino['kde']['optimal_points']}")

    print("\nTest terminé avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")
