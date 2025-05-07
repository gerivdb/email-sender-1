#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les métriques de cohésion des clusters et les seuils de qualité associés.
"""

import numpy as np
from typing import Dict, List, Tuple, Union, Optional, Any
from sklearn.metrics import pairwise_distances
from sklearn.neighbors import NearestNeighbors

# Constantes par défaut
DEFAULT_EPSILON = 1e-10
DEFAULT_MAX_INTRA_CLUSTER_VARIANCE = 1.0
DEFAULT_MIN_DENSITY = 0.1

def calculate_intra_cluster_variance(X: np.ndarray,
                                    labels: np.ndarray,
                                    centroids: Optional[np.ndarray] = None) -> Dict[str, Any]:
    """
    Calcule la variance intra-cluster pour chaque cluster.

    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        centroids: Coordonnées des centres de clusters (optionnel)

    Returns:
        Dict[str, Any]: Dictionnaire contenant les variances intra-cluster
    """
    n_clusters = len(np.unique(labels))
    n_features = X.shape[1]

    # Si les centroids ne sont pas fournis, les calculer
    if centroids is None:
        centroids = np.zeros((n_clusters, n_features), dtype=float)
        for i in range(n_clusters):
            cluster_points = X[labels == i]
            if len(cluster_points) > 0:
                centroids[i] = np.mean(cluster_points, axis=0)

    # Initialiser les résultats
    variances = np.zeros(n_clusters, dtype=float)
    point_counts = np.zeros(n_clusters, dtype=int)
    max_distances = np.zeros(n_clusters, dtype=float)
    mean_distances = np.zeros(n_clusters, dtype=float)

    # Calculer la variance pour chaque cluster
    for i in range(n_clusters):
        cluster_points = X[labels == i]
        point_counts[i] = len(cluster_points)

        if point_counts[i] > 0:
            # Calculer la variance comme la moyenne des distances au carré au centroid
            distances = np.linalg.norm(cluster_points - centroids[i], axis=1)
            variances[i] = np.mean(distances ** 2)
            max_distances[i] = np.max(distances) if len(distances) > 0 else 0
            mean_distances[i] = np.mean(distances) if len(distances) > 0 else 0

    # Calculer les statistiques globales
    total_variance = np.sum(variances * point_counts) / np.sum(point_counts) if np.sum(point_counts) > 0 else 0
    max_variance = np.max(variances) if len(variances) > 0 else 0
    min_variance = np.min(variances[variances > 0]) if np.any(variances > 0) else 0
    variance_ratio = max_variance / min_variance if min_variance > 0 else float('inf')

    return {
        "cluster_variances": variances.tolist(),
        "point_counts": point_counts.tolist(),
        "max_distances": max_distances.tolist(),
        "mean_distances": mean_distances.tolist(),
        "total_variance": float(total_variance),
        "max_variance": float(max_variance),
        "min_variance": float(min_variance),
        "variance_ratio": float(variance_ratio)
    }

def establish_intra_cluster_variance_criteria(data_dimensionality: int = 2,
                                             cluster_count: int = 5,
                                             data_sparsity: str = "medium") -> Dict[str, Dict[str, float]]:
    """
    Établit les critères de variance intra-cluster maximale en fonction
    de la dimensionnalité des données, du nombre de clusters et de la densité des données.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, float]]: Critères de variance intra-cluster maximale
    """
    # Facteurs d'ajustement basés sur la dimensionnalité
    # Plus la dimensionnalité est élevée, plus la variance acceptable est élevée
    dim_factors = {
        1: 0.5,    # 1D: variance plus faible attendue
        2: 1.0,    # 2D: référence
        3: 1.5,    # 3D: variance plus élevée acceptable
        4: 2.0,    # 4D
        5: 2.5,    # 5D
        6: 3.0,    # 6D
        7: 3.5,    # 7D
        8: 4.0,    # 8D
        9: 4.5,    # 9D
        10: 5.0    # 10D et plus: variance beaucoup plus élevée acceptable
    }

    # Facteurs d'ajustement basés sur le nombre de clusters
    # Plus il y a de clusters, plus la variance acceptable est faible
    cluster_factors = {
        2: 1.5,    # 2 clusters: variance plus élevée acceptable
        3: 1.3,    # 3 clusters
        4: 1.1,    # 4 clusters
        5: 1.0,    # 5 clusters: référence
        6: 0.9,    # 6 clusters
        7: 0.85,   # 7 clusters
        8: 0.8,    # 8 clusters
        9: 0.75,   # 9 clusters
        10: 0.7,   # 10 clusters et plus: variance plus faible attendue
    }

    # Facteurs d'ajustement basés sur la densité des données
    # Plus les données sont denses, plus la variance acceptable est faible
    sparsity_factors = {
        "very_low": 2.0,    # Très faible densité: variance plus élevée acceptable
        "low": 1.5,         # Faible densité
        "medium": 1.0,      # Densité moyenne: référence
        "high": 0.7,        # Haute densité
        "very_high": 0.5    # Très haute densité: variance plus faible attendue
    }

    # Appliquer les facteurs avec des limites
    dim_factor = dim_factors.get(min(data_dimensionality, 10),
                                dim_factors[10] * (data_dimensionality / 10))
    cluster_factor = cluster_factors.get(min(cluster_count, 10),
                                        cluster_factors[10])
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)

    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor * sparsity_factor

    # Définir les critères de variance intra-cluster maximale
    max_variance_criteria = {
        "excellent": 0.2 * global_factor,
        "very_good": 0.4 * global_factor,
        "good": 0.6 * global_factor,
        "acceptable": 0.8 * global_factor,
        "limited": 1.0 * global_factor,
        "insufficient": float('inf')
    }

    # Définir les critères pour le ratio de variance (max/min)
    variance_ratio_criteria = {
        "excellent": 1.5,
        "very_good": 2.0,
        "good": 3.0,
        "acceptable": 4.0,
        "limited": 5.0,
        "insufficient": float('inf')
    }

    return {
        "max_variance": max_variance_criteria,
        "variance_ratio": variance_ratio_criteria
    }

def evaluate_intra_cluster_variance_quality(variance_metrics: Dict[str, Any],
                                           criteria: Optional[Dict[str, Dict[str, float]]] = None,
                                           data_dimensionality: int = 2,
                                           cluster_count: int = 5,
                                           data_sparsity: str = "medium") -> Dict[str, str]:
    """
    Évalue la qualité de la cohésion des clusters basée sur la variance intra-cluster.

    Args:
        variance_metrics: Métriques de variance intra-cluster
        criteria: Critères de variance intra-cluster (optionnel)
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, str]: Évaluation de la qualité
    """
    # Si les critères ne sont pas fournis, les établir
    if criteria is None:
        criteria = establish_intra_cluster_variance_criteria(
            data_dimensionality=data_dimensionality,
            cluster_count=cluster_count,
            data_sparsity=data_sparsity
        )

    # Évaluer la qualité basée sur la variance maximale
    max_variance = variance_metrics["max_variance"]
    max_variance_quality = "Insuffisante"

    for level, threshold in criteria["max_variance"].items():
        if max_variance <= threshold:
            if level == "excellent":
                max_variance_quality = "Excellente"
            elif level == "very_good":
                max_variance_quality = "Très bonne"
            elif level == "good":
                max_variance_quality = "Bonne"
            elif level == "acceptable":
                max_variance_quality = "Acceptable"
            elif level == "limited":
                max_variance_quality = "Limitée"
            break

    # Évaluer la qualité basée sur le ratio de variance
    variance_ratio = variance_metrics["variance_ratio"]
    variance_ratio_quality = "Insuffisante"

    for level, threshold in criteria["variance_ratio"].items():
        if variance_ratio <= threshold:
            if level == "excellent":
                variance_ratio_quality = "Excellente"
            elif level == "very_good":
                variance_ratio_quality = "Très bonne"
            elif level == "good":
                variance_ratio_quality = "Bonne"
            elif level == "acceptable":
                variance_ratio_quality = "Acceptable"
            elif level == "limited":
                variance_ratio_quality = "Limitée"
            break

    # Déterminer la qualité globale (prendre la moins bonne des deux)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    max_variance_index = quality_levels.index(max_variance_quality)
    variance_ratio_index = quality_levels.index(variance_ratio_quality)
    overall_index = max(max_variance_index, variance_ratio_index)
    overall_quality = quality_levels[overall_index]

    return {
        "max_variance_quality": max_variance_quality,
        "variance_ratio_quality": variance_ratio_quality,
        "overall_quality": overall_quality
    }

def calculate_cluster_density_metrics(X: np.ndarray,
                                     labels: np.ndarray,
                                     k: int = 5) -> Dict[str, Any]:
    """
    Calcule les métriques de densité pour la cohésion des clusters.

    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        k: Nombre de voisins à considérer pour les métriques de densité locale

    Returns:
        Dict[str, Any]: Dictionnaire contenant les métriques de densité
    """
    n_clusters = len(np.unique(labels))
    n_samples = X.shape[0]

    # Initialiser les résultats
    densities = np.zeros(n_clusters, dtype=float)
    relative_densities = np.zeros(n_clusters, dtype=float)
    density_variations = np.zeros(n_clusters, dtype=float)
    point_counts = np.zeros(n_clusters, dtype=int)

    # Calculer les k plus proches voisins pour tous les points
    nn = NearestNeighbors(n_neighbors=k+1)  # +1 car le point lui-même est inclus
    nn.fit(X)
    distances, _ = nn.kneighbors(X)

    # Calculer la densité locale pour chaque point (inverse de la distance moyenne aux k voisins)
    # Exclure le point lui-même (distance = 0)
    local_densities = 1.0 / (np.mean(distances[:, 1:], axis=1) + DEFAULT_EPSILON)

    # Calculer les métriques de densité pour chaque cluster
    for i in range(n_clusters):
        cluster_mask = (labels == i)
        point_counts[i] = np.sum(cluster_mask)

        if point_counts[i] > 0:
            cluster_local_densities = local_densities[cluster_mask]
            densities[i] = np.mean(cluster_local_densities)
            density_variations[i] = np.std(cluster_local_densities) / (densities[i] + DEFAULT_EPSILON)

    # Calculer la densité relative (par rapport à la densité moyenne globale)
    global_density = np.mean(local_densities)
    relative_densities = densities / (global_density + DEFAULT_EPSILON)

    # Calculer les statistiques globales
    mean_density = np.mean(densities)
    max_density = np.max(densities) if len(densities) > 0 else 0
    min_density = np.min(densities[densities > 0]) if np.any(densities > 0) else 0
    density_ratio = max_density / (min_density + DEFAULT_EPSILON)
    mean_density_variation = np.mean(density_variations)

    return {
        "cluster_densities": densities.tolist(),
        "relative_densities": relative_densities.tolist(),
        "density_variations": density_variations.tolist(),
        "point_counts": point_counts.tolist(),
        "mean_density": float(mean_density),
        "max_density": float(max_density),
        "min_density": float(min_density),
        "density_ratio": float(density_ratio),
        "mean_density_variation": float(mean_density_variation)
    }

def define_density_metrics_thresholds(data_dimensionality: int = 2,
                                     cluster_count: int = 5,
                                     data_sparsity: str = "medium") -> Dict[str, Dict[str, float]]:
    """
    Définit les métriques de densité pour la cohésion des clusters en fonction
    de la dimensionnalité des données, du nombre de clusters et de la densité des données.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, float]]: Seuils pour les métriques de densité
    """
    # Facteurs d'ajustement basés sur la dimensionnalité
    # Plus la dimensionnalité est élevée, plus les variations de densité acceptables sont élevées
    dim_factors = {
        1: 0.7,    # 1D: variations plus faibles attendues
        2: 1.0,    # 2D: référence
        3: 1.3,    # 3D: variations plus élevées acceptables
        4: 1.6,    # 4D
        5: 1.9,    # 5D
        6: 2.2,    # 6D
        7: 2.5,    # 7D
        8: 2.8,    # 8D
        9: 3.1,    # 9D
        10: 3.5    # 10D et plus: variations beaucoup plus élevées acceptables
    }

    # Facteurs d'ajustement basés sur le nombre de clusters
    # Plus il y a de clusters, plus les variations de densité acceptables sont élevées
    cluster_factors = {
        2: 0.8,    # 2 clusters: variations plus faibles attendues
        3: 0.9,    # 3 clusters
        4: 0.95,   # 4 clusters
        5: 1.0,    # 5 clusters: référence
        6: 1.05,   # 6 clusters
        7: 1.1,    # 7 clusters
        8: 1.15,   # 8 clusters
        9: 1.2,    # 9 clusters
        10: 1.25   # 10 clusters et plus: variations plus élevées acceptables
    }

    # Facteurs d'ajustement basés sur la densité des données
    # Plus les données sont denses, plus les variations de densité acceptables sont faibles
    sparsity_factors = {
        "very_low": 1.5,    # Très faible densité: variations plus élevées acceptables
        "low": 1.2,         # Faible densité
        "medium": 1.0,      # Densité moyenne: référence
        "high": 0.8,        # Haute densité
        "very_high": 0.6    # Très haute densité: variations plus faibles attendues
    }

    # Appliquer les facteurs avec des limites
    dim_factor = dim_factors.get(min(data_dimensionality, 10),
                                dim_factors[10] * (data_dimensionality / 10))
    cluster_factor = cluster_factors.get(min(cluster_count, 10),
                                        cluster_factors[10])
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)

    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor * sparsity_factor

    # Définir les seuils pour le ratio de densité (max/min)
    density_ratio_thresholds = {
        "excellent": 1.5 * global_factor,
        "very_good": 2.0 * global_factor,
        "good": 3.0 * global_factor,
        "acceptable": 4.0 * global_factor,
        "limited": 5.0 * global_factor,
        "insufficient": float('inf')
    }

    # Définir les seuils pour la variation de densité intra-cluster
    density_variation_thresholds = {
        "excellent": 0.2 * global_factor,
        "very_good": 0.3 * global_factor,
        "good": 0.4 * global_factor,
        "acceptable": 0.5 * global_factor,
        "limited": 0.7 * global_factor,
        "insufficient": float('inf')
    }

    # Définir les seuils pour la densité minimale relative
    min_relative_density_thresholds = {
        "excellent": 0.8 / global_factor,
        "very_good": 0.6 / global_factor,
        "good": 0.4 / global_factor,
        "acceptable": 0.3 / global_factor,
        "limited": 0.2 / global_factor,
        "insufficient": 0.0
    }

    return {
        "density_ratio": density_ratio_thresholds,
        "density_variation": density_variation_thresholds,
        "min_relative_density": min_relative_density_thresholds
    }

def evaluate_density_metrics_quality(density_metrics: Dict[str, Any],
                                    thresholds: Optional[Dict[str, Dict[str, float]]] = None,
                                    data_dimensionality: int = 2,
                                    cluster_count: int = 5,
                                    data_sparsity: str = "medium") -> Dict[str, str]:
    """
    Évalue la qualité de la cohésion des clusters basée sur les métriques de densité.

    Args:
        density_metrics: Métriques de densité des clusters
        thresholds: Seuils pour les métriques de densité (optionnel)
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, str]: Évaluation de la qualité
    """
    # Si les seuils ne sont pas fournis, les définir
    if thresholds is None:
        thresholds = define_density_metrics_thresholds(
            data_dimensionality=data_dimensionality,
            cluster_count=cluster_count,
            data_sparsity=data_sparsity
        )

    # Évaluer la qualité basée sur le ratio de densité
    density_ratio = density_metrics["density_ratio"]
    density_ratio_quality = "Insuffisante"

    for level, threshold in thresholds["density_ratio"].items():
        if density_ratio <= threshold:
            if level == "excellent":
                density_ratio_quality = "Excellente"
            elif level == "very_good":
                density_ratio_quality = "Très bonne"
            elif level == "good":
                density_ratio_quality = "Bonne"
            elif level == "acceptable":
                density_ratio_quality = "Acceptable"
            elif level == "limited":
                density_ratio_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la variation de densité
    mean_density_variation = density_metrics["mean_density_variation"]
    density_variation_quality = "Insuffisante"

    for level, threshold in thresholds["density_variation"].items():
        if mean_density_variation <= threshold:
            if level == "excellent":
                density_variation_quality = "Excellente"
            elif level == "very_good":
                density_variation_quality = "Très bonne"
            elif level == "good":
                density_variation_quality = "Bonne"
            elif level == "acceptable":
                density_variation_quality = "Acceptable"
            elif level == "limited":
                density_variation_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la densité minimale relative
    relative_densities = np.array(density_metrics["relative_densities"])
    min_relative_density = np.min(relative_densities[relative_densities > 0]) if np.any(relative_densities > 0) else 0
    min_density_quality = "Insuffisante"

    for level, threshold in thresholds["min_relative_density"].items():
        if min_relative_density >= threshold:
            if level == "excellent":
                min_density_quality = "Excellente"
            elif level == "very_good":
                min_density_quality = "Très bonne"
            elif level == "good":
                min_density_quality = "Bonne"
            elif level == "acceptable":
                min_density_quality = "Acceptable"
            elif level == "limited":
                min_density_quality = "Limitée"
            break

    # Déterminer la qualité globale (prendre la moins bonne des trois)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    density_ratio_index = quality_levels.index(density_ratio_quality)
    density_variation_index = quality_levels.index(density_variation_quality)
    min_density_index = quality_levels.index(min_density_quality)
    overall_index = max(density_ratio_index, density_variation_index, min_density_index)
    overall_quality = quality_levels[overall_index]

    return {
        "density_ratio_quality": density_ratio_quality,
        "density_variation_quality": density_variation_quality,
        "min_density_quality": min_density_quality,
        "overall_quality": overall_quality
    }

def establish_cluster_cohesion_quality_thresholds(data_dimensionality: int = 2,
                                                cluster_count: int = 5,
                                                data_sparsity: str = "medium") -> Dict[str, Dict[str, Dict[str, float]]]:
    """
    Établit les seuils de qualité pour la cohésion des clusters en fonction
    de la dimensionnalité des données, du nombre de clusters et de la densité des données.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualité pour la cohésion des clusters
    """
    # Obtenir les seuils pour la variance intra-cluster
    variance_thresholds = establish_intra_cluster_variance_criteria(
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Obtenir les seuils pour les métriques de densité
    density_thresholds = define_density_metrics_thresholds(
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Combiner les seuils
    combined_thresholds = {
        "variance": variance_thresholds,
        "density": density_thresholds
    }

    return combined_thresholds

def evaluate_cluster_cohesion_quality(X: np.ndarray,
                                     labels: np.ndarray,
                                     centroids: Optional[np.ndarray] = None,
                                     thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None,
                                     data_dimensionality: int = 2,
                                     cluster_count: int = 5,
                                     data_sparsity: str = "medium",
                                     k: int = 5) -> Dict[str, Any]:
    """
    Évalue la qualité globale de la cohésion des clusters en combinant les métriques
    de variance intra-cluster et de densité.

    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        centroids: Coordonnées des centres de clusters (optionnel)
        thresholds: Seuils de qualité pour la cohésion des clusters (optionnel)
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")
        k: Nombre de voisins à considérer pour les métriques de densité locale

    Returns:
        Dict[str, Any]: Évaluation de la qualité de la cohésion des clusters
    """
    # Si les seuils ne sont pas fournis, les établir
    if thresholds is None:
        thresholds = establish_cluster_cohesion_quality_thresholds(
            data_dimensionality=data_dimensionality,
            cluster_count=cluster_count,
            data_sparsity=data_sparsity
        )

    # Calculer les métriques de variance intra-cluster
    variance_metrics = calculate_intra_cluster_variance(X, labels, centroids)

    # Évaluer la qualité basée sur la variance intra-cluster
    variance_quality = evaluate_intra_cluster_variance_quality(
        variance_metrics=variance_metrics,
        criteria=thresholds["variance"],
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Calculer les métriques de densité
    density_metrics = calculate_cluster_density_metrics(X, labels, k)

    # Évaluer la qualité basée sur les métriques de densité
    density_quality = evaluate_density_metrics_quality(
        density_metrics=density_metrics,
        thresholds=thresholds["density"],
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Déterminer la qualité globale (prendre la moins bonne des deux)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    variance_overall_index = quality_levels.index(variance_quality["overall_quality"])
    density_overall_index = quality_levels.index(density_quality["overall_quality"])
    overall_index = max(variance_overall_index, density_overall_index)
    overall_quality = quality_levels[overall_index]

    # Calculer un score combiné (0 à 1, où 1 est excellent)
    # Convertir les niveaux de qualité en scores numériques
    quality_scores = {
        "Excellente": 1.0,
        "Très bonne": 0.8,
        "Bonne": 0.6,
        "Acceptable": 0.4,
        "Limitée": 0.2,
        "Insuffisante": 0.0
    }

    # Calculer les scores individuels
    variance_score = quality_scores[variance_quality["overall_quality"]]
    density_score = quality_scores[density_quality["overall_quality"]]

    # Calculer le score combiné (moyenne pondérée)
    combined_score = 0.5 * variance_score + 0.5 * density_score

    return {
        "variance_metrics": variance_metrics,
        "density_metrics": density_metrics,
        "variance_quality": variance_quality,
        "density_quality": density_quality,
        "overall_quality": overall_quality,
        "combined_score": combined_score
    }
