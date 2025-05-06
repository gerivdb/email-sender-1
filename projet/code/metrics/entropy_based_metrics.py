#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques basées sur l'entropie pour évaluer
la fidélité informationnelle des histogrammes et des représentations de distributions.

Ce module fournit des fonctions pour calculer différentes métriques qui mesurent
la quantité d'information préservée ou perdue lors de la représentation d'une
distribution par un histogramme ou une autre approximation.
"""

import numpy as np
import scipy.stats
import scipy.integrate
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Constantes pour les paramètres par défaut
DEFAULT_BIN_METHOD = 'auto'  # Méthode de détermination du nombre de bins
DEFAULT_KDE_BANDWIDTH = 'scott'  # Méthode de Scott pour la largeur de bande KDE
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter log(0)


def calculate_shannon_entropy(probabilities: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule l'entropie de Shannon d'une distribution discrète.
    
    Args:
        probabilities: Probabilités de la distribution (doivent sommer à 1)
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        
    Returns:
        float: Entropie de Shannon en unités correspondant à la base
    """
    # Filtrer les probabilités nulles pour éviter log(0)
    valid_probs = probabilities[probabilities > 0]
    
    # Normaliser si nécessaire
    if not np.isclose(np.sum(valid_probs), 1.0):
        valid_probs = valid_probs / np.sum(valid_probs)
    
    # Calculer l'entropie
    if base == 2.0:
        entropy = -np.sum(valid_probs * np.log2(valid_probs))
    elif base == np.e:
        entropy = -np.sum(valid_probs * np.log(valid_probs))
    elif base == 10.0:
        entropy = -np.sum(valid_probs * np.log10(valid_probs))
    else:
        entropy = -np.sum(valid_probs * np.log(valid_probs)) / np.log(base)
    
    return entropy


def calculate_histogram_entropy(bin_counts: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule l'entropie de Shannon d'un histogramme.
    
    Args:
        bin_counts: Comptage par bin de l'histogramme
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        
    Returns:
        float: Entropie de Shannon en unités correspondant à la base
    """
    # Convertir les comptages en probabilités
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 0.0
    
    probabilities = bin_counts / total_count
    
    # Calculer l'entropie
    return calculate_shannon_entropy(probabilities, base)


def estimate_differential_entropy(data: np.ndarray, 
                                 kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                 base: float = 2.0,
                                 num_samples: int = 1000) -> float:
    """
    Estime l'entropie différentielle d'une distribution continue.
    
    Args:
        data: Données d'entrée
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        num_samples: Nombre de points pour l'estimation numérique
        
    Returns:
        float: Entropie différentielle estimée
    """
    # Estimer la densité avec KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=kde_bandwidth)
    
    # Créer une grille pour l'évaluation
    x_min, x_max = np.min(data), np.max(data)
    x_range = x_max - x_min
    x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, num_samples)
    
    # Évaluer la densité sur la grille
    density = kde(x_grid)
    
    # Éviter les valeurs nulles ou négatives
    density = np.maximum(density, DEFAULT_EPSILON)
    
    # Calculer l'entropie différentielle
    if base == 2.0:
        log_density = np.log2(density)
    elif base == np.e:
        log_density = np.log(density)
    elif base == 10.0:
        log_density = np.log10(density)
    else:
        log_density = np.log(density) / np.log(base)
    
    # Intégration numérique: -∫ f(x) log(f(x)) dx
    entropy = -np.trapz(density * log_density, x_grid)
    
    return entropy


def calculate_kl_divergence(p: np.ndarray, q: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule la divergence de Kullback-Leibler entre deux distributions discrètes.
    
    Args:
        p: Distribution de référence (doit sommer à 1)
        q: Distribution approximative (doit sommer à 1)
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        
    Returns:
        float: Divergence KL en unités correspondant à la base
    """
    # Filtrer les probabilités nulles et s'assurer que q > 0 où p > 0
    mask = p > 0
    p_valid = p[mask]
    q_valid = np.maximum(q[mask], DEFAULT_EPSILON)
    
    # Normaliser si nécessaire
    if not np.isclose(np.sum(p_valid), 1.0):
        p_valid = p_valid / np.sum(p_valid)
    if not np.isclose(np.sum(q_valid), 1.0):
        q_valid = q_valid / np.sum(q_valid)
    
    # Calculer la divergence KL
    if base == 2.0:
        kl_div = np.sum(p_valid * np.log2(p_valid / q_valid))
    elif base == np.e:
        kl_div = np.sum(p_valid * np.log(p_valid / q_valid))
    elif base == 10.0:
        kl_div = np.sum(p_valid * np.log10(p_valid / q_valid))
    else:
        kl_div = np.sum(p_valid * np.log(p_valid / q_valid)) / np.log(base)
    
    return kl_div


def estimate_continuous_kl_divergence(p_data: np.ndarray, 
                                     q_data: np.ndarray,
                                     kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                     base: float = 2.0,
                                     num_samples: int = 1000) -> float:
    """
    Estime la divergence de Kullback-Leibler entre deux distributions continues.
    
    Args:
        p_data: Données de la distribution de référence
        q_data: Données de la distribution approximative
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        num_samples: Nombre de points pour l'estimation numérique
        
    Returns:
        float: Divergence KL estimée
    """
    # Estimer les densités avec KDE
    p_kde = scipy.stats.gaussian_kde(p_data, bw_method=kde_bandwidth)
    q_kde = scipy.stats.gaussian_kde(q_data, bw_method=kde_bandwidth)
    
    # Créer une grille pour l'évaluation
    x_min = min(np.min(p_data), np.min(q_data))
    x_max = max(np.max(p_data), np.max(q_data))
    x_range = x_max - x_min
    x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, num_samples)
    
    # Évaluer les densités sur la grille
    p_density = p_kde(x_grid)
    q_density = q_kde(x_grid)
    
    # Éviter les valeurs nulles ou négatives
    p_density = np.maximum(p_density, DEFAULT_EPSILON)
    q_density = np.maximum(q_density, DEFAULT_EPSILON)
    
    # Calculer le rapport des densités
    if base == 2.0:
        log_ratio = np.log2(p_density / q_density)
    elif base == np.e:
        log_ratio = np.log(p_density / q_density)
    elif base == 10.0:
        log_ratio = np.log10(p_density / q_density)
    else:
        log_ratio = np.log(p_density / q_density) / np.log(base)
    
    # Intégration numérique: ∫ p(x) log(p(x)/q(x)) dx
    kl_div = np.trapz(p_density * log_ratio, x_grid)
    
    return kl_div


