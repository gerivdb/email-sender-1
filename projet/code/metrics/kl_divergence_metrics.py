#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques basées sur la divergence de Kullback-Leibler (KL)
pour évaluer la fidélité informationnelle des représentations de distributions.

Ce module étend les fonctionnalités du module entropy_based_metrics.py avec des
métriques spécialisées basées sur la divergence KL.
"""

import numpy as np
import scipy.stats
import scipy.integrate
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Importer les fonctions de base du module d'entropie
from entropy_based_metrics import (
    calculate_kl_divergence,
    estimate_continuous_kl_divergence,
    DEFAULT_EPSILON,
    DEFAULT_KDE_BANDWIDTH
)


def calculate_symmetric_kl_divergence(p: np.ndarray, q: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule la divergence KL symétrique entre deux distributions discrètes.

    Args:
        p: Première distribution (doit sommer à 1)
        q: Deuxième distribution (doit sommer à 1)
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Divergence KL symétrique en unités correspondant à la base
    """
    # Calculer KL(P||Q) et KL(Q||P)
    kl_pq = calculate_kl_divergence(p, q, base)
    kl_qp = calculate_kl_divergence(q, p, base)

    # Retourner la moyenne
    return 0.5 * (kl_pq + kl_qp)


def calculate_kl_divergence_score(p: np.ndarray, q: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule un score de similarité basé sur la divergence KL, normalisé entre 0 et 1.

    Args:
        p: Distribution de référence (doit sommer à 1)
        q: Distribution approximative (doit sommer à 1)
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Score de similarité (0-1), où 1 indique des distributions identiques
    """
    # Calculer la divergence KL
    kl_div = calculate_kl_divergence(p, q, base)

    # Convertir en score de similarité (décroissance exponentielle)
    score = np.exp(-kl_div)

    return score


def calculate_continuous_kl_divergence_score(p_data: np.ndarray,
                                           q_data: np.ndarray,
                                           kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                           base: float = 2.0) -> float:
    """
    Calcule un score de similarité basé sur la divergence KL pour des distributions continues.

    Args:
        p_data: Données de la distribution de référence
        q_data: Données de la distribution approximative
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Score de similarité (0-1), où 1 indique des distributions identiques
    """
    # Estimer la divergence KL
    kl_div = estimate_continuous_kl_divergence(p_data, q_data, kde_bandwidth, base)

    # Convertir en score de similarité (décroissance exponentielle)
    if np.isfinite(kl_div):
        score = np.exp(-kl_div)
    else:
        score = 0.0

    return score


def evaluate_kl_divergence_quality(score: float) -> str:
    """
    Évalue la qualité de la représentation en fonction du score de divergence KL.

    Args:
        score: Score de similarité basé sur la divergence KL (0-1)

    Returns:
        str: Niveau de qualité
    """
    if score >= 0.95:
        return "Excellente"
    elif score >= 0.90:
        return "Très bonne"
    elif score >= 0.80:
        return "Bonne"
    elif score >= 0.70:
        return "Acceptable"
    elif score >= 0.60:
        return "Limitée"
    else:
        return "Insuffisante"


def compare_histograms_kl(hist1_counts: np.ndarray,
                         hist2_counts: np.ndarray,
                         base: float = 2.0) -> Dict[str, Any]:
    """
    Compare deux histogrammes en utilisant la divergence KL.

    Args:
        hist1_counts: Comptages du premier histogramme
        hist2_counts: Comptages du deuxième histogramme
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        Dict[str, Any]: Résultats de la comparaison
    """
    # Convertir les comptages en probabilités
    total1 = np.sum(hist1_counts)
    total2 = np.sum(hist2_counts)

    if total1 == 0 or total2 == 0:
        return {
            "kl_div_1_2": float('inf'),
            "kl_div_2_1": float('inf'),
            "symmetric_kl": float('inf'),
            "similarity_score": 0.0,
            "quality": "Insuffisante"
        }

    p1 = hist1_counts / total1
    p2 = hist2_counts / total2

    # Calculer les divergences KL dans les deux sens
    kl_div_1_2 = calculate_kl_divergence(p1, p2, base)
    kl_div_2_1 = calculate_kl_divergence(p2, p1, base)

    # Calculer la divergence KL symétrique
    symmetric_kl = 0.5 * (kl_div_1_2 + kl_div_2_1)

    # Calculer le score de similarité
    similarity_score = np.exp(-symmetric_kl)

    # Évaluer la qualité
    quality = evaluate_kl_divergence_quality(similarity_score)

    return {
        "kl_div_1_2": kl_div_1_2,
        "kl_div_2_1": kl_div_2_1,
        "symmetric_kl": symmetric_kl,
        "similarity_score": similarity_score,
        "quality": quality
    }


def evaluate_histogram_fidelity(original_data: np.ndarray,
                               bin_edges: np.ndarray,
                               bin_counts: np.ndarray,
                               base: float = 2.0) -> Dict[str, Any]:
    """
    Évalue la fidélité d'un histogramme par rapport aux données originales
    en utilisant des métriques basées sur la divergence KL.

    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        Dict[str, Any]: Métriques de fidélité
    """
    # Reconstruire les données à partir de l'histogramme
    reconstructed_data = []
    for i in range(len(bin_counts)):
        bin_count = bin_counts[i]
        bin_start = bin_edges[i]
        bin_end = bin_edges[i + 1]

        # Répartir uniformément les points dans le bin
        if bin_count > 0:
            step = (bin_end - bin_start) / bin_count
            bin_data = [bin_start + step * (j + 0.5) for j in range(bin_count)]
            reconstructed_data.extend(bin_data)

    reconstructed_data = np.array(reconstructed_data)

    if len(reconstructed_data) == 0:
        return {
            "kl_divergence": float('inf'),
            "similarity_score": 0.0,
            "quality": "Insuffisante"
        }

    # Estimer la divergence KL entre les distributions originale et reconstruite
    kl_div = estimate_continuous_kl_divergence(original_data, reconstructed_data, base=base)

    # Calculer le score de similarité
    if np.isfinite(kl_div):
        similarity_score = np.exp(-kl_div)
    else:
        similarity_score = 0.0

    # Évaluer la qualité
    quality = evaluate_kl_divergence_quality(similarity_score)

    return {
        "kl_divergence": kl_div,
        "similarity_score": similarity_score,
        "quality": quality
    }


def compare_binning_strategies_kl(data: np.ndarray,
                                strategies: Optional[List[str]] = None,
                                num_bins: int = 20,
                                base: float = 2.0) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de fidélité informationnelle
    en utilisant des métriques basées sur la divergence KL.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

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

        # Évaluer la fidélité de l'histogramme
        fidelity_metrics = evaluate_histogram_fidelity(data, bin_edges, bin_counts, base)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "kl_divergence": fidelity_metrics["kl_divergence"],
            "similarity_score": fidelity_metrics["similarity_score"],
            "quality": fidelity_metrics["quality"]
        }

    return results


def find_optimal_binning_strategy_kl(data: np.ndarray,
                                   strategies: Optional[List[str]] = None,
                                   num_bins_range: Optional[List[int]] = None,
                                   base: float = 2.0) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de fidélité informationnelle
    en utilisant des métriques basées sur la divergence KL.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins_range: Liste des nombres de bins à tester
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

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

            # Évaluer la fidélité de l'histogramme
            fidelity_metrics = evaluate_histogram_fidelity(data, bin_edges, bin_counts, base)

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "kl_divergence": fidelity_metrics["kl_divergence"],
                "similarity_score": fidelity_metrics["similarity_score"],
                "quality": fidelity_metrics["quality"]
            }

            # Mettre à jour la meilleure stratégie
            if fidelity_metrics["similarity_score"] > best_score:
                best_score = fidelity_metrics["similarity_score"]
                best_strategy = strategy
                best_num_bins = num_bins
                best_metrics = fidelity_metrics

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

    # Tester les métriques basées sur la divergence KL
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Comparer différentes stratégies de binning
        results = compare_binning_strategies_kl(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Score de similarité: {result['similarity_score']:.4f}")
            print(f"Qualité: {result['quality']}")
            print(f"Divergence KL: {result['kl_divergence']:.4f}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_kl(data)
        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Score optimal: {optimization['best_score']:.4f}")
        print(f"Qualité: {optimization['best_quality']}")
