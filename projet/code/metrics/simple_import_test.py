#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simple d'importation du module cluster_separation_metrics.
"""

print("Tentative d'importation du module...")
try:
    from cluster_separation_metrics import (
        calculate_inter_cluster_distance,
        evaluate_inter_cluster_distance_quality,
        calculate_silhouette_metrics,
        evaluate_silhouette_quality,
        define_cluster_separation_thresholds,
        evaluate_cluster_quality
    )
    print("Importation réussie!")
except Exception as e:
    print(f"Erreur lors de l'importation: {e}")

print("Test terminé.")