def calculate_jensen_shannon_divergence(p: np.ndarray, q: np.ndarray, base: float = 2.0) -> float:
    """
    Calcule la divergence de Jensen-Shannon entre deux distributions discrètes.
    
    Args:
        p: Première distribution (doit sommer à 1)
        q: Deuxième distribution (doit sommer à 1)
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        
    Returns:
        float: Divergence JS en unités correspondant à la base
    """
    # Normaliser si nécessaire
    if not np.isclose(np.sum(p), 1.0):
        p = p / np.sum(p)
    if not np.isclose(np.sum(q), 1.0):
        q = q / np.sum(q)
    
    # Calculer la distribution moyenne
    m = 0.5 * (p + q)
    
    # Calculer la divergence JS
    js_div = 0.5 * calculate_kl_divergence(p, m, base) + 0.5 * calculate_kl_divergence(q, m, base)
    
    return js_div


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


def calculate_information_loss(original_data: np.ndarray, 
                              bin_edges: np.ndarray, 
                              bin_counts: np.ndarray,
                              base: float = 2.0) -> Dict[str, Any]:
    """
    Calcule la perte d'information lors de la représentation d'une distribution
    par un histogramme.
    
    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        
    Returns:
        Dict[str, Any]: Métriques de perte d'information
    """
    # Estimer l'entropie différentielle des données originales
    original_entropy = estimate_differential_entropy(original_data, base=base)
    
    # Calculer l'entropie de l'histogramme
    histogram_entropy = calculate_histogram_entropy(bin_counts, base=base)
    
    # Calculer la perte d'information absolue
    # Note: Les entropies différentielles et discrètes ne sont pas directement comparables,
    # mais nous pouvons estimer la perte relative
    
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
    
    # Estimer l'entropie différentielle des données reconstruites
    if len(reconstructed_data) > 0:
        reconstructed_entropy = estimate_differential_entropy(reconstructed_data, base=base)
    else:
        reconstructed_entropy = 0.0
    
    # Estimer la divergence KL entre les distributions originale et reconstruite
    if len(reconstructed_data) > 0:
        kl_divergence = estimate_continuous_kl_divergence(original_data, reconstructed_data, base=base)
    else:
        kl_divergence = float('inf')
    
    # Calculer le ratio d'information préservée
    if original_entropy != 0:
        information_preservation_ratio = reconstructed_entropy / original_entropy
    else:
        information_preservation_ratio = 1.0 if reconstructed_entropy == 0 else 0.0
    
    # Calculer le ratio de perte d'information
    information_loss_ratio = 1.0 - information_preservation_ratio
    
    return {
        "original_entropy": original_entropy,
        "histogram_entropy": histogram_entropy,
        "reconstructed_entropy": reconstructed_entropy,
        "kl_divergence": kl_divergence,
        "information_preservation_ratio": information_preservation_ratio,
        "information_loss_ratio": information_loss_ratio
    }


