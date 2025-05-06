#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques basées sur la saillance visuelle
pour évaluer la fidélité perceptuelle des représentations de distributions.

Ce module fournit des fonctions pour quantifier comment les caractéristiques
importantes d'une distribution sont visuellement perceptibles dans sa représentation
par histogramme ou autre visualisation.
"""

import numpy as np
import scipy.stats
import scipy.ndimage
import scipy.signal
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Constantes pour les paramètres par défaut
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter les divisions par zéro
DEFAULT_KERNEL_SIZE = 5  # Taille du noyau pour les filtres de saillance


def calculate_contrast_map(histogram: np.ndarray, kernel_size: int = DEFAULT_KERNEL_SIZE) -> np.ndarray:
    """
    Calcule une carte de contraste pour un histogramme.

    Le contraste est une mesure de la différence locale entre les valeurs de l'histogramme,
    qui est un facteur important de saillance visuelle.

    Args:
        histogram: Valeurs de l'histogramme
        kernel_size: Taille du noyau pour le calcul du contraste local

    Returns:
        np.ndarray: Carte de contraste
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return np.zeros_like(histogram)

    # Calculer le contraste local en utilisant un filtre de différence gaussienne (DoG)
    # qui est une approximation de la détection de contraste dans le système visuel humain
    sigma1 = 0.5
    sigma2 = 1.0

    # Créer les noyaux gaussiens
    x = np.linspace(-(kernel_size//2), kernel_size//2, kernel_size)
    gaussian1 = np.exp(-0.5 * (x**2) / sigma1**2)
    gaussian1 = gaussian1 / np.sum(gaussian1)

    gaussian2 = np.exp(-0.5 * (x**2) / sigma2**2)
    gaussian2 = gaussian2 / np.sum(gaussian2)

    # Appliquer les filtres gaussiens
    filtered1 = np.convolve(normalized_hist, gaussian1, mode='same')
    filtered2 = np.convolve(normalized_hist, gaussian2, mode='same')

    # Calculer la différence (DoG)
    contrast_map = np.abs(filtered1 - filtered2)

    return contrast_map


def calculate_edge_map(histogram: np.ndarray) -> np.ndarray:
    """
    Calcule une carte des bords pour un histogramme.

    Les bords (changements brusques) sont des éléments visuellement saillants.

    Args:
        histogram: Valeurs de l'histogramme

    Returns:
        np.ndarray: Carte des bords
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return np.zeros_like(histogram)

    # Calculer le gradient (première dérivée)
    gradient = np.gradient(normalized_hist)

    # Calculer la magnitude du gradient
    edge_map = np.abs(gradient)

    return edge_map


def calculate_curvature_map(histogram: np.ndarray) -> np.ndarray:
    """
    Calcule une carte de courbure pour un histogramme.

    La courbure (changements de direction) est un élément visuellement saillant.

    Args:
        histogram: Valeurs de l'histogramme

    Returns:
        np.ndarray: Carte de courbure
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return np.zeros_like(histogram)

    # Calculer la dérivée seconde (approximation de la courbure)
    curvature = np.gradient(np.gradient(normalized_hist))

    # Prendre la valeur absolue pour mesurer l'ampleur de la courbure
    curvature_map = np.abs(curvature)

    return curvature_map


def calculate_peak_map(histogram: np.ndarray, prominence_threshold: float = 0.1) -> np.ndarray:
    """
    Calcule une carte des pics pour un histogramme.

    Les pics sont des éléments visuellement saillants qui attirent l'attention.

    Args:
        histogram: Valeurs de l'histogramme
        prominence_threshold: Seuil de proéminence pour considérer un pic

    Returns:
        np.ndarray: Carte des pics
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return np.zeros_like(histogram)

    # Trouver les pics
    peaks, properties = scipy.signal.find_peaks(normalized_hist, prominence=prominence_threshold)

    # Créer une carte des pics
    peak_map = np.zeros_like(normalized_hist)

    # Attribuer la proéminence comme valeur de saillance pour chaque pic
    if len(peaks) > 0:
        peak_map[peaks] = properties['prominences']

    return peak_map


def calculate_saliency_map(histogram: np.ndarray,
                          weights: Optional[Dict[str, float]] = None) -> np.ndarray:
    """
    Calcule une carte de saillance globale pour un histogramme en combinant
    différentes caractéristiques visuellement saillantes.

    Args:
        histogram: Valeurs de l'histogramme
        weights: Poids pour les différentes composantes de saillance

    Returns:
        np.ndarray: Carte de saillance globale
    """
    # Définir les poids par défaut si non spécifiés
    if weights is None:
        weights = {
            "contrast": 0.25,
            "edge": 0.25,
            "curvature": 0.25,
            "peak": 0.25
        }

    # Calculer les différentes cartes de caractéristiques
    contrast_map = calculate_contrast_map(histogram)
    edge_map = calculate_edge_map(histogram)
    curvature_map = calculate_curvature_map(histogram)
    peak_map = calculate_peak_map(histogram)

    # Normaliser chaque carte
    contrast_map = contrast_map / (np.max(contrast_map) + DEFAULT_EPSILON)
    edge_map = edge_map / (np.max(edge_map) + DEFAULT_EPSILON)
    curvature_map = curvature_map / (np.max(curvature_map) + DEFAULT_EPSILON)
    peak_map = peak_map / (np.max(peak_map) + DEFAULT_EPSILON)

    # Combiner les cartes avec les poids spécifiés
    saliency_map = (
        weights["contrast"] * contrast_map +
        weights["edge"] * edge_map +
        weights["curvature"] * curvature_map +
        weights["peak"] * peak_map
    )

    # Normaliser la carte de saillance finale
    if np.max(saliency_map) > 0:
        saliency_map = saliency_map / np.max(saliency_map)

    return saliency_map


def calculate_saliency_score(histogram: np.ndarray,
                            weights: Optional[Dict[str, float]] = None) -> float:
    """
    Calcule un score global de saillance pour un histogramme.

    Args:
        histogram: Valeurs de l'histogramme
        weights: Poids pour les différentes composantes de saillance

    Returns:
        float: Score de saillance (0-1)
    """
    # Calculer la carte de saillance
    saliency_map = calculate_saliency_map(histogram, weights)

    # Calculer le score comme la moyenne de la carte de saillance
    score = np.mean(saliency_map)

    return score


def evaluate_saliency_quality(score: float) -> str:
    """
    Évalue la qualité de saillance visuelle en fonction du score.

    Args:
        score: Score de saillance (0-1)

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


def calculate_saliency_preservation(original_histogram: np.ndarray,
                                  simplified_histogram: np.ndarray,
                                  weights: Optional[Dict[str, float]] = None) -> float:
    """
    Calcule le taux de préservation de la saillance visuelle entre un histogramme
    original et sa version simplifiée.

    Args:
        original_histogram: Histogramme original
        simplified_histogram: Histogramme simplifié
        weights: Poids pour les différentes composantes de saillance

    Returns:
        float: Taux de préservation de la saillance (0-1)
    """
    # Calculer les cartes de saillance
    original_saliency = calculate_saliency_map(original_histogram, weights)
    simplified_saliency = calculate_saliency_map(simplified_histogram, weights)

    # Redimensionner la carte simplifiée si nécessaire
    if len(original_saliency) != len(simplified_saliency):
        # Interpolation pour avoir la même taille
        x_simplified = np.linspace(0, 1, len(simplified_saliency))
        x_original = np.linspace(0, 1, len(original_saliency))
        simplified_saliency = np.interp(x_original, x_simplified, simplified_saliency)

    # Calculer la corrélation entre les cartes de saillance
    if np.std(original_saliency) > 0 and np.std(simplified_saliency) > 0:
        correlation = np.corrcoef(original_saliency, simplified_saliency)[0, 1]
        # Convertir la corrélation en score de préservation (0-1)
        preservation_score = (correlation + 1) / 2  # Transformer de [-1,1] à [0,1]
    else:
        preservation_score = 0.0

    return preservation_score


def compare_histograms_saliency(original_histogram: np.ndarray,
                              simplified_histogram: np.ndarray,
                              weights: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
    """
    Compare deux histogrammes en termes de saillance visuelle.

    Args:
        original_histogram: Histogramme original
        simplified_histogram: Histogramme simplifié
        weights: Poids pour les différentes composantes de saillance

    Returns:
        Dict[str, Any]: Résultats de la comparaison
    """
    # Calculer les scores de saillance individuels
    original_score = calculate_saliency_score(original_histogram, weights)
    simplified_score = calculate_saliency_score(simplified_histogram, weights)

    # Calculer le taux de préservation de la saillance
    preservation_score = calculate_saliency_preservation(original_histogram, simplified_histogram, weights)

    # Évaluer la qualité de préservation
    quality = evaluate_saliency_quality(preservation_score)

    # Calculer le ratio de saillance
    if original_score > 0:
        saliency_ratio = simplified_score / original_score
    else:
        saliency_ratio = 0.0

    return {
        "original_saliency": original_score,
        "simplified_saliency": simplified_score,
        "preservation_score": preservation_score,
        "saliency_ratio": saliency_ratio,
        "quality": quality
    }


def compare_binning_strategies_saliency(data: np.ndarray,
                                      strategies: Optional[List[str]] = None,
                                      num_bins: int = 20,
                                      weights: Optional[Dict[str, float]] = None) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de saillance visuelle.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        weights: Poids pour les différentes composantes de saillance

    Returns:
        Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    # Créer un histogramme de référence avec un grand nombre de bins
    reference_bins = min(len(data) // 10, 1000)  # Limiter à 1000 bins maximum
    reference_hist, _ = np.histogram(data, bins=reference_bins)

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

        # Comparer avec l'histogramme de référence
        comparison = compare_histograms_saliency(reference_hist, bin_counts, weights)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "saliency_score": comparison["simplified_saliency"],
            "preservation_score": comparison["preservation_score"],
            "saliency_ratio": comparison["saliency_ratio"],
            "quality": comparison["quality"]
        }

    return results


def find_optimal_binning_strategy_saliency(data: np.ndarray,
                                         strategies: Optional[List[str]] = None,
                                         num_bins_range: Optional[List[int]] = None,
                                         weights: Optional[Dict[str, float]] = None) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de saillance visuelle.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins_range: Liste des nombres de bins à tester
        weights: Poids pour les différentes composantes de saillance

    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    if num_bins_range is None:
        num_bins_range = [5, 10, 20, 50, 100]

    # Créer un histogramme de référence avec un grand nombre de bins
    reference_bins = min(len(data) // 10, 1000)  # Limiter à 1000 bins maximum
    reference_hist, _ = np.histogram(data, bins=reference_bins)

    best_score = -1
    best_strategy = None
    best_num_bins = None
    best_metrics = None

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

            # Comparer avec l'histogramme de référence
            comparison = compare_histograms_saliency(reference_hist, bin_counts, weights)

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "saliency_score": comparison["simplified_saliency"],
                "preservation_score": comparison["preservation_score"],
                "saliency_ratio": comparison["saliency_ratio"],
                "quality": comparison["quality"]
            }

            # Mettre à jour la meilleure stratégie
            if comparison["preservation_score"] > best_score:
                best_score = comparison["preservation_score"]
                best_strategy = strategy
                best_num_bins = num_bins
                best_metrics = comparison

        results[strategy] = strategy_results

    return {
        "best_strategy": best_strategy,
        "best_num_bins": best_num_bins,
        "best_score": best_score,
        "best_quality": best_metrics["quality"] if best_metrics else "Insuffisante",
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

    # Tester les métriques basées sur la saillance visuelle
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Créer un histogramme avec différents nombres de bins
        hist_fine, _ = np.histogram(data, bins=100)
        hist_medium, _ = np.histogram(data, bins=20)
        hist_coarse, _ = np.histogram(data, bins=5)

        # Calculer les cartes de saillance
        saliency_fine = calculate_saliency_map(hist_fine)
        saliency_medium = calculate_saliency_map(hist_medium)
        saliency_coarse = calculate_saliency_map(hist_coarse)

        # Calculer les scores de saillance
        score_fine = calculate_saliency_score(hist_fine)
        score_medium = calculate_saliency_score(hist_medium)
        score_coarse = calculate_saliency_score(hist_coarse)

        print(f"Score de saillance (100 bins): {score_fine:.4f}")
        print(f"Score de saillance (20 bins): {score_medium:.4f}")
        print(f"Score de saillance (5 bins): {score_coarse:.4f}")

        # Comparer les histogrammes
        comparison_medium = compare_histograms_saliency(hist_fine, hist_medium)
        comparison_coarse = compare_histograms_saliency(hist_fine, hist_coarse)

        print(f"\nComparaison (20 bins vs 100 bins):")
        print(f"  Score de préservation: {comparison_medium['preservation_score']:.4f}")
        print(f"  Qualité: {comparison_medium['quality']}")

        print(f"\nComparaison (5 bins vs 100 bins):")
        print(f"  Score de préservation: {comparison_coarse['preservation_score']:.4f}")
        print(f"  Qualité: {comparison_coarse['quality']}")

        # Comparer différentes stratégies de binning
        print("\nComparaison des stratégies de binning:")
        results = compare_binning_strategies_saliency(data)

        for strategy, result in results.items():
            print(f"  Stratégie {strategy}:")
            print(f"    Score de saillance: {result['saliency_score']:.4f}")
            print(f"    Score de préservation: {result['preservation_score']:.4f}")
            print(f"    Qualité: {result['quality']}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_saliency(data, num_bins_range=[5, 10, 20, 50])

        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Score optimal: {optimization['best_score']:.4f}")
        print(f"Qualité: {optimization['best_quality']}")

        # Visualiser les résultats pour la distribution multimodale
        if dist_name == "multimodal":
            plt.figure(figsize=(15, 10))

            # Tracer l'histogramme fin et sa carte de saillance
            plt.subplot(3, 2, 1)
            plt.title("Histogramme fin (100 bins)")
            plt.bar(range(len(hist_fine)), hist_fine, width=1.0)
            plt.grid(True, alpha=0.3)

            plt.subplot(3, 2, 2)
            plt.title(f"Carte de saillance (score: {score_fine:.4f})")
            plt.bar(range(len(saliency_fine)), saliency_fine, width=1.0, color='red')
            plt.grid(True, alpha=0.3)

            # Tracer l'histogramme moyen et sa carte de saillance
            plt.subplot(3, 2, 3)
            plt.title("Histogramme moyen (20 bins)")
            plt.bar(range(len(hist_medium)), hist_medium, width=1.0)
            plt.grid(True, alpha=0.3)

            plt.subplot(3, 2, 4)
            plt.title(f"Carte de saillance (score: {score_medium:.4f})")
            plt.bar(range(len(saliency_medium)), saliency_medium, width=1.0, color='red')
            plt.grid(True, alpha=0.3)

            # Tracer l'histogramme grossier et sa carte de saillance
            plt.subplot(3, 2, 5)
            plt.title("Histogramme grossier (5 bins)")
            plt.bar(range(len(hist_coarse)), hist_coarse, width=1.0)
            plt.grid(True, alpha=0.3)

            plt.subplot(3, 2, 6)
            plt.title(f"Carte de saillance (score: {score_coarse:.4f})")
            plt.bar(range(len(saliency_coarse)), saliency_coarse, width=1.0, color='red')
            plt.grid(True, alpha=0.3)

            plt.tight_layout()
            plt.savefig("visual_saliency_comparison.png")
            print("Figure sauvegardée sous 'visual_saliency_comparison.png'")
