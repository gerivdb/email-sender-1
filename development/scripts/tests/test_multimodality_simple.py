#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié pour les métriques de conservation de la multimodalité.
"""

import os
import sys
import numpy as np

# Ajouter le chemin du module
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))

# Importer directement le module
import multimodality_preservation_metrics as mpm

# Générer des données de test
np.random.seed(42)

# Créer une distribution bimodale
data_bimodal = np.concatenate([
    np.random.normal(loc=70, scale=10, size=500),
    np.random.normal(loc=130, scale=15, size=500)
])

# Détecter les modes
print("=== Test de détection des modes ===")
modes_info = mpm.detect_modes(data_bimodal)
print(f"Nombre de modes détectés: {modes_info['num_modes']}")
for i, mode in enumerate(modes_info['modes']):
    print(f"Mode {i+1}: position={mode['position']:.2f}, hauteur={mode['height']:.2f}, largeur={mode['width']:.2f}")

# Créer un histogramme
print("\n=== Test de création d'histogramme ===")
bin_edges = np.linspace(min(data_bimodal), max(data_bimodal), 20 + 1)
bin_counts, _ = np.histogram(data_bimodal, bins=bin_edges)

# Reconstruire les données
reconstructed_data = []
for i in range(len(bin_counts)):
    bin_count = bin_counts[i]
    bin_start = bin_edges[i]
    bin_end = bin_edges[i + 1]
    
    # Répartir uniformément les points dans le bin
    if bin_count > 0:
        step = (bin_end - bin_start) / bin_count
        bin_data = [bin_start + step * (j + 0.5) for j in range(bin_count)]
        reconstructed_data.extend(bin_data)

reconstructed_data = np.array(reconstructed_data)

# Calculer les métriques de préservation des modes
print("\n=== Test de calcul des métriques de préservation ===")
metrics = mpm.calculate_mode_preservation(data_bimodal, reconstructed_data)
print(f"Nombre de modes originaux: {metrics['original_num_modes']}")
print(f"Nombre de modes reconstruits: {metrics['reconstructed_num_modes']}")
print(f"Ratio de préservation du nombre de modes: {metrics['mode_count_ratio']:.2f}")

if metrics['mode_count_preserved'] and metrics['original_num_modes'] > 0:
    print(f"Erreur moyenne de position: {metrics['mean_position_error']:.4f}")
    print(f"Erreur moyenne de hauteur: {metrics['mean_height_error']:.4f}")
    print(f"Erreur moyenne de largeur: {metrics['mean_width_error']:.4f}")

# Calculer le score de préservation
print("\n=== Test de calcul du score de préservation ===")
score = mpm.calculate_multimodality_preservation_score(data_bimodal, reconstructed_data)
quality = mpm.evaluate_multimodality_preservation_quality(score)
print(f"Score de préservation: {score:.4f}")
print(f"Qualité: {quality}")

print("\nTest terminé avec succès!")