def calculate_information_preservation_score(original_data: np.ndarray, 
                                           bin_edges: np.ndarray, 
                                           bin_counts: np.ndarray,
                                           base: float = 2.0,
                                           weights: Dict[str, float] = None) -> float:
    """
    Calcule un score global de préservation de l'information entre 0 et 1.
    
    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        weights: Poids pour les différentes composantes du score
        
    Returns:
        float: Score de préservation de l'information (0-1)
    """
    # Calculer les métriques de perte d'information
    metrics = calculate_information_loss(original_data, bin_edges, bin_counts, base)
    
    # Définir les poids par défaut si non spécifiés
    if weights is None:
        weights = {
            "entropy_ratio": 0.6,
            "kl_divergence": 0.4
        }
    
    # Calculer le score basé sur le ratio d'entropie
    entropy_ratio_score = metrics["information_preservation_ratio"]
    
    # Calculer le score basé sur la divergence KL (normalisé entre 0 et 1)
    # Plus la divergence KL est faible, meilleur est le score
    kl_div = metrics["kl_divergence"]
    if np.isfinite(kl_div):
        kl_score = np.exp(-kl_div)  # Décroissance exponentielle
    else:
        kl_score = 0.0
    
    # Calculer le score pondéré
    score = (
        weights["entropy_ratio"] * entropy_ratio_score +
        weights["kl_divergence"] * kl_score
    )
    
    # Normaliser le score entre 0 et 1
    return max(0.0, min(1.0, score))


def evaluate_information_preservation_quality(score: float) -> str:
    """
    Évalue la qualité de préservation de l'information en fonction du score.
    
    Args:
        score: Score de préservation de l'information (0-1)
        
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


def compare_binning_strategies_information_preservation(data: np.ndarray, 
                                                      strategies: List[str] = None,
                                                      num_bins: int = 20,
                                                      base: float = 2.0) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de préservation de l'information.
    
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
        
        # Calculer les métriques de préservation de l'information
        metrics = calculate_information_loss(data, bin_edges, bin_counts, base)
        score = calculate_information_preservation_score(data, bin_edges, bin_counts, base)
        quality = evaluate_information_preservation_quality(score)
        
        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "metrics": metrics,
            "score": score,
            "quality": quality
        }
    
    return results


def find_optimal_bin_count_for_information_preservation(data: np.ndarray, 
                                                      strategy: str = "uniform",
                                                      min_bins: int = 5,
                                                      max_bins: int = 100,
                                                      step: int = 5,
                                                      base: float = 2.0,
                                                      target_score: float = 0.9) -> Dict[str, Any]:
    """
    Trouve le nombre optimal de bins pour préserver l'information.
    
    Args:
        data: Données originales
        strategy: Stratégie de binning
        min_bins: Nombre minimum de bins à tester
        max_bins: Nombre maximum de bins à tester
        step: Pas d'incrémentation du nombre de bins
        base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
        target_score: Score cible de préservation de l'information
        
    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    results = {}
    best_score = 0
    optimal_bins = min_bins
    
    for num_bins in range(min_bins, max_bins + 1, step):
        # Générer l'histogramme
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
        
        # Calculer le score de préservation de l'information
        score = calculate_information_preservation_score(data, bin_edges, bin_counts, base)
        
        # Stocker les résultats
        results[num_bins] = score
        
        # Mettre à jour le meilleur score
        if score > best_score:
            best_score = score
            optimal_bins = num_bins
        
        # Arrêter si le score cible est atteint
        if score >= target_score:
            break
    
    return {
        "optimal_bins": optimal_bins,
        "best_score": best_score,
        "scores": results,
        "target_reached": best_score >= target_score
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
    
    # Tester les métriques basées sur l'entropie
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")
        
        # Estimer l'entropie différentielle
        entropy = estimate_differential_entropy(data)
        print(f"Entropie différentielle: {entropy:.4f} bits")
        
        # Comparer différentes stratégies de binning
        results = compare_binning_strategies_information_preservation(data)
        
        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Score de préservation de l'information: {result['score']:.4f}")
            print(f"Qualité: {result['quality']}")
            print(f"Ratio de préservation de l'information: {result['metrics']['information_preservation_ratio']:.4f}")
            print(f"Divergence KL: {result['metrics']['kl_divergence']:.4f}")
        
        # Trouver le nombre optimal de bins
        print("\nRecherche du nombre optimal de bins:")
        for strategy in ["uniform", "quantile", "logarithmic"]:
            optimization = find_optimal_bin_count_for_information_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            print(f"  {strategy}: {optimization['optimal_bins']} bins (score: {optimization['best_score']:.4f})")
