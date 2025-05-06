#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié pour les métriques de préservation des percentiles.
"""

import os
import sys
import numpy as np

# Ajouter le chemin du module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))

# Importer directement le module
import percentile_preservation_metrics as ppm

# Générer des données de test
np.random.seed(42)
data = np.random.normal(loc=100, scale=15, size=1000)

# Calculer les percentiles
percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
percentile_values = ppm.calculate_percentiles(data, percentiles)

print("=== Test des métriques de préservation des percentiles ===")
print("\nPercentiles calculés:")
for p, value in percentile_values.items():
    print(f"  P{p}: {value:.2f}")

# Générer un histogramme
bin_edges = np.linspace(min(data), max(data), 20 + 1)
bin_counts, _ = np.histogram(data, bins=bin_edges)

# Calculer le score de préservation des percentiles
score = ppm.calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
quality = ppm.evaluate_percentile_preservation_quality(score)

print(f"\nScore de préservation des percentiles: {score:.4f}")
print(f"Qualité: {quality}")

# Comparer différentes stratégies de binning
print("\nComparaison des stratégies de binning:")
results = ppm.compare_binning_strategies_percentile_preservation(data, ["uniform", "quantile", "logarithmic"], 20, percentiles)

for strategy, result in results.items():
    print(f"\nStratégie: {strategy}")
    print(f"  Score: {result['score']:.4f}")
    print(f"  Qualité: {result['quality']}")
    print(f"  Erreur relative moyenne: {result['metrics']['mean_relative_error']:.2f}%")
    print(f"  Erreur relative maximale: {result['metrics']['max_relative_error']:.2f}%")

print("\nTest terminé avec succès!")
