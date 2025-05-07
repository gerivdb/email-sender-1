#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des métriques de séparation des clusters sur des données réelles.
"""

import numpy as np
import matplotlib.pyplot as plt
from sklearn.datasets import fetch_openml
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from cluster_separation_metrics import (
    calculate_inter_cluster_distance,
    calculate_silhouette_metrics,
    define_cluster_separation_thresholds,
    evaluate_cluster_quality
)

def load_and_prepare_data(dataset_name="iris", max_samples=1000):
    """
    Charge et prépare un jeu de données pour le clustering.
    
    Args:
        dataset_name: Nom du jeu de données
        max_samples: Nombre maximal d'échantillons à utiliser
        
    Returns:
        X: Données préparées
        y: Étiquettes (si disponibles)
    """
    print(f"Chargement du jeu de données {dataset_name}...")
    
    try:
        # Charger le jeu de données
        data = fetch_openml(name=dataset_name, version=1, as_frame=True)
        X = data.data
        y = data.target
        
        # Limiter le nombre d'échantillons si nécessaire
        if X.shape[0] > max_samples:
            indices = np.random.choice(X.shape[0], max_samples, replace=False)
            X = X.iloc[indices]
            y = y.iloc[indices]
        
        # Convertir en tableau numpy
        X = X.values
        
        # Standardiser les données
        scaler = StandardScaler()
        X = scaler.fit_transform(X)
        
        print(f"Données chargées: {X.shape[0]} échantillons, {X.shape[1]} caractéristiques")
        return X, y
        
    except Exception as e:
        print(f"Erreur lors du chargement des données: {e}")
        print("Utilisation de données synthétiques à la place.")
        
        # Générer des données synthétiques
        from sklearn.datasets import make_blobs
        X, y = make_blobs(n_samples=300, n_features=4, centers=3, random_state=42)
        X = StandardScaler().fit_transform(X)
        
        print(f"Données synthétiques générées: {X.shape[0]} échantillons, {X.shape[1]} caractéristiques")
        return X, y

def perform_clustering(X, n_clusters=3):
    """
    Effectue un clustering K-means sur les données.
    
    Args:
        X: Données d'entrée
        n_clusters: Nombre de clusters
        
    Returns:
        labels: Étiquettes des clusters
        centroids: Centres des clusters
    """
    print(f"Clustering avec K-means (k={n_clusters})...")
    
    # Appliquer K-means
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X)
    centroids = kmeans.cluster_centers_
    
    print(f"Clustering terminé: {n_clusters} clusters")
    return labels, centroids

def evaluate_clustering(X, labels, centroids):
    """
    Évalue la qualité du clustering.
    
    Args:
        X: Données d'entrée
        labels: Étiquettes des clusters
        centroids: Centres des clusters
        
    Returns:
        quality_results: Résultats de l'évaluation
    """
    print("Évaluation de la qualité du clustering...")
    
    # Évaluer la qualité des clusters
    quality_results = evaluate_cluster_quality(X, labels, centroids)
    
    # Afficher les résultats
    print(f"Score de silhouette: {quality_results['silhouette_metrics']['silhouette_score']:.4f}")
    print(f"Qualité de silhouette: {quality_results['silhouette_metrics']['silhouette_quality']}")
    print(f"Distance minimale inter-clusters: {quality_results['inter_cluster_metrics']['min_distance']:.4f}")
    print(f"Qualité de la distance: {quality_results['distance_quality']}")
    print(f"Qualité globale: {quality_results['overall_quality']}")
    
    return quality_results

def visualize_clustering_2d(X, labels, centroids, quality_results):
    """
    Visualise le clustering en 2D après réduction de dimensionnalité.
    
    Args:
        X: Données d'entrée
        labels: Étiquettes des clusters
        centroids: Centres des clusters
        quality_results: Résultats de l'évaluation
    """
    print("Visualisation du clustering...")
    
    # Réduire la dimensionnalité pour la visualisation si nécessaire
    if X.shape[1] > 2:
        pca = PCA(n_components=2)
        X_2d = pca.fit_transform(X)
        centroids_2d = pca.transform(centroids)
    else:
        X_2d = X
        centroids_2d = centroids
    
    # Créer la figure
    plt.figure(figsize=(12, 10))
    
    # Tracer les points
    unique_labels = np.unique(labels)
    colors = plt.cm.rainbow(np.linspace(0, 1, len(unique_labels)))
    
    for i, label in enumerate(unique_labels):
        cluster_points = X_2d[labels == label]
        plt.scatter(
            cluster_points[:, 0],
            cluster_points[:, 1],
            color=colors[i],
            alpha=0.7,
            label=f"Cluster {label}"
        )
    
    # Tracer les centres
    plt.scatter(
        centroids_2d[:, 0],
        centroids_2d[:, 1],
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
        f"Visualisation du clustering (PCA)\n"
        f"Silhouette: {silhouette_score:.4f}, "
        f"Distance min: {min_distance:.4f}, "
        f"Qualité: {overall_quality}",
        fontsize=12
    )
    
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.tight_layout()
    plt.show()

def compare_cluster_counts(X, max_clusters=10):
    """
    Compare différents nombres de clusters et leurs métriques de qualité.
    
    Args:
        X: Données d'entrée
        max_clusters: Nombre maximal de clusters à tester
    """
    print(f"Comparaison de différents nombres de clusters (2-{max_clusters})...")
    
    # Initialiser les listes pour stocker les résultats
    cluster_counts = list(range(2, max_clusters + 1))
    silhouette_scores = []
    ch_scores = []
    db_scores = []
    min_distances = []
    overall_qualities = []
    
    # Tester différents nombres de clusters
    for n_clusters in cluster_counts:
        # Effectuer le clustering
        labels, centroids = perform_clustering(X, n_clusters)
        
        # Évaluer la qualité
        quality_results = evaluate_cluster_quality(X, labels, centroids)
        
        # Stocker les résultats
        silhouette_scores.append(quality_results['silhouette_metrics']['silhouette_score'])
        ch_scores.append(quality_results['silhouette_metrics']['calinski_harabasz_score'])
        db_scores.append(quality_results['silhouette_metrics']['davies_bouldin_score'])
        min_distances.append(quality_results['inter_cluster_metrics']['min_distance'])
        overall_qualities.append(quality_results['overall_quality'])
        
        print(f"k={n_clusters}: Silhouette={silhouette_scores[-1]:.4f}, Qualité={overall_qualities[-1]}")
    
    # Créer la figure pour visualiser les résultats
    fig, axs = plt.subplots(2, 2, figsize=(14, 10))
    
    # Tracer le score de silhouette
    axs[0, 0].plot(cluster_counts, silhouette_scores, 'o-', color='blue')
    axs[0, 0].set_title('Score de silhouette')
    axs[0, 0].set_xlabel('Nombre de clusters')
    axs[0, 0].set_ylabel('Score')
    axs[0, 0].grid(True)
    
    # Tracer le score de Calinski-Harabasz
    axs[0, 1].plot(cluster_counts, ch_scores, 'o-', color='green')
    axs[0, 1].set_title('Score de Calinski-Harabasz')
    axs[0, 1].set_xlabel('Nombre de clusters')
    axs[0, 1].set_ylabel('Score')
    axs[0, 1].grid(True)
    
    # Tracer le score de Davies-Bouldin
    axs[1, 0].plot(cluster_counts, db_scores, 'o-', color='red')
    axs[1, 0].set_title('Score de Davies-Bouldin')
    axs[1, 0].set_xlabel('Nombre de clusters')
    axs[1, 0].set_ylabel('Score')
    axs[1, 0].grid(True)
    
    # Tracer la distance minimale inter-clusters
    axs[1, 1].plot(cluster_counts, min_distances, 'o-', color='purple')
    axs[1, 1].set_title('Distance minimale inter-clusters')
    axs[1, 1].set_xlabel('Nombre de clusters')
    axs[1, 1].set_ylabel('Distance')
    axs[1, 1].grid(True)
    
    plt.tight_layout()
    plt.show()
    
    # Déterminer le nombre optimal de clusters
    # Pour le score de silhouette et Calinski-Harabasz, plus c'est élevé, mieux c'est
    # Pour le score de Davies-Bouldin, plus c'est bas, mieux c'est
    best_silhouette = np.argmax(silhouette_scores) + 2
    best_ch = np.argmax(ch_scores) + 2
    best_db = np.argmin(db_scores) + 2
    
    print(f"Nombre optimal de clusters selon le score de silhouette: {best_silhouette}")
    print(f"Nombre optimal de clusters selon le score de Calinski-Harabasz: {best_ch}")
    print(f"Nombre optimal de clusters selon le score de Davies-Bouldin: {best_db}")
    
    # Retourner le nombre optimal de clusters selon le score de silhouette
    return best_silhouette

def main():
    """
    Fonction principale pour démontrer l'utilisation des métriques de séparation des clusters.
    """
    print("=== Exemple d'utilisation des métriques de séparation des clusters ===")
    
    # Charger et préparer les données
    X, y = load_and_prepare_data(dataset_name="iris")
    
    # Comparer différents nombres de clusters
    optimal_clusters = compare_cluster_counts(X, max_clusters=8)
    
    # Effectuer le clustering avec le nombre optimal de clusters
    labels, centroids = perform_clustering(X, n_clusters=optimal_clusters)
    
    # Évaluer la qualité du clustering
    quality_results = evaluate_clustering(X, labels, centroids)
    
    # Visualiser le clustering
    visualize_clustering_2d(X, labels, centroids, quality_results)
    
    print("\nExemple terminé avec succès!")

if __name__ == "__main__":
    main()
