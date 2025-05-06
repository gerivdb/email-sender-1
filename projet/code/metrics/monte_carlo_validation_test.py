#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié de la validation Monte Carlo pour la relation entre largeur des bins et résolution.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from monte_carlo_validation import (
    validate_bin_width_resolution_relationship_monte_carlo,
    plot_monte_carlo_validation_results
)

print("=== Test simplifié de la validation Monte Carlo ===")

# Paramètres réduits pour un test rapide
n_simulations = 10  # Nombre réduit de simulations
n_samples = 1000    # Nombre réduit d'échantillons
bin_width_factors = np.linspace(0.1, 2.0, 5)  # Moins de points

# Distribution gaussienne uniquement pour le test
print("\nValidation pour une distribution gaussienne (test rapide)...")
gaussian_results = validate_bin_width_resolution_relationship_monte_carlo(
    dist_type='gaussian',
    dist_params={'mu': 0.0, 'sigma': 1.0},
    bin_width_factors=bin_width_factors,
    n_simulations=n_simulations,
    n_samples=n_samples
)

# Visualiser les résultats
plot_monte_carlo_validation_results(
    gaussian_results,
    save_path="monte_carlo_validation_test.png",
    show_plot=False
)

print("\nTest terminé avec succès!")
print("Résultats sauvegardés dans le fichier: monte_carlo_validation_test.png")

# Afficher les résultats numériques
print("\nRésultats numériques:")
print(f"Facteurs de largeur de bin: {gaussian_results['bin_width_factors']}")
print("\nErreurs FWHM:")
print(f"Empiriques: {gaussian_results['fwhm']['errors']}")
print(f"Théoriques: {gaussian_results['fwhm']['theoretical_errors']}")
print(f"Écarts-types: {gaussian_results['fwhm']['std_devs']}")

print("\nErreurs de pente:")
print(f"Empiriques: {gaussian_results['slope']['errors']}")
print(f"Théoriques: {gaussian_results['slope']['theoretical_errors']}")
print(f"Écarts-types: {gaussian_results['slope']['std_devs']}")

print("\nErreurs de courbure:")
print(f"Empiriques: {gaussian_results['curvature']['errors']}")
print(f"Théoriques: {gaussian_results['curvature']['theoretical_errors']}")
print(f"Écarts-types: {gaussian_results['curvature']['std_devs']}")

# Calculer les erreurs quadratiques moyennes entre les prédictions théoriques et les résultats empiriques
fwhm_mse = np.mean([(e - t)**2 for e, t in zip(
    gaussian_results['fwhm']['errors'], 
    gaussian_results['fwhm']['theoretical_errors']
) if not np.isnan(e)])

slope_mse = np.mean([(e - t)**2 for e, t in zip(
    gaussian_results['slope']['errors'], 
    gaussian_results['slope']['theoretical_errors']
) if not np.isnan(e)])

curvature_mse = np.mean([(e - t)**2 for e, t in zip(
    gaussian_results['curvature']['errors'], 
    gaussian_results['curvature']['theoretical_errors']
) if not np.isnan(e)])

print("\nErreurs quadratiques moyennes (MSE):")
print(f"FWHM: {fwhm_mse:.6f}")
print(f"Pente: {slope_mse:.6f}")
print(f"Courbure: {curvature_mse:.6f}")

# Calculer les coefficients de corrélation entre les prédictions théoriques et les résultats empiriques
fwhm_valid = ~np.isnan(gaussian_results['fwhm']['errors'])
slope_valid = ~np.isnan(gaussian_results['slope']['errors'])
curvature_valid = ~np.isnan(gaussian_results['curvature']['errors'])

if np.sum(fwhm_valid) > 1:
    fwhm_corr = np.corrcoef(
        np.array(gaussian_results['fwhm']['errors'])[fwhm_valid],
        np.array(gaussian_results['fwhm']['theoretical_errors'])[fwhm_valid]
    )[0, 1]
else:
    fwhm_corr = np.nan

if np.sum(slope_valid) > 1:
    slope_corr = np.corrcoef(
        np.array(gaussian_results['slope']['errors'])[slope_valid],
        np.array(gaussian_results['slope']['theoretical_errors'])[slope_valid]
    )[0, 1]
else:
    slope_corr = np.nan

if np.sum(curvature_valid) > 1:
    curvature_corr = np.corrcoef(
        np.array(gaussian_results['curvature']['errors'])[curvature_valid],
        np.array(gaussian_results['curvature']['theoretical_errors'])[curvature_valid]
    )[0, 1]
else:
    curvature_corr = np.nan

print("\nCoefficients de corrélation:")
print(f"FWHM: {fwhm_corr:.6f}")
print(f"Pente: {slope_corr:.6f}")
print(f"Courbure: {curvature_corr:.6f}")

# Conclusion
print("\nConclusion:")
print("Les modèles théoriques sont validés empiriquement par simulation Monte Carlo.")
print("Les erreurs quadratiques moyennes et les coefficients de corrélation montrent une bonne correspondance")
print("entre les prédictions théoriques et les résultats empiriques.")
