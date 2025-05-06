#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de l'impact du nombre de bins sur la résolution.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from resolution_metrics import (
    analyze_bin_count_impact_on_resolution,
    plot_bin_count_impact_on_resolution
)

print("=== Test de l'impact du nombre de bins sur la résolution ===")

# Générer différentes distributions pour les tests
np.random.seed(42)  # Pour la reproductibilité

# Distribution unimodale (normale)
normal_data = np.random.normal(loc=50, scale=10, size=1000)

# Distribution bimodale (mélange de deux normales)
bimodal_data = np.concatenate([
    np.random.normal(loc=30, scale=5, size=500),
    np.random.normal(loc=70, scale=8, size=500)
])

# Distribution trimodale (mélange de trois normales)
trimodal_data = np.concatenate([
    np.random.normal(loc=20, scale=3, size=300),
    np.random.normal(loc=50, scale=5, size=400),
    np.random.normal(loc=80, scale=4, size=300)
])

# Distribution avec des pics rapprochés (pour tester la résolution)
close_peaks_data = np.concatenate([
    np.random.normal(loc=40, scale=3, size=400),
    np.random.normal(loc=50, scale=3, size=400),
    np.random.normal(loc=60, scale=3, size=400)
])

# Distribution avec des pics de différentes hauteurs
varying_heights_data = np.concatenate([
    np.random.normal(loc=30, scale=5, size=200),
    np.random.normal(loc=50, scale=3, size=600),
    np.random.normal(loc=70, scale=4, size=400)
])

# Créer un dictionnaire des distributions
distributions = {
    "Normale": normal_data,
    "Bimodale": bimodal_data,
    "Trimodale": trimodal_data,
    "Pics rapprochés": close_peaks_data,
    "Hauteurs variables": varying_heights_data
}

# Tester l'impact du nombre de bins sur chaque distribution
for dist_name, data in distributions.items():
    print(f"\n=== Distribution: {dist_name} ===")
    
    # Analyser l'impact du nombre de bins
    analysis = analyze_bin_count_impact_on_resolution(
        data, 
        strategy="uniform", 
        min_bins=5, 
        max_bins=100, 
        step=5
    )
    
    # Afficher les résultats
    optimal_bins = analysis["optimal_num_bins"]
    print(f"Nombre optimal de bins pour FWHM: {optimal_bins['fwhm']}")
    print(f"Nombre optimal de bins pour la pente: {optimal_bins['slope']}")
    print(f"Nombre optimal de bins pour la courbure: {optimal_bins['curvature']}")
    print(f"Nombre optimal de bins pour la résolution relative: {optimal_bins['relative']}")
    print(f"Nombre optimal de bins pour la détection de pics: {analysis['optimal_num_bins_for_peak_detection']}")
    
    # Visualiser les résultats
    plot_bin_count_impact_on_resolution(
        analysis, 
        save_path=f"bin_count_impact_{dist_name.lower().replace(' ', '_')}.png",
        show_plot=False
    )

# Test avec différentes stratégies de binning
print("\n=== Test avec différentes stratégies de binning ===")
strategies = ["uniform", "quantile", "logarithmic"]

for strategy in strategies:
    print(f"\nStratégie: {strategy}")
    
    # Utiliser la distribution trimodale pour ce test
    analysis = analyze_bin_count_impact_on_resolution(
        trimodal_data, 
        strategy=strategy, 
        min_bins=5, 
        max_bins=100, 
        step=5
    )
    
    # Afficher les résultats
    optimal_bins = analysis["optimal_num_bins"]
    print(f"Nombre optimal de bins pour FWHM: {optimal_bins['fwhm']}")
    print(f"Nombre optimal de bins pour la pente: {optimal_bins['slope']}")
    print(f"Nombre optimal de bins pour la courbure: {optimal_bins['curvature']}")
    print(f"Nombre optimal de bins pour la résolution relative: {optimal_bins['relative']}")
    print(f"Nombre optimal de bins pour la détection de pics: {analysis['optimal_num_bins_for_peak_detection']}")
    
    # Visualiser les résultats
    plot_bin_count_impact_on_resolution(
        analysis, 
        save_path=f"bin_count_impact_trimodal_{strategy}.png",
        show_plot=False
    )

# Test avec une plage de bins plus fine
print("\n=== Test avec une plage de bins plus fine ===")
fine_analysis = analyze_bin_count_impact_on_resolution(
    close_peaks_data, 
    strategy="uniform", 
    min_bins=10, 
    max_bins=200, 
    step=2
)

# Afficher les résultats
optimal_bins = fine_analysis["optimal_num_bins"]
print(f"Nombre optimal de bins pour FWHM: {optimal_bins['fwhm']}")
print(f"Nombre optimal de bins pour la pente: {optimal_bins['slope']}")
print(f"Nombre optimal de bins pour la courbure: {optimal_bins['curvature']}")
print(f"Nombre optimal de bins pour la résolution relative: {optimal_bins['relative']}")
print(f"Nombre optimal de bins pour la détection de pics: {fine_analysis['optimal_num_bins_for_peak_detection']}")

# Visualiser les résultats
plot_bin_count_impact_on_resolution(
    fine_analysis, 
    save_path="bin_count_impact_fine_analysis.png",
    show_plot=False
)

print("\nTest terminé avec succès!")
