#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test d'importation des modules nécessaires.
"""

print("Importation des modules...")

try:
    import numpy as np
    print("numpy importé avec succès.")
except Exception as e:
    print(f"Erreur lors de l'importation de numpy: {e}")

try:
    from sklearn.datasets import make_blobs
    print("make_blobs importé avec succès.")
except Exception as e:
    print(f"Erreur lors de l'importation de make_blobs: {e}")

try:
    from sklearn.cluster import KMeans
    print("KMeans importé avec succès.")
except Exception as e:
    print(f"Erreur lors de l'importation de KMeans: {e}")

try:
    from sklearn.metrics import silhouette_score
    print("silhouette_score importé avec succès.")
except Exception as e:
    print(f"Erreur lors de l'importation de silhouette_score: {e}")

print("Test d'importation terminé.")
