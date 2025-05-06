#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques basées sur l'information mutuelle.
"""

import numpy as np
import matplotlib.pyplot as plt
from mutual_information_metrics import (
    calculate_mutual_information,
    calculate_normalized_mutual_information,
    estimate_mutual_information_from_samples,
    estimate_normalized_mutual_information_from_samples,
    calculate_mutual_information_score,
    evaluate_mutual_information_quality,
    evaluate_histogram_fidelity_mi,
    compare_binning_strategies_mi,
    find_optimal_binning_strategy_mi
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

print("=== Test des métriques basées sur l'information mutuelle ===")

# Test 1: Calcul de l'information mutuelle
print("\n1. Test du calcul de l'information mutuelle")
# Créer une distribution jointe avec dépendance
joint_distribution = np.array([
    [0.2, 0.1, 0.0],
    [0.1, 0.3, 0.1],
    [0.0, 0.1, 0.2]
])
mi = calculate_mutual_information(joint_distribution)
nmi = calculate_normalized_mutual_information(joint_distribution)
print(f"Information mutuelle: {mi:.4f} bits")
print(f"Information mutuelle normalisée: {nmi:.4f}")

# Test 2: Estimation de l'information mutuelle à partir d'échantillons
print("\n2. Test de l'estimation de l'information mutuelle à partir d'échantillons")
# Créer des échantillons corrélés
n_samples = 1000
x = np.random.normal(0, 1, n_samples)
noise = np.random.normal(0, 0.5, n_samples)
y = 0.8 * x + noise  # y est corrélé à x

mi_samples = estimate_mutual_information_from_samples(x, y, bins=20)
nmi_samples = estimate_normalized_mutual_information_from_samples(x, y, bins=20)
print(f"Information mutuelle estimée: {mi_samples:.4f} bits")
print(f"Information mutuelle normalisée estimée: {nmi_samples:.4f}")

# Test 3: Calcul du score d'information mutuelle
print("\n3. Test du calcul du score d'information mutuelle")
max_mi = 2.0  # Valeur arbitraire pour l'exemple
score = calculate_mutual_information_score(mi, max_mi)
quality = evaluate_mutual_information_quality(score)
print(f"Score d'information mutuelle: {score:.4f}")
print(f"Qualité: {quality}")

# Test 4: Évaluation de la fidélité d'un histogramme
print("\n4. Test de l'évaluation de la fidélité d'un histogramme")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 20 + 1)
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Évaluer la fidélité de l'histogramme
    fidelity = evaluate_histogram_fidelity_mi(data, bin_edges, bin_counts)

    print(f"Information mutuelle: {fidelity['mutual_information']:.4f} bits")
    print(f"Information mutuelle normalisée: {fidelity['normalized_mutual_information']:.4f}")
    print(f"Score MI: {fidelity['mi_score']:.4f}")
    print(f"Qualité: {fidelity['quality']}")

# Test 5: Comparaison des stratégies de binning
print("\n5. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_mi(data)

    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Information mutuelle: {result['mutual_information']:.4f} bits")
        print(f"    Information mutuelle normalisée: {result['normalized_mutual_information']:.4f}")
        print(f"    Score MI: {result['mi_score']:.4f}")
        print(f"    Qualité: {result['quality']}")

# Test 6: Recherche de la stratégie optimale
print("\n6. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")

    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_mi(data, num_bins_range=[5, 10, 20])

    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Score optimal: {optimization['best_score']:.4f}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 7: Visualisation des résultats
print("\n7. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Comparer différentes stratégies de binning
results = compare_binning_strategies_mi(data)

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
    plt.title(f"Stratégie: {strategy} (Score MI: {result['mi_score']:.4f}, Qualité: {result['quality']})")
    plt.hist(data, bins=result['bin_edges'], density=True, alpha=0.5)
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("mutual_information_comparison.png")
print("Figure sauvegardée sous 'mutual_information_comparison.png'")

print("\nTest terminé avec succès!")
