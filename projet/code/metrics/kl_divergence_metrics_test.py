#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques basées sur la divergence KL.
"""

import numpy as np
import matplotlib.pyplot as plt
from kl_divergence_metrics import (
    calculate_symmetric_kl_divergence,
    calculate_kl_divergence_score,
    calculate_continuous_kl_divergence_score,
    evaluate_kl_divergence_quality,
    compare_histograms_kl,
    evaluate_histogram_fidelity,
    compare_binning_strategies_kl,
    find_optimal_binning_strategy_kl
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

print("=== Test des métriques basées sur la divergence KL ===")

# Test 1: Calcul de la divergence KL symétrique
print("\n1. Test du calcul de la divergence KL symétrique")
p = np.array([0.1, 0.4, 0.5])
q = np.array([0.2, 0.3, 0.5])
symmetric_kl = calculate_symmetric_kl_divergence(p, q)
print(f"Divergence KL symétrique: {symmetric_kl:.4f} bits")

# Test 2: Calcul du score de similarité basé sur la divergence KL
print("\n2. Test du calcul du score de similarité basé sur la divergence KL")
score = calculate_kl_divergence_score(p, q)
quality = evaluate_kl_divergence_quality(score)
print(f"Score de similarité: {score:.4f}")
print(f"Qualité: {quality}")

# Test 3: Comparaison d'histogrammes
print("\n3. Test de la comparaison d'histogrammes")
hist1 = np.array([10, 20, 30, 20, 10])
hist2 = np.array([5, 15, 40, 25, 5])
comparison = compare_histograms_kl(hist1, hist2)
print(f"Divergence KL (1→2): {comparison['kl_div_1_2']:.4f} bits")
print(f"Divergence KL (2→1): {comparison['kl_div_2_1']:.4f} bits")
print(f"Divergence KL symétrique: {comparison['symmetric_kl']:.4f} bits")
print(f"Score de similarité: {comparison['similarity_score']:.4f}")
print(f"Qualité: {comparison['quality']}")

# Test 4: Évaluation de la fidélité d'un histogramme
print("\n4. Test de l'évaluation de la fidélité d'un histogramme")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 20 + 1)
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    
    # Évaluer la fidélité de l'histogramme
    fidelity = evaluate_histogram_fidelity(data, bin_edges, bin_counts)
    
    print(f"Divergence KL: {fidelity['kl_divergence']:.4f} bits")
    print(f"Score de similarité: {fidelity['similarity_score']:.4f}")
    print(f"Qualité: {fidelity['quality']}")

# Test 5: Comparaison des stratégies de binning
print("\n5. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_kl(data)
    
    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Score de similarité: {result['similarity_score']:.4f}")
        print(f"    Qualité: {result['quality']}")
        print(f"    Divergence KL: {result['kl_divergence']:.4f}")

# Test 6: Recherche de la stratégie optimale
print("\n6. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_kl(data, num_bins_range=[5, 10, 20, 50])
    
    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Score optimal: {optimization['best_score']:.4f}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 7: Visualisation des résultats
print("\n7. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Comparer différentes stratégies de binning
results = compare_binning_strategies_kl(data)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 10))

# Tracer la distribution originale (KDE)
plt.subplot(2, 2, 1)
plt.title(f"Distribution originale ({dist_name})")
plt.hist(data, bins=50, density=True, alpha=0.5, color='gray')
x = np.linspace(min(data), max(data), 1000)
kde = np.exp(-(x - np.mean(data))**2 / (2 * np.var(data))) / np.sqrt(2 * np.pi * np.var(data))
plt.plot(x, kde, 'k-', linewidth=2)
plt.grid(True, alpha=0.3)

# Tracer les histogrammes pour chaque stratégie
for i, (strategy, result) in enumerate(results.items()):
    plt.subplot(2, 2, i + 2)
    plt.title(f"Stratégie: {strategy} (Score: {result['similarity_score']:.4f}, Qualité: {result['quality']})")
    plt.hist(data, bins=result['bin_edges'], density=True, alpha=0.5)
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("kl_divergence_comparison.png")
print("Figure sauvegardée sous 'kl_divergence_comparison.png'")

print("\nTest terminé avec succès!")
