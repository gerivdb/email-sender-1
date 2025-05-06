#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'évaluation de la résolution avec binning par quantiles.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, List, Tuple, Optional, Any

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from resolution_metrics import (
    calculate_fwhm,
    calculate_max_slope_resolution,
    calculate_curvature_resolution,
    calculate_relative_resolution,
    analyze_bin_count_impact_on_resolution
)

def evaluate_quantile_binning_resolution(data: np.ndarray,
                                       min_bins: int = 5,
                                       max_bins: int = 100,
                                       step: int = 5,
                                       theoretical_params: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
    """
    Évalue en détail la résolution obtenue avec le binning par quantiles.

    Args:
        data: Données à analyser
        min_bins: Nombre minimal de bins à tester
        max_bins: Nombre maximal de bins à tester
        step: Pas entre les nombres de bins à tester
        theoretical_params: Paramètres théoriques de la distribution (optionnel)

    Returns:
        Dict[str, Any]: Résultats détaillés de l'évaluation
    """
    # Analyser l'impact du nombre de bins sur la résolution
    bin_count_analysis = analyze_bin_count_impact_on_resolution(
        data,
        strategy="quantile",
        min_bins=min_bins,
        max_bins=max_bins,
        step=step
    )

    # Calculer les statistiques de base des données
    data_range = max(data) - min(data)
    data_std = np.std(data)
    data_iqr = np.percentile(data, 75) - np.percentile(data, 25)

    # Calculer les règles empiriques pour le nombre optimal de bins
    n = len(data)
    sturges_rule = int(np.ceil(np.log2(n) + 1))
    scott_rule = int(np.ceil(3.5 * data_std * n**(-1/3)))
    freedman_diaconis_rule = int(np.ceil(2 * data_iqr * n**(-1/3)))

    # Calculer les scores de qualité pour chaque nombre de bins
    quality_scores = {}

    for num_bins, result in bin_count_analysis["results_by_bin_count"].items():
        # Score basé sur le nombre de pics détectés
        peak_detection_score = result["num_peaks_fwhm"] / max(
            [r["num_peaks_fwhm"] for r in bin_count_analysis["results_by_bin_count"].values()]
        ) if any(r["num_peaks_fwhm"] > 0 for r in bin_count_analysis["results_by_bin_count"].values()) else 0

        # Score basé sur la résolution relative
        relative_resolution = result["relative_resolution"]
        if relative_resolution is not None:
            valid_resolutions = [r["relative_resolution"] for r in bin_count_analysis["results_by_bin_count"].values()
                               if r["relative_resolution"] is not None]
            if valid_resolutions:
                max_resolution = max(valid_resolutions)
                relative_resolution_score = 1 - relative_resolution / max_resolution
            else:
                relative_resolution_score = 0
        else:
            relative_resolution_score = 0

        # Score global
        quality_scores[num_bins] = 0.7 * peak_detection_score + 0.3 * relative_resolution_score

    # Trouver le nombre de bins avec le meilleur score de qualité
    best_quality_num_bins = max(quality_scores.keys(), key=lambda k: quality_scores[k])

    # Résultats
    results = {
        "bin_count_analysis": bin_count_analysis,
        "data_statistics": {
            "range": data_range,
            "std": data_std,
            "iqr": data_iqr,
            "n": n
        },
        "empirical_rules": {
            "sturges": sturges_rule,
            "scott": scott_rule,
            "freedman_diaconis": freedman_diaconis_rule
        },
        "quality_scores": quality_scores,
        "best_quality_num_bins": best_quality_num_bins
    }

    return results

def plot_quantile_binning_resolution_evaluation(evaluation_results: Dict[str, Any],
                                              save_path: Optional[str] = None,
                                              show_plot: bool = True) -> None:
    """
    Visualise les résultats de l'évaluation de la résolution avec binning par quantiles.

    Args:
        evaluation_results: Résultats de l'évaluation
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les données
    bin_count_analysis = evaluation_results["bin_count_analysis"]
    bin_counts = sorted(bin_count_analysis["results_by_bin_count"].keys())
    empirical_rules = evaluation_results["empirical_rules"]
    quality_scores = evaluation_results["quality_scores"]
    best_quality_num_bins = evaluation_results["best_quality_num_bins"]

    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(12, 15), sharex=True)

    # Graphique 1: Nombre de pics détectés
    ax1 = axes[0]
    num_peaks_fwhm = [bin_count_analysis["results_by_bin_count"][n]["num_peaks_fwhm"] for n in bin_counts]

    ax1.plot(bin_counts, num_peaks_fwhm, 'o-', color='blue', label='FWHM')
    ax1.set_ylabel('Nombre de pics détectés')
    ax1.set_title('Impact du nombre de bins sur la détection des pics (Binning par quantiles)')
    ax1.grid(True, alpha=0.3)

    # Ajouter des lignes verticales pour les règles empiriques
    ax1.axvline(x=empirical_rules["sturges"], color='red', linestyle='--', alpha=0.7,
               label=f'Règle de Sturges ({empirical_rules["sturges"]} bins)')
    ax1.axvline(x=empirical_rules["scott"], color='green', linestyle='--', alpha=0.7,
               label=f'Règle de Scott ({empirical_rules["scott"]} bins)')
    ax1.axvline(x=empirical_rules["freedman_diaconis"], color='purple', linestyle='--', alpha=0.7,
               label=f'Règle de Freedman-Diaconis ({empirical_rules["freedman_diaconis"]} bins)')

    # Ajouter une ligne verticale pour le meilleur nombre de bins
    ax1.axvline(x=best_quality_num_bins, color='black', linestyle='-', alpha=0.7,
               label=f'Meilleur score de qualité ({best_quality_num_bins} bins)')

    ax1.legend()

    # Graphique 2: Métriques de résolution
    ax2 = axes[1]
    mean_fwhm = [bin_count_analysis["results_by_bin_count"][n]["mean_fwhm"]
                if bin_count_analysis["results_by_bin_count"][n]["num_peaks_fwhm"] > 0 else np.nan
                for n in bin_counts]
    relative_resolution = [bin_count_analysis["results_by_bin_count"][n]["relative_resolution"]
                         if bin_count_analysis["results_by_bin_count"][n]["relative_resolution"] is not None else np.nan
                         for n in bin_counts]

    ax2.plot(bin_counts, mean_fwhm, 'o-', color='blue', label='FWHM moyenne')
    ax2_twin = ax2.twinx()
    ax2_twin.plot(bin_counts, relative_resolution, 's-', color='green', label='Résolution relative')

    ax2.set_ylabel('FWHM moyenne')
    ax2_twin.set_ylabel('Résolution relative')
    ax2.set_title('Impact du nombre de bins sur les métriques de résolution (Binning par quantiles)')
    ax2.grid(True, alpha=0.3)

    # Combiner les légendes
    lines1, labels1 = ax2.get_legend_handles_labels()
    lines2, labels2 = ax2_twin.get_legend_handles_labels()
    ax2.legend(lines1 + lines2, labels1 + labels2, loc='upper right')

    # Graphique 3: Scores de qualité
    ax3 = axes[2]
    scores = [quality_scores[n] for n in bin_counts]

    ax3.plot(bin_counts, scores, 'o-', color='purple', label='Score de qualité')
    ax3.set_xlabel('Nombre de bins')
    ax3.set_ylabel('Score de qualité')
    ax3.set_title('Score de qualité en fonction du nombre de bins (Binning par quantiles)')
    ax3.grid(True, alpha=0.3)

    # Ajouter une ligne verticale pour le meilleur nombre de bins
    ax3.axvline(x=best_quality_num_bins, color='black', linestyle='-', alpha=0.7,
               label=f'Meilleur score ({best_quality_num_bins} bins)')

    ax3.legend()

    plt.tight_layout()

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
    print("=== Évaluation de la résolution avec binning par quantiles ===")

    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité

    # Distribution gaussienne
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])

    # Évaluer la résolution pour la distribution gaussienne
    print("\nÉvaluation pour la distribution gaussienne...")
    gaussian_evaluation = evaluate_quantile_binning_resolution(
        gaussian_data,
        min_bins=5,
        max_bins=50,
        step=5
    )

    # Visualiser les résultats
    plot_quantile_binning_resolution_evaluation(
        gaussian_evaluation,
        save_path="quantile_binning_resolution_gaussian.png",
        show_plot=False
    )

    # Évaluer la résolution pour la distribution bimodale
    print("\nÉvaluation pour la distribution bimodale...")
    bimodal_evaluation = evaluate_quantile_binning_resolution(
        bimodal_data,
        min_bins=5,
        max_bins=50,
        step=5
    )

    # Visualiser les résultats
    plot_quantile_binning_resolution_evaluation(
        bimodal_evaluation,
        save_path="quantile_binning_resolution_bimodal.png",
        show_plot=False
    )

    # Afficher les résultats
    print("\nRésultats pour la distribution gaussienne:")
    print(f"Meilleur nombre de bins selon le score de qualité: {gaussian_evaluation['best_quality_num_bins']}")
    print(f"Règle de Sturges: {gaussian_evaluation['empirical_rules']['sturges']} bins")
    print(f"Règle de Scott: {gaussian_evaluation['empirical_rules']['scott']} bins")
    print(f"Règle de Freedman-Diaconis: {gaussian_evaluation['empirical_rules']['freedman_diaconis']} bins")

    print("\nRésultats pour la distribution bimodale:")
    print(f"Meilleur nombre de bins selon le score de qualité: {bimodal_evaluation['best_quality_num_bins']}")
    print(f"Règle de Sturges: {bimodal_evaluation['empirical_rules']['sturges']} bins")
    print(f"Règle de Scott: {bimodal_evaluation['empirical_rules']['scott']} bins")
    print(f"Règle de Freedman-Diaconis: {bimodal_evaluation['empirical_rules']['freedman_diaconis']} bins")

    print("\nÉvaluation terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- quantile_binning_resolution_gaussian.png")
    print("- quantile_binning_resolution_bimodal.png")
