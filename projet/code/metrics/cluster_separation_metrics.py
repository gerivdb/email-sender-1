#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les métriques de séparation des clusters et les seuils de qualité associés.
"""

import numpy as np
from typing import Dict, List, Tuple, Union, Optional, Any
from sklearn.metrics import silhouette_score, calinski_harabasz_score, davies_bouldin_score

# Constantes par défaut
DEFAULT_EPSILON = 1e-10
DEFAULT_MIN_INTER_CLUSTER_DISTANCE = 0.1
DEFAULT_MIN_SILHOUETTE_SCORE = 0.5

def calculate_inter_cluster_distance(centroids: np.ndarray) -> Dict[str, Any]:
    """
    Calcule les distances entre les centres des clusters.
    
    Args:
        centroids: Tableau des coordonnées des centres de clusters (n_clusters, n_features)
        
    Returns:
        Dict[str, Any]: Dictionnaire contenant les distances inter-clusters
    """
    n_clusters = centroids.shape[0]
    
    # Initialiser la matrice de distances
    distances = np.zeros((n_clusters, n_clusters))
    
    # Calculer les distances euclidiennes entre chaque paire de centroids
    for i in range(n_clusters):
        for j in range(i+1, n_clusters):
            dist = np.linalg.norm(centroids[i] - centroids[j])
            distances[i, j] = dist
            distances[j, i] = dist
    
    # Calculer les statistiques sur les distances
    min_distance = np.min(distances[distances > 0])
    max_distance = np.max(distances)
    mean_distance = np.mean(distances[distances > 0])
    median_distance = np.median(distances[distances > 0])
    
    return {
        "distance_matrix": distances,
        "min_distance": float(min_distance),
        "max_distance": float(max_distance),
        "mean_distance": float(mean_distance),
        "median_distance": float(median_distance)
    }

def evaluate_inter_cluster_distance_quality(min_distance: float, 
                                           threshold: float = DEFAULT_MIN_INTER_CLUSTER_DISTANCE) -> str:
    """
    Évalue la qualité de la séparation des clusters basée sur la distance minimale inter-clusters.
    
    Args:
        min_distance: Distance minimale entre deux clusters
        threshold: Seuil minimal de distance acceptable
        
    Returns:
        str: Niveau de qualité ("Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante")
    """
    if min_distance >= 2.0 * threshold:
        return "Excellente"
    elif min_distance >= 1.5 * threshold:
        return "Très bonne"
    elif min_distance >= threshold:
        return "Bonne"
    elif min_distance >= 0.7 * threshold:
        return "Acceptable"
    elif min_distance >= 0.5 * threshold:
        return "Limitée"
    else:
        return "Insuffisante"

def calculate_silhouette_metrics(X: np.ndarray, labels: np.ndarray) -> Dict[str, Any]:
    """
    Calcule les métriques de silhouette pour évaluer la qualité des clusters.
    
    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        
    Returns:
        Dict[str, Any]: Dictionnaire contenant les métriques de silhouette
    """
    # Vérifier qu'il y a au moins 2 clusters
    n_clusters = len(np.unique(labels))
    if n_clusters < 2:
        return {
            "silhouette_score": 0.0,
            "silhouette_quality": "Insuffisante",
            "calinski_harabasz_score": 0.0,
            "davies_bouldin_score": float('inf'),
            "overall_quality": "Insuffisante"
        }
    
    # Calculer le score de silhouette global
    try:
        sil_score = silhouette_score(X, labels)
    except:
        sil_score = 0.0
    
    # Calculer d'autres métriques de qualité de clustering
    try:
        ch_score = calinski_harabasz_score(X, labels)
    except:
        ch_score = 0.0
    
    try:
        db_score = davies_bouldin_score(X, labels)
    except:
        db_score = float('inf')
    
    # Évaluer la qualité basée sur le score de silhouette
    silhouette_quality = evaluate_silhouette_quality(sil_score)
    
    # Calculer une qualité globale (combinaison des différentes métriques)
    # Note: Le score de Davies-Bouldin est meilleur quand il est plus bas
    db_normalized = max(0, min(1, 1 - db_score / 10)) if db_score < float('inf') else 0
    
    # Normaliser le score de Calinski-Harabasz (valeurs typiques entre 0 et quelques milliers)
    ch_normalized = min(1, ch_score / 1000) if ch_score > 0 else 0
    
    # Combiner les scores (avec plus de poids sur la silhouette)
    combined_score = 0.6 * sil_score + 0.2 * ch_normalized + 0.2 * db_normalized
    overall_quality = evaluate_silhouette_quality(combined_score)
    
    return {
        "silhouette_score": float(sil_score),
        "silhouette_quality": silhouette_quality,
        "calinski_harabasz_score": float(ch_score),
        "davies_bouldin_score": float(db_score),
        "combined_score": float(combined_score),
        "overall_quality": overall_quality
    }

def evaluate_silhouette_quality(silhouette_score: float) -> str:
    """
    Évalue la qualité du clustering basée sur le score de silhouette.
    
    Args:
        silhouette_score: Score de silhouette (-1 à 1)
        
    Returns:
        str: Niveau de qualité
    """
    if silhouette_score >= 0.7:
        return "Excellente"
    elif silhouette_score >= 0.6:
        return "Très bonne"
    elif silhouette_score >= 0.5:
        return "Bonne"
    elif silhouette_score >= 0.4:
        return "Acceptable"
    elif silhouette_score >= 0.3:
        return "Limitée"
    else:
        return "Insuffisante"

def define_cluster_separation_thresholds(data_dimensionality: int = 2,
                                        cluster_count: int = 5,
                                        data_sparsity: str = "medium") -> Dict[str, Dict[str, float]]:
    """
    Définit les seuils de qualité pour la séparation des clusters en fonction
    de la dimensionnalité des données, du nombre de clusters et de la densité des données.
    
    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")
        
    Returns:
        Dict[str, Dict[str, float]]: Seuils pour différentes métriques
    """
    # Facteur d'ajustement basé sur la dimensionnalité
    # Plus la dimensionnalité est élevée, plus il est difficile d'avoir une bonne séparation
    dim_factor = max(0.5, min(1.0, 2.0 / np.sqrt(data_dimensionality)))
    
    # Facteur d'ajustement basé sur le nombre de clusters
    # Plus il y a de clusters, plus il est difficile de les séparer
    cluster_factor = max(0.5, min(1.0, 3.0 / np.sqrt(cluster_count)))
    
    # Facteur d'ajustement basé sur la densité des données
    sparsity_factors = {
        "low": 0.7,    # Données éparses: plus facile à séparer
        "medium": 1.0,  # Densité moyenne
        "high": 1.3     # Données denses: plus difficile à séparer
    }
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)
    
    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor / sparsity_factor
    
    # Définir les seuils pour la distance inter-clusters
    inter_cluster_distance_thresholds = {
        "excellent": 0.5 * global_factor,
        "very_good": 0.35 * global_factor,
        "good": 0.25 * global_factor,
        "acceptable": 0.15 * global_factor,
        "limited": 0.1 * global_factor,
        "insufficient": 0.0
    }
    
    # Définir les seuils pour le score de silhouette
    silhouette_thresholds = {
        "excellent": 0.7 * global_factor,
        "very_good": 0.6 * global_factor,
        "good": 0.5 * global_factor,
        "acceptable": 0.4 * global_factor,
        "limited": 0.3 * global_factor,
        "insufficient": 0.0
    }
    
    # Définir les seuils pour le score de Calinski-Harabasz
    # Ce score n'a pas de limite supérieure, donc nous utilisons des valeurs typiques
    ch_thresholds = {
        "excellent": 1000 * global_factor,
        "very_good": 500 * global_factor,
        "good": 200 * global_factor,
        "acceptable": 100 * global_factor,
        "limited": 50 * global_factor,
        "insufficient": 0.0
    }
    
    # Définir les seuils pour le score de Davies-Bouldin
    # Ce score est meilleur quand il est plus bas
    db_thresholds = {
        "excellent": 0.4 / global_factor,
        "very_good": 0.7 / global_factor,
        "good": 1.0 / global_factor,
        "acceptable": 1.5 / global_factor,
        "limited": 2.0 / global_factor,
        "insufficient": float('inf')
    }
    
    return {
        "inter_cluster_distance": inter_cluster_distance_thresholds,
        "silhouette": silhouette_thresholds,
        "calinski_harabasz": ch_thresholds,
        "davies_bouldin": db_thresholds
    }

def evaluate_cluster_quality(X: np.ndarray, 
                           labels: np.ndarray, 
                           centroids: Optional[np.ndarray] = None) -> Dict[str, Any]:
    """
    Évalue la qualité globale du clustering en combinant plusieurs métriques.
    
    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        centroids: Coordonnées des centres de clusters (optionnel)
        
    Returns:
        Dict[str, Any]: Résultats de l'évaluation
    """
    # Calculer les métriques de silhouette
    silhouette_metrics = calculate_silhouette_metrics(X, labels)
    
    # Si les centroids ne sont pas fournis, les calculer
    if centroids is None:
        n_clusters = len(np.unique(labels))
        n_features = X.shape[1]
        centroids = np.zeros((n_clusters, n_features))
        
        for i in range(n_clusters):
            cluster_points = X[labels == i]
            if len(cluster_points) > 0:
                centroids[i] = np.mean(cluster_points, axis=0)
    
    # Calculer les distances inter-clusters
    inter_cluster_metrics = calculate_inter_cluster_distance(centroids)
    
    # Évaluer la qualité basée sur la distance minimale inter-clusters
    distance_quality = evaluate_inter_cluster_distance_quality(
        inter_cluster_metrics["min_distance"]
    )
    
    # Combiner les évaluations de qualité
    # Donner plus de poids au score de silhouette (60%) qu'à la distance inter-clusters (40%)
    quality_ranks = {
        "Excellente": 5,
        "Très bonne": 4,
        "Bonne": 3,
        "Acceptable": 2,
        "Limitée": 1,
        "Insuffisante": 0
    }
    
    silhouette_rank = quality_ranks.get(silhouette_metrics["overall_quality"], 0)
    distance_rank = quality_ranks.get(distance_quality, 0)
    
    combined_rank = 0.6 * silhouette_rank + 0.4 * distance_rank
    
    # Convertir le rang combiné en niveau de qualité
    if combined_rank >= 4.5:
        overall_quality = "Excellente"
    elif combined_rank >= 3.5:
        overall_quality = "Très bonne"
    elif combined_rank >= 2.5:
        overall_quality = "Bonne"
    elif combined_rank >= 1.5:
        overall_quality = "Acceptable"
    elif combined_rank >= 0.5:
        overall_quality = "Limitée"
    else:
        overall_quality = "Insuffisante"
    
    # Construire le résultat final
    result = {
        "silhouette_metrics": silhouette_metrics,
        "inter_cluster_metrics": inter_cluster_metrics,
        "distance_quality": distance_quality,
        "overall_quality": overall_quality,
        "combined_rank": float(combined_rank)
    }
    
    return result
