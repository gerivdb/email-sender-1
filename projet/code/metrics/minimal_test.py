#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test minimal des métriques de séparation des clusters.
"""

import numpy as np
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from cluster_separation_metrics import (
    calculate_inter_cluster_distance,
    evaluate_inter_cluster_distance_quality,
    calculate_silhouette_metrics,
    evaluate_cluster_quality
)

print("=== Test minimal des métriques de séparation des clusters ===")

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

# Calculer les métriques de séparation
print("Calcul des métriques de séparation...")
try:
    distance_metrics = calculate_inter_cluster_distance(centroids)
    print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
except Exception as e:
    print(f"Erreur lors du calcul des distances: {e}")

try:
    silhouette_metrics = calculate_silhouette_metrics(X, labels)
    print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
except Exception as e:
    print(f"Erreur lors du calcul des métriques de silhouette: {e}")

try:
    quality_results = evaluate_cluster_quality(X, labels, centroids)
    print(f"Qualité globale: {quality_results['overall_quality']}")
except Exception as e:
    print(f"Erreur lors de l'évaluation de la qualité: {e}")

print("Test terminé avec succès!")
