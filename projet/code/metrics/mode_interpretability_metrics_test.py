#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques d'interprétabilité des modes.
"""

import numpy as np
import matplotlib.pyplot as plt
from mode_interpretability_metrics import (
    detect_modes,
    calculate_mode_clarity,
    calculate_mode_distinctness,
    calculate_mode_consistency,
    evaluate_interpretability_quality,
    calculate_interpretability_score,
    evaluate_histogram_interpretability,
    compare_binning_strategies_interpretability,
    find_optimal_binning_strategy_interpretability
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

print("=== Test des métriques d'interprétabilité des modes ===")

# Test 1: Détection des modes
print("\n1. Test de la détection des modes")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    mode_info = detect_modes(data)
    print(f"Nombre de modes détectés: {mode_info['num_modes']}")
    if mode_info['num_modes'] > 0:
        print(f"Positions des modes: {mode_info['mode_positions']}")
        print(f"Hauteurs des modes: {mode_info['mode_heights']}")
        print(f"Proéminences des modes: {mode_info['mode_prominences']}")
        print(f"Largeurs des modes: {mode_info['mode_widths']}")

# Test 2: Calcul des scores d'interprétabilité
print("\n2. Test du calcul des scores d'interprétabilité")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    mode_info = detect_modes(data)
    
    clarity = calculate_mode_clarity(mode_info)
    distinctness = calculate_mode_distinctness(mode_info)
    
    print(f"Score de clarté: {clarity:.4f}")
    print(f"Score de distinctivité: {distinctness:.4f}")
    
    interpretability_score = calculate_interpretability_score(clarity, distinctness)
    quality = evaluate_interpretability_quality(interpretability_score)
    
    print(f"Score d'interprétabilité: {interpretability_score:.4f}")
    print(f"Qualité: {quality}")

# Test 3: Cohérence des modes entre distributions
print("\n3. Test de la cohérence des modes entre distributions")
# Créer une version simplifiée de la distribution multimodale
data = distributions["multimodal"]
original_mode_info = detect_modes(data)

# Créer différentes simplifications
bin_edges_coarse = np.linspace(min(data), max(data), 6)  # 5 bins
bin_counts_coarse, _ = np.histogram(data, bins=bin_edges_coarse)
mode_info_coarse = detect_modes(data, bin_edges_coarse, bin_counts_coarse)

bin_edges_medium = np.linspace(min(data), max(data), 21)  # 20 bins
bin_counts_medium, _ = np.histogram(data, bins=bin_edges_medium)
mode_info_medium = detect_modes(data, bin_edges_medium, bin_counts_medium)

# Calculer la cohérence
consistency_coarse = calculate_mode_consistency(original_mode_info, mode_info_coarse)
consistency_medium = calculate_mode_consistency(original_mode_info, mode_info_medium)

print(f"Nombre de modes dans la distribution originale: {original_mode_info['num_modes']}")
print(f"Nombre de modes dans la simplification grossière (5 bins): {mode_info_coarse['num_modes']}")
print(f"Nombre de modes dans la simplification moyenne (20 bins): {mode_info_medium['num_modes']}")
print(f"Cohérence des modes (5 bins): {consistency_coarse:.4f}")
print(f"Cohérence des modes (20 bins): {consistency_medium:.4f}")

# Test 4: Évaluation de l'interprétabilité d'un histogramme
print("\n4. Test de l'évaluation de l'interprétabilité d'un histogramme")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    
    # Évaluer l'interprétabilité
    evaluation = evaluate_histogram_interpretability(data, bin_edges, bin_counts)
    
    print(f"Nombre de modes: {evaluation['mode_info']['num_modes']}")
    print(f"Score de clarté: {evaluation['clarity']:.4f}")
    print(f"Score de distinctivité: {evaluation['distinctness']:.4f}")
    print(f"Score d'interprétabilité: {evaluation['interpretability_score']:.4f}")
    print(f"Qualité: {evaluation['quality']}")

# Test 5: Comparaison des stratégies de binning
print("\n5. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_interpretability(data)
    
    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Nombre de modes: {result['mode_info']['num_modes']}")
        print(f"    Score de clarté: {result['clarity']:.4f}")
        print(f"    Score de distinctivité: {result['distinctness']:.4f}")
        print(f"    Score de cohérence: {result['consistency']:.4f}")
        print(f"    Score d'interprétabilité: {result['interpretability_score']:.4f}")
        print(f"    Qualité: {result['quality']}")

# Test 6: Recherche de la stratégie optimale
print("\n6. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_interpretability(data, num_bins_range=[5, 10, 20])
    
    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Score optimal: {optimization['best_score']:.4f}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 7: Visualisation des résultats
print("\n7. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Comparer différentes stratégies de binning
results = compare_binning_strategies_interpretability(data)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 10))

# Tracer la distribution originale
plt.subplot(2, 2, 1)
plt.title(f"Distribution originale ({dist_name})")
plt.hist(data, bins=50, density=True, alpha=0.5, color='gray')
plt.grid(True, alpha=0.3)

# Tracer les histogrammes pour chaque stratégie
for i, (strategy, result) in enumerate(results.items()):
    plt.subplot(2, 2, i + 2)
    plt.title(f"Stratégie: {strategy} (Score: {result['interpretability_score']:.4f}, Qualité: {result['quality']})")
    plt.hist(data, bins=result['bin_edges'], density=True, alpha=0.5)
    
    # Marquer les modes détectés
    if result['mode_info']['num_modes'] > 0:
        for pos, height in zip(result['mode_info']['mode_positions'], result['mode_info']['mode_heights']):
            plt.plot(pos, height, 'ro', markersize=8)
    
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("mode_interpretability_comparison.png")
print("Figure sauvegardée sous 'mode_interpretability_comparison.png'")

print("\nTest terminé avec succès!")
