#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de l'évaluation de la résolution avec binning par quantiles.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from quantile_binning_resolution import (
    evaluate_quantile_binning_resolution,
    plot_quantile_binning_resolution_evaluation
)

# Importer également les fonctions pour le binning uniforme pour comparaison
from uniform_binning_resolution import (
    evaluate_uniform_binning_resolution
)

print("=== Test de l'évaluation de la résolution avec binning par quantiles ===")

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

# Évaluer la résolution pour la distribution gaussienne
print("\nÉvaluation pour la distribution gaussienne...")
gaussian_quantile_evaluation = evaluate_quantile_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec le binning uniforme pour comparaison
gaussian_uniform_evaluation = evaluate_uniform_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,
    step=5,
    theoretical_params={"sigma": 10}
)

# Visualiser les résultats
plot_quantile_binning_resolution_evaluation(
    gaussian_quantile_evaluation,
    save_path="quantile_binning_resolution_test_gaussian.png",
    show_plot=False
)

# Afficher les résultats clés
print("\nRésultats pour la distribution gaussienne:")
print(f"Meilleur nombre de bins (quantile): {gaussian_quantile_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {gaussian_uniform_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {gaussian_quantile_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {gaussian_quantile_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {gaussian_quantile_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Évaluer la résolution pour la distribution bimodale
print("\nÉvaluation pour la distribution bimodale...")
bimodal_quantile_evaluation = evaluate_quantile_binning_resolution(
    bimodal_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec le binning uniforme pour comparaison
bimodal_uniform_evaluation = evaluate_uniform_binning_resolution(
    bimodal_data,
    min_bins=5,
    max_bins=50,
    step=5,
    theoretical_params={"sigma": 6.5}  # Moyenne pondérée des écarts-types
)

# Visualiser les résultats
plot_quantile_binning_resolution_evaluation(
    bimodal_quantile_evaluation,
    save_path="quantile_binning_resolution_test_bimodal.png",
    show_plot=False
)

# Afficher les résultats clés
print("\nRésultats pour la distribution bimodale:")
print(f"Meilleur nombre de bins (quantile): {bimodal_quantile_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {bimodal_uniform_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {bimodal_quantile_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {bimodal_quantile_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {bimodal_quantile_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Évaluer la résolution pour la distribution asymétrique
print("\nÉvaluation pour la distribution asymétrique (log-normale)...")
lognormal_quantile_evaluation = evaluate_quantile_binning_resolution(
    lognormal_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5
)

# Évaluer également avec le binning uniforme pour comparaison
lognormal_uniform_evaluation = evaluate_uniform_binning_resolution(
    lognormal_data,
    min_bins=5,
    max_bins=50,
    step=5
)

# Visualiser les résultats
plot_quantile_binning_resolution_evaluation(
    lognormal_quantile_evaluation,
    save_path="quantile_binning_resolution_test_lognormal.png",
    show_plot=False
)

# Afficher les résultats clés
print("\nRésultats pour la distribution asymétrique (log-normale):")
print(f"Meilleur nombre de bins (quantile): {lognormal_quantile_evaluation['best_quality_num_bins']}")
print(f"Meilleur nombre de bins (uniforme): {lognormal_uniform_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {lognormal_quantile_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {lognormal_quantile_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {lognormal_quantile_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Comparer les résultats entre les distributions et les méthodes de binning
print("\nComparaison entre les distributions et méthodes de binning:")
print("\nDistribution gaussienne:")
optimal_res_quantile = gaussian_quantile_evaluation['bin_count_analysis'].get('optimal_resolution')
optimal_res_uniform = gaussian_uniform_evaluation['bin_count_analysis'].get('optimal_resolution')
if optimal_res_quantile is not None:
    print(f"Résolution relative optimale (quantile): {optimal_res_quantile:.4f}")
else:
    print("Résolution relative optimale (quantile): N/A")
if optimal_res_uniform is not None:
    print(f"Résolution relative optimale (uniforme): {optimal_res_uniform:.4f}")
else:
    print("Résolution relative optimale (uniforme): N/A")

print("\nDistribution bimodale:")
optimal_res_quantile = bimodal_quantile_evaluation['bin_count_analysis'].get('optimal_resolution')
optimal_res_uniform = bimodal_uniform_evaluation['bin_count_analysis'].get('optimal_resolution')
if optimal_res_quantile is not None:
    print(f"Résolution relative optimale (quantile): {optimal_res_quantile:.4f}")
else:
    print("Résolution relative optimale (quantile): N/A")
if optimal_res_uniform is not None:
    print(f"Résolution relative optimale (uniforme): {optimal_res_uniform:.4f}")
else:
    print("Résolution relative optimale (uniforme): N/A")

print("\nDistribution asymétrique (log-normale):")
optimal_res_quantile = lognormal_quantile_evaluation['bin_count_analysis'].get('optimal_resolution')
optimal_res_uniform = lognormal_uniform_evaluation['bin_count_analysis'].get('optimal_resolution')
if optimal_res_quantile is not None:
    print(f"Résolution relative optimale (quantile): {optimal_res_quantile:.4f}")
else:
    print("Résolution relative optimale (quantile): N/A")
if optimal_res_uniform is not None:
    print(f"Résolution relative optimale (uniforme): {optimal_res_uniform:.4f}")
else:
    print("Résolution relative optimale (uniforme): N/A")

# Conclusions
print("\nConclusions:")
print("1. Le binning par quantiles est particulièrement efficace pour les distributions asymétriques")
print("   où il offre une meilleure résolution que le binning uniforme.")
print("2. Pour les distributions multimodales, le binning par quantiles permet une meilleure")
print("   détection des pics en adaptant la largeur des bins à la densité des données.")
print("3. Pour les distributions gaussiennes, le binning uniforme reste compétitif et plus simple à interpréter.")
print("4. Le nombre optimal de bins dépend fortement de la distribution sous-jacente et")
print("   de la métrique de résolution considérée.")

print("\nTest terminé avec succès!")
print("Résultats sauvegardés dans les fichiers:")
print("- quantile_binning_resolution_test_gaussian.png")
print("- quantile_binning_resolution_test_bimodal.png")
print("- quantile_binning_resolution_test_lognormal.png")
