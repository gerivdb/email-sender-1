#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques de résolution.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Afficher des informations de débogage
print("Chemin Python:", sys.path)
print("Répertoire courant:", os.getcwd())
print("Fichiers dans le répertoire:", os.listdir(os.path.dirname(os.path.abspath(__file__))))

from resolution_metrics import (
    calculate_fwhm,
    calculate_max_slope_resolution,
    calculate_curvature_resolution,
    calculate_relative_resolution,
    compare_resolution_metrics,
    compare_binning_strategies_resolution,
    find_optimal_binning_strategy_resolution
)

# Générer des données de test
np.random.seed(42)

# Différentes distributions pour les tests
distributions = {
    "normal": np.random.normal(loc=100, scale=15, size=1000),
    "asymmetric": np.random.gamma(shape=3, scale=10, size=1000),
    "leptokurtic": np.random.standard_t(df=3, size=1000) * 15 + 100,
    "multimodal": np.concatenate([
        np.random.normal(loc=70, scale=10, size=500),
        np.random.normal(loc=130, scale=15, size=500)
    ])
}

print("=== Test des métriques de résolution ===")

# Test 1: Calcul de la largeur à mi-hauteur (FWHM)
print("\n1. Test du calcul de la largeur à mi-hauteur (FWHM)")
# Créer un histogramme simple pour le test
test_hist = np.array([1, 2, 5, 10, 15, 10, 5, 2, 1])
test_bin_edges = np.linspace(0, 10, len(test_hist) + 1)

fwhm_results = calculate_fwhm(test_hist, test_bin_edges)

print(f"Histogramme de test: {test_hist}")
print(f"Nombre de pics détectés: {len(fwhm_results['peaks'])}")
if len(fwhm_results['peaks']) > 0:
    print(f"Positions des pics: {fwhm_results['peaks']}")
    print(f"FWHM (bins): {fwhm_results['fwhm_bins']}")
    print(f"FWHM (valeurs): {fwhm_results['fwhm_values']}")
    print(f"FWHM moyenne (bins): {fwhm_results['mean_fwhm_bins']}")
    print(f"FWHM moyenne (valeurs): {fwhm_results['mean_fwhm_values']}")

# Test 2: Calcul de la résolution basée sur la pente maximale
print("\n2. Test du calcul de la résolution basée sur la pente maximale")
slope_results = calculate_max_slope_resolution(test_hist, test_bin_edges)

print(f"Histogramme de test: {test_hist}")
print(f"Nombre de pics détectés: {len(slope_results['peaks'])}")
if len(slope_results['peaks']) > 0:
    print(f"Positions des pics: {slope_results['peaks']}")
    print(f"Pentes maximales: {slope_results['max_slopes']}")
    print(f"Résolutions basées sur la pente: {slope_results['slope_resolutions']}")
    print(f"Résolution moyenne basée sur la pente: {slope_results['mean_slope_resolution']}")

# Test 3: Calcul de la résolution basée sur la courbure
print("\n3. Test du calcul de la résolution basée sur la courbure")
curvature_results = calculate_curvature_resolution(test_hist, test_bin_edges)

print(f"Histogramme de test: {test_hist}")
print(f"Nombre de pics détectés: {len(curvature_results['peaks'])}")
if len(curvature_results['peaks']) > 0:
    print(f"Positions des pics: {curvature_results['peaks']}")
    print(f"Courbures maximales: {curvature_results['max_curvatures']}")
    print(f"Résolutions basées sur la courbure: {curvature_results['curvature_resolutions']}")
    print(f"Résolution moyenne basée sur la courbure: {curvature_results['mean_curvature_resolution']}")

# Test 4: Calcul de la résolution relative
print("\n4. Test du calcul de la résolution relative")
resolution_results = calculate_relative_resolution(test_hist, test_bin_edges)

print(f"Résolution relative: {resolution_results['relative_resolution']}")
print(f"Qualité de la résolution: {resolution_results['resolution_quality']}")
print(f"Distance moyenne entre les modes: {resolution_results['mean_mode_distance']}")

# Test 5: Comparaison des métriques de résolution
print("\n5. Test de la comparaison des métriques de résolution")
comparison = compare_resolution_metrics(test_hist, test_bin_edges)

print(f"Nombre de pics détectés (FWHM): {comparison['num_peaks_fwhm']}")
print(f"Nombre de pics détectés (Slope): {comparison['num_peaks_slope']}")
print(f"Nombre de pics détectés (Curvature): {comparison['num_peaks_curvature']}")
print(f"Résolution FWHM moyenne: {comparison['mean_fwhm']}")
print(f"Résolution Slope moyenne: {comparison['mean_slope_resolution']}")
print(f"Résolution Curvature moyenne: {comparison['mean_curvature_resolution']}")
print(f"Résolution relative: {comparison['relative_resolution']}")
print(f"Qualité de la résolution: {comparison['resolution_quality']}")
print(f"Métrique la plus discriminante: {comparison['most_discriminant']}")

