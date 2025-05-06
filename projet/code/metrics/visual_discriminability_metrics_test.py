#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques de discriminabilité visuelle.
"""

import numpy as np
import matplotlib.pyplot as plt
from visual_discriminability_metrics import (
    calculate_local_contrast,
    calculate_discriminability_score,
    evaluate_discriminability_quality,
    calculate_region_discriminability,
    evaluate_histogram_discriminability,
    compare_binning_strategies_discriminability,
    find_optimal_binning_strategy_discriminability
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

print("=== Test des métriques de discriminabilité visuelle ===")

# Test 1: Calcul du contraste local
print("\n1. Test du calcul du contraste local")
# Créer un histogramme simple pour le test
test_hist = np.array([1, 2, 5, 10, 15, 10, 5, 2, 1])
local_contrast = calculate_local_contrast(test_hist)

print(f"Histogramme de test: {test_hist}")
print(f"Contraste local: {local_contrast}")

# Test 2: Calcul du score de discriminabilité
print("\n2. Test du calcul du score de discriminabilité")
discriminability_score = calculate_discriminability_score(local_contrast)
quality = evaluate_discriminability_quality(discriminability_score)

print(f"Score de discriminabilité: {discriminability_score:.4f}")
print(f"Qualité: {quality}")

# Test 3: Calcul de la discriminabilité entre régions
print("\n3. Test du calcul de la discriminabilité entre régions")
# Définir des régions dans l'histogramme
regions = [(0, 3), (3, 6), (6, 9)]
region_discriminability = calculate_region_discriminability(test_hist, regions)

print(f"Moyennes des régions: {region_discriminability['region_means']}")
print(f"Contrastes des régions: {region_discriminability['region_contrasts']}")
print(f"Contrastes entre régions: {region_discriminability['inter_region_contrasts']}")
print(f"Score de discriminabilité: {region_discriminability['discriminability_score']:.4f}")
print(f"Qualité: {region_discriminability['quality']}")

# Test 4: Évaluation de la discriminabilité d'un histogramme
print("\n4. Test de l'évaluation de la discriminabilité d'un histogramme")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    
    # Évaluer la discriminabilité
    evaluation = evaluate_histogram_discriminability(bin_counts)
    
    print(f"Score de discriminabilité: {evaluation['discriminability_score']:.4f}")
    print(f"Score de discriminabilité entre régions: {evaluation['region_discriminability']['discriminability_score']:.4f}")
    print(f"Qualité: {evaluation['quality']}")

# Test 5: Comparaison des stratégies de binning
print("\n5. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_discriminability(data)
    
    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Score de discriminabilité: {result['discriminability_score']:.4f}")
        print(f"    Score de discriminabilité entre régions: {result['region_discriminability']:.4f}")
        print(f"    Qualité: {result['quality']}")

# Test 6: Recherche de la stratégie optimale
print("\n6. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_discriminability(data, num_bins_range=[5, 10, 20])
    
    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Score optimal: {optimization['best_score']:.4f}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 7: Visualisation des résultats
print("\n7. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Comparer différentes stratégies de binning
results = compare_binning_strategies_discriminability(data)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 10))

# Tracer la distribution originale
plt.subplot(2, 2, 1)
plt.title(f"Distribution originale ({dist_name})")
plt.hist(data, bins=50, density=True, alpha=0.5, color='gray')
plt.grid(True, alpha=0.3)

# Tracer les histogrammes et leur contraste local pour chaque stratégie
for i, (strategy, result) in enumerate(results.items()):
    plt.subplot(2, 2, i + 2)
    plt.title(f"Stratégie: {strategy} (Score: {result['discriminability_score']:.4f}, Qualité: {result['quality']})")
    
    # Tracer l'histogramme
    bin_counts = result['bin_counts']
    bin_edges = result['bin_edges']
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    plt.bar(bin_centers, bin_counts, width=bin_edges[1] - bin_edges[0], alpha=0.5, label='Histogramme')
    
    # Calculer et tracer le contraste local
    local_contrast = calculate_local_contrast(bin_counts)
    max_height = np.max(bin_counts)
    scaled_contrast = local_contrast * max_height * 0.5  # Mettre à l'échelle pour la visualisation
    
    plt.plot(bin_centers, scaled_contrast, 'r-', linewidth=2, label='Contraste local')
    plt.legend()
    plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("visual_discriminability_comparison.png")
print("Figure sauvegardée sous 'visual_discriminability_comparison.png'")

print("\nTest terminé avec succès!")
