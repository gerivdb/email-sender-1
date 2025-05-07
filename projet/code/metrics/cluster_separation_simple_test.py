#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié des métriques de séparation des clusters.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import colormaps
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from cluster_separation_metrics import (
    calculate_inter_cluster_distance,
    evaluate_inter_cluster_distance_quality,
    calculate_silhouette_metrics,
    evaluate_cluster_quality
)

# Créer des données de test avec des clusters
def generate_test_data(n_samples=300, n_clusters=4, cluster_std=1.0, random_state=42):
    """Génère des données de test avec des clusters."""
    # make_blobs peut retourner 2 ou 3 valeurs selon la version de scikit-learn
    # Nous n'utilisons que X et y, donc nous ignorons les centres si retournés
    result = make_blobs(
        n_samples=n_samples,
        n_features=2,
        centers=n_clusters,
        cluster_std=cluster_std,
        random_state=random_state
    )

    # Extraire X et y du résultat (ignorer les centres si présents)
    if len(result) == 3:
        X, y, _ = result
    else:
        X, y = result

    return X, y

# Générer des données avec différents niveaux de séparation
print("=== Test simplifié des métriques de séparation des clusters ===")

# Générer des données bien séparées
X_well, _ = generate_test_data(cluster_std=0.8)
print("\n1. Clusters bien séparés (std=0.8)")

# Appliquer K-means
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
labels = kmeans.fit_predict(X_well)
centroids = kmeans.cluster_centers_

# Calculer les métriques de séparation
distance_metrics = calculate_inter_cluster_distance(centroids)
silhouette_metrics = calculate_silhouette_metrics(X_well, labels)
quality_results = evaluate_cluster_quality(X_well, labels, centroids)

# Afficher les résultats
print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
print(f"Qualité de la distance: {evaluate_inter_cluster_distance_quality(distance_metrics['min_distance'])}")
print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
print(f"Qualité de silhouette: {silhouette_metrics['silhouette_quality']}")
print(f"Qualité globale: {quality_results['overall_quality']}")

# Générer des données moyennement séparées
X_medium, _ = generate_test_data(cluster_std=1.5)
print("\n2. Clusters moyennement séparés (std=1.5)")

# Appliquer K-means
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
labels = kmeans.fit_predict(X_medium)
centroids = kmeans.cluster_centers_

# Calculer les métriques de séparation
distance_metrics = calculate_inter_cluster_distance(centroids)
silhouette_metrics = calculate_silhouette_metrics(X_medium, labels)
quality_results = evaluate_cluster_quality(X_medium, labels, centroids)

# Afficher les résultats
print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
print(f"Qualité de la distance: {evaluate_inter_cluster_distance_quality(distance_metrics['min_distance'])}")
print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
print(f"Qualité de silhouette: {silhouette_metrics['silhouette_quality']}")
print(f"Qualité globale: {quality_results['overall_quality']}")

# Générer des données mal séparées
X_poor, _ = generate_test_data(cluster_std=3.0)
print("\n3. Clusters mal séparés (std=3.0)")

# Appliquer K-means
kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
labels = kmeans.fit_predict(X_poor)
centroids = kmeans.cluster_centers_

# Calculer les métriques de séparation
distance_metrics = calculate_inter_cluster_distance(centroids)
silhouette_metrics = calculate_silhouette_metrics(X_poor, labels)
quality_results = evaluate_cluster_quality(X_poor, labels, centroids)

# Afficher les résultats
print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
print(f"Qualité de la distance: {evaluate_inter_cluster_distance_quality(distance_metrics['min_distance'])}")
print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
print(f"Qualité de silhouette: {silhouette_metrics['silhouette_quality']}")
print(f"Qualité globale: {quality_results['overall_quality']}")

# Visualiser les clusters avec leur qualité
def visualize_clusters(X, labels, centroids, quality_results, title):
    """Visualise les clusters avec leur évaluation de qualité."""
    plt.figure(figsize=(10, 8))

    # Tracer les points
    unique_labels = np.unique(labels)
    cmap = colormaps['viridis']
    colors = cmap(np.linspace(0, 1, len(unique_labels)))

    for i, label in enumerate(unique_labels):
        cluster_points = X[labels == label]
        plt.scatter(
            cluster_points[:, 0],
            cluster_points[:, 1],
            color=colors[i],
            alpha=0.7,
            label=f"Cluster {label}"
        )

    # Tracer les centres
    plt.scatter(
        centroids[:, 0],
        centroids[:, 1],
        s=200,
        marker='X',
        color='black',
        label="Centres"
    )

    # Ajouter les informations de qualité
    silhouette_score = quality_results['silhouette_metrics']['silhouette_score']
    min_distance = quality_results['inter_cluster_metrics']['min_distance']
    overall_quality = quality_results['overall_quality']

    plt.title(
        f"{title}\n"
        f"Silhouette: {silhouette_score:.4f}, "
        f"Distance min: {min_distance:.4f}, "
        f"Qualité: {overall_quality}",
        fontsize=12
    )

    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()

# Visualiser les trois cas
print("\nVisualisation des clusters...")
visualize_clusters(X_well, kmeans.fit_predict(X_well), kmeans.cluster_centers_,
                  evaluate_cluster_quality(X_well, kmeans.fit_predict(X_well), kmeans.cluster_centers_),
                  "Clusters bien séparés (std=0.8)")

visualize_clusters(X_medium, kmeans.fit_predict(X_medium), kmeans.cluster_centers_,
                  evaluate_cluster_quality(X_medium, kmeans.fit_predict(X_medium), kmeans.cluster_centers_),
                  "Clusters moyennement séparés (std=1.5)")

visualize_clusters(X_poor, kmeans.fit_predict(X_poor), kmeans.cluster_centers_,
                  evaluate_cluster_quality(X_poor, kmeans.fit_predict(X_poor), kmeans.cluster_centers_),
                  "Clusters mal séparés (std=3.0)")

print("\nTest terminé avec succès!")
