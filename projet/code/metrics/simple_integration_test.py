#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test d'intégration simplifié pour les métriques pondérées.
"""

import numpy as np
from weighted_moment_metrics import calculate_total_weighted_error


def test_simple_integration():
    """Test d'intégration simplifié."""
    print("Test d'intégration simplifié pour les métriques pondérées")
    print("=" * 70)
    
    # Générer des données de test
    np.random.seed(42)
    data = np.random.normal(loc=100, scale=15, size=1000)
    
    # Générer un histogramme
    bin_edges = np.linspace(min(data), max(data), 21)
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    
    # Définir différentes stratégies de pondération
    weight_sets = [
        [0.25, 0.25, 0.25, 0.25],  # Équilibrée
        [0.40, 0.30, 0.20, 0.10],  # Standard
        [0.45, 0.35, 0.15, 0.05],  # Monitoring
        [0.20, 0.50, 0.20, 0.10]   # Stabilité
    ]
    
    weight_names = [
        "Équilibrée",
        "Standard",
        "Monitoring",
        "Stabilité"
    ]
    
    # Calculer et afficher les résultats
    for weights, name in zip(weight_sets, weight_names):
        total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
        
        print(f"\nStratégie de pondération: {name}")
        print(f"Poids: {weights}")
        print(f"Erreur totale pondérée: {total_error:.2f}")
        print("Composantes:")
        for moment, error_info in components.items():
            print(f"  {moment.capitalize()}: Erreur brute = {error_info['raw_error']:.2f}%, "
                  f"Poids = {error_info['weight']:.2f}, "
                  f"Erreur pondérée = {error_info['weighted_error']:.2f}")
    
    print("\nTest d'intégration terminé avec succès!")
    return True


if __name__ == "__main__":
    test_simple_integration()
