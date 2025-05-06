#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques basées sur la saillance visuelle.
"""

import numpy as np
import matplotlib.pyplot as plt
from visual_saliency_metrics import (
    calculate_contrast_map,
    calculate_edge_map,
    calculate_curvature_map,
    calculate_peak_map,
    calculate_saliency_map,
    calculate_saliency_score,
    evaluate_saliency_quality,
    calculate_saliency_preservation,
    compare_histograms_saliency,
    compare_binning_strategies_saliency,
    find_optimal_binning_strategy_saliency
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

print("=== Test des métriques basées sur la saillance visuelle ===")

# Test 1: Calcul des cartes de caractéristiques
print("\n1. Test du calcul des cartes de caractéristiques")
# Créer un histogramme simple pour le test
test_hist = np.array([1, 2, 5, 10, 15, 10, 5, 2, 1])

contrast_map = calculate_contrast_map(test_hist)
edge_map = calculate_edge_map(test_hist)
curvature_map = calculate_curvature_map(test_hist)
peak_map = calculate_peak_map(test_hist)

print(f"Histogramme de test: {test_hist}")
print(f"Carte de contraste: {contrast_map}")
print(f"Carte des bords: {edge_map}")
print(f"Carte de courbure: {curvature_map}")
print(f"Carte des pics: {peak_map}")

# Test 2: Calcul de la carte de saillance globale
print("\n2. Test du calcul de la carte de saillance globale")
saliency_map = calculate_saliency_map(test_hist)
print(f"Carte de saillance: {saliency_map}")

# Test 3: Calcul du score de saillance
print("\n3. Test du calcul du score de saillance")
score = calculate_saliency_score(test_hist)
quality = evaluate_saliency_quality(score)
print(f"Score de saillance: {score:.4f}")
print(f"Qualité: {quality}")

# Test 4: Comparaison d'histogrammes
print("\n4. Test de la comparaison d'histogrammes")
# Créer un histogramme simplifié
simplified_hist = np.array([3, 15, 15, 3])

comparison = compare_histograms_saliency(test_hist, simplified_hist)
print(f"Score de saillance original: {comparison['original_saliency']:.4f}")
print(f"Score de saillance simplifié: {comparison['simplified_saliency']:.4f}")
print(f"Score de préservation: {comparison['preservation_score']:.4f}")
print(f"Ratio de saillance: {comparison['saliency_ratio']:.4f}")
print(f"Qualité: {comparison['quality']}")

# Test 5: Comparaison des stratégies de binning
print("\n5. Test de la comparaison des stratégies de binning")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Comparer différentes stratégies de binning
    results = compare_binning_strategies_saliency(data)
    
    for strategy, result in results.items():
        print(f"  Stratégie {strategy}:")
        print(f"    Score de saillance: {result['saliency_score']:.4f}")
        print(f"    Score de préservation: {result['preservation_score']:.4f}")
        print(f"    Qualité: {result['quality']}")

# Test 6: Recherche de la stratégie optimale
print("\n6. Test de la recherche de la stratégie optimale")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Trouver la stratégie optimale
    optimization = find_optimal_binning_strategy_saliency(data, num_bins_range=[5, 10, 20])
    
    print(f"Meilleure stratégie: {optimization['best_strategy']}")
    print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
    print(f"Score optimal: {optimization['best_score']:.4f}")
    print(f"Qualité: {optimization['best_quality']}")

# Test 7: Visualisation des résultats
print("\n7. Visualisation des résultats")
dist_name = "multimodal"  # Utiliser la distribution multimodale pour la visualisation
data = distributions[dist_name]

# Créer des histogrammes avec différents nombres de bins
hist_fine, _ = np.histogram(data, bins=100)
hist_medium, _ = np.histogram(data, bins=20)
hist_coarse, _ = np.histogram(data, bins=5)

# Calculer les cartes de saillance
saliency_fine = calculate_saliency_map(hist_fine)
saliency_medium = calculate_saliency_map(hist_medium)
saliency_coarse = calculate_saliency_map(hist_coarse)

# Calculer les scores de saillance
score_fine = calculate_saliency_score(hist_fine)
score_medium = calculate_saliency_score(hist_medium)
score_coarse = calculate_saliency_score(hist_coarse)

# Créer une figure pour la visualisation
plt.figure(figsize=(15, 10))

# Tracer l'histogramme fin et sa carte de saillance
plt.subplot(3, 2, 1)
plt.title("Histogramme fin (100 bins)")
plt.bar(range(len(hist_fine)), hist_fine, width=1.0)
plt.grid(True, alpha=0.3)

plt.subplot(3, 2, 2)
plt.title(f"Carte de saillance (score: {score_fine:.4f})")
plt.bar(range(len(saliency_fine)), saliency_fine, width=1.0, color='red')
plt.grid(True, alpha=0.3)

# Tracer l'histogramme moyen et sa carte de saillance
plt.subplot(3, 2, 3)
plt.title("Histogramme moyen (20 bins)")
plt.bar(range(len(hist_medium)), hist_medium, width=1.0)
plt.grid(True, alpha=0.3)

plt.subplot(3, 2, 4)
plt.title(f"Carte de saillance (score: {score_medium:.4f})")
plt.bar(range(len(saliency_medium)), saliency_medium, width=1.0, color='red')
plt.grid(True, alpha=0.3)

# Tracer l'histogramme grossier et sa carte de saillance
plt.subplot(3, 2, 5)
plt.title("Histogramme grossier (5 bins)")
plt.bar(range(len(hist_coarse)), hist_coarse, width=1.0)
plt.grid(True, alpha=0.3)

plt.subplot(3, 2, 6)
plt.title(f"Carte de saillance (score: {score_coarse:.4f})")
plt.bar(range(len(saliency_coarse)), saliency_coarse, width=1.0, color='red')
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("visual_saliency_comparison_test.png")
print("Figure sauvegardée sous 'visual_saliency_comparison_test.png'")

print("\nTest terminé avec succès!")
