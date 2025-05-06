#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié des métriques basées sur la saillance visuelle.
"""

import numpy as np
from visual_saliency_metrics import calculate_contrast_map, calculate_saliency_score

# Créer un histogramme simple pour le test
test_hist = np.array([1, 2, 5, 10, 15, 10, 5, 2, 1])

print("=== Test simplifié des métriques basées sur la saillance visuelle ===")

# Calculer la carte de contraste
contrast_map = calculate_contrast_map(test_hist)
print(f"Histogramme de test: {test_hist}")
print(f"Carte de contraste: {contrast_map}")

# Calculer le score de saillance
score = calculate_saliency_score(test_hist)
print(f"Score de saillance: {score:.4f}")

print("\nTest terminé avec succès!")
