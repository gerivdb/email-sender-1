#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour comparer les performances des différentes stratégies de binning.
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
    compare_binning_strategies_resolution,
    find_optimal_binning_strategy_resolution
)

from quantile_binning_resolution import (
    evaluate_quantile_binning_resolution
)

from uniform_binning_resolution import (
    evaluate_uniform_binning_resolution
)

def compare_binning_strategies_for_resolution(data: np.ndarray,
                                            strategies: Optional[List[str]] = None,
                                            num_bins: int = 20,
                                            save_path: Optional[str] = None,
                                            show_plot: bool = True) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de résolution.
    
    Args:
        data: Données à analyser
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
        
    Returns:
        Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]
    
    # Comparer les stratégies de binning
    results = compare_binning_strategies_resolution(data, strategies, num_bins)
    
    # Créer la figure
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # Graphique 1: Histogrammes
    ax1 = axes[0, 0]
    
    for strategy in strategies:
        # Générer l'histogramme selon la stratégie
        if strategy == "uniform":
            bin_edges = np.linspace(min(data), max(data), num_bins + 1)
        elif strategy == "logarithmic":
            min_value = max(min(data), 1e-10)  # Éviter les valeurs négatives ou nulles
            bin_edges = np.logspace(np.log10(min_value), np.log10(max(data)), num_bins + 1)
        elif strategy == "quantile":
            bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
        else:
            raise ValueError(f"Stratégie de binning inconnue: {strategy}")
        
        # Calculer l'histogramme
        bin_counts, _ = np.histogram(data, bins=bin_edges)
        bin_counts = bin_counts / np.max(bin_counts)  # Normaliser
        
        # Tracer l'histogramme
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
        ax1.plot(bin_centers, bin_counts, '-', label=f'{strategy.capitalize()}')
        
        # Ajouter des marqueurs pour les limites des bins
        ax1.plot(bin_edges[1:-1], np.zeros_like(bin_edges[1:-1]), '|', 
                color=ax1.lines[-1].get_color(), alpha=0.7)
    
    ax1.set_xlabel('Valeur')
    ax1.set_ylabel('Fréquence normalisée')
    ax1.set_title(f'Histogrammes avec différentes stratégies de binning ({num_bins} bins)')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Graphique 2: Nombre de pics détectés
    ax2 = axes[0, 1]
    
    strategies_labels = [s.capitalize() for s in strategies]
    num_peaks = [len(results[s]["peaks"]) for s in strategies]
    
    ax2.bar(strategies_labels, num_peaks, color=['blue', 'green', 'orange'][:len(strategies)])
    ax2.set_xlabel('Stratégie de binning')
    ax2.set_ylabel('Nombre de pics détectés')
    ax2.set_title('Nombre de pics détectés par stratégie')
    ax2.grid(True, alpha=0.3, axis='y')
    
    # Graphique 3: Résolution relative
    ax3 = axes[1, 0]
    
    relative_resolutions = [results[s]["relative_resolution"] for s in strategies]
    
    ax3.bar(strategies_labels, relative_resolutions, color=['blue', 'green', 'orange'][:len(strategies)])
    ax3.set_xlabel('Stratégie de binning')
    ax3.set_ylabel('Résolution relative')
    ax3.set_title('Résolution relative par stratégie')
    ax3.grid(True, alpha=0.3, axis='y')
    
    # Graphique 4: FWHM moyenne
    ax4 = axes[1, 1]
    
    mean_fwhms = [results[s]["mean_fwhm"] for s in strategies]
    
    ax4.bar(strategies_labels, mean_fwhms, color=['blue', 'green', 'orange'][:len(strategies)])
    ax4.set_xlabel('Stratégie de binning')
    ax4.set_ylabel('FWHM moyenne')
    ax4.set_title('FWHM moyenne par stratégie')
    ax4.grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    
    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
    
    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)
    
    return results

