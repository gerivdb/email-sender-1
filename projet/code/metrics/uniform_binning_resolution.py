#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'évaluation de la résolution avec binning uniforme.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, List, Tuple, Optional, Any
from tqdm import tqdm

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

def evaluate_uniform_binning_resolution(data: np.ndarray,
                                      min_bins: int = 5,
                                      max_bins: int = 100,
                                      step: int = 5,
                                      theoretical_params: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
    """
    Évalue en détail la résolution obtenue avec le binning uniforme.

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
        strategy="uniform",
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

    # Calculer les largeurs de bins correspondantes
    bin_widths = {
        num_bins: data_range / num_bins
        for num_bins in range(min_bins, max_bins + 1, step)
    }

    # Calculer les largeurs de bins optimales selon les règles empiriques
    optimal_bin_widths = {
        "sturges": data_range / sturges_rule,
        "scott": data_range / scott_rule,
        "freedman_diaconis": data_range / freedman_diaconis_rule
    }

    # Calculer les largeurs de bins optimales selon les métriques de résolution
    optimal_num_bins = bin_count_analysis["optimal_num_bins"]
    optimal_resolution_bin_widths = {
        "fwhm": data_range / optimal_num_bins["fwhm"],
        "slope": data_range / optimal_num_bins["slope"],
        "curvature": data_range / optimal_num_bins["curvature"],
        "relative": data_range / optimal_num_bins["relative"]
    }

    # Calculer les largeurs de bins optimales selon les formules théoriques
    theoretical_bin_widths = {}

    if theoretical_params is not None:
        if "sigma" in theoretical_params:
            sigma = theoretical_params["sigma"]
            theoretical_bin_widths["fwhm"] = 0.5 * 2.355 * sigma  # 0.5 * FWHM
            theoretical_bin_widths["slope"] = 0.7 * sigma
            theoretical_bin_widths["curvature"] = 0.5 * sigma
            theoretical_bin_widths["general"] = 0.5 * sigma

    # Calculer les erreurs relatives par rapport aux valeurs théoriques
    relative_errors = {}

    if theoretical_params is not None:
        # Pour chaque nombre de bins, calculer les erreurs relatives
        for num_bins, result in bin_count_analysis["results_by_bin_count"].items():
            bin_width = bin_widths[num_bins]

            if "sigma" in theoretical_params:
                sigma = theoretical_params["sigma"]
                fwhm_true = 2.355 * sigma

                # Erreur FWHM théorique: sqrt(1 + (bin_width/fwhm)^2) - 1
                bin_width_to_fwhm_ratio = bin_width / fwhm_true
                theoretical_fwhm_error = np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1

                # Erreur pente théorique: 1 / (1 + k * (bin_width/sigma)^2) - 1
                k_slope = 0.5  # Coefficient empirique
                theoretical_slope_error = 1 / (1 + k_slope * (bin_width/sigma)**2) - 1

                # Erreur courbure théorique: 1 / (1 + k' * (bin_width/sigma)^2) - 1
                k_curvature = 1.0  # Coefficient empirique
                theoretical_curvature_error = 1 / (1 + k_curvature * (bin_width/sigma)**2) - 1

                relative_errors[num_bins] = {
                    "fwhm": {
                        "theoretical": theoretical_fwhm_error,
                        "empirical": (result["mean_fwhm"] - fwhm_true) / fwhm_true if result["num_peaks_fwhm"] > 0 else np.nan
                    },
                    "slope": {
                        "theoretical": theoretical_slope_error,
                        "empirical": np.nan  # Difficile à calculer sans connaître la vraie pente maximale
                    },
                    "curvature": {
                        "theoretical": theoretical_curvature_error,
                        "empirical": np.nan  # Difficile à calculer sans connaître la vraie courbure maximale
                    }
                }

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
        "bin_widths": bin_widths,
        "optimal_bin_widths": {
            "empirical_rules": optimal_bin_widths,
            "resolution_metrics": optimal_resolution_bin_widths
        },
        "theoretical_bin_widths": theoretical_bin_widths,
        "relative_errors": relative_errors,
        "quality_scores": quality_scores,
        "best_quality_num_bins": best_quality_num_bins
    }

    return results

def plot_uniform_binning_resolution_evaluation(evaluation_results: Dict[str, Any],
                                             save_path: Optional[str] = None,
                                             show_plot: bool = True) -> None:
    """
    Visualise les résultats de l'évaluation de la résolution avec binning uniforme.

    Args:
        evaluation_results: Résultats de l'évaluation
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les données
    bin_count_analysis = evaluation_results["bin_count_analysis"]
    bin_counts = sorted(bin_count_analysis["results_by_bin_count"].keys())
    data_stats = evaluation_results["data_statistics"]
    empirical_rules = evaluation_results["empirical_rules"]
    bin_widths = evaluation_results["bin_widths"]
    optimal_bin_widths = evaluation_results["optimal_bin_widths"]
    theoretical_bin_widths = evaluation_results["theoretical_bin_widths"]
    quality_scores = evaluation_results["quality_scores"]
    best_quality_num_bins = evaluation_results["best_quality_num_bins"]

    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(12, 15), sharex=True)

    # Graphique 1: Nombre de pics détectés
    ax1 = axes[0]
    num_peaks_fwhm = [bin_count_analysis["results_by_bin_count"][n]["num_peaks_fwhm"] for n in bin_counts]

    ax1.plot(bin_counts, num_peaks_fwhm, 'o-', color='blue', label='FWHM')
    ax1.set_ylabel('Nombre de pics détectés')
    ax1.set_title('Impact du nombre de bins sur la détection des pics (Binning uniforme)')
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
    ax2.set_title('Impact du nombre de bins sur les métriques de résolution (Binning uniforme)')
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
    ax3.set_title('Score de qualité en fonction du nombre de bins (Binning uniforme)')
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

    # Créer une deuxième figure pour les largeurs de bins
    fig2, axes2 = plt.subplots(2, 1, figsize=(12, 10))

    # Graphique 1: Largeurs de bins
    ax1 = axes2[0]
    bin_width_values = list(bin_widths.values())

    ax1.plot(bin_counts, bin_width_values, 'o-', color='blue', label='Largeur des bins')
    ax1.set_ylabel('Largeur des bins')
    ax1.set_title('Largeur des bins en fonction du nombre de bins (Binning uniforme)')
    ax1.grid(True, alpha=0.3)

    # Ajouter des lignes horizontales pour les largeurs optimales selon les règles empiriques
    ax1.axhline(y=optimal_bin_widths["empirical_rules"]["sturges"], color='red', linestyle='--', alpha=0.7,
               label=f'Règle de Sturges ({optimal_bin_widths["empirical_rules"]["sturges"]:.4f})')
    ax1.axhline(y=optimal_bin_widths["empirical_rules"]["scott"], color='green', linestyle='--', alpha=0.7,
               label=f'Règle de Scott ({optimal_bin_widths["empirical_rules"]["scott"]:.4f})')
    ax1.axhline(y=optimal_bin_widths["empirical_rules"]["freedman_diaconis"], color='purple', linestyle='--', alpha=0.7,
               label=f'Règle de Freedman-Diaconis ({optimal_bin_widths["empirical_rules"]["freedman_diaconis"]:.4f})')

    # Ajouter des lignes horizontales pour les largeurs optimales selon les métriques de résolution
    ax1.axhline(y=optimal_bin_widths["resolution_metrics"]["fwhm"], color='cyan', linestyle='-.', alpha=0.7,
               label=f'Optimale FWHM ({optimal_bin_widths["resolution_metrics"]["fwhm"]:.4f})')
    ax1.axhline(y=optimal_bin_widths["resolution_metrics"]["relative"], color='magenta', linestyle='-.', alpha=0.7,
               label=f'Optimale résolution relative ({optimal_bin_widths["resolution_metrics"]["relative"]:.4f})')

    # Ajouter des lignes horizontales pour les largeurs théoriques si disponibles
    if theoretical_bin_widths:
        for metric, width in theoretical_bin_widths.items():
            if metric == "general":
                ax1.axhline(y=width, color='black', linestyle='-', alpha=0.7,
                           label=f'Théorique générale ({width:.4f})')
            else:
                ax1.axhline(y=width, color='orange', linestyle=':', alpha=0.7,
                           label=f'Théorique {metric} ({width:.4f})')

    ax1.legend()

    # Graphique 2: Erreurs relatives
    ax2 = axes2[1]

    if evaluation_results["relative_errors"]:
        fwhm_theoretical_errors = [evaluation_results["relative_errors"][n]["fwhm"]["theoretical"]
                                 for n in bin_counts if n in evaluation_results["relative_errors"]]
        fwhm_empirical_errors = [evaluation_results["relative_errors"][n]["fwhm"]["empirical"]
                               for n in bin_counts if n in evaluation_results["relative_errors"]]

        ax2.plot(bin_counts[:len(fwhm_theoretical_errors)], fwhm_theoretical_errors, 'o-', color='blue',
                label='Erreur FWHM théorique')
        ax2.plot(bin_counts[:len(fwhm_empirical_errors)], fwhm_empirical_errors, 's-', color='green',
                label='Erreur FWHM empirique')

        ax2.set_xlabel('Nombre de bins')
        ax2.set_ylabel('Erreur relative')
        ax2.set_title('Erreurs relatives en fonction du nombre de bins (Binning uniforme)')
        ax2.grid(True, alpha=0.3)
        ax2.legend()
    else:
        ax2.text(0.5, 0.5, 'Pas de données d\'erreurs relatives disponibles',
                ha='center', va='center', transform=ax2.transAxes)

    plt.tight_layout()

    # Sauvegarder la deuxième figure si un chemin est spécifié
    if save_path:
        save_path2 = save_path.replace('.png', '_bin_widths.png')
        plt.savefig(save_path2, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig2)

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Évaluation de la résolution avec binning uniforme ===")

    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité

    # Distribution gaussienne
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])

    # Distribution trimodale
    trimodal_data = np.concatenate([
        np.random.normal(loc=20, scale=3, size=300),
        np.random.normal(loc=50, scale=5, size=400),
        np.random.normal(loc=80, scale=4, size=300)
    ])

    # Évaluer la résolution pour la distribution gaussienne
    print("\nÉvaluation pour la distribution gaussienne...")
    gaussian_evaluation = evaluate_uniform_binning_resolution(
        gaussian_data,
        min_bins=5,
        max_bins=100,
        step=5,
        theoretical_params={"sigma": 10}
    )

    # Visualiser les résultats
    plot_uniform_binning_resolution_evaluation(
        gaussian_evaluation,
        save_path="uniform_binning_resolution_gaussian.png",
        show_plot=False
    )

    # Évaluer la résolution pour la distribution bimodale
    print("\nÉvaluation pour la distribution bimodale...")
    bimodal_evaluation = evaluate_uniform_binning_resolution(
        bimodal_data,
        min_bins=5,
        max_bins=100,
        step=5,
        theoretical_params={"sigma": 6.5}  # Moyenne pondérée des écarts-types
    )

    # Visualiser les résultats
    plot_uniform_binning_resolution_evaluation(
        bimodal_evaluation,
        save_path="uniform_binning_resolution_bimodal.png",
        show_plot=False
    )

    # Évaluer la résolution pour la distribution trimodale
    print("\nÉvaluation pour la distribution trimodale...")
    trimodal_evaluation = evaluate_uniform_binning_resolution(
        trimodal_data,
        min_bins=5,
        max_bins=100,
        step=5,
        theoretical_params={"sigma": 4}  # Moyenne pondérée des écarts-types
    )

    # Visualiser les résultats
    plot_uniform_binning_resolution_evaluation(
        trimodal_evaluation,
        save_path="uniform_binning_resolution_trimodal.png",
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

    print("\nRésultats pour la distribution trimodale:")
    print(f"Meilleur nombre de bins selon le score de qualité: {trimodal_evaluation['best_quality_num_bins']}")
    print(f"Règle de Sturges: {trimodal_evaluation['empirical_rules']['sturges']} bins")
    print(f"Règle de Scott: {trimodal_evaluation['empirical_rules']['scott']} bins")
    print(f"Règle de Freedman-Diaconis: {trimodal_evaluation['empirical_rules']['freedman_diaconis']} bins")

    print("\nÉvaluation terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- uniform_binning_resolution_gaussian.png")
    print("- uniform_binning_resolution_gaussian_bin_widths.png")
    print("- uniform_binning_resolution_bimodal.png")
    print("- uniform_binning_resolution_bimodal_bin_widths.png")
    print("- uniform_binning_resolution_trimodal.png")
    print("- uniform_binning_resolution_trimodal_bin_widths.png")
