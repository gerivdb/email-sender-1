#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'évaluation de la résolution avec binning logarithmique.
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
    analyze_bin_count_impact_on_resolution
)

def evaluate_logarithmic_binning_resolution(data: np.ndarray,
                                          min_bins: int = 5,
                                          max_bins: int = 100,
                                          step: int = 5,
                                          theoretical_params: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
    """
    Évalue en détail la résolution obtenue avec le binning logarithmique.
    
    Args:
        data: Données à analyser
        min_bins: Nombre minimal de bins à tester
        max_bins: Nombre maximal de bins à tester
        step: Pas entre les nombres de bins à tester
        theoretical_params: Paramètres théoriques de la distribution (optionnel)
        
    Returns:
        Dict[str, Any]: Résultats détaillés de l'évaluation
    """
    # Vérifier que les données sont positives pour le binning logarithmique
    if np.min(data) <= 0:
        # Décaler les données pour qu'elles soient toutes positives
        data_shift = np.abs(np.min(data)) + 1e-5
        data_log = data + data_shift
        shift_applied = True
    else:
        data_log = data.copy()
        shift_applied = False
    
    # Analyser l'impact du nombre de bins sur la résolution
    bin_count_analysis = analyze_bin_count_impact_on_resolution(
        data_log, 
        strategy="logarithmic", 
        min_bins=min_bins, 
        max_bins=max_bins, 
        step=step
    )
    
    # Calculer les statistiques de base des données
    data_range = max(data_log) - min(data_log)
    data_std = np.std(data_log)
    data_iqr = np.percentile(data_log, 75) - np.percentile(data_log, 25)
    
    # Calculer les règles empiriques pour le nombre optimal de bins
    n = len(data_log)
    sturges_rule = int(np.ceil(np.log2(n) + 1))
    scott_rule = int(np.ceil(3.5 * data_std * n**(-1/3)))
    freedman_diaconis_rule = int(np.ceil(2 * data_iqr * n**(-1/3)))
    
    # Calculer les largeurs de bins logarithmiques correspondantes
    bin_widths = {}
    for num_bins in range(min_bins, max_bins + 1, step):
        min_value = min(data_log)
        max_value = max(data_log)
        # Calculer les largeurs des bins logarithmiques (qui varient)
        bin_edges = np.logspace(np.log10(min_value), np.log10(max_value), num_bins + 1)
        bin_widths[num_bins] = {
            "min": np.min(bin_edges[1:] - bin_edges[:-1]),
            "max": np.max(bin_edges[1:] - bin_edges[:-1]),
            "mean": np.mean(bin_edges[1:] - bin_edges[:-1]),
            "median": np.median(bin_edges[1:] - bin_edges[:-1]),
            "ratio": np.max(bin_edges[1:] - bin_edges[:-1]) / np.min(bin_edges[1:] - bin_edges[:-1])
        }
    
    # Calculer les largeurs de bins optimales selon les règles empiriques
    min_value = min(data_log)
    max_value = max(data_log)
    
    sturges_bin_edges = np.logspace(np.log10(min_value), np.log10(max_value), sturges_rule + 1)
    scott_bin_edges = np.logspace(np.log10(min_value), np.log10(max_value), scott_rule + 1)
    fd_bin_edges = np.logspace(np.log10(min_value), np.log10(max_value), freedman_diaconis_rule + 1)
    
    optimal_bin_widths = {
        "sturges": {
            "min": np.min(sturges_bin_edges[1:] - sturges_bin_edges[:-1]),
            "max": np.max(sturges_bin_edges[1:] - sturges_bin_edges[:-1]),
            "mean": np.mean(sturges_bin_edges[1:] - sturges_bin_edges[:-1]),
            "median": np.median(sturges_bin_edges[1:] - sturges_bin_edges[:-1]),
            "ratio": np.max(sturges_bin_edges[1:] - sturges_bin_edges[:-1]) / np.min(sturges_bin_edges[1:] - sturges_bin_edges[:-1])
        },
        "scott": {
            "min": np.min(scott_bin_edges[1:] - scott_bin_edges[:-1]),
            "max": np.max(scott_bin_edges[1:] - scott_bin_edges[:-1]),
            "mean": np.mean(scott_bin_edges[1:] - scott_bin_edges[:-1]),
            "median": np.median(scott_bin_edges[1:] - scott_bin_edges[:-1]),
            "ratio": np.max(scott_bin_edges[1:] - scott_bin_edges[:-1]) / np.min(scott_bin_edges[1:] - scott_bin_edges[:-1])
        },
        "freedman_diaconis": {
            "min": np.min(fd_bin_edges[1:] - fd_bin_edges[:-1]),
            "max": np.max(fd_bin_edges[1:] - fd_bin_edges[:-1]),
            "mean": np.mean(fd_bin_edges[1:] - fd_bin_edges[:-1]),
            "median": np.median(fd_bin_edges[1:] - fd_bin_edges[:-1]),
            "ratio": np.max(fd_bin_edges[1:] - fd_bin_edges[:-1]) / np.min(fd_bin_edges[1:] - fd_bin_edges[:-1])
        }
    }
    
    # Calculer les largeurs de bins optimales selon les métriques de résolution
    optimal_num_bins = bin_count_analysis["optimal_num_bins"]
    
    optimal_resolution_bin_edges = {}
    for metric, num_bins in optimal_num_bins.items():
        if num_bins is not None:
            bin_edges = np.logspace(np.log10(min_value), np.log10(max_value), num_bins + 1)
            optimal_resolution_bin_edges[metric] = {
                "min": np.min(bin_edges[1:] - bin_edges[:-1]),
                "max": np.max(bin_edges[1:] - bin_edges[:-1]),
                "mean": np.mean(bin_edges[1:] - bin_edges[:-1]),
                "median": np.median(bin_edges[1:] - bin_edges[:-1]),
                "ratio": np.max(bin_edges[1:] - bin_edges[:-1]) / np.min(bin_edges[1:] - bin_edges[:-1])
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
            "n": n,
            "shift_applied": shift_applied,
            "shift_value": data_shift if shift_applied else 0
        },
        "empirical_rules": {
            "sturges": sturges_rule,
            "scott": scott_rule,
            "freedman_diaconis": freedman_diaconis_rule
        },
        "bin_widths": bin_widths,
        "optimal_bin_widths": {
            "empirical_rules": optimal_bin_widths,
            "resolution_metrics": optimal_resolution_bin_edges
        },
        "quality_scores": quality_scores,
        "best_quality_num_bins": best_quality_num_bins
    }
    
    return results

