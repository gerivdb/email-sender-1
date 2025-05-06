#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques basées sur l'information mutuelle
pour évaluer la fidélité informationnelle des représentations de distributions.

Ce module étend les fonctionnalités des modules entropy_based_metrics.py et
kl_divergence_metrics.py avec des métriques spécialisées basées sur l'information mutuelle.
"""

import numpy as np
import scipy.stats
import scipy.integrate
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Importer les fonctions de base des modules d'entropie et de divergence KL
from entropy_based_metrics import (
    calculate_shannon_entropy,
    estimate_differential_entropy,
    DEFAULT_EPSILON,
    DEFAULT_KDE_BANDWIDTH
)

from kl_divergence_metrics import (
    calculate_kl_divergence,
    estimate_continuous_kl_divergence,
    evaluate_kl_divergence_quality
)


def calculate_mutual_information(joint_distribution: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule l'information mutuelle entre deux variables aléatoires discrètes.

    Args:
        joint_distribution: Distribution jointe P(X,Y) sous forme de matrice
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Information mutuelle en unités correspondant à la base
    """
    # Normaliser si nécessaire
    if not np.isclose(np.sum(joint_distribution), 1.0):
        joint_distribution = joint_distribution / np.sum(joint_distribution)

    # Calculer les distributions marginales
    p_x = np.sum(joint_distribution, axis=1)
    p_y = np.sum(joint_distribution, axis=0)

    # Calculer l'information mutuelle
    mutual_info = 0.0

    for i in range(len(p_x)):
        for j in range(len(p_y)):
            if joint_distribution[i, j] > 0 and p_x[i] > 0 and p_y[j] > 0:
                if base == 2.0:
                    mutual_info += joint_distribution[i, j] * np.log2(joint_distribution[i, j] / (p_x[i] * p_y[j]))
                elif base == np.e:
                    mutual_info += joint_distribution[i, j] * np.log(joint_distribution[i, j] / (p_x[i] * p_y[j]))
                elif base == 10.0:
                    mutual_info += joint_distribution[i, j] * np.log10(joint_distribution[i, j] / (p_x[i] * p_y[j]))
                else:
                    mutual_info += joint_distribution[i, j] * np.log(joint_distribution[i, j] / (p_x[i] * p_y[j])) / np.log(base)

    return mutual_info


