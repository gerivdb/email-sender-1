#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simple avec scikit-learn.
"""

print("Début du test scikit-learn...")

# Importer les modules nécessaires
try:
    import numpy as np
    from sklearn.datasets import make_blobs
    from sklearn.cluster import KMeans
    from sklearn.metrics import silhouette_score
    
    print("Modules importés avec succès.")
    
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
        print(f"Données générées avec centres. Forme de X: {X.shape}, forme de y: {y.shape}")
    else:
        X, y = result
        print(f"Données générées sans centres. Forme de X: {X.shape}, forme de y: {y.shape}")
    
    # Appliquer K-means
    print("Application de K-means...")
    kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X)
    centroids = kmeans.cluster_centers_
    
    print(f"K-means appliqué. Forme des étiquettes: {labels.shape}, forme des centroids: {centroids.shape}")
    
    # Calculer le score de silhouette
    print("Calcul du score de silhouette...")
    sil_score = silhouette_score(X, labels)
    print(f"Score de silhouette: {sil_score:.4f}")
    
except Exception as e:
    print(f"Erreur: {e}")

print("Test scikit-learn terminé.")