def find_optimal_binning_for_resolution(data: np.ndarray,
                                      strategies: Optional[List[str]] = None,
                                      num_bins_range: Optional[List[int]] = None,
                                      save_path: Optional[str] = None,
                                      show_plot: bool = True) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de résolution.
    
    Args:
        data: Données à analyser
        strategies: Liste des stratégies de binning à comparer
        num_bins_range: Liste des nombres de bins à tester
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
        
    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]
    
    if num_bins_range is None:
        num_bins_range = [5, 10, 20, 50, 100]
    
    # Trouver la stratégie optimale
    results = find_optimal_binning_strategy_resolution(data, strategies, num_bins_range)
    
    # Créer la figure
    fig, axes = plt.subplots(2, 1, figsize=(12, 10))
    
    # Graphique 1: Résolution relative par stratégie et nombre de bins
    ax1 = axes[0]
    
    for strategy in strategies:
        strategy_results = results["results"][strategy]
        relative_resolutions = [strategy_results[n]["relative_resolution"] for n in num_bins_range]
        
        ax1.plot(num_bins_range, relative_resolutions, 'o-', label=f'{strategy.capitalize()}')
    
    # Ajouter un marqueur pour la stratégie optimale
    ax1.plot(results["best_num_bins"], results["best_resolution"], 'r*', markersize=15,
            label=f'Optimal: {results["best_strategy"].capitalize()}, {results["best_num_bins"]} bins')
    
    ax1.set_xlabel('Nombre de bins')
    ax1.set_ylabel('Résolution relative')
    ax1.set_title('Résolution relative par stratégie et nombre de bins')
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Graphique 2: Qualité de la résolution par stratégie et nombre de bins
    ax2 = axes[1]
    
    for strategy in strategies:
        strategy_results = results["results"][strategy]
        qualities = [strategy_results[n]["resolution_quality"] for n in num_bins_range]
        
        ax2.plot(num_bins_range, qualities, 'o-', label=f'{strategy.capitalize()}')
    
    # Ajouter un marqueur pour la stratégie optimale
    ax2.plot(results["best_num_bins"], results["best_quality"], 'r*', markersize=15,
            label=f'Optimal: {results["best_strategy"].capitalize()}, {results["best_num_bins"]} bins')
    
    ax2.set_xlabel('Nombre de bins')
    ax2.set_ylabel('Qualité de la résolution')
    ax2.set_title('Qualité de la résolution par stratégie et nombre de bins')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
    
    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)
    
    return results

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Comparaison des stratégies de binning pour la résolution ===")
    
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
    
    # Comparer les stratégies de binning pour la distribution gaussienne
    print("\nComparaison pour la distribution gaussienne...")
    gaussian_comparison = compare_binning_strategies_for_resolution(
        gaussian_data,
        save_path="binning_strategies_comparison_gaussian.png",
        show_plot=False
    )
    
    # Trouver la stratégie optimale pour la distribution gaussienne
    print("\nRecherche de la stratégie optimale pour la distribution gaussienne...")
    gaussian_optimization = find_optimal_binning_for_resolution(
        gaussian_data,
        num_bins_range=[5, 10, 15, 20, 30, 50],
        save_path="optimal_binning_gaussian.png",
        show_plot=False
    )
    
    # Comparer les stratégies de binning pour la distribution bimodale
    print("\nComparaison pour la distribution bimodale...")
    bimodal_comparison = compare_binning_strategies_for_resolution(
        bimodal_data,
        save_path="binning_strategies_comparison_bimodal.png",
        show_plot=False
    )
    
    # Trouver la stratégie optimale pour la distribution bimodale
    print("\nRecherche de la stratégie optimale pour la distribution bimodale...")
    bimodal_optimization = find_optimal_binning_for_resolution(
        bimodal_data,
        num_bins_range=[5, 10, 15, 20, 30, 50],
        save_path="optimal_binning_bimodal.png",
        show_plot=False
    )
    
    # Comparer les stratégies de binning pour la distribution asymétrique
    print("\nComparaison pour la distribution asymétrique (log-normale)...")
    lognormal_comparison = compare_binning_strategies_for_resolution(
        lognormal_data,
        save_path="binning_strategies_comparison_lognormal.png",
        show_plot=False
    )
    
    # Trouver la stratégie optimale pour la distribution asymétrique
    print("\nRecherche de la stratégie optimale pour la distribution asymétrique (log-normale)...")
    lognormal_optimization = find_optimal_binning_for_resolution(
        lognormal_data,
        num_bins_range=[5, 10, 15, 20, 30, 50],
        save_path="optimal_binning_lognormal.png",
        show_plot=False
    )
    
    # Afficher les résultats
    print("\nRésultats pour la distribution gaussienne:")
    for strategy, result in gaussian_comparison.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Nombre de pics détectés: {len(result['peaks'])}")
        print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        print(f"    Qualité de la résolution: {result['resolution_quality']}")
    
    print(f"\nStratégie optimale pour la distribution gaussienne: {gaussian_optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {gaussian_optimization['best_num_bins']}")
    print(f"Meilleure résolution relative: {gaussian_optimization['best_resolution']:.4f}")
    print(f"Qualité: {gaussian_optimization['best_quality']}")
    
    print("\nRésultats pour la distribution bimodale:")
    for strategy, result in bimodal_comparison.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Nombre de pics détectés: {len(result['peaks'])}")
        print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        print(f"    Qualité de la résolution: {result['resolution_quality']}")
    
    print(f"\nStratégie optimale pour la distribution bimodale: {bimodal_optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {bimodal_optimization['best_num_bins']}")
    print(f"Meilleure résolution relative: {bimodal_optimization['best_resolution']:.4f}")
    print(f"Qualité: {bimodal_optimization['best_quality']}")
    
    print("\nRésultats pour la distribution asymétrique (log-normale):")
    for strategy, result in lognormal_comparison.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Nombre de pics détectés: {len(result['peaks'])}")
        print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        print(f"    Qualité de la résolution: {result['resolution_quality']}")
    
    print(f"\nStratégie optimale pour la distribution asymétrique: {lognormal_optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {lognormal_optimization['best_num_bins']}")
    print(f"Meilleure résolution relative: {lognormal_optimization['best_resolution']:.4f}")
    print(f"Qualité: {lognormal_optimization['best_quality']}")
    
    print("\nComparaison terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- binning_strategies_comparison_gaussian.png")
    print("- optimal_binning_gaussian.png")
    print("- binning_strategies_comparison_bimodal.png")
    print("- optimal_binning_bimodal.png")
    print("- binning_strategies_comparison_lognormal.png")
    print("- optimal_binning_lognormal.png")