def plot_logarithmic_binning_resolution_evaluation(evaluation_results: Dict[str, Any],
                                                 save_path: Optional[str] = None,
                                                 show_plot: bool = True) -> None:
    """
    Visualise les résultats de l'évaluation de la résolution avec binning logarithmique.
    
    Args:
        evaluation_results: Résultats de l'évaluation
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les données
    bin_count_analysis = evaluation_results["bin_count_analysis"]
    bin_counts = sorted(bin_count_analysis["results_by_bin_count"].keys())
    empirical_rules = evaluation_results["empirical_rules"]
    bin_widths = evaluation_results["bin_widths"]
    quality_scores = evaluation_results["quality_scores"]
    best_quality_num_bins = evaluation_results["best_quality_num_bins"]
    
    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(12, 15), sharex=True)
    
    # Graphique 1: Nombre de pics détectés
    ax1 = axes[0]
    num_peaks_fwhm = [bin_count_analysis["results_by_bin_count"][n]["num_peaks_fwhm"] for n in bin_counts]
    
    ax1.plot(bin_counts, num_peaks_fwhm, 'o-', color='blue', label='FWHM')
    ax1.set_ylabel('Nombre de pics détectés')
    ax1.set_title('Impact du nombre de bins sur la détection des pics (Binning logarithmique)')
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
    ax2.set_title('Impact du nombre de bins sur les métriques de résolution (Binning logarithmique)')
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
    ax3.set_title('Score de qualité en fonction du nombre de bins (Binning logarithmique)')
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
    
    # Graphique 1: Largeurs de bins (min, max, moyenne)
    ax1 = axes2[0]
    min_widths = [bin_widths[n]["min"] for n in bin_counts]
    max_widths = [bin_widths[n]["max"] for n in bin_counts]
    mean_widths = [bin_widths[n]["mean"] for n in bin_counts]
    
    ax1.plot(bin_counts, min_widths, 'o-', color='blue', label='Largeur minimale')
    ax1.plot(bin_counts, max_widths, 's-', color='red', label='Largeur maximale')
    ax1.plot(bin_counts, mean_widths, '^-', color='green', label='Largeur moyenne')
    
    ax1.set_ylabel('Largeur des bins')
    ax1.set_title('Largeurs des bins en fonction du nombre de bins (Binning logarithmique)')
    ax1.grid(True, alpha=0.3)
    ax1.legend()
    
    # Graphique 2: Ratio max/min des largeurs de bins
    ax2 = axes2[1]
    ratios = [bin_widths[n]["ratio"] for n in bin_counts]
    
    ax2.plot(bin_counts, ratios, 'o-', color='purple', label='Ratio max/min')
    ax2.set_xlabel('Nombre de bins')
    ax2.set_ylabel('Ratio max/min des largeurs')
    ax2.set_title('Ratio max/min des largeurs de bins (Binning logarithmique)')
    ax2.grid(True, alpha=0.3)
    
    # Ajouter une ligne horizontale pour le ratio = 1 (largeur uniforme)
    ax2.axhline(y=1.0, color='black', linestyle='--', alpha=0.7,
               label='Largeur uniforme (ratio = 1)')
    
    ax2.legend()
    
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
    print("=== Évaluation de la résolution avec binning logarithmique ===")
    
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
    gaussian_evaluation = evaluate_logarithmic_binning_resolution(
        gaussian_data,
        min_bins=5,
        max_bins=50,
        step=5
    )
    
    # Visualiser les résultats
    plot_logarithmic_binning_resolution_evaluation(
        gaussian_evaluation,
        save_path="logarithmic_binning_resolution_gaussian.png",
        show_plot=False
    )
    
    # Évaluer la résolution pour la distribution bimodale
    print("\nÉvaluation pour la distribution bimodale...")
    bimodal_evaluation = evaluate_logarithmic_binning_resolution(
        bimodal_data,
        min_bins=5,
        max_bins=50,
        step=5
    )
    
    # Visualiser les résultats
    plot_logarithmic_binning_resolution_evaluation(
        bimodal_evaluation,
        save_path="logarithmic_binning_resolution_bimodal.png",
        show_plot=False
    )
    
    # Évaluer la résolution pour la distribution asymétrique
    print("\nÉvaluation pour la distribution asymétrique (log-normale)...")
    lognormal_evaluation = evaluate_logarithmic_binning_resolution(
        lognormal_data,
        min_bins=5,
        max_bins=50,
        step=5
    )
    
    # Visualiser les résultats
    plot_logarithmic_binning_resolution_evaluation(
        lognormal_evaluation,
        save_path="logarithmic_binning_resolution_lognormal.png",
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
    
    print("\nRésultats pour la distribution asymétrique (log-normale):")
    print(f"Meilleur nombre de bins selon le score de qualité: {lognormal_evaluation['best_quality_num_bins']}")
    print(f"Règle de Sturges: {lognormal_evaluation['empirical_rules']['sturges']} bins")
    print(f"Règle de Scott: {lognormal_evaluation['empirical_rules']['scott']} bins")
    print(f"Règle de Freedman-Diaconis: {lognormal_evaluation['empirical_rules']['freedman_diaconis']} bins")
    
    print("\nÉvaluation terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- logarithmic_binning_resolution_gaussian.png")
    print("- logarithmic_binning_resolution_gaussian_bin_widths.png")
    print("- logarithmic_binning_resolution_bimodal.png")
    print("- logarithmic_binning_resolution_bimodal_bin_widths.png")
    print("- logarithmic_binning_resolution_lognormal.png")
    print("- logarithmic_binning_resolution_lognormal_bin_widths.png")
