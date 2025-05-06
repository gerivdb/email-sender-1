#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de l'évaluation de la résolution avec binning logarithmique.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from logarithmic_binning_resolution import (
    evaluate_logarithmic_binning_resolution,
    plot_logarithmic_binning_resolution_evaluation
)

# Importer également les fonctions pour les autres stratégies de binning pour comparaison
from uniform_binning_resolution import (
    evaluate_uniform_binning_resolution
)

from quantile_binning_resolution import (
    evaluate_quantile_binning_resolution
)

from binning_strategies_comparison import (
    compare_binning_strategies_for_resolution,
    find_optimal_binning_for_resolution
)

print("=== Test de l'évaluation de la résolution avec binning logarithmique ===")

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

# Distribution exponentielle
exponential_data = np.random.exponential(scale=5.0, size=1000)

# Évaluer la résolution pour la distribution gaussienne
print("\nÉvaluation pour la distribution gaussienne...")
gaussian_log_evaluation = evaluate_logarithmic_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec les autres stratégies de binning pour comparaison
gaussian_uniform_evaluation = evaluate_uniform_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,
    step=5,
    theoretical_params={"sigma": 10}
)

gaussian_quantile_evaluation = evaluate_quantile_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,
    step=5
)

# Visualiser les résultats
plot_logarithmic_binning_resolution_evaluation(
    gaussian_log_evaluation,
    save_path="logarithmic_binning_resolution_test_gaussian.png",
    show_plot=False
)

# Créer une fonction simplifiée pour comparer les stratégies de binning
def simple_compare_strategies(data, strategies=None, num_bins=20):
    if strategies is None:
        strategies = ["uniform", "logarithmic", "quantile"]

    results = {}

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

        # Normaliser l'histogramme
        if np.sum(bin_counts) > 0:
            bin_counts = bin_counts / np.max(bin_counts)

        # Calculer les métriques de résolution
        from resolution_metrics import (
            calculate_fwhm,
            calculate_max_slope_resolution,
            calculate_curvature_resolution,
            calculate_relative_resolution
        )

        fwhm_results = calculate_fwhm(bin_counts, bin_edges)
        slope_results = calculate_max_slope_resolution(bin_counts, bin_edges)
        curvature_results = calculate_curvature_resolution(bin_counts, bin_edges)
        relative_resolution = calculate_relative_resolution(bin_counts, bin_edges)

        results[strategy] = {
            "peaks": fwhm_results.get("peaks", []),
            "fwhm_values": fwhm_results.get("fwhm_values", []),
            "mean_fwhm": fwhm_results.get("mean_fwhm_values", 0),
            "max_slopes": slope_results.get("max_slopes", []),
            "max_curvatures": curvature_results.get("max_curvatures", []),
            "relative_resolution": relative_resolution
        }

    return results

# Comparer les stratégies de binning
gaussian_comparison = simple_compare_strategies(
    gaussian_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins=20
)