# Test 6: Test sur différentes distributions
print("\n6. Test sur différentes distributions")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Calculer la largeur à mi-hauteur (FWHM)
    fwhm_results = calculate_fwhm(bin_counts, bin_edges)

    print(f"Nombre de pics détectés: {len(fwhm_results['peaks'])}")
    if len(fwhm_results['peaks']) > 0:
        print(f"FWHM moyenne (valeurs): {fwhm_results['mean_fwhm_values']}")

    # Calculer la résolution relative
    resolution_results = calculate_relative_resolution(bin_counts, bin_edges)

    print(f"Résolution relative: {resolution_results['relative_resolution']}")
    print(f"Qualité de la résolution: {resolution_results['resolution_quality']}")

# Test 7: Comparaison des stratégies de binning
print("\n7. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_resolution(data)

    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Nombre de pics détectés: {len(result['peaks'])}")
        print(f"    Résolution relative: {result['relative_resolution']}")
        print(f"    Qualité de la résolution: {result['resolution_quality']}")

# Test 8: Recherche de la stratégie optimale
print("\n8. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_resolution(data, num_bins_range=[5, 10, 20])

    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Meilleure résolution relative: {optimization['best_resolution']}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 9: Visualisation des résultats
print("\n9. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Comparer différentes stratégies de binning
results = compare_binning_strategies_resolution(data)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 10))

# Tracer l'histogramme original
plt.subplot(2, 2, 1)
plt.title(f"Distribution originale ({dist_name})")
plt.hist(data, bins=50, density=True, alpha=0.5, color='gray')
plt.grid(True, alpha=0.3)

# Tracer les histogrammes pour chaque stratégie
for i, (strategy, result) in enumerate(results.items()):
    plt.subplot(2, 2, i + 2)
    resolution_str = f"{result['relative_resolution']:.4f}" if result['relative_resolution'] is not None else "N/A"
    plt.title(f"Stratégie: {strategy} (Résolution: {resolution_str}, Qualité: {result['resolution_quality']})")

    # Tracer l'histogramme
    plt.hist(data, bins=result['bin_edges'], density=True, alpha=0.5)

    # Marquer les pics détectés
    if len(result['peaks']) > 0:
        for peak in result['peaks']:
            plt.axvline(x=peak, color='r', linestyle='--', alpha=0.7)

    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("resolution_comparison_test.png")
print("Figure sauvegardée sous 'resolution_comparison_test.png'")

# Test 10: Visualisation de la comparaison des métriques de résolution
print("\n10. Visualisation de la comparaison des métriques de résolution")

# Créer un histogramme
bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
bin_counts, _ = np.histogram(data, bins=bin_edges)

# Comparer les métriques de résolution
comparison = compare_resolution_metrics(bin_counts, bin_edges)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 15))

# Tracer l'histogramme original
plt.subplot(3, 2, 1)
plt.title(f"Distribution originale ({dist_name})")
plt.hist(data, bins=bin_edges, density=True, alpha=0.5, color='gray')
plt.grid(True, alpha=0.3)

# Tracer l'histogramme avec les pics détectés par FWHM
plt.subplot(3, 2, 2)
plt.title(f"FWHM: {comparison['num_peaks_fwhm']} pics, Résolution: {comparison['mean_fwhm']:.4f}")
plt.hist(data, bins=bin_edges, density=True, alpha=0.5)
if comparison['num_peaks_fwhm'] > 0:
    for peak in comparison['peaks_fwhm']:
        plt.axvline(x=peak, color='r', linestyle='--', alpha=0.7)
plt.grid(True, alpha=0.3)

# Tracer l'histogramme avec les pics détectés par la pente maximale
plt.subplot(3, 2, 3)
plt.title(f"Slope: {comparison['num_peaks_slope']} pics, Résolution: {comparison['mean_slope_resolution']:.4f}")
plt.hist(data, bins=bin_edges, density=True, alpha=0.5)
if comparison['num_peaks_slope'] > 0:
    for peak in comparison['peaks_slope']:
        plt.axvline(x=peak, color='g', linestyle='--', alpha=0.7)
plt.grid(True, alpha=0.3)

# Tracer l'histogramme avec les pics détectés par la courbure
plt.subplot(3, 2, 4)
plt.title(f"Curvature: {comparison['num_peaks_curvature']} pics, Résolution: {comparison['mean_curvature_resolution']:.4f}")
plt.hist(data, bins=bin_edges, density=True, alpha=0.5)
if comparison['num_peaks_curvature'] > 0:
    for peak in comparison['peaks_curvature']:
        plt.axvline(x=peak, color='b', linestyle='--', alpha=0.7)
plt.grid(True, alpha=0.3)

# Tracer l'histogramme avec tous les types de pics
plt.subplot(3, 2, 5)
plt.title(f"Comparaison: {comparison['most_discriminant']} est plus discriminant")
plt.hist(data, bins=bin_edges, density=True, alpha=0.5)
if comparison['num_peaks_fwhm'] > 0:
    for peak in comparison['peaks_fwhm']:
        plt.axvline(x=peak, color='r', linestyle='--', alpha=0.7, label='FWHM')
if comparison['num_peaks_slope'] > 0:
    for peak in comparison['peaks_slope']:
        plt.axvline(x=peak, color='g', linestyle=':', alpha=0.7, label='Slope')
if comparison['num_peaks_curvature'] > 0:
    for peak in comparison['peaks_curvature']:
        plt.axvline(x=peak, color='b', linestyle='-.', alpha=0.7, label='Curvature')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("resolution_metrics_comparison.png")
print("Figure sauvegardée sous 'resolution_metrics_comparison.png'")

print("\nTest terminé avec succès!")
