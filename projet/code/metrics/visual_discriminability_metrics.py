#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques de discriminabilité visuelle
pour évaluer la fidélité perceptuelle des représentations de distributions.

Ce module fournit des fonctions pour quantifier la facilité avec laquelle
un utilisateur peut distinguer visuellement différentes parties d'un histogramme.
"""

import numpy as np
import scipy.stats
import scipy.ndimage
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Constantes pour les paramètres par défaut
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter les divisions par zéro
DEFAULT_CONTRAST_THRESHOLD = 0.05  # Seuil de contraste minimal perceptible


def calculate_local_contrast(histogram: np.ndarray) -> np.ndarray:
    """
    Calcule le contraste local pour chaque bin de l'histogramme.

    Le contraste local est une mesure de la différence relative entre un bin
    et ses voisins, ce qui affecte la discriminabilité visuelle.

    Args:
        histogram: Valeurs de l'histogramme

    Returns:
        np.ndarray: Contraste local pour chaque bin
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return np.zeros_like(histogram)

    # Calculer le contraste local (différence relative avec les voisins)
    padded_hist = np.pad(normalized_hist, 1, mode='edge')
    left_neighbors = padded_hist[:-2]
    right_neighbors = padded_hist[2:]
    center_values = normalized_hist

    # Calculer la différence relative moyenne avec les voisins
    avg_neighbors = (left_neighbors + right_neighbors) / 2
    local_contrast = np.abs(center_values - avg_neighbors) / (avg_neighbors + DEFAULT_EPSILON)

    return local_contrast


def calculate_discriminability_score(local_contrast: np.ndarray,
                                   threshold: float = DEFAULT_CONTRAST_THRESHOLD) -> float:
    """
    Calcule un score de discriminabilité visuelle basé sur le contraste local.

    Args:
        local_contrast: Contraste local pour chaque bin
        threshold: Seuil de contraste minimal perceptible

    Returns:
        float: Score de discriminabilité (0-1)
    """
    # Calculer la proportion de bins avec un contraste suffisant
    discriminable_bins = np.sum(local_contrast > threshold)
    total_bins = len(local_contrast)

    if total_bins > 0:
        # Pondérer par l'amplitude moyenne du contraste au-dessus du seuil
        contrast_above_threshold = local_contrast[local_contrast > threshold]
        if len(contrast_above_threshold) > 0:
            mean_contrast = np.mean(contrast_above_threshold)
            # Normaliser le contraste moyen (saturation à 1.0)
            normalized_contrast = min(1.0, mean_contrast / 0.5)

            # Combiner la proportion et l'amplitude
            discriminability = (discriminable_bins / total_bins) * normalized_contrast
        else:
            discriminability = 0.0
    else:
        discriminability = 0.0

    return float(discriminability)


def evaluate_discriminability_quality(score: float) -> str:
    """
    Évalue la qualité de discriminabilité visuelle en fonction du score.

    Args:
        score: Score de discriminabilité (0-1)

    Returns:
        str: Niveau de qualité
    """
    if score >= 0.8:
        return "Excellente"
    elif score >= 0.6:
        return "Très bonne"
    elif score >= 0.4:
        return "Bonne"
    elif score >= 0.2:
        return "Acceptable"
    elif score >= 0.1:
        return "Limitée"
    else:
        return "Insuffisante"


