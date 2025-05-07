#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test d'importation du module.
"""

print("Début du test d'importation...")

try:
    # Importer une fonction du module
    from cluster_separation_metrics import calculate_inter_cluster_distance
    print("Fonction calculate_inter_cluster_distance importée avec succès.")
    
    # Tester la fonction avec un tableau simple
    import numpy as np
    centroids = np.array([[0, 0], [1, 1], [2, 2]])
    
    print("Calcul des distances inter-clusters...")
    result = calculate_inter_cluster_distance(centroids)
    
    print(f"Résultat: {result}")
    
except Exception as e:
    print(f"Erreur: {e}")

print("Test d'importation terminé.")