def calculate_normalized_mutual_information(joint_distribution: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule l'information mutuelle normalisée entre deux variables aléatoires discrètes.

    Args:
        joint_distribution: Distribution jointe P(X,Y) sous forme de matrice
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Information mutuelle normalisée (0-1)
    """
    # Normaliser si nécessaire
    if not np.isclose(np.sum(joint_distribution), 1.0):
        joint_distribution = joint_distribution / np.sum(joint_distribution)

    # Calculer les distributions marginales
    p_x = np.sum(joint_distribution, axis=1)
    p_y = np.sum(joint_distribution, axis=0)

    # Calculer les entropies marginales
    h_x = calculate_shannon_entropy(p_x, base)
    h_y = calculate_shannon_entropy(p_y, base)

    # Calculer l'information mutuelle
    mi = calculate_mutual_information(joint_distribution, base)

    # Calculer l'information mutuelle normalisée
    if h_x + h_y > 0:
        nmi = 2 * mi / (h_x + h_y)
    else:
        nmi = 0.0

    return nmi


def estimate_mutual_information_from_samples(x: np.ndarray,
                                           y: np.ndarray,
                                           bins: int = 20,
                                           base: float = 2.0) -> float:
    """
    Estime l'information mutuelle entre deux variables à partir d'échantillons.

    Args:
        x: Échantillons de la première variable
        y: Échantillons de la deuxième variable
        bins: Nombre de bins ou liste de limites de bins
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Information mutuelle estimée
    """
    # Vérifier que les échantillons ont la même taille
    if len(x) != len(y):
        raise ValueError("Les échantillons x et y doivent avoir la même taille")

    # Calculer l'histogramme 2D (distribution jointe empirique)
    hist_2d, x_edges, y_edges = np.histogram2d(x, y, bins=bins)

    # Normaliser pour obtenir une distribution de probabilité
    hist_2d = hist_2d / np.sum(hist_2d)

    # Calculer l'information mutuelle
    return calculate_mutual_information(hist_2d, base)


def estimate_normalized_mutual_information_from_samples(x: np.ndarray,
                                                      y: np.ndarray,
                                                      bins: int = 20,
                                                      base: float = 2.0) -> float:
    """
    Estime l'information mutuelle normalisée entre deux variables à partir d'échantillons.

    Args:
        x: Échantillons de la première variable
        y: Échantillons de la deuxième variable
        bins: Nombre de bins ou méthode pour déterminer les bins
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

    Returns:
        float: Information mutuelle normalisée estimée (0-1)
    """
    # Vérifier que les échantillons ont la même taille
    if len(x) != len(y):
        raise ValueError("Les échantillons x et y doivent avoir la même taille")

    # Calculer l'histogramme 2D (distribution jointe empirique)
    hist_2d, x_edges, y_edges = np.histogram2d(x, y, bins=bins)

    # Normaliser pour obtenir une distribution de probabilité
    hist_2d = hist_2d / np.sum(hist_2d)

    # Calculer l'information mutuelle normalisée
    return calculate_normalized_mutual_information(hist_2d, base)


def calculate_mutual_information_score(mi: float, max_mi: float) -> float:
    """
    Calcule un score de similarité basé sur l'information mutuelle, normalisé entre 0 et 1.

    Args:
        mi: Information mutuelle calculée
        max_mi: Information mutuelle maximale possible

    Returns:
        float: Score de similarité (0-1), où 1 indique une dépendance parfaite
    """
    if max_mi <= 0:
        return 0.0

    # Normaliser l'information mutuelle
    score = mi / max_mi

    # S'assurer que le score est entre 0 et 1
    return max(0.0, min(1.0, score))


def evaluate_mutual_information_quality(score: float) -> str:
    """
    Évalue la qualité de la dépendance en fonction du score d'information mutuelle.

    Args:
        score: Score basé sur l'information mutuelle (0-1)

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


def evaluate_histogram_fidelity_mi(original_data: np.ndarray,
                                 bin_edges: np.ndarray,
                                 bin_counts: np.ndarray,
                                 base: float = 2.0) -> Dict[str, Any]:
    """
    Évalue la fidélité d'un histogramme par rapport aux données originales
    en utilisant des métriques basées sur l'information mutuelle.

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
            "mutual_information": 0.0,
            "normalized_mutual_information": 0.0,
            "mi_score": 0.0,
            "quality": "Insuffisante"
        }

    # Calculer l'information mutuelle entre les données originales et reconstruites
    # Pour cela, nous devons créer des paires de points correspondants
    # Nous utilisons un rééchantillonnage pour avoir des tableaux de même taille
    if len(original_data) > len(reconstructed_data):
        indices = np.random.choice(len(original_data), len(reconstructed_data), replace=False)
        original_samples = original_data[indices]
        reconstructed_samples = reconstructed_data
    elif len(reconstructed_data) > len(original_data):
        indices = np.random.choice(len(reconstructed_data), len(original_data), replace=False)
        original_samples = original_data
        reconstructed_samples = reconstructed_data[indices]
    else:
        original_samples = original_data
        reconstructed_samples = reconstructed_data

    # Estimer l'information mutuelle
    mi = estimate_mutual_information_from_samples(original_samples, reconstructed_samples, bins=20, base=base)

    # Estimer l'information mutuelle normalisée
    nmi = estimate_normalized_mutual_information_from_samples(original_samples, reconstructed_samples, bins=20, base=base)

    # Calculer le score de similarité
    # L'information mutuelle maximale est l'entropie minimale des deux variables
    h_original = estimate_differential_entropy(original_samples, base=base)
    h_reconstructed = estimate_differential_entropy(reconstructed_samples, base=base)
    max_mi = min(h_original, h_reconstructed)

    mi_score = calculate_mutual_information_score(mi, max_mi)

    # Évaluer la qualité
    quality = evaluate_mutual_information_quality(mi_score)

    return {
        "mutual_information": mi,
        "normalized_mutual_information": nmi,
        "mi_score": mi_score,
        "quality": quality
    }


def compare_binning_strategies_mi(data: np.ndarray,
                                strategies: Optional[List[str]] = None,
                                num_bins: int = 20,
                                base: float = 2.0) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de fidélité informationnelle
    en utilisant des métriques basées sur l'information mutuelle.

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
        fidelity_metrics = evaluate_histogram_fidelity_mi(data, bin_edges, bin_counts, base)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "mutual_information": fidelity_metrics["mutual_information"],
            "normalized_mutual_information": fidelity_metrics["normalized_mutual_information"],
            "mi_score": fidelity_metrics["mi_score"],
            "quality": fidelity_metrics["quality"]
        }

    return results


def find_optimal_binning_strategy_mi(data: np.ndarray,
                                   strategies: Optional[List[str]] = None,
                                   num_bins_range: Optional[List[int]] = None,
                                   base: float = 2.0) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de fidélité informationnelle
    en utilisant des métriques basées sur l'information mutuelle.

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
            fidelity_metrics = evaluate_histogram_fidelity_mi(data, bin_edges, bin_counts, base)

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "mutual_information": fidelity_metrics["mutual_information"],
                "normalized_mutual_information": fidelity_metrics["normalized_mutual_information"],
                "mi_score": fidelity_metrics["mi_score"],
                "quality": fidelity_metrics["quality"]
            }

            # Mettre à jour la meilleure stratégie
            if fidelity_metrics["mi_score"] > best_score:
                best_score = fidelity_metrics["mi_score"]
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

    # Tester les métriques basées sur l'information mutuelle
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Comparer différentes stratégies de binning
        results = compare_binning_strategies_mi(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Information mutuelle: {result['mutual_information']:.4f} bits")
            print(f"Information mutuelle normalisée: {result['normalized_mutual_information']:.4f}")
            print(f"Score MI: {result['mi_score']:.4f}")
            print(f"Qualité: {result['quality']}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_mi(data, num_bins_range=[5, 10, 20, 50])
        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Score optimal: {optimization['best_score']:.4f}")
        print(f"Qualité: {optimization['best_quality']}")