def calculate_region_discriminability(histogram: np.ndarray,
                                    region_indices: List[Tuple[int, int]]) -> Dict[str, Any]:
    """
    Calcule la discriminabilité visuelle entre différentes régions d'un histogramme.

    Args:
        histogram: Valeurs de l'histogramme
        region_indices: Liste de tuples (début, fin) définissant les régions

    Returns:
        Dict[str, Any]: Résultats de discriminabilité entre régions
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return {
            "region_means": [],
            "region_contrasts": [],
            "inter_region_contrasts": [],
            "discriminability_score": 0.0,
            "quality": "Insuffisante"
        }

    # Calculer les statistiques pour chaque région
    region_means = []
    region_contrasts = []

    for start, end in region_indices:
        # Vérifier les limites
        start = max(0, min(start, len(normalized_hist) - 1))
        end = max(start + 1, min(end, len(normalized_hist)))

        # Extraire la région
        region = normalized_hist[start:end]

        # Calculer la moyenne de la région
        region_mean = np.mean(region)
        region_means.append(region_mean)

        # Calculer le contraste local moyen dans la région
        local_contrast = calculate_local_contrast(region)
        region_contrast = np.mean(local_contrast)
        region_contrasts.append(region_contrast)

    # Calculer le contraste entre les régions
    inter_region_contrasts = []

    for i in range(len(region_means)):
        for j in range(i + 1, len(region_means)):
            # Calculer le contraste entre les moyennes des régions
            contrast = np.abs(region_means[i] - region_means[j]) / (max(region_means[i], region_means[j]) + DEFAULT_EPSILON)
            inter_region_contrasts.append(contrast)

    # Calculer le score global de discriminabilité
    if len(inter_region_contrasts) > 0:
        # Pondérer le contraste inter-régions et le contraste intra-région
        inter_region_score = np.mean(inter_region_contrasts)
        intra_region_score = np.mean(region_contrasts)

        # Combiner les scores (le contraste inter-régions est plus important)
        discriminability_score = 0.7 * inter_region_score + 0.3 * intra_region_score
    else:
        discriminability_score = 0.0

    # Évaluer la qualité
    quality = evaluate_discriminability_quality(float(discriminability_score))

    return {
        "region_means": region_means,
        "region_contrasts": region_contrasts,
        "inter_region_contrasts": inter_region_contrasts,
        "discriminability_score": float(discriminability_score),
        "quality": quality
    }


def evaluate_histogram_discriminability(bin_counts: np.ndarray,
                                      threshold: float = DEFAULT_CONTRAST_THRESHOLD) -> Dict[str, Any]:
    """
    Évalue la discriminabilité visuelle d'un histogramme.

    Args:
        bin_counts: Valeurs de l'histogramme
        threshold: Seuil de contraste minimal perceptible

    Returns:
        Dict[str, Any]: Résultats de l'évaluation
    """
    # Calculer le contraste local
    local_contrast = calculate_local_contrast(bin_counts)

    # Calculer le score de discriminabilité
    discriminability_score = calculate_discriminability_score(local_contrast, threshold)

    # Identifier les régions significatives (modes)
    from scipy.signal import find_peaks
    peaks, _ = find_peaks(bin_counts, prominence=0.1 * np.max(bin_counts))

    # Définir les régions autour des pics
    regions = []
    for peak in peaks:
        # Définir une région autour du pic (±10% de la largeur totale)
        width = max(1, int(0.1 * len(bin_counts)))
        start = max(0, peak - width)
        end = min(len(bin_counts), peak + width + 1)
        regions.append((start, end))

    # Si aucun pic n'est détecté, diviser l'histogramme en quartiles
    if len(regions) == 0:
        n_bins = len(bin_counts)
        quartiles = [int(n_bins * q) for q in [0, 0.25, 0.5, 0.75, 1.0]]
        regions = [(quartiles[i], quartiles[i+1]) for i in range(4)]

    # Calculer la discriminabilité entre les régions
    region_discriminability = calculate_region_discriminability(bin_counts, regions)

    # Évaluer la qualité
    quality = evaluate_discriminability_quality(discriminability_score)

    return {
        "local_contrast": local_contrast,
        "discriminability_score": discriminability_score,
        "region_discriminability": region_discriminability,
        "quality": quality
    }


def compare_binning_strategies_discriminability(data: np.ndarray,
                                              strategies: Optional[List[str]] = None,
                                              num_bins: int = 20) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de discriminabilité visuelle.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes

    Returns:
        Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    results = {}

    for strategy in strategies:
        # Générer l'histogramme selon la stratégie
        if strategy == "uniform":
            bin_edges = np.linspace(min(data), max(data), num_bins + 1)
        elif strategy == "logarithmic":
            min_value = max(min(data), 1e-10)  # Éviter les valeurs négatives ou nulles
            bin_edges = np.logspace(np.log10(min_value), np.log10(max(data)), num_bins + 1)
        elif strategy == "quantile":
            bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
        else:
            raise ValueError(f"Stratégie de binning inconnue: {strategy}")

        bin_counts, _ = np.histogram(data, bins=bin_edges)

        # Évaluer la discriminabilité visuelle
        evaluation = evaluate_histogram_discriminability(bin_counts)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "discriminability_score": evaluation["discriminability_score"],
            "region_discriminability": evaluation["region_discriminability"]["discriminability_score"],
            "quality": evaluation["quality"]
        }

    return results


def find_optimal_binning_strategy_discriminability(data: np.ndarray,
                                                 strategies: Optional[List[str]] = None,
                                                 num_bins_range: Optional[List[int]] = None) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de discriminabilité visuelle.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins_range: Liste des nombres de bins à tester

    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    if num_bins_range is None:
        num_bins_range = [5, 10, 20, 50, 100]

    best_score = -1
    best_strategy = None
    best_num_bins = None
    best_quality = None

    results = {}

    for strategy in strategies:
        strategy_results = {}

        for num_bins in num_bins_range:
            # Générer l'histogramme selon la stratégie
            if strategy == "uniform":
                bin_edges = np.linspace(min(data), max(data), num_bins + 1)
            elif strategy == "logarithmic":
                min_value = max(min(data), 1e-10)  # Éviter les valeurs négatives ou nulles
                bin_edges = np.logspace(np.log10(min_value), np.log10(max(data)), num_bins + 1)
            elif strategy == "quantile":
                bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
            else:
                raise ValueError(f"Stratégie de binning inconnue: {strategy}")

            bin_counts, _ = np.histogram(data, bins=bin_edges)

            # Évaluer la discriminabilité visuelle
            evaluation = evaluate_histogram_discriminability(bin_counts)

            # Calculer un score combiné (discriminabilité globale et entre régions)
            combined_score = 0.5 * evaluation["discriminability_score"] + 0.5 * evaluation["region_discriminability"]["discriminability_score"]

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "discriminability_score": evaluation["discriminability_score"],
                "region_discriminability": evaluation["region_discriminability"]["discriminability_score"],
                "combined_score": combined_score,
                "quality": evaluation["quality"]
            }

            # Mettre à jour la meilleure stratégie
            if combined_score > best_score:
                best_score = combined_score
                best_strategy = strategy
                best_num_bins = num_bins
                best_quality = evaluation["quality"]

        results[strategy] = strategy_results

    return {
        "best_strategy": best_strategy,
        "best_num_bins": best_num_bins,
        "best_score": best_score,
        "best_quality": best_quality,
        "results": results
    }


if __name__ == "__main__":
    # Exemple d'utilisation
    import matplotlib.pyplot as plt

    # Générer des données de test
    np.random.seed(42)

    # Différentes distributions pour les tests
    distributions = {
        "normal": np.random.normal(loc=100, scale=15, size=1000),
        "asymmetric": np.random.gamma(shape=3, scale=10, size=1000),
        "leptokurtic": np.random.standard_t(df=3, size=1000) * 15 + 100,
        "multimodal": np.concatenate([
            np.random.normal(loc=70, scale=10, size=500),
            np.random.normal(loc=130, scale=15, size=500)
        ])
    }

    # Tester les métriques de discriminabilité visuelle
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Créer un histogramme
        bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
        bin_counts, _ = np.histogram(data, bins=bin_edges)

        # Calculer le contraste local
        local_contrast = calculate_local_contrast(bin_counts)

        # Calculer le score de discriminabilité
        discriminability_score = calculate_discriminability_score(local_contrast)
        quality = evaluate_discriminability_quality(discriminability_score)

        print(f"Score de discriminabilité: {discriminability_score:.4f}")
        print(f"Qualité: {quality}")

        # Comparer différentes stratégies de binning
        print("\nComparaison des stratégies de binning:")
        results = compare_binning_strategies_discriminability(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Score de discriminabilité: {result['discriminability_score']:.4f}")
            print(f"Score de discriminabilité entre régions: {result['region_discriminability']:.4f}")
            print(f"Qualité: {result['quality']}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_discriminability(data, num_bins_range=[5, 10, 20, 50])

        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Score optimal: {optimization['best_score']:.4f}")
        print(f"Qualité: {optimization['best_quality']}")
