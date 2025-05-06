#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'algorithme adaptatif de maximisation de la résolution des histogrammes.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, List, Tuple, Optional, Any
from scipy.signal import find_peaks
import scipy.stats

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from resolution_metrics import (
    calculate_fwhm,
    calculate_max_slope_resolution,
    calculate_curvature_resolution,
    calculate_relative_resolution,
    analyze_bin_count_impact_on_resolution,
    compare_binning_strategies_resolution
)

def detect_distribution_characteristics(data: np.ndarray) -> Dict[str, Any]:
    """
    Détecte les caractéristiques importantes de la distribution pour optimiser le binning.

    Args:
        data: Données à analyser

    Returns:
        Dict[str, Any]: Caractéristiques de la distribution
    """
    # Calculer les statistiques de base
    mean = np.mean(data)
    median = np.median(data)
    std = np.std(data)
    min_val = np.min(data)
    max_val = np.max(data)
    range_val = max_val - min_val
    iqr = np.percentile(data, 75) - np.percentile(data, 25)

    # Calculer les moments statistiques
    skewness = scipy.stats.skew(data)
    kurtosis = scipy.stats.kurtosis(data, fisher=False)  # Fisher=False donne le kurtosis "brut" (3 pour une normale)

    # Détecter la multimodalité
    # Générer un histogramme avec un nombre élevé de bins pour détecter les modes
    hist, bin_edges = np.histogram(data, bins=min(100, len(data) // 10), density=True)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Normaliser l'histogramme
    hist_max = np.max(hist)
    hist_normalized = hist / hist_max if hist_max > 0 else hist

    # Trouver les pics
    peaks, properties = find_peaks(
        hist_normalized,
        prominence=0.1,  # Prominence minimale pour être considéré comme un pic
        height=0.2,      # Hauteur minimale pour être considéré comme un pic
        distance=3       # Distance minimale entre les pics en nombre de bins
    )

    # Filtrer les pics trop proches en valeur
    if len(peaks) > 1:
        # Trier les pics par hauteur décroissante
        peak_heights = hist_normalized[peaks]
        sorted_indices = np.argsort(-peak_heights)
        sorted_peaks = peaks[sorted_indices]

        # Filtrer les pics
        filtered_peaks = [sorted_peaks[0]]
        for peak in sorted_peaks[1:]:
            # Vérifier si le pic est suffisamment distant des pics déjà retenus
            min_distance = np.min(np.abs(bin_centers[peak] - bin_centers[filtered_peaks]))
            if min_distance > range_val * 0.1:  # 10% de la plage des données
                filtered_peaks.append(peak)

        peaks = np.array(filtered_peaks)

    # Déterminer le type de distribution
    is_multimodal = len(peaks) > 1
    is_asymmetric = abs(skewness) > 0.5
    is_heavy_tailed = kurtosis > 3.5
    is_light_tailed = kurtosis < 2.5

    # Calculer le ratio entre l'écart-type et l'IQR (utile pour détecter les outliers)
    std_iqr_ratio = std / iqr if iqr > 0 else float('inf')

    # Calculer le ratio entre la moyenne et la médiane (utile pour détecter l'asymétrie)
    mean_median_ratio = mean / median if median != 0 else float('inf')

    # Résultats
    return {
        "basic_stats": {
            "mean": mean,
            "median": median,
            "std": std,
            "min": min_val,
            "max": max_val,
            "range": range_val,
            "iqr": iqr
        },
        "moments": {
            "skewness": skewness,
            "kurtosis": kurtosis
        },
        "modality": {
            "is_multimodal": is_multimodal,
            "num_modes": len(peaks),
            "mode_positions": bin_centers[peaks].tolist() if len(peaks) > 0 else [],
            "mode_heights": hist_normalized[peaks].tolist() if len(peaks) > 0 else []
        },
        "distribution_type": {
            "is_asymmetric": is_asymmetric,
            "is_heavy_tailed": is_heavy_tailed,
            "is_light_tailed": is_light_tailed,
            "std_iqr_ratio": std_iqr_ratio,
            "mean_median_ratio": mean_median_ratio
        }
    }

def create_adaptive_binning(data: np.ndarray,
                          target_resolution: str = "high",
                          max_bins: int = 100) -> Tuple[np.ndarray, Dict[str, Any]]:
    """
    Crée un binning adaptatif qui maximise la résolution en fonction des caractéristiques de la distribution.

    Args:
        data: Données à analyser
        target_resolution: Niveau de résolution cible ("high", "medium", "low")
        max_bins: Nombre maximum de bins

    Returns:
        Tuple[np.ndarray, Dict[str, Any]]: Limites des bins et métadonnées
    """
    # Détecter les caractéristiques de la distribution
    characteristics = detect_distribution_characteristics(data)

    # Déterminer la stratégie de binning de base en fonction des caractéristiques
    if characteristics["modality"]["is_multimodal"]:
        base_strategy = "quantile"  # Le binning par quantiles est souvent meilleur pour les distributions multimodales
    elif characteristics["distribution_type"]["is_heavy_tailed"] or characteristics["distribution_type"]["is_asymmetric"]:
        base_strategy = "logarithmic"  # Le binning logarithmique est souvent meilleur pour les distributions asymétriques ou à queue lourde
    else:
        base_strategy = "uniform"  # Le binning uniforme est souvent meilleur pour les distributions quasi-normales

    # Déterminer le nombre de bins en fonction du niveau de résolution cible
    n = len(data)
    std = characteristics["basic_stats"]["std"]
    iqr = characteristics["basic_stats"]["iqr"]

    # Calculer les règles empiriques pour le nombre de bins
    sturges_rule = int(np.ceil(np.log2(n) + 1))
    scott_rule = int(np.ceil(3.5 * std * n**(-1/3)))
    freedman_diaconis_rule = int(np.ceil(2 * iqr * n**(-1/3)))

    # Ajuster le nombre de bins en fonction du niveau de résolution cible
    if target_resolution == "high":
        num_bins = max(sturges_rule, scott_rule, freedman_diaconis_rule)
        num_bins = min(num_bins * 2, max_bins)  # Doubler pour une haute résolution, mais limiter au maximum
    elif target_resolution == "medium":
        num_bins = np.median([sturges_rule, scott_rule, freedman_diaconis_rule])
        num_bins = int(num_bins)
    else:  # "low"
        num_bins = min(sturges_rule, scott_rule, freedman_diaconis_rule)
        num_bins = max(num_bins // 2, 5)  # Diviser par 2 pour une basse résolution, mais au moins 5 bins

    # Générer les limites des bins selon la stratégie de base
    if base_strategy == "uniform":
        bin_edges = np.linspace(min(data), max(data), num_bins + 1)
    elif base_strategy == "logarithmic":
        # Vérifier que les données sont positives pour le binning logarithmique
        if np.min(data) <= 0:
            # Décaler les données pour qu'elles soient toutes positives
            data_shift = np.abs(np.min(data)) + 1e-5
            data_log = data + data_shift
            shift_applied = True
        else:
            data_log = data.copy()
            shift_applied = False

        bin_edges = np.logspace(np.log10(min(data_log)), np.log10(max(data_log)), num_bins + 1)

        # Si un décalage a été appliqué, le retirer des limites des bins
        if shift_applied:
            bin_edges = bin_edges - data_shift
    elif base_strategy == "quantile":
        bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
    else:
        raise ValueError(f"Stratégie de binning inconnue: {base_strategy}")

    # Métadonnées
    metadata = {
        "characteristics": characteristics,
        "base_strategy": base_strategy,
        "num_bins": num_bins,
        "target_resolution": target_resolution,
        "empirical_rules": {
            "sturges": sturges_rule,
            "scott": scott_rule,
            "freedman_diaconis": freedman_diaconis_rule
        }
    }

    return bin_edges, metadata

def evaluate_adaptive_binning_resolution(data: np.ndarray,
                                       target_resolution: str = "high",
                                       max_bins: int = 100,
                                       compare_with_standard: bool = True) -> Dict[str, Any]:
    """
    Évalue la résolution obtenue avec le binning adaptatif et compare avec les stratégies standard.

    Args:
        data: Données à analyser
        target_resolution: Niveau de résolution cible ("high", "medium", "low")
        max_bins: Nombre maximum de bins
        compare_with_standard: Si True, compare avec les stratégies standard

    Returns:
        Dict[str, Any]: Résultats de l'évaluation
    """
    # Créer le binning adaptatif
    bin_edges, metadata = create_adaptive_binning(data, target_resolution, max_bins)

    # Calculer l'histogramme
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Normaliser l'histogramme
    if np.sum(bin_counts) > 0:
        bin_counts = bin_counts / np.max(bin_counts)

    # Calculer les métriques de résolution
    fwhm_results = calculate_fwhm(bin_counts, bin_edges)
    slope_results = calculate_max_slope_resolution(bin_counts, bin_edges)
    curvature_results = calculate_curvature_resolution(bin_counts, bin_edges)
    relative_resolution = calculate_relative_resolution(bin_counts, bin_edges)

    # Résultats pour le binning adaptatif
    adaptive_results = {
        "bin_edges": bin_edges,
        "bin_counts": bin_counts,
        "num_bins": len(bin_edges) - 1,
        "peaks": fwhm_results.get("peaks", []),
        "num_peaks_fwhm": len(fwhm_results.get("peaks", [])),
        "fwhm_values": fwhm_results.get("fwhm_values", []),
        "mean_fwhm": fwhm_results.get("mean_fwhm_values", 0),
        "max_slopes": slope_results.get("max_slopes", []),
        "max_curvatures": curvature_results.get("max_curvatures", []),
        "relative_resolution": relative_resolution,
        "metadata": metadata
    }

    # Résultats complets
    results = {
        "adaptive": adaptive_results
    }

    # Comparer avec les stratégies standard si demandé
    if compare_with_standard:
        # Nombre de bins pour les stratégies standard (même que pour l'adaptatif)
        num_bins = len(bin_edges) - 1

        # Comparer avec les stratégies standard
        standard_strategies = ["uniform", "quantile", "logarithmic"]
        standard_results = compare_binning_strategies_resolution(data, standard_strategies, num_bins)

        # Ajouter les résultats des stratégies standard
        for strategy, result in standard_results.items():
            results[strategy] = result

    return results

def plot_adaptive_binning_resolution(evaluation_results: Dict[str, Any],
                                   save_path: Optional[str] = None,
                                   show_plot: bool = True) -> None:
    """
    Visualise les résultats de l'évaluation du binning adaptatif.

    Args:
        evaluation_results: Résultats de l'évaluation
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les données
    adaptive_results = evaluation_results["adaptive"]
    metadata = adaptive_results["metadata"]
    characteristics = metadata["characteristics"]

    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(12, 10))

    # Graphique 1: Histogrammes
    ax1 = axes[0]

    # Tracer l'histogramme adaptatif
    bin_edges = adaptive_results["bin_edges"]
    bin_counts = adaptive_results["bin_counts"]
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    ax1.plot(bin_centers, bin_counts, '-', color='blue', linewidth=2, label='Adaptatif')

    # Tracer les histogrammes des stratégies standard si disponibles
    standard_strategies = ["uniform", "quantile", "logarithmic"]
    colors = ['red', 'green', 'purple']

    for i, strategy in enumerate(standard_strategies):
        if strategy in evaluation_results:
            result = evaluation_results[strategy]
            if "bin_edges" in result and "bin_counts" in result:
                std_bin_edges = result["bin_edges"]
                std_bin_counts = result["bin_counts"]
                std_bin_centers = (std_bin_edges[:-1] + std_bin_edges[1:]) / 2

                ax1.plot(std_bin_centers, std_bin_counts, '--', color=colors[i], alpha=0.7, label=strategy.capitalize())

    ax1.set_xlabel('Valeur')
    ax1.set_ylabel('Fréquence normalisée')
    ax1.set_title('Comparaison des histogrammes')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Graphique 2: Métriques de résolution
    ax2 = axes[1]

    # Préparer les données pour le graphique à barres
    strategies = ["Adaptatif"] + [s.capitalize() for s in standard_strategies if s in evaluation_results]
    num_peaks = [adaptive_results["num_peaks_fwhm"]]
    mean_fwhms = [adaptive_results["mean_fwhm"]]

    # Traiter les résolutions relatives avec précaution
    rel_res_adaptive = adaptive_results["relative_resolution"]
    if isinstance(rel_res_adaptive, dict):
        # Si c'est un dictionnaire, essayer d'extraire la valeur
        rel_res_value = rel_res_adaptive.get("relative_resolution")
        if isinstance(rel_res_value, (int, float)):
            relative_resolutions = [rel_res_value]
        else:
            relative_resolutions = [0]  # Valeur par défaut
    elif isinstance(rel_res_adaptive, (int, float)):
        relative_resolutions = [rel_res_adaptive]
    else:
        relative_resolutions = [0]  # Valeur par défaut

    for strategy in standard_strategies:
        if strategy in evaluation_results:
            result = evaluation_results[strategy]
            num_peaks.append(len(result.get("peaks", [])))
            mean_fwhms.append(result.get("mean_fwhm", 0))

            # Traiter la résolution relative avec précaution
            rel_res = result.get("relative_resolution")
            if isinstance(rel_res, dict):
                # Si c'est un dictionnaire, essayer d'extraire la valeur
                rel_res_value = rel_res.get("relative_resolution")
                if isinstance(rel_res_value, (int, float)):
                    relative_resolutions.append(rel_res_value)
                else:
                    relative_resolutions.append(0)  # Valeur par défaut
            elif isinstance(rel_res, (int, float)):
                relative_resolutions.append(rel_res)
            else:
                relative_resolutions.append(0)  # Valeur par défaut

    # Créer le graphique à barres
    x = np.arange(len(strategies))
    width = 0.25

    ax2.bar(x - width, num_peaks, width, label='Nombre de pics', color='blue')
    ax2.bar(x, mean_fwhms, width, label='FWHM moyenne', color='green')
    ax2.bar(x + width, relative_resolutions, width, label='Résolution relative', color='red')

    ax2.set_xlabel('Stratégie de binning')
    ax2.set_ylabel('Valeur')
    ax2.set_title('Comparaison des métriques de résolution')
    ax2.set_xticks(x)
    ax2.set_xticklabels(strategies)
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    # Ajouter des informations sur les caractéristiques de la distribution
    plt.figtext(0.5, 0.01,
               f"Distribution: {'Multimodale' if characteristics['modality']['is_multimodal'] else 'Unimodale'}, "
               f"{'Asymétrique' if characteristics['distribution_type']['is_asymmetric'] else 'Symétrique'}, "
               f"Skewness={characteristics['moments']['skewness']:.2f}, "
               f"Kurtosis={characteristics['moments']['kurtosis']:.2f}",
               ha='center', fontsize=10)

    plt.tight_layout(rect=[0, 0.03, 1, 0.97])

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
    print("=== Algorithme adaptatif pour maximiser la résolution ===")

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

    # Évaluer la résolution pour la distribution gaussienne
    print("\nÉvaluation pour la distribution gaussienne...")
    gaussian_evaluation = evaluate_adaptive_binning_resolution(
        gaussian_data,
        target_resolution="high",
        max_bins=50,
        compare_with_standard=True
    )

    # Visualiser les résultats
    plot_adaptive_binning_resolution(
        gaussian_evaluation,
        save_path="adaptive_binning_resolution_gaussian.png",
        show_plot=False
    )

    # Évaluer la résolution pour la distribution bimodale
    print("\nÉvaluation pour la distribution bimodale...")
    bimodal_evaluation = evaluate_adaptive_binning_resolution(
        bimodal_data,
        target_resolution="high",
        max_bins=50,
        compare_with_standard=True
    )

    # Visualiser les résultats
    plot_adaptive_binning_resolution(
        bimodal_evaluation,
        save_path="adaptive_binning_resolution_bimodal.png",
        show_plot=False
    )

    # Évaluer la résolution pour la distribution asymétrique
    print("\nÉvaluation pour la distribution asymétrique (log-normale)...")
    lognormal_evaluation = evaluate_adaptive_binning_resolution(
        lognormal_data,
        target_resolution="high",
        max_bins=50,
        compare_with_standard=True
    )

    # Visualiser les résultats
    plot_adaptive_binning_resolution(
        lognormal_evaluation,
        save_path="adaptive_binning_resolution_lognormal.png",
        show_plot=False
    )

    # Afficher les résultats
    print("\nRésultats pour la distribution gaussienne:")
    print(f"Stratégie de base: {gaussian_evaluation['adaptive']['metadata']['base_strategy']}")
    print(f"Nombre de bins: {gaussian_evaluation['adaptive']['num_bins']}")
    print(f"Nombre de pics détectés: {gaussian_evaluation['adaptive']['num_peaks_fwhm']}")
    print(f"Résolution relative: {gaussian_evaluation['adaptive']['relative_resolution']}")

    print("\nRésultats pour la distribution bimodale:")
    print(f"Stratégie de base: {bimodal_evaluation['adaptive']['metadata']['base_strategy']}")
    print(f"Nombre de bins: {bimodal_evaluation['adaptive']['num_bins']}")
    print(f"Nombre de pics détectés: {bimodal_evaluation['adaptive']['num_peaks_fwhm']}")
    print(f"Résolution relative: {bimodal_evaluation['adaptive']['relative_resolution']}")

    print("\nRésultats pour la distribution asymétrique (log-normale):")
    print(f"Stratégie de base: {lognormal_evaluation['adaptive']['metadata']['base_strategy']}")
    print(f"Nombre de bins: {lognormal_evaluation['adaptive']['num_bins']}")
    print(f"Nombre de pics détectés: {lognormal_evaluation['adaptive']['num_peaks_fwhm']}")
    print(f"Résolution relative: {lognormal_evaluation['adaptive']['relative_resolution']}")

    print("\nÉvaluation terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- adaptive_binning_resolution_gaussian.png")
    print("- adaptive_binning_resolution_bimodal.png")
    print("- adaptive_binning_resolution_lognormal.png")
