#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour définir les métriques de stabilité des clusters.
"""

import numpy as np
from typing import Dict, List, Tuple, Union, Optional, Any, Callable
from sklearn.metrics import pairwise_distances, adjusted_rand_score, adjusted_mutual_info_score
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.utils import resample

# Constantes par défaut
DEFAULT_EPSILON = 1e-10
DEFAULT_N_RESAMPLINGS = 10
DEFAULT_SUBSAMPLE_SIZE = 0.8
DEFAULT_N_ITERATIONS = 20

def calculate_resolution_robustness(X: np.ndarray,
                                   labels: np.ndarray,
                                   n_clusters: int,
                                   resolutions: Optional[List[float]] = None,
                                   n_resamplings: int = DEFAULT_N_RESAMPLINGS) -> Dict[str, Any]:
    """
    Calcule la robustesse des clusters face aux variations de résolution.

    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        n_clusters: Nombre de clusters
        resolutions: Liste des facteurs de résolution à tester (par défaut: [0.5, 0.75, 1.0, 1.25, 1.5])
        n_resamplings: Nombre de ré-échantillonnages pour chaque résolution

    Returns:
        Dict[str, Any]: Métriques de robustesse face aux variations de résolution
    """
    if resolutions is None:
        resolutions = [0.5, 0.75, 1.0, 1.25, 1.5]

    n_samples, n_features = X.shape

    # Initialiser les résultats
    stability_scores = []
    centroid_shifts = []
    label_consistency = []
    resolution_metrics = []

    # Obtenir les centroids originaux
    original_centroids = np.zeros((n_clusters, n_features))
    for i in range(n_clusters):
        cluster_points = X[labels == i]
        if len(cluster_points) > 0:
            original_centroids[i] = np.mean(cluster_points, axis=0)

    # Tester différentes résolutions
    for resolution in resolutions:
        # Appliquer la résolution (simuler une réduction/augmentation de la résolution)
        if resolution != 1.0:
            # Simuler une réduction de résolution en ajoutant du bruit gaussien
            noise_level = (1.0 - resolution) if resolution < 1.0 else (resolution - 1.0) / resolution
            noise_scale = noise_level * np.std(X, axis=0)

            resolution_stability = []
            resolution_shifts = []
            resolution_consistency = []

            for _ in range(n_resamplings):
                # Ajouter du bruit pour simuler la variation de résolution
                X_noisy = X + np.random.normal(0, noise_scale, X.shape)

                # Appliquer le clustering
                kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
                new_labels = kmeans.fit_predict(X_noisy)
                new_centroids = kmeans.cluster_centers_

                # Calculer la stabilité (correspondance entre les clusters originaux et nouveaux)
                stability_score = calculate_cluster_correspondence(labels, new_labels)
                resolution_stability.append(stability_score)

                # Calculer le déplacement des centroids
                centroid_shift = calculate_centroid_shift(original_centroids, new_centroids)
                resolution_shifts.append(centroid_shift)

                # Calculer la cohérence des étiquettes
                consistency = calculate_label_consistency(labels, new_labels)
                resolution_consistency.append(consistency)

            # Agréger les résultats pour cette résolution
            stability_scores.append(np.mean(resolution_stability))
            centroid_shifts.append(np.mean(resolution_shifts))
            label_consistency.append(np.mean(resolution_consistency))

            resolution_metrics.append({
                "resolution": resolution,
                "stability_score": np.mean(resolution_stability),
                "stability_std": np.std(resolution_stability),
                "centroid_shift": np.mean(resolution_shifts),
                "centroid_shift_std": np.std(resolution_shifts),
                "label_consistency": np.mean(resolution_consistency),
                "label_consistency_std": np.std(resolution_consistency)
            })
        else:
            # Pour la résolution originale (1.0), la stabilité est parfaite
            stability_scores.append(1.0)
            centroid_shifts.append(0.0)
            label_consistency.append(1.0)

            resolution_metrics.append({
                "resolution": resolution,
                "stability_score": 1.0,
                "stability_std": 0.0,
                "centroid_shift": 0.0,
                "centroid_shift_std": 0.0,
                "label_consistency": 1.0,
                "label_consistency_std": 0.0
            })

    # Calculer les métriques globales
    mean_stability = np.mean(stability_scores)
    min_stability = np.min(stability_scores)
    stability_range = np.max(stability_scores) - min_stability

    mean_shift = np.mean(centroid_shifts)
    max_shift = np.max(centroid_shifts)

    mean_consistency = np.mean(label_consistency)
    min_consistency = np.min(label_consistency)

    # Calculer un score global de robustesse (plus élevé = meilleur)
    # Combinaison pondérée de la stabilité, du déplacement des centroids et de la cohérence des étiquettes
    global_robustness = 0.4 * mean_stability + 0.3 * (1.0 - mean_shift / (mean_shift + 1.0)) + 0.3 * mean_consistency

    return {
        "resolution_metrics": resolution_metrics,
        "mean_stability": float(mean_stability),
        "min_stability": float(min_stability),
        "stability_range": float(stability_range),
        "mean_centroid_shift": float(mean_shift),
        "max_centroid_shift": float(max_shift),
        "mean_label_consistency": float(mean_consistency),
        "min_label_consistency": float(min_consistency),
        "global_robustness": float(global_robustness)
    }

def calculate_cluster_correspondence(labels1: np.ndarray, labels2: np.ndarray) -> float:
    """
    Calcule la correspondance entre deux ensembles d'étiquettes de cluster.

    Args:
        labels1: Premier ensemble d'étiquettes
        labels2: Deuxième ensemble d'étiquettes

    Returns:
        float: Score de correspondance (0-1, où 1 = correspondance parfaite)
    """
    n_samples = len(labels1)
    if n_samples != len(labels2):
        raise ValueError("Les ensembles d'étiquettes doivent avoir la même taille")

    # Créer une matrice de contingence
    unique_labels1 = np.unique(labels1)
    unique_labels2 = np.unique(labels2)
    n_clusters1 = len(unique_labels1)
    n_clusters2 = len(unique_labels2)

    contingency = np.zeros((n_clusters1, n_clusters2))

    for i, label1 in enumerate(unique_labels1):
        for j, label2 in enumerate(unique_labels2):
            contingency[i, j] = np.sum((labels1 == label1) & (labels2 == label2))

    # Normaliser la matrice
    contingency = contingency / n_samples

    # Calculer la correspondance maximale pour chaque cluster
    max_correspondence = np.sum(np.max(contingency, axis=1))

    # Normaliser par le nombre de clusters
    normalized_correspondence = max_correspondence / n_clusters1 if n_clusters1 > 0 else 0.0

    return float(normalized_correspondence)

def calculate_centroid_shift(centroids1: np.ndarray, centroids2: np.ndarray) -> float:
    """
    Calcule le déplacement moyen entre deux ensembles de centroids.

    Args:
        centroids1: Premier ensemble de centroids
        centroids2: Deuxième ensemble de centroids

    Returns:
        float: Déplacement moyen des centroids
    """
    n_clusters1, n_features1 = centroids1.shape
    n_clusters2, n_features2 = centroids2.shape

    if n_features1 != n_features2:
        raise ValueError("Les centroids doivent avoir le même nombre de caractéristiques")

    if n_clusters1 != n_clusters2:
        # Si le nombre de clusters est différent, utiliser une approche différente
        # Calculer la distance minimale pour chaque centroid du premier ensemble
        min_distances = []
        for centroid in centroids1:
            distances = np.linalg.norm(centroids2 - centroid, axis=1)
            min_distances.append(np.min(distances))

        return float(np.mean(min_distances))
    else:
        # Calculer la matrice de distances entre les centroids
        distances = pairwise_distances(centroids1, centroids2)

        # Trouver l'assignation optimale (problème d'assignation hongrois)
        # Pour simplifier, nous utilisons une approche gloutonne
        assigned_indices = []
        total_distance = 0.0

        for i in range(n_clusters1):
            # Trouver l'indice du centroid le plus proche dans le deuxième ensemble
            # qui n'a pas encore été assigné
            available_indices = [j for j in range(n_clusters2) if j not in assigned_indices]
            if not available_indices:
                break

            distances_i = [distances[i, j] for j in available_indices]
            min_idx = available_indices[np.argmin(distances_i)]
            assigned_indices.append(min_idx)
            total_distance += distances[i, min_idx]

        # Calculer la distance moyenne
        mean_distance = total_distance / n_clusters1 if n_clusters1 > 0 else 0.0

        return float(mean_distance)

def calculate_label_consistency(labels1: np.ndarray, labels2: np.ndarray) -> float:
    """
    Calcule la cohérence des étiquettes entre deux ensembles d'étiquettes de cluster.

    Args:
        labels1: Premier ensemble d'étiquettes
        labels2: Deuxième ensemble d'étiquettes

    Returns:
        float: Score de cohérence (0-1, où 1 = cohérence parfaite)
    """
    n_samples = len(labels1)
    if n_samples != len(labels2):
        raise ValueError("Les ensembles d'étiquettes doivent avoir la même taille")

    # Calculer la matrice de paires
    # Une paire est cohérente si les deux points sont dans le même cluster
    # dans les deux ensembles d'étiquettes, ou dans des clusters différents
    # dans les deux ensembles d'étiquettes
    same_cluster1 = np.zeros((n_samples, n_samples), dtype=bool)
    same_cluster2 = np.zeros((n_samples, n_samples), dtype=bool)

    for i in range(n_samples):
        same_cluster1[i, :] = labels1 == labels1[i]
        same_cluster2[i, :] = labels2 == labels2[i]

    # Calculer la cohérence
    consistent_pairs = (same_cluster1 & same_cluster2) | (~same_cluster1 & ~same_cluster2)

    # Ne compter que les paires uniques (matrice triangulaire supérieure sans la diagonale)
    mask = np.triu(np.ones((n_samples, n_samples), dtype=bool), k=1)
    n_pairs = np.sum(mask)
    n_consistent_pairs = np.sum(consistent_pairs[mask])

    consistency = n_consistent_pairs / n_pairs if n_pairs > 0 else 0.0

    return float(consistency)

def establish_resolution_robustness_criteria(data_dimensionality: int = 2,
                                           cluster_count: int = 5,
                                           data_sparsity: str = "medium") -> Dict[str, Dict[str, float]]:
    """
    Établit les critères de robustesse face aux variations de résolution.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, float]]: Critères de robustesse face aux variations de résolution
    """
    # Facteurs d'ajustement basés sur la dimensionnalité
    # Plus la dimensionnalité est élevée, plus la robustesse attendue est faible
    dim_factors = {
        1: 1.2,    # 1D: robustesse plus élevée attendue
        2: 1.0,    # 2D: référence
        3: 0.9,    # 3D: robustesse plus faible acceptable
        4: 0.85,   # 4D
        5: 0.8,    # 5D
        6: 0.75,   # 6D
        7: 0.7,    # 7D
        8: 0.65,   # 8D
        9: 0.6,    # 9D
        10: 0.55   # 10D et plus: robustesse beaucoup plus faible acceptable
    }

    # Facteurs d'ajustement basés sur le nombre de clusters
    # Plus il y a de clusters, plus la robustesse attendue est faible
    cluster_factors = {
        2: 1.2,    # 2 clusters: robustesse plus élevée attendue
        3: 1.1,    # 3 clusters
        4: 1.05,   # 4 clusters
        5: 1.0,    # 5 clusters: référence
        6: 0.95,   # 6 clusters
        7: 0.9,    # 7 clusters
        8: 0.85,   # 8 clusters
        9: 0.8,    # 9 clusters
        10: 0.75   # 10 clusters et plus: robustesse plus faible attendue
    }

    # Facteurs d'ajustement basés sur la densité des données
    # Plus les données sont denses, plus la robustesse attendue est élevée
    sparsity_factors = {
        "very_low": 0.7,    # Très faible densité: robustesse plus faible attendue
        "low": 0.85,        # Faible densité
        "medium": 1.0,      # Densité moyenne: référence
        "high": 1.1,        # Haute densité
        "very_high": 1.2    # Très haute densité: robustesse plus élevée attendue
    }

    # Appliquer les facteurs avec des limites
    dim_factor = dim_factors.get(min(data_dimensionality, 10),
                                dim_factors[10] * (data_dimensionality / 10))
    cluster_factor = cluster_factors.get(min(cluster_count, 10),
                                        cluster_factors[10])
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)

    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor * sparsity_factor

    # Définir les seuils pour la stabilité globale
    stability_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour le déplacement des centroids
    # Plus le déplacement est faible, meilleure est la robustesse
    centroid_shift_thresholds = {
        "excellent": 0.1 / global_factor,
        "very_good": 0.2 / global_factor,
        "good": 0.3 / global_factor,
        "acceptable": 0.4 / global_factor,
        "limited": 0.5 / global_factor,
        "insufficient": float('inf')
    }

    # Définir les seuils pour la cohérence des étiquettes
    label_consistency_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour la robustesse globale
    global_robustness_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    return {
        "stability": stability_thresholds,
        "centroid_shift": centroid_shift_thresholds,
        "label_consistency": label_consistency_thresholds,
        "global_robustness": global_robustness_thresholds
    }

def calculate_cluster_reproducibility(X: np.ndarray,
                                    clustering_method: Callable,
                                    n_clusters: int,
                                    n_iterations: int = DEFAULT_N_ITERATIONS,
                                    subsample_size: float = DEFAULT_SUBSAMPLE_SIZE,
                                    random_state: int = 42) -> Dict[str, Any]:
    """
    Calcule la reproductibilité des clusters en utilisant des sous-échantillonnages répétés.

    Args:
        X: Données d'entrée (n_samples, n_features)
        clustering_method: Méthode de clustering à utiliser (doit accepter n_clusters et random_state)
        n_clusters: Nombre de clusters
        n_iterations: Nombre d'itérations pour le sous-échantillonnage
        subsample_size: Taille du sous-échantillon (proportion des données)
        random_state: Graine aléatoire

    Returns:
        Dict[str, Any]: Métriques de reproductibilité des clusters
    """
    n_samples, n_features = X.shape
    subsample_n = int(n_samples * subsample_size)

    # Initialiser les résultats
    rand_scores = []
    ami_scores = []
    centroid_stabilities = []
    membership_stabilities = []

    # Effectuer le clustering sur l'ensemble complet des données
    full_clustering = clustering_method(n_clusters=n_clusters, random_state=random_state)
    full_labels = full_clustering.fit_predict(X)

    try:
        full_centroids = full_clustering.cluster_centers_
    except AttributeError:
        # Si la méthode de clustering ne fournit pas de centroids, les calculer manuellement
        full_centroids = np.zeros((n_clusters, n_features))
        for i in range(n_clusters):
            cluster_points = X[full_labels == i]
            if len(cluster_points) > 0:
                full_centroids[i] = np.mean(cluster_points, axis=0)

    # Effectuer des itérations de sous-échantillonnage
    for i in range(n_iterations):
        # Sous-échantillonner les données
        indices = resample(np.arange(n_samples), n_samples=subsample_n, random_state=random_state+i)
        X_subsample = X[indices]

        # Effectuer le clustering sur le sous-échantillon
        subsample_clustering = clustering_method(n_clusters=n_clusters, random_state=random_state)
        subsample_labels = subsample_clustering.fit_predict(X_subsample)

        # Prédire les étiquettes pour l'ensemble complet des données
        # en utilisant le modèle entraîné sur le sous-échantillon
        try:
            # Si la méthode de clustering a une méthode predict
            full_predicted_labels = subsample_clustering.predict(X)
        except AttributeError:
            # Sinon, utiliser l'assignation au centroid le plus proche
            try:
                subsample_centroids = subsample_clustering.cluster_centers_
            except AttributeError:
                # Si la méthode de clustering ne fournit pas de centroids, les calculer manuellement
                subsample_centroids = np.zeros((n_clusters, n_features))
                for j in range(n_clusters):
                    cluster_points = X_subsample[subsample_labels == j]
                    if len(cluster_points) > 0:
                        subsample_centroids[j] = np.mean(cluster_points, axis=0)

            # Assigner chaque point au centroid le plus proche
            distances = pairwise_distances(X, subsample_centroids)
            full_predicted_labels = np.argmin(distances, axis=1)

        # Calculer les scores de reproductibilité
        rand_score = adjusted_rand_score(full_labels, full_predicted_labels)
        ami_score = adjusted_mutual_info_score(full_labels, full_predicted_labels)

        rand_scores.append(rand_score)
        ami_scores.append(ami_score)

        # Calculer la stabilité des centroids
        try:
            subsample_centroids = subsample_clustering.cluster_centers_
        except AttributeError:
            # Si la méthode de clustering ne fournit pas de centroids, les calculer manuellement
            subsample_centroids = np.zeros((n_clusters, n_features))
            for j in range(n_clusters):
                cluster_points = X_subsample[subsample_labels == j]
                if len(cluster_points) > 0:
                    subsample_centroids[j] = np.mean(cluster_points, axis=0)

        # Calculer la distance moyenne entre les centroids originaux et prédits
        centroid_stability = 1.0 - calculate_centroid_shift(full_centroids, subsample_centroids)
        centroid_stabilities.append(centroid_stability)

        # Calculer la stabilité des appartenances aux clusters
        membership_stability = calculate_label_consistency(full_labels, full_predicted_labels)
        membership_stabilities.append(membership_stability)

    # Calculer les statistiques
    mean_rand = np.mean(rand_scores)
    std_rand = np.std(rand_scores)
    mean_ami = np.mean(ami_scores)
    std_ami = np.std(ami_scores)
    mean_centroid_stability = np.mean(centroid_stabilities)
    std_centroid_stability = np.std(centroid_stabilities)
    mean_membership_stability = np.mean(membership_stabilities)
    std_membership_stability = np.std(membership_stabilities)

    # Calculer un score global de reproductibilité (plus élevé = meilleur)
    # Combinaison pondérée des différentes métriques
    global_reproducibility = (0.3 * mean_rand +
                             0.3 * mean_ami +
                             0.2 * mean_centroid_stability +
                             0.2 * mean_membership_stability)

    return {
        "rand_scores": {
            "mean": float(mean_rand),
            "std": float(std_rand),
            "values": [float(x) for x in rand_scores]
        },
        "ami_scores": {
            "mean": float(mean_ami),
            "std": float(std_ami),
            "values": [float(x) for x in ami_scores]
        },
        "centroid_stabilities": {
            "mean": float(mean_centroid_stability),
            "std": float(std_centroid_stability),
            "values": [float(x) for x in centroid_stabilities]
        },
        "membership_stabilities": {
            "mean": float(mean_membership_stability),
            "std": float(std_membership_stability),
            "values": [float(x) for x in membership_stabilities]
        },
        "global_reproducibility": float(global_reproducibility)
    }

def define_reproducibility_thresholds(data_dimensionality: int = 2,
                                    cluster_count: int = 5,
                                    data_sparsity: str = "medium") -> Dict[str, Dict[str, float]]:
    """
    Définit les seuils pour les métriques de reproductibilité des clusters.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, float]]: Seuils pour les métriques de reproductibilité
    """
    # Facteurs d'ajustement basés sur la dimensionnalité
    # Plus la dimensionnalité est élevée, plus la reproductibilité attendue est faible
    dim_factors = {
        1: 1.2,    # 1D: reproductibilité plus élevée attendue
        2: 1.0,    # 2D: référence
        3: 0.9,    # 3D: reproductibilité plus faible acceptable
        4: 0.85,   # 4D
        5: 0.8,    # 5D
        6: 0.75,   # 6D
        7: 0.7,    # 7D
        8: 0.65,   # 8D
        9: 0.6,    # 9D
        10: 0.55   # 10D et plus: reproductibilité beaucoup plus faible acceptable
    }

    # Facteurs d'ajustement basés sur le nombre de clusters
    # Plus il y a de clusters, plus la reproductibilité attendue est faible
    cluster_factors = {
        2: 1.2,    # 2 clusters: reproductibilité plus élevée attendue
        3: 1.1,    # 3 clusters
        4: 1.05,   # 4 clusters
        5: 1.0,    # 5 clusters: référence
        6: 0.95,   # 6 clusters
        7: 0.9,    # 7 clusters
        8: 0.85,   # 8 clusters
        9: 0.8,    # 9 clusters
        10: 0.75   # 10 clusters et plus: reproductibilité plus faible attendue
    }

    # Facteurs d'ajustement basés sur la densité des données
    # Plus les données sont denses, plus la reproductibilité attendue est élevée
    sparsity_factors = {
        "very_low": 0.7,    # Très faible densité: reproductibilité plus faible attendue
        "low": 0.85,        # Faible densité
        "medium": 1.0,      # Densité moyenne: référence
        "high": 1.1,        # Haute densité
        "very_high": 1.2    # Très haute densité: reproductibilité plus élevée attendue
    }

    # Appliquer les facteurs avec des limites
    dim_factor = dim_factors.get(min(data_dimensionality, 10),
                                dim_factors[10] * (data_dimensionality / 10))
    cluster_factor = cluster_factors.get(min(cluster_count, 10),
                                        cluster_factors[10])
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)

    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor * sparsity_factor

    # Définir les seuils pour le score de Rand ajusté
    rand_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour le score d'information mutuelle ajustée
    ami_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour la stabilité des centroids
    centroid_stability_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour la stabilité des appartenances aux clusters
    membership_stability_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Définir les seuils pour la reproductibilité globale
    global_reproducibility_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    return {
        "rand": rand_thresholds,
        "ami": ami_thresholds,
        "centroid_stability": centroid_stability_thresholds,
        "membership_stability": membership_stability_thresholds,
        "global_reproducibility": global_reproducibility_thresholds
    }

def evaluate_reproducibility_quality(reproducibility_metrics: Dict[str, Any],
                                   thresholds: Optional[Dict[str, Dict[str, float]]] = None,
                                   data_dimensionality: int = 2,
                                   cluster_count: int = 5,
                                   data_sparsity: str = "medium") -> Dict[str, str]:
    """
    Évalue la qualité de la reproductibilité des clusters.

    Args:
        reproducibility_metrics: Métriques de reproductibilité des clusters
        thresholds: Seuils pour les métriques de reproductibilité (optionnel)
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, str]: Évaluation de la qualité
    """
    # Si les seuils ne sont pas fournis, les définir
    if thresholds is None:
        thresholds = define_reproducibility_thresholds(
            data_dimensionality=data_dimensionality,
            cluster_count=cluster_count,
            data_sparsity=data_sparsity
        )

    # Évaluer la qualité basée sur le score de Rand ajusté
    mean_rand = reproducibility_metrics["rand_scores"]["mean"]
    rand_quality = "Insuffisante"

    for level, threshold in thresholds["rand"].items():
        if mean_rand >= threshold:
            if level == "excellent":
                rand_quality = "Excellente"
            elif level == "very_good":
                rand_quality = "Très bonne"
            elif level == "good":
                rand_quality = "Bonne"
            elif level == "acceptable":
                rand_quality = "Acceptable"
            elif level == "limited":
                rand_quality = "Limitée"
            break

    # Évaluer la qualité basée sur le score d'information mutuelle ajustée
    mean_ami = reproducibility_metrics["ami_scores"]["mean"]
    ami_quality = "Insuffisante"

    for level, threshold in thresholds["ami"].items():
        if mean_ami >= threshold:
            if level == "excellent":
                ami_quality = "Excellente"
            elif level == "very_good":
                ami_quality = "Très bonne"
            elif level == "good":
                ami_quality = "Bonne"
            elif level == "acceptable":
                ami_quality = "Acceptable"
            elif level == "limited":
                ami_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la stabilité des centroids
    mean_centroid_stability = reproducibility_metrics["centroid_stabilities"]["mean"]
    centroid_quality = "Insuffisante"

    for level, threshold in thresholds["centroid_stability"].items():
        if mean_centroid_stability >= threshold:
            if level == "excellent":
                centroid_quality = "Excellente"
            elif level == "very_good":
                centroid_quality = "Très bonne"
            elif level == "good":
                centroid_quality = "Bonne"
            elif level == "acceptable":
                centroid_quality = "Acceptable"
            elif level == "limited":
                centroid_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la stabilité des appartenances aux clusters
    mean_membership_stability = reproducibility_metrics["membership_stabilities"]["mean"]
    membership_quality = "Insuffisante"

    for level, threshold in thresholds["membership_stability"].items():
        if mean_membership_stability >= threshold:
            if level == "excellent":
                membership_quality = "Excellente"
            elif level == "very_good":
                membership_quality = "Très bonne"
            elif level == "good":
                membership_quality = "Bonne"
            elif level == "acceptable":
                membership_quality = "Acceptable"
            elif level == "limited":
                membership_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la reproductibilité globale
    global_reproducibility = reproducibility_metrics["global_reproducibility"]
    global_quality = "Insuffisante"

    for level, threshold in thresholds["global_reproducibility"].items():
        if global_reproducibility >= threshold:
            if level == "excellent":
                global_quality = "Excellente"
            elif level == "very_good":
                global_quality = "Très bonne"
            elif level == "good":
                global_quality = "Bonne"
            elif level == "acceptable":
                global_quality = "Acceptable"
            elif level == "limited":
                global_quality = "Limitée"
            break

    # Déterminer la qualité globale (prendre la moins bonne des cinq)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    rand_index = quality_levels.index(rand_quality)
    ami_index = quality_levels.index(ami_quality)
    centroid_index = quality_levels.index(centroid_quality)
    membership_index = quality_levels.index(membership_quality)
    global_index = quality_levels.index(global_quality)
    overall_index = max(rand_index, ami_index, centroid_index, membership_index, global_index)
    overall_quality = quality_levels[overall_index]

    return {
        "rand_quality": rand_quality,
        "ami_quality": ami_quality,
        "centroid_stability_quality": centroid_quality,
        "membership_stability_quality": membership_quality,
        "global_reproducibility_quality": global_quality,
        "overall_quality": overall_quality
    }

def establish_cluster_stability_quality_thresholds(data_dimensionality: int = 2,
                                                cluster_count: int = 5,
                                                data_sparsity: str = "medium") -> Dict[str, Dict[str, Dict[str, float]]]:
    """
    Établit les seuils de qualité pour la stabilité des clusters en combinant
    les critères de robustesse face aux variations de résolution et de reproductibilité.

    Args:
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, Dict[str, Dict[str, float]]]: Seuils de qualité pour la stabilité des clusters
    """
    # Obtenir les seuils pour la robustesse face aux variations de résolution
    resolution_robustness_thresholds = establish_resolution_robustness_criteria(
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Obtenir les seuils pour la reproductibilité des clusters
    reproducibility_thresholds = define_reproducibility_thresholds(
        data_dimensionality=data_dimensionality,
        cluster_count=cluster_count,
        data_sparsity=data_sparsity
    )

    # Combiner les seuils
    combined_thresholds: Dict[str, Dict[str, Dict[str, float]]] = {
        "resolution_robustness": resolution_robustness_thresholds,
        "reproducibility": reproducibility_thresholds,
        "global_stability": {}  # Sera rempli plus tard
    }

    # Définir les seuils pour la stabilité globale
    # Facteurs d'ajustement basés sur la dimensionnalité
    dim_factors = {
        1: 1.2,    # 1D: stabilité plus élevée attendue
        2: 1.0,    # 2D: référence
        3: 0.9,    # 3D: stabilité plus faible acceptable
        4: 0.85,   # 4D
        5: 0.8,    # 5D
        6: 0.75,   # 6D
        7: 0.7,    # 7D
        8: 0.65,   # 8D
        9: 0.6,    # 9D
        10: 0.55   # 10D et plus: stabilité beaucoup plus faible acceptable
    }

    # Facteurs d'ajustement basés sur le nombre de clusters
    cluster_factors = {
        2: 1.2,    # 2 clusters: stabilité plus élevée attendue
        3: 1.1,    # 3 clusters
        4: 1.05,   # 4 clusters
        5: 1.0,    # 5 clusters: référence
        6: 0.95,   # 6 clusters
        7: 0.9,    # 7 clusters
        8: 0.85,   # 8 clusters
        9: 0.8,    # 9 clusters
        10: 0.75   # 10 clusters et plus: stabilité plus faible attendue
    }

    # Facteurs d'ajustement basés sur la densité des données
    sparsity_factors = {
        "very_low": 0.7,    # Très faible densité: stabilité plus faible attendue
        "low": 0.85,        # Faible densité
        "medium": 1.0,      # Densité moyenne: référence
        "high": 1.1,        # Haute densité
        "very_high": 1.2    # Très haute densité: stabilité plus élevée attendue
    }

    # Appliquer les facteurs avec des limites
    dim_factor = dim_factors.get(min(data_dimensionality, 10),
                                dim_factors[10] * (data_dimensionality / 10))
    cluster_factor = cluster_factors.get(min(cluster_count, 10),
                                        cluster_factors[10])
    sparsity_factor = sparsity_factors.get(data_sparsity, 1.0)

    # Calculer le facteur global
    global_factor = dim_factor * cluster_factor * sparsity_factor

    # Définir les seuils pour la stabilité globale
    global_stability_thresholds = {
        "excellent": 0.9 * global_factor,
        "very_good": 0.8 * global_factor,
        "good": 0.7 * global_factor,
        "acceptable": 0.6 * global_factor,
        "limited": 0.5 * global_factor,
        "insufficient": 0.0
    }

    # Ajouter les seuils de stabilité globale
    combined_thresholds["global_stability"] = {"thresholds": global_stability_thresholds}

    return combined_thresholds

def evaluate_cluster_stability_quality(X: np.ndarray,
                                     labels: np.ndarray,
                                     clustering_method: Callable,
                                     n_clusters: int,
                                     thresholds: Optional[Dict[str, Dict[str, Dict[str, float]]]] = None,
                                     data_dimensionality: int = 2,
                                     data_sparsity: str = "medium",
                                     resolutions: Optional[List[float]] = None,
                                     n_resamplings: int = DEFAULT_N_RESAMPLINGS,
                                     n_iterations: int = DEFAULT_N_ITERATIONS,
                                     subsample_size: float = DEFAULT_SUBSAMPLE_SIZE,
                                     random_state: int = 42) -> Dict[str, Any]:
    """
    Évalue la qualité globale de la stabilité des clusters en combinant
    les métriques de robustesse face aux variations de résolution et de reproductibilité.

    Args:
        X: Données d'entrée (n_samples, n_features)
        labels: Étiquettes de cluster pour chaque échantillon (n_samples,)
        clustering_method: Méthode de clustering à utiliser (doit accepter n_clusters et random_state)
        n_clusters: Nombre de clusters
        thresholds: Seuils de qualité pour la stabilité des clusters (optionnel)
        data_dimensionality: Nombre de dimensions des données
        data_sparsity: Densité des données ("low", "medium", "high")
        resolutions: Liste des facteurs de résolution à tester (par défaut: [0.5, 0.75, 1.0, 1.25, 1.5])
        n_resamplings: Nombre de ré-échantillonnages pour chaque résolution
        n_iterations: Nombre d'itérations pour le sous-échantillonnage
        subsample_size: Taille du sous-échantillon (proportion des données)
        random_state: Graine aléatoire

    Returns:
        Dict[str, Any]: Évaluation de la qualité de la stabilité des clusters
    """
    # Si les seuils ne sont pas fournis, les établir
    if thresholds is None:
        thresholds = establish_cluster_stability_quality_thresholds(
            data_dimensionality=data_dimensionality,
            cluster_count=n_clusters,
            data_sparsity=data_sparsity
        )

    # Calculer les métriques de robustesse face aux variations de résolution
    robustness_metrics = calculate_resolution_robustness(
        X=X,
        labels=labels,
        n_clusters=n_clusters,
        resolutions=resolutions,
        n_resamplings=n_resamplings
    )

    # Évaluer la qualité de la robustesse face aux variations de résolution
    robustness_quality = evaluate_resolution_robustness_quality(
        robustness_metrics=robustness_metrics,
        criteria=thresholds["resolution_robustness"],
        data_dimensionality=data_dimensionality,
        cluster_count=n_clusters,
        data_sparsity=data_sparsity
    )

    # Calculer les métriques de reproductibilité des clusters
    reproducibility_metrics = calculate_cluster_reproducibility(
        X=X,
        clustering_method=clustering_method,
        n_clusters=n_clusters,
        n_iterations=n_iterations,
        subsample_size=subsample_size,
        random_state=random_state
    )

    # Évaluer la qualité de la reproductibilité des clusters
    reproducibility_quality = evaluate_reproducibility_quality(
        reproducibility_metrics=reproducibility_metrics,
        thresholds=thresholds["reproducibility"],
        data_dimensionality=data_dimensionality,
        cluster_count=n_clusters,
        data_sparsity=data_sparsity
    )

    # Calculer un score global de stabilité (plus élevé = meilleur)
    # Combinaison pondérée de la robustesse et de la reproductibilité
    global_stability_score = (0.5 * robustness_metrics["global_robustness"] +
                             0.5 * reproducibility_metrics["global_reproducibility"])

    # Évaluer la qualité de la stabilité globale
    global_stability_quality = "Insuffisante"

    for level, threshold in thresholds["global_stability"]["thresholds"].items():
        if global_stability_score >= threshold:
            if level == "excellent":
                global_stability_quality = "Excellente"
            elif level == "very_good":
                global_stability_quality = "Très bonne"
            elif level == "good":
                global_stability_quality = "Bonne"
            elif level == "acceptable":
                global_stability_quality = "Acceptable"
            elif level == "limited":
                global_stability_quality = "Limitée"
            break

    # Déterminer la qualité globale (prendre la moins bonne des trois)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    robustness_index = quality_levels.index(robustness_quality["overall_quality"])
    reproducibility_index = quality_levels.index(reproducibility_quality["overall_quality"])
    global_stability_index = quality_levels.index(global_stability_quality)
    overall_index = max(robustness_index, reproducibility_index, global_stability_index)
    overall_quality = quality_levels[overall_index]

    return {
        "robustness_metrics": robustness_metrics,
        "reproducibility_metrics": reproducibility_metrics,
        "robustness_quality": robustness_quality,
        "reproducibility_quality": reproducibility_quality,
        "global_stability_score": float(global_stability_score),
        "global_stability_quality": global_stability_quality,
        "overall_quality": overall_quality
    }

def evaluate_resolution_robustness_quality(robustness_metrics: Dict[str, Any],
                                         criteria: Optional[Dict[str, Dict[str, float]]] = None,
                                         data_dimensionality: int = 2,
                                         cluster_count: int = 5,
                                         data_sparsity: str = "medium") -> Dict[str, str]:
    """
    Évalue la qualité de la robustesse face aux variations de résolution.

    Args:
        robustness_metrics: Métriques de robustesse face aux variations de résolution
        criteria: Critères de robustesse (optionnel)
        data_dimensionality: Nombre de dimensions des données
        cluster_count: Nombre de clusters
        data_sparsity: Densité des données ("low", "medium", "high")

    Returns:
        Dict[str, str]: Évaluation de la qualité
    """
    # Si les critères ne sont pas fournis, les établir
    if criteria is None:
        criteria = establish_resolution_robustness_criteria(
            data_dimensionality=data_dimensionality,
            cluster_count=cluster_count,
            data_sparsity=data_sparsity
        )

    # Évaluer la qualité basée sur la stabilité
    mean_stability = robustness_metrics["mean_stability"]
    stability_quality = "Insuffisante"

    for level, threshold in criteria["stability"].items():
        if mean_stability >= threshold:
            if level == "excellent":
                stability_quality = "Excellente"
            elif level == "very_good":
                stability_quality = "Très bonne"
            elif level == "good":
                stability_quality = "Bonne"
            elif level == "acceptable":
                stability_quality = "Acceptable"
            elif level == "limited":
                stability_quality = "Limitée"
            break

    # Évaluer la qualité basée sur le déplacement des centroids
    mean_shift = robustness_metrics["mean_centroid_shift"]
    shift_quality = "Insuffisante"

    for level, threshold in criteria["centroid_shift"].items():
        if mean_shift <= threshold:
            if level == "excellent":
                shift_quality = "Excellente"
            elif level == "very_good":
                shift_quality = "Très bonne"
            elif level == "good":
                shift_quality = "Bonne"
            elif level == "acceptable":
                shift_quality = "Acceptable"
            elif level == "limited":
                shift_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la cohérence des étiquettes
    mean_consistency = robustness_metrics["mean_label_consistency"]
    consistency_quality = "Insuffisante"

    for level, threshold in criteria["label_consistency"].items():
        if mean_consistency >= threshold:
            if level == "excellent":
                consistency_quality = "Excellente"
            elif level == "very_good":
                consistency_quality = "Très bonne"
            elif level == "good":
                consistency_quality = "Bonne"
            elif level == "acceptable":
                consistency_quality = "Acceptable"
            elif level == "limited":
                consistency_quality = "Limitée"
            break

    # Évaluer la qualité basée sur la robustesse globale
    global_robustness = robustness_metrics["global_robustness"]
    global_quality = "Insuffisante"

    for level, threshold in criteria["global_robustness"].items():
        if global_robustness >= threshold:
            if level == "excellent":
                global_quality = "Excellente"
            elif level == "very_good":
                global_quality = "Très bonne"
            elif level == "good":
                global_quality = "Bonne"
            elif level == "acceptable":
                global_quality = "Acceptable"
            elif level == "limited":
                global_quality = "Limitée"
            break

    # Déterminer la qualité globale (prendre la moins bonne des quatre)
    quality_levels = ["Excellente", "Très bonne", "Bonne", "Acceptable", "Limitée", "Insuffisante"]
    stability_index = quality_levels.index(stability_quality)
    shift_index = quality_levels.index(shift_quality)
    consistency_index = quality_levels.index(consistency_quality)
    global_index = quality_levels.index(global_quality)
    overall_index = max(stability_index, shift_index, consistency_index, global_index)
    overall_quality = quality_levels[overall_index]

    return {
        "stability_quality": stability_quality,
        "centroid_shift_quality": shift_quality,
        "label_consistency_quality": consistency_quality,
        "global_robustness_quality": global_quality,
        "overall_quality": overall_quality
    }
