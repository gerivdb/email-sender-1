#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simple du module personnalisé.
"""

print("Début du test du module personnalisé...")

# Importer les modules nécessaires
try:
    import numpy as np
    from sklearn.datasets import make_blobs
    from sklearn.cluster import KMeans
    
    print("Modules scikit-learn importés avec succès.")
    
    # Générer des données
    print("Génération des données...")
    result = make_blobs(
        n_samples=100,
        n_features=2,
        centers=3,
        cluster_std=1.0,
        random_state=42
    )
    
    # Extraire X et y
    if len(result) == 3:
        X, y, centers = result
    else:
        X, y = result
    
    print(f"Données générées. Forme de X: {X.shape}")
    
    # Appliquer K-means
    print("Application de K-means...")
    kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X)
    centroids = kmeans.cluster_centers_
    
    print(f"K-means appliqué. Forme des centroids: {centroids.shape}")
    
    # Importer notre module personnalisé
    print("Importation du module personnalisé...")
    from cluster_separation_metrics import calculate_inter_cluster_distance
    
    print("Module importé avec succès.")
    
    # Calculer les distances inter-clusters
    print("Calcul des distances inter-clusters...")
    distance_metrics = calculate_inter_cluster_distance(centroids)
    
    print(f"Distance minimale inter-clusters: {distance_metrics['min_distance']:.4f}")
    
except Exception as e:
    print(f"Erreur: {e}")

print("Test du module personnalisé terminé.")
