#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test des métriques de cohésion des clusters.
"""

import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import make_blobs
from sklearn.cluster import KMeans
from cluster_cohesion_metrics import (
    calculate_intra_cluster_variance,
    evaluate_intra_cluster_variance_quality,
    calculate_cluster_density_metrics,
    evaluate_density_metrics_quality,
    evaluate_cluster_cohesion_quality
)

def generate_test_data(n_samples=300, n_features=2, centers=4, cluster_std=1.0, random_state=42):
    """
    Génère des données de test pour le clustering.
    
    Args:
        n_samples: Nombre d'échantillons
        n_features: Nombre de caractéristiques
        centers: Nombre de centres (clusters)
        cluster_std: Écart-type des clusters
        random_state: Graine aléatoire
        
    Returns:
        X: Données générées
        y: Étiquettes réelles
    """
    X, y = make_blobs(
        n_samples=n_samples,
        n_features=n_features,
        centers=centers,
        cluster_std=cluster_std,
        random_state=random_state
    )
    return X, y

def test_intra_cluster_variance():
    """
    Teste le calcul de la variance intra-cluster.
    """
    print("\n=== Test du calcul de la variance intra-cluster ===")
    
    # Générer des données avec différents niveaux de variance
    datasets = [
        ("Faible variance", 0.5),
        ("Variance moyenne", 1.0),
        ("Variance élevée", 2.0)
    ]
    
    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")
        
        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)
        
        # Appliquer K-means
        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)
        centroids = kmeans.cluster_centers_
        
        # Calculer la variance intra-cluster
        variance_metrics = calculate_intra_cluster_variance(X, labels, centroids)
        
        # Évaluer la qualité
        quality_results = evaluate_intra_cluster_variance_quality(variance_metrics)
        
        # Afficher les résultats
        print(f"Variance totale: {variance_metrics['total_variance']:.4f}")
        print(f"Variance maximale: {variance_metrics['max_variance']:.4f}")
        print(f"Variance minimale: {variance_metrics['min_variance']:.4f}")
        print(f"Ratio de variance: {variance_metrics['variance_ratio']:.4f}")
        print(f"Qualité de la variance maximale: {quality_results['max_variance_quality']}")
        print(f"Qualité du ratio de variance: {quality_results['variance_ratio_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")
    
    return variance_metrics, quality_results

def test_density_metrics():
    """
    Teste le calcul des métriques de densité.
    """
    print("\n=== Test du calcul des métriques de densité ===")
    
    # Générer des données avec différents niveaux de densité
    datasets = [
        ("Clusters denses", 0.5),
        ("Clusters moyennement denses", 1.0),
        ("Clusters peu denses", 2.0)
    ]
    
    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")
        
        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)
        
        # Appliquer K-means
        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)
        
        # Calculer les métriques de densité
        density_metrics = calculate_cluster_density_metrics(X, labels)
        
        # Évaluer la qualité
        quality_results = evaluate_density_metrics_quality(density_metrics)
        
        # Afficher les résultats
        print(f"Densité moyenne: {density_metrics['mean_density']:.4f}")
        print(f"Densité maximale: {density_metrics['max_density']:.4f}")
        print(f"Densité minimale: {density_metrics['min_density']:.4f}")
        print(f"Ratio de densité: {density_metrics['density_ratio']:.4f}")
        print(f"Variation moyenne de densité: {density_metrics['mean_density_variation']:.4f}")
        print(f"Qualité du ratio de densité: {quality_results['density_ratio_quality']}")
        print(f"Qualité de la variation de densité: {quality_results['density_variation_quality']}")
        print(f"Qualité de la densité minimale: {quality_results['min_density_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")
    
    return density_metrics, quality_results

def test_cluster_cohesion_quality():
    """
    Teste l'évaluation de la qualité de la cohésion des clusters.
    """
    print("\n=== Test de l'évaluation de la qualité de la cohésion des clusters ===")
    
    # Générer des données avec différents niveaux de cohésion
    datasets = [
        ("Forte cohésion", 0.5),
        ("Cohésion moyenne", 1.0),
        ("Faible cohésion", 2.0)
    ]
    
    for name, cluster_std in datasets:
        print(f"\n--- {name} (std={cluster_std}) ---")
        
        # Générer les données
        X, _ = generate_test_data(cluster_std=cluster_std)
        
        # Appliquer K-means
        kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
        labels = kmeans.fit_predict(X)
        centroids = kmeans.cluster_centers_
        
        # Évaluer la qualité de la cohésion des clusters
        quality_results = evaluate_cluster_cohesion_quality(X, labels, centroids)
        
        # Afficher les résultats
        print(f"Qualité de la variance: {quality_results['variance_quality']['overall_quality']}")
        print(f"Qualité de la densité: {quality_results['density_quality']['overall_quality']}")
        print(f"Qualité globale: {quality_results['overall_quality']}")
        print(f"Score combiné: {quality_results['combined_score']:.4f}")
    
    return quality_results

def visualize_clusters_with_cohesion(X, labels, centroids, quality_results):
    """
    Visualise les clusters avec leur qualité de cohésion.
    
    Args:
        X: Données d'entrée
        labels: Étiquettes des clusters
        centroids: Centres des clusters
        quality_results: Résultats de l'évaluation de la qualité
    """
    # Vérifier que les données sont en 2D
    if X.shape[1] != 2:
        print("La visualisation n'est possible qu'en 2D.")
        return
    
    # Créer la figure
    plt.figure(figsize=(10, 8))
    
    # Couleurs pour les clusters
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf']
    
    # Tracer les points
    for i in range(len(np.unique(labels))):
        cluster_points = X[labels == i]
        plt.scatter(cluster_points[:, 0], cluster_points[:, 1], c=colors[i % len(colors)], label=f'Cluster {i+1}', alpha=0.7)
    
    # Tracer les centroids
    plt.scatter(centroids[:, 0], centroids[:, 1], c='black', marker='X', s=100, label='Centroids')
    
    # Ajouter les informations de qualité
    variance_quality = quality_results['variance_quality']['overall_quality']
    density_quality = quality_results['density_quality']['overall_quality']
    overall_quality = quality_results['overall_quality']
    combined_score = quality_results['combined_score']
    
    plt.title(f'Clusters avec évaluation de la cohésion\nQualité globale: {overall_quality} (Score: {combined_score:.2f})')
    plt.xlabel('Caractéristique 1')
    plt.ylabel('Caractéristique 2')
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    
    # Ajouter une annotation avec les détails de qualité
    plt.annotate(
        f"Qualité de variance: {variance_quality}\nQualité de densité: {density_quality}",
        xy=(0.02, 0.02),
        xycoords='axes fraction',
        bbox=dict(boxstyle="round,pad=0.5", fc="white", ec="gray", alpha=0.8)
    )
    
    plt.tight_layout()
    plt.show()

def main():
    """
    Fonction principale pour exécuter les tests.
    """
    print("=== Tests des métriques de cohésion des clusters ===")
    
    # Tester le calcul de la variance intra-cluster
    variance_metrics, variance_quality = test_intra_cluster_variance()
    
    # Tester le calcul des métriques de densité
    density_metrics, density_quality = test_density_metrics()
    
    # Tester l'évaluation de la qualité de la cohésion des clusters
    quality_results = test_cluster_cohesion_quality()
    
    # Visualiser les clusters avec leur qualité de cohésion
    print("\n=== Visualisation des clusters avec leur qualité de cohésion ===")
    
    # Générer des données
    X, _ = generate_test_data(cluster_std=1.0)
    
    # Appliquer K-means
    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X)
    centroids = kmeans.cluster_centers_
    
    # Évaluer la qualité de la cohésion des clusters
    quality_results = evaluate_cluster_cohesion_quality(X, labels, centroids)
    
    # Visualiser les clusters
    visualize_clusters_with_cohesion(X, labels, centroids, quality_results)
    
    return 0

if __name__ == "__main__":
    main()
