#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test du module personnalisé cluster_separation_metrics.
"""

import numpy as np
from sklearn.cluster import KMeans

print("=== Test du module personnalisé cluster_separation_metrics ===")

# Générer des données de test
print("Génération des données...")
# Créer des données synthétiques directement avec numpy pour éviter les problèmes
np.random.seed(42)
X = np.random.randn(300, 2) * 0.5
X[:100] += np.array([2, 2])
X[100:200] += np.array([-2, 2])
X[200:300] += np.array([0, -2])
y = np.zeros(300)
y[:100] = 0
y[100:200] = 1
y[200:300] = 2

# Appliquer K-means
print("Application de K-means...")
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
labels = kmeans.fit_predict(X)
centroids = kmeans.cluster_centers_

# Importer et utiliser les fonctions du module personnalisé
print("Importation du module personnalisé...")
try:
    from cluster_separation_metrics import calculate_inter_cluster_distance
    print("Fonction calculate_inter_cluster_distance importée avec succès.")

    # Calculer les distances inter-clusters
    print("Calcul des distances inter-clusters...")
    distance_metrics = calculate_inter_cluster_distance(centroids)
    print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
except Exception as e:
    print(f"Erreur lors de l'utilisation de calculate_inter_cluster_distance: {e}")

try:
    from cluster_separation_metrics import calculate_silhouette_metrics
    print("Fonction calculate_silhouette_metrics importée avec succès.")

    # Calculer les métriques de silhouette
    print("Calcul des métriques de silhouette...")
    silhouette_metrics = calculate_silhouette_metrics(X, labels)
    print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
    print(f"Qualité de silhouette: {silhouette_metrics['silhouette_quality']}")
except Exception as e:
    print(f"Erreur lors de l'utilisation de calculate_silhouette_metrics: {e}")

print("Test terminé.")
