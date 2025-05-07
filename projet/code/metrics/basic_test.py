#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test basique des métriques de clustering.
"""

import numpy as np
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

print("=== Test basique des métriques de clustering ===")

# Générer des données de test
print("Génération des données...")
X, y = make_blobs(
    n_samples=300,
    n_features=2,
    centers=4,
    cluster_std=1.0,
    random_state=42
)

# Appliquer K-means
print("Application de K-means...")
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
labels = kmeans.fit_predict(X)
centroids = kmeans.cluster_centers_

# Calculer le score de silhouette
print("Calcul du score de silhouette...")
sil_score = silhouette_score(X, labels)
print(f"Score de silhouette: {sil_score:.4f}")

# Calculer les distances entre les centres des clusters
print("Calcul des distances entre les centres des clusters...")
n_clusters = centroids.shape[0]
distances = np.zeros((n_clusters, n_clusters))

for i in range(n_clusters):
    for j in range(i+1, n_clusters):
        dist = np.linalg.norm(centroids[i] - centroids[j])
        distances[i, j] = dist
        distances[j, i] = dist

min_distance = np.min(distances[distances > 0])
print(f"Distance minimale entre les centres: {min_distance:.4f}")

print("Test terminé avec succès!")
