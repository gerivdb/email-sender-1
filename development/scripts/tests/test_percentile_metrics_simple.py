#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test simplifié pour les métriques de préservation des percentiles.
"""

import os
import sys
import numpy as np

# Ajouter le répertoire du module au chemin de recherche
module_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics'))
sys.path.append(module_path)

# Importer le module de métriques de préservation des percentiles
from percentile_preservation_metrics import (
    calculate_percentiles,
    calculate_percentile_preservation_score,
    evaluate_percentile_preservation_quality,
    compare_binning_strategies_percentile_preservation
)


def generate_test_data(distribution_type="normal", size=1000):
    """
    Génère des données de test selon le type de distribution spécifié.
    """
    np.random.seed(42)

    if distribution_type == "normal":
        return np.random.normal(loc=100, scale=15, size=size)
    elif distribution_type == "asymmetric":
        return np.random.gamma(shape=3, scale=10, size=size)
    elif distribution_type == "multimodal":
        return np.concatenate([
            np.random.normal(loc=70, scale=10, size=size // 2),
            np.random.normal(loc=130, scale=15, size=size // 2)
        ])
    else:
        return np.random.normal(loc=100, scale=15, size=size)


def main():
    """
    Fonction principale exécutant les tests simplifiés.
    """
    print("=== Tests simplifiés des métriques de préservation des percentiles ===")

    # Générer des données de test
    data_normal = generate_test_data("normal")
    data_asymmetric = generate_test_data("asymmetric")
    data_multimodal = generate_test_data("multimodal")

    # Tester le calcul des percentiles
    print("\n1. Test du calcul des percentiles")
    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]

    for name, data in [("normale", data_normal), ("asymétrique", data_asymmetric), ("multimodale", data_multimodal)]:
        print(f"\nDistribution {name}:")
        percentile_values = calculate_percentiles(data, percentiles)
        for p, value in percentile_values.items():
            print(f"  P{p}: {value:.2f}")

    # Tester la comparaison des stratégies de binning
    print("\n2. Test de la comparaison des stratégies de binning")

    for name, data in [("normale", data_normal), ("asymétrique", data_asymmetric), ("multimodale", data_multimodal)]:
        print(f"\nDistribution {name}:")
        results = compare_binning_strategies_percentile_preservation(data)

        for strategy, result in results.items():
            score = result["score"]
            quality = result["quality"]
            mean_error = result["metrics"]["mean_relative_error"]
            max_error = result["metrics"]["max_relative_error"]

            print(f"  Stratégie {strategy}:")
            print(f"    Score: {score:.4f} ({quality})")
            print(f"    Erreur relative moyenne: {mean_error:.2f}%")
            print(f"    Erreur relative maximale: {max_error:.2f}%")

    print("\nTests simplifiés terminés avec succès!")


if __name__ == "__main__":
    main()