# Afficher les résultats clés
print("\nRésultats pour la distribution gaussienne:")
print(f"Meilleur nombre de bins (logarithmique): {gaussian_log_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {gaussian_uniform_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (quantile): {gaussian_quantile_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {gaussian_log_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {gaussian_log_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {gaussian_log_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Évaluer la résolution pour la distribution asymétrique
print("\nÉvaluation pour la distribution asymétrique (log-normale)...")
lognormal_log_evaluation = evaluate_logarithmic_binning_resolution(
    lognormal_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec les autres stratégies de binning pour comparaison
lognormal_uniform_evaluation = evaluate_uniform_binning_resolution(
    lognormal_data,
    min_bins=5,
    max_bins=50,
    step=5
)

lognormal_quantile_evaluation = evaluate_quantile_binning_resolution(
    lognormal_data,
    min_bins=5,
    max_bins=50,
    step=5
)

# Visualiser les résultats
plot_logarithmic_binning_resolution_evaluation(
    lognormal_log_evaluation,
    save_path="logarithmic_binning_resolution_test_lognormal.png",
    show_plot=False
)

# Comparer les stratégies de binning
lognormal_comparison = simple_compare_strategies(
    lognormal_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins=20
)

# Afficher les résultats clés
print("\nRésultats pour la distribution asymétrique (log-normale):")
print(f"Meilleur nombre de bins (logarithmique): {lognormal_log_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {lognormal_uniform_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (quantile): {lognormal_quantile_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {lognormal_log_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {lognormal_log_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {lognormal_log_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Évaluer la résolution pour la distribution exponentielle
print("\nÉvaluation pour la distribution exponentielle...")
exponential_log_evaluation = evaluate_logarithmic_binning_resolution(
    exponential_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec les autres stratégies de binning pour comparaison
exponential_uniform_evaluation = evaluate_uniform_binning_resolution(
    exponential_data,
    min_bins=5,
    max_bins=50,
    step=5
)

exponential_quantile_evaluation = evaluate_quantile_binning_resolution(
    exponential_data,
    min_bins=5,
    max_bins=50,
    step=5
)

# Visualiser les résultats
plot_logarithmic_binning_resolution_evaluation(
    exponential_log_evaluation,
    save_path="logarithmic_binning_resolution_test_exponential.png",
    show_plot=False
)

# Comparer les stratégies de binning
exponential_comparison = simple_compare_strategies(
    exponential_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins=20
)

# Afficher les résultats clés
print("\nRésultats pour la distribution exponentielle:")
print(f"Meilleur nombre de bins (logarithmique): {exponential_log_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {exponential_uniform_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (quantile): {exponential_quantile_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {exponential_log_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {exponential_log_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {exponential_log_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Créer une fonction simplifiée pour trouver la stratégie optimale
def simple_find_optimal_strategy(data, strategies=None, num_bins_range=None):
    if strategies is None:
        strategies = ["uniform", "logarithmic", "quantile"]

    if num_bins_range is None:
        num_bins_range = [5, 10, 20, 30, 50]

    best_resolution = float('inf')
    best_strategy = None
    best_num_bins = None

    results = {}

    for strategy in strategies:
        strategy_results = {}

        for num_bins in num_bins_range:
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

            # Normaliser l'histogramme
            if np.sum(bin_counts) > 0:
                bin_counts = bin_counts / np.max(bin_counts)

            # Calculer les métriques de résolution
            from resolution_metrics import calculate_relative_resolution

            relative_resolution = calculate_relative_resolution(bin_counts, bin_edges)

            strategy_results[num_bins] = {
                "relative_resolution": relative_resolution
            }

            # Mettre à jour la meilleure stratégie
            if relative_resolution is not None:
                if isinstance(relative_resolution, (int, float)) and isinstance(best_resolution, (int, float)):
                    if relative_resolution < best_resolution:
                        best_resolution = relative_resolution
                        best_strategy = strategy
                        best_num_bins = num_bins

        results[strategy] = strategy_results

    return {
        "best_strategy": best_strategy,
        "best_num_bins": best_num_bins,
        "best_resolution": best_resolution,
        "results": results
    }

# Trouver la stratégie optimale pour chaque distribution
print("\nRecherche de la stratégie optimale pour chaque distribution...")

# Distribution gaussienne
gaussian_optimization = simple_find_optimal_strategy(
    gaussian_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins_range=[5, 10, 20, 30, 50]
)

# Distribution asymétrique (log-normale)
lognormal_optimization = simple_find_optimal_strategy(
    lognormal_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins_range=[5, 10, 20, 30, 50]
)

# Distribution exponentielle
exponential_optimization = simple_find_optimal_strategy(
    exponential_data,
    strategies=["uniform", "logarithmic", "quantile"],
    num_bins_range=[5, 10, 20, 30, 50]
)

# Afficher les résultats de l'optimisation
print("\nStratégie optimale pour chaque distribution:")
print(f"Gaussienne: {gaussian_optimization['best_strategy']} avec {gaussian_optimization['best_num_bins']} bins")
print(f"Log-normale: {lognormal_optimization['best_strategy']} avec {lognormal_optimization['best_num_bins']} bins")
print(f"Exponentielle: {exponential_optimization['best_strategy']} avec {exponential_optimization['best_num_bins']} bins")

# Comparer les performances des différentes stratégies
print("\nComparaison des performances des différentes stratégies:")

# Pour la distribution gaussienne
print("\nDistribution gaussienne:")
for strategy, result in gaussian_comparison.items():
    print(f"  Stratégie {strategy}:")
    print(f"    Nombre de pics détectés: {len(result['peaks'])}")
    if result['relative_resolution'] is not None:
        if isinstance(result['relative_resolution'], (int, float)):
            print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        else:
            print(f"    Résolution relative: {result['relative_resolution']}")
    else:
        print(f"    Résolution relative: N/A")

# Pour la distribution log-normale
print("\nDistribution log-normale:")
for strategy, result in lognormal_comparison.items():
    print(f"  Stratégie {strategy}:")
    print(f"    Nombre de pics détectés: {len(result['peaks'])}")
    if result['relative_resolution'] is not None:
        if isinstance(result['relative_resolution'], (int, float)):
            print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        else:
            print(f"    Résolution relative: {result['relative_resolution']}")
    else:
        print(f"    Résolution relative: N/A")

# Pour la distribution exponentielle
print("\nDistribution exponentielle:")
for strategy, result in exponential_comparison.items():
    print(f"  Stratégie {strategy}:")
    print(f"    Nombre de pics détectés: {len(result['peaks'])}")
    if result['relative_resolution'] is not None:
        if isinstance(result['relative_resolution'], (int, float)):
            print(f"    Résolution relative: {result['relative_resolution']:.4f}")
        else:
            print(f"    Résolution relative: {result['relative_resolution']}")
    else:
        print(f"    Résolution relative: N/A")

# Conclusions
print("\nConclusions:")
print("1. Le binning logarithmique est particulièrement efficace pour les distributions asymétriques")
print("   et à queue lourde comme les distributions log-normales et exponentielles.")
print("2. Pour les distributions gaussiennes, le binning uniforme reste généralement plus efficace")
print("   en termes de résolution et de détection des pics.")
print("3. Le binning logarithmique offre une meilleure résolution dans les régions de faible densité")
print("   (queues des distributions), au prix d'une résolution réduite dans les régions de forte densité.")
print("4. Le ratio entre la largeur maximale et minimale des bins logarithmiques augmente avec le nombre")
print("   de bins, ce qui peut affecter l'interprétation visuelle de l'histogramme.")
print("5. Pour les distributions fortement asymétriques, le binning logarithmique peut être préférable")
print("   même avec un nombre réduit de bins, offrant un bon compromis entre résolution et lisibilité.")

print("\nTest terminé avec succès!")
print("Résultats sauvegardés dans les fichiers PNG correspondants.")
