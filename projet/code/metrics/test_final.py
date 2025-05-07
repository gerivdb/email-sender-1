#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test final simplifié.
"""

print("Début du test final...")

# Importer numpy
import numpy as np

# Créer des données synthétiques simples
centroids = np.array([[0, 0], [1, 1], [2, 2]])

# Importer la fonction du module
try:
    from cluster_separation_metrics import calculate_inter_cluster_distance
    print("Fonction importée avec succès.")
    
    # Calculer les distances
    result = calculate_inter_cluster_distance(centroids)
    print(f"Distance minimale: {result['min_distance']}")
    print("Test réussi!")
except Exception as e:
    print(f"Erreur: {e}")

print("Test final terminé.")
