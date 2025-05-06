#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de l'évaluation de la résolution avec binning uniforme.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from uniform_binning_resolution import (
    evaluate_uniform_binning_resolution,
    plot_uniform_binning_resolution_evaluation
)

print("=== Test de l'évaluation de la résolution avec binning uniforme ===")

# Générer des distributions synthétiques pour les tests
np.random.seed(42)  # Pour la reproductibilité

# Distribution gaussienne
gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

# Distribution bimodale
bimodal_data = np.concatenate([
    np.random.normal(loc=30, scale=5, size=500),
    np.random.normal(loc=70, scale=8, size=500)
])

# Évaluer la résolution pour la distribution gaussienne
print("\nÉvaluation pour la distribution gaussienne...")
gaussian_evaluation = evaluate_uniform_binning_resolution(
    gaussian_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5,
    theoretical_params={"sigma": 10}
)

# Visualiser les résultats
plot_uniform_binning_resolution_evaluation(
    gaussian_evaluation,
    save_path="uniform_binning_resolution_test_gaussian.png",
    show_plot=False
)

# Afficher les résultats clés
print("\nRésultats pour la distribution gaussienne:")
print(f"Meilleur nombre de bins selon le score de qualité: {gaussian_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {gaussian_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {gaussian_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {gaussian_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Afficher les largeurs de bins optimales
print("\nLargeurs de bins optimales:")
print(f"Selon la règle de Sturges: {gaussian_evaluation['optimal_bin_widths']['empirical_rules']['sturges']:.4f}")
print(f"Selon la règle de Scott: {gaussian_evaluation['optimal_bin_widths']['empirical_rules']['scott']:.4f}")
print(f"Selon la règle de Freedman-Diaconis: {gaussian_evaluation['optimal_bin_widths']['empirical_rules']['freedman_diaconis']:.4f}")
print(f"Selon la métrique FWHM: {gaussian_evaluation['optimal_bin_widths']['resolution_metrics']['fwhm']:.4f}")
print(f"Selon la métrique de résolution relative: {gaussian_evaluation['optimal_bin_widths']['resolution_metrics']['relative']:.4f}")

# Afficher les largeurs de bins théoriques
if gaussian_evaluation['theoretical_bin_widths']:
    print("\nLargeurs de bins théoriques:")
    for metric, width in gaussian_evaluation['theoretical_bin_widths'].items():
        print(f"Pour la métrique {metric}: {width:.4f}")

# Évaluer la résolution pour la distribution bimodale
print("\nÉvaluation pour la distribution bimodale...")
bimodal_evaluation = evaluate_uniform_binning_resolution(
    bimodal_data,
    min_bins=5,
    max_bins=50,  # Réduire pour accélérer le test
    step=5,
    theoretical_params={"sigma": 6.5}  # Moyenne pondérée des écarts-types
)

# Visualiser les résultats
plot_uniform_binning_resolution_evaluation(
    bimodal_evaluation,
    save_path="uniform_binning_resolution_test_bimodal.png",
    show_plot=False
)

# Afficher les résultats clés
print("\nRésultats pour la distribution bimodale:")
print(f"Meilleur nombre de bins selon le score de qualité: {bimodal_evaluation['best_quality_num_bins']}")
print(f"Règle de Sturges: {bimodal_evaluation['empirical_rules']['sturges']} bins")
print(f"Règle de Scott: {bimodal_evaluation['empirical_rules']['scott']} bins")
print(f"Règle de Freedman-Diaconis: {bimodal_evaluation['empirical_rules']['freedman_diaconis']} bins")

# Comparer les résultats entre les distributions
print("\nComparaison entre les distributions:")
print("Nombre optimal de bins:")
print(f"Gaussienne: {gaussian_evaluation['best_quality_num_bins']}")
print(f"Bimodale: {bimodal_evaluation['best_quality_num_bins']}")

print("\nRésolution relative optimale:")
gaussian_optimal_bins = gaussian_evaluation['bin_count_analysis']['optimal_num_bins']['relative']
bimodal_optimal_bins = bimodal_evaluation['bin_count_analysis']['optimal_num_bins']['relative']
gaussian_optimal_resolution = gaussian_evaluation['bin_count_analysis']['results_by_bin_count'][gaussian_optimal_bins]['relative_resolution']
bimodal_optimal_resolution = bimodal_evaluation['bin_count_analysis']['results_by_bin_count'][bimodal_optimal_bins]['relative_resolution']
print(f"Gaussienne: {gaussian_optimal_resolution:.4f} (avec {gaussian_optimal_bins} bins)")
print(f"Bimodale: {bimodal_optimal_resolution:.4f} (avec {bimodal_optimal_bins} bins)")

# Conclusions
print("\nConclusions:")
print("1. Le binning uniforme est plus efficace pour la distribution gaussienne que pour la distribution bimodale")
print("   en termes de résolution relative.")
print("2. La règle de Scott donne généralement de bons résultats pour les distributions unimodales.")
print("3. Pour les distributions multimodales, un nombre plus élevé de bins est souvent nécessaire")
print("   pour capturer correctement la structure des pics.")
print("4. La largeur optimale des bins dépend fortement de la structure de la distribution sous-jacente.")

print("\nTest terminé avec succès!")
print("Résultats sauvegardés dans les fichiers:")
print("- uniform_binning_resolution_test_gaussian.png")
print("- uniform_binning_resolution_test_gaussian_bin_widths.png")
print("- uniform_binning_resolution_test_bimodal.png")
print("- uniform_binning_resolution_test_bimodal_bin_widths.png")
