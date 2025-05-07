#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques de séparation des clusters.
"""

import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from cluster_separation_metrics import (
    calculate_inter_cluster_distance,
    evaluate_inter_cluster_distance_quality,
    calculate_silhouette_metrics,
    evaluate_silhouette_quality,
    define_cluster_separation_thresholds,
    evaluate_cluster_quality
)

def generate_test_clusters(n_samples=300, n_features=2, n_clusters=4, cluster_std=1.0, random_state=42):
    """
    Génère des données de test avec des clusters.
    
    Args:
        n_samples: Nombre d'échantillons
        n_features: Nombre de caractéristiques
        n_clusters: Nombre de clusters
        cluster_std: Écart-type des clusters
        random_state: Graine aléatoire
        
    Returns:
        X: Données générées
        labels: Étiquettes des clusters
        centers: Centres des clusters
    """
    X, labels = make_blobs(
        n_samples=n_samples,
        n_features=n_features,
        centers=n_clusters,
        cluster_std=cluster_std,
        random_state=random_state
    )
    
    # Calculer les centres réels
    centers = np.zeros((n_clusters, n_features))
    for i in range(n_clusters):
        centers[i] = np.mean(X[labels == i], axis=0)
    
    return X, labels, centers

def test_inter_cluster_distance():
    """
    Teste le calcul de la distance inter-clusters.
    """
    print("\n=== Test du calcul de la distance inter-clusters ===")
    
    # Générer des données de test
    X, labels, centers = generate_test_clusters(cluster_std=1.0)
    
    # Calculer les distances inter-clusters
    distance_metrics = calculate_inter_cluster_distance(centers)
    
    # Afficher les résultats
    print(f"Distance minimale: {distance_metrics['min_distance']:.4f}")
    print(f"Distance maximale: {distance_metrics['max_distance']:.4f}")
    print(f"Distance moyenne: {distance_metrics['mean_distance']:.4f}")
    print(f"Distance médiane: {distance_metrics['median_distance']:.4f}")
    
    # Évaluer la qualité
    quality = evaluate_inter_cluster_distance_quality(distance_metrics['min_distance'])
    print(f"Qualité de la séparation: {quality}")
    
    return distance_metrics

def test_silhouette_metrics():
    """
    Teste le calcul des métriques de silhouette.
    """
    print("\n=== Test du calcul des métriques de silhouette ===")
    
    # Générer des données de test avec différents niveaux de séparation
    datasets = [
        ("Clusters bien séparés", 0.8),
        ("Clusters moyennement séparés", 1.5),
        ("Clusters mal séparés", 3.0)
    ]
    
    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")
        
        # Générer les données
        X, labels, _ = generate_test_clusters(cluster_std=cluster_std)
        
        # Calculer les métriques de silhouette
        silhouette_metrics = calculate_silhouette_metrics(X, labels)
        
        # Afficher les résultats
        print(f"Score de silhouette: {silhouette_metrics['silhouette_score']:.4f}")
        print(f"Qualité de silhouette: {silhouette_metrics['silhouette_quality']}")
        print(f"Score de Calinski-Harabasz: {silhouette_metrics['calinski_harabasz_score']:.4f}")
        print(f"Score de Davies-Bouldin: {silhouette_metrics['davies_bouldin_score']:.4f}")
        print(f"Qualité globale: {silhouette_metrics['overall_quality']}")
    
    return silhouette_metrics

def test_cluster_separation_thresholds():
    """
    Teste la définition des seuils de séparation des clusters.
    """
    print("\n=== Test de la définition des seuils de séparation des clusters ===")
    
    # Tester différentes configurations
    configs = [
        (2, 3, "low"),
        (2, 5, "medium"),
        (10, 5, "medium"),
        (50, 10, "high")
    ]
    
    for dim, clusters, sparsity in configs:
        print(f"\n--- Dimensionnalité={dim}, Clusters={clusters}, Densité={sparsity} ---")
        
        # Définir les seuils
        thresholds = define_cluster_separation_thresholds(
            data_dimensionality=dim,
            cluster_count=clusters,
            data_sparsity=sparsity
        )
        
        # Afficher les seuils pour le score de silhouette
        print("Seuils pour le score de silhouette:")
        for level, value in thresholds["silhouette"].items():
            print(f"  {level}: {value:.4f}")
        
        # Afficher les seuils pour la distance inter-clusters
        print("\nSeuils pour la distance inter-clusters:")
        for level, value in thresholds["inter_cluster_distance"].items():
            print(f"  {level}: {value:.4f}")
    
    return thresholds

def test_cluster_quality_evaluation():
    """
    Teste l'évaluation globale de la qualité des clusters.
    """
    print("\n=== Test de l'évaluation globale de la qualité des clusters ===")
    
    # Générer des données de test avec différents niveaux de séparation
    datasets = [
        ("Clusters bien séparés", 0.8),
        ("Clusters moyennement séparés", 1.5),
        ("Clusters mal séparés", 3.0)
    ]
    
    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")
        
        # Générer les données
        X, labels, centers = generate_test_clusters(cluster_std=cluster_std)
        
        # Évaluer la qualité des clusters
        quality_results = evaluate_cluster_quality(X, labels, centers)
        
        # Afficher les résultats
        print(f"Qualité de silhouette: {quality_results['silhouette_metrics']['overall_quality']}")
        print(f"Qualité de distance: {quality_results['distance_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")
        print(f"Score combiné: {quality_results['combined_rank']:.4f}")
    
    return quality_results

def visualize_clusters_with_quality(X, labels, centers, quality_results):
    """
    Visualise les clusters avec leur évaluation de qualité.
    
    Args:
        X: Données (n_samples, 2)
        labels: Étiquettes des clusters
        centers: Centres des clusters
        quality_results: Résultats de l'évaluation de qualité
    """
    # Vérifier que les données sont en 2D
    if X.shape[1] != 2:
        print("La visualisation nécessite des données en 2D.")
        return
    
    # Créer la figure
    plt.figure(figsize=(10, 8))
    
    # Tracer les points
    unique_labels = np.unique(labels)
    colors = plt.cm.rainbow(np.linspace(0, 1, len(unique_labels)))
    
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
        centers[:, 0],
        centers[:, 1],
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
        f"Clusters avec évaluation de qualité\n"
        f"Silhouette: {silhouette_score:.4f}, "
        f"Distance min: {min_distance:.4f}, "
        f"Qualité: {overall_quality}",
        fontsize=12
    )
    
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()

def main():
    """
    Fonction principale pour tester les métriques de séparation des clusters.
    """
    print("=== Test des métriques de séparation des clusters ===")
    
    # Tester le calcul de la distance inter-clusters
    distance_metrics = test_inter_cluster_distance()
    
    # Tester le calcul des métriques de silhouette
    silhouette_metrics = test_silhouette_metrics()
    
    # Tester la définition des seuils de séparation des clusters
    thresholds = test_cluster_separation_thresholds()
    
    # Tester l'évaluation globale de la qualité des clusters
    quality_results = test_cluster_quality_evaluation()
    
    # Visualiser un exemple de clusters avec leur évaluation de qualité
    X, labels, centers = generate_test_clusters(cluster_std=1.2)
    quality_results = evaluate_cluster_quality(X, labels, centers)
    visualize_clusters_with_quality(X, labels, centers, quality_results)
    
    print("\nTests terminés avec succès!")

if __name__ == "__main__":
    main()
