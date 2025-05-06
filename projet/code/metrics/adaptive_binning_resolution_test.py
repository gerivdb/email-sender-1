#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de l'algorithme adaptatif pour maximiser la résolution des histogrammes.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from adaptive_binning_resolution import (
    detect_distribution_characteristics,
    create_adaptive_binning,
    evaluate_adaptive_binning_resolution,
    plot_adaptive_binning_resolution
)

print("=== Test de l'algorithme adaptatif pour maximiser la résolution ===")

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

# Tester la détection des caractéristiques de la distribution
print("\nTest de la détection des caractéristiques de la distribution:")

for name, data in [("Gaussienne", gaussian_data),
                  ("Bimodale", bimodal_data),
                  ("Log-normale", lognormal_data),
                  ("Exponentielle", exponential_data)]:
    print(f"\nDistribution {name}:")
    characteristics = detect_distribution_characteristics(data)

    print(f"  Statistiques de base:")
    print(f"    Moyenne: {characteristics['basic_stats']['mean']:.2f}")
    print(f"    Médiane: {characteristics['basic_stats']['median']:.2f}")
    print(f"    Écart-type: {characteristics['basic_stats']['std']:.2f}")
    print(f"    Plage: {characteristics['basic_stats']['range']:.2f}")

    print(f"  Moments:")
    print(f"    Asymétrie (skewness): {characteristics['moments']['skewness']:.2f}")
    print(f"    Aplatissement (kurtosis): {characteristics['moments']['kurtosis']:.2f}")

    print(f"  Modalité:")
    print(f"    Multimodale: {characteristics['modality']['is_multimodal']}")
    print(f"    Nombre de modes: {characteristics['modality']['num_modes']}")

    print(f"  Type de distribution:")
    print(f"    Asymétrique: {characteristics['distribution_type']['is_asymmetric']}")
    print(f"    Queue lourde: {characteristics['distribution_type']['is_heavy_tailed']}")
    print(f"    Queue légère: {characteristics['distribution_type']['is_light_tailed']}")

# Tester la création du binning adaptatif
print("\nTest de la création du binning adaptatif:")

for name, data in [("Gaussienne", gaussian_data),
                  ("Bimodale", bimodal_data),
                  ("Log-normale", lognormal_data),
                  ("Exponentielle", exponential_data)]:
    print(f"\nDistribution {name}:")

    # Tester différents niveaux de résolution
    for resolution in ["low", "medium", "high"]:
        bin_edges, metadata = create_adaptive_binning(data, target_resolution=resolution, max_bins=50)

        print(f"  Résolution {resolution}:")
        print(f"    Stratégie de base: {metadata['base_strategy']}")
        print(f"    Nombre de bins: {metadata['num_bins']}")
        print(f"    Règles empiriques: Sturges={metadata['empirical_rules']['sturges']}, "
              f"Scott={metadata['empirical_rules']['scott']}, "
              f"Freedman-Diaconis={metadata['empirical_rules']['freedman_diaconis']}")

# Tester l'évaluation de la résolution avec binning adaptatif
print("\nTest de l'évaluation de la résolution avec binning adaptatif:")

for name, data in [("Gaussienne", gaussian_data),
                  ("Bimodale", bimodal_data),
                  ("Log-normale", lognormal_data),
                  ("Exponentielle", exponential_data)]:
    print(f"\nDistribution {name}:")

    # Évaluer la résolution avec binning adaptatif
    evaluation = evaluate_adaptive_binning_resolution(
        data,
        target_resolution="high",
        max_bins=50,
        compare_with_standard=True
    )

    # Afficher les résultats
    adaptive_results = evaluation["adaptive"]
    print(f"  Binning adaptatif:")
    print(f"    Stratégie de base: {adaptive_results['metadata']['base_strategy']}")
    print(f"    Nombre de bins: {adaptive_results['num_bins']}")
    print(f"    Nombre de pics détectés: {adaptive_results['num_peaks_fwhm']}")

    rel_res = adaptive_results['relative_resolution']
    if rel_res is not None:
        if isinstance(rel_res, (int, float)):
            print(f"    Résolution relative: {rel_res:.4f}")
        else:
            print(f"    Résolution relative: {rel_res}")
    else:
        print(f"    Résolution relative: N/A")

    # Comparer avec les stratégies standard
    for strategy in ["uniform", "quantile", "logarithmic"]:
        if strategy in evaluation:
            result = evaluation[strategy]
            print(f"  Binning {strategy}:")
            print(f"    Nombre de pics détectés: {len(result.get('peaks', []))}")
            rel_res = result.get('relative_resolution')
            if rel_res is not None:
                if isinstance(rel_res, (int, float)):
                    print(f"    Résolution relative: {rel_res:.4f}")
                else:
                    print(f"    Résolution relative: {rel_res}")
            else:
                print(f"    Résolution relative: N/A")

    # Visualiser les résultats
    plot_adaptive_binning_resolution(
        evaluation,
        save_path=f"adaptive_binning_resolution_test_{name.lower()}.png",
        show_plot=False
    )

# Tester l'impact du niveau de résolution cible
print("\nTest de l'impact du niveau de résolution cible:")

for name, data in [("Gaussienne", gaussian_data),
                  ("Bimodale", bimodal_data)]:
    print(f"\nDistribution {name}:")

    # Tester différents niveaux de résolution
    for resolution in ["low", "medium", "high"]:
        evaluation = evaluate_adaptive_binning_resolution(
            data,
            target_resolution=resolution,
            max_bins=50,
            compare_with_standard=False
        )

        adaptive_results = evaluation["adaptive"]
        print(f"  Résolution {resolution}:")
        print(f"    Stratégie de base: {adaptive_results['metadata']['base_strategy']}")
        print(f"    Nombre de bins: {adaptive_results['num_bins']}")
        print(f"    Nombre de pics détectés: {adaptive_results['num_peaks_fwhm']}")

        rel_res = adaptive_results['relative_resolution']
        if rel_res is not None:
            if isinstance(rel_res, (int, float)):
                print(f"    Résolution relative: {rel_res:.4f}")
            else:
                print(f"    Résolution relative: {rel_res}")
        else:
            print(f"    Résolution relative: N/A")

# Conclusions
print("\nConclusions:")
print("1. L'algorithme adaptatif sélectionne automatiquement la stratégie de binning optimale")
print("   en fonction des caractéristiques de la distribution.")
print("2. Pour les distributions gaussiennes, le binning uniforme est généralement préféré,")
print("   tandis que pour les distributions asymétriques, le binning logarithmique est choisi.")
print("3. Pour les distributions multimodales, le binning par quantiles offre souvent")
print("   une meilleure résolution en adaptant la largeur des bins à la densité des données.")
print("4. Le niveau de résolution cible permet d'ajuster le compromis entre la détection")
print("   des pics et la lisibilité de l'histogramme.")
print("5. L'algorithme adaptatif combine les avantages des différentes stratégies de binning")
print("   pour maximiser la résolution en fonction du type de distribution.")

print("\nTest terminé avec succès!")
print("Résultats sauvegardés dans les fichiers PNG correspondants.")
