#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques de préservation des percentiles pour évaluer
la qualité des histogrammes et des représentations de distributions.

Ce module fournit des fonctions pour calculer différentes métriques qui mesurent
à quel point les percentiles d'une distribution originale sont préservés dans
une représentation simplifiée (comme un histogramme).
"""

import numpy as np
import scipy.stats
from typing import Dict, List, Tuple, Union, Optional, Any, Callable


def calculate_percentiles(data: np.ndarray, percentiles: List[float] = None) -> Dict[float, float]:
    """
    Calcule les percentiles spécifiés pour un ensemble de données.
    
    Args:
        data: Données d'entrée
        percentiles: Liste des percentiles à calculer (0-100)
        
    Returns:
        Dict[float, float]: Dictionnaire des percentiles {percentile: valeur}
    """
    if percentiles is None:
        # Percentiles par défaut: 1, 5, 10, 25, 50, 75, 90, 95, 99
        percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
    result = {}
    for p in percentiles:
        result[p] = float(np.percentile(data, p))
    
    return result


def reconstruct_data_from_histogram(bin_edges: np.ndarray, bin_counts: np.ndarray, 
                                    method: str = "uniform") -> np.ndarray:
    """
    Reconstruit un ensemble de données approximatif à partir d'un histogramme.
    
    Args:
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        method: Méthode de reconstruction ("uniform", "midpoint", "random")
        
    Returns:
        np.ndarray: Données reconstruites
    """
    reconstructed_data = []
    
    for i in range(len(bin_counts)):
        bin_count = bin_counts[i]
        bin_start = bin_edges[i]
        bin_end = bin_edges[i + 1]
        
        if method == "uniform":
            # Répartir uniformément les points dans le bin
            if bin_count > 0:
                step = (bin_end - bin_start) / bin_count
                bin_data = [bin_start + step * (j + 0.5) for j in range(bin_count)]
                reconstructed_data.extend(bin_data)
        
        elif method == "midpoint":
            # Placer tous les points au milieu du bin
            bin_midpoint = (bin_start + bin_end) / 2
            bin_data = [bin_midpoint] * bin_count
            reconstructed_data.extend(bin_data)
        
        elif method == "random":
            # Répartir aléatoirement les points dans le bin
            bin_data = np.random.uniform(bin_start, bin_end, bin_count)
            reconstructed_data.extend(bin_data)
        
        else:
            raise ValueError(f"Méthode de reconstruction inconnue: {method}")
    
    return np.array(reconstructed_data)


def calculate_percentile_preservation_error(original_data: np.ndarray, 
                                           bin_edges: np.ndarray, 
                                           bin_counts: np.ndarray,
                                           percentiles: List[float] = None,
                                           reconstruction_method: str = "uniform") -> Dict[str, Any]:
    """
    Calcule l'erreur de préservation des percentiles entre les données originales
    et une représentation par histogramme.
    
    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        percentiles: Liste des percentiles à évaluer
        reconstruction_method: Méthode de reconstruction des données
        
    Returns:
        Dict[str, Any]: Métriques d'erreur de préservation des percentiles
    """
    if percentiles is None:
        percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
    # Calculer les percentiles des données originales
    original_percentiles = calculate_percentiles(original_data, percentiles)
    
    # Reconstruire les données à partir de l'histogramme
    reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts, reconstruction_method)
    
    # Calculer les percentiles des données reconstruites
    reconstructed_percentiles = calculate_percentiles(reconstructed_data, percentiles)
    
    # Calculer les erreurs absolues et relatives pour chaque percentile
    absolute_errors = {}
    relative_errors = {}
    for p in percentiles:
        original_value = original_percentiles[p]
        reconstructed_value = reconstructed_percentiles[p]
        
        absolute_errors[p] = abs(reconstructed_value - original_value)
        
        # Éviter la division par zéro
        if original_value != 0:
            relative_errors[p] = abs((reconstructed_value - original_value) / original_value) * 100
        else:
            relative_errors[p] = 0.0 if reconstructed_value == 0 else float('inf')
    
    # Calculer les métriques agrégées
    mean_absolute_error = np.mean(list(absolute_errors.values()))
    median_absolute_error = np.median(list(absolute_errors.values()))
    max_absolute_error = max(absolute_errors.values())
    
    mean_relative_error = np.mean([e for e in relative_errors.values() if e != float('inf')])
    median_relative_error = np.median([e for e in relative_errors.values() if e != float('inf')])
    max_relative_error = max([e for e in relative_errors.values() if e != float('inf')])
    
    # Calculer l'erreur quadratique moyenne (RMSE)
    squared_errors = [(reconstructed_percentiles[p] - original_percentiles[p])**2 for p in percentiles]
    rmse = np.sqrt(np.mean(squared_errors))
    
    # Calculer le coefficient de corrélation entre les percentiles originaux et reconstruits
    correlation = np.corrcoef(
        [original_percentiles[p] for p in percentiles],
        [reconstructed_percentiles[p] for p in percentiles]
    )[0, 1]
    
    return {
        "percentiles": percentiles,
        "original_percentiles": original_percentiles,
        "reconstructed_percentiles": reconstructed_percentiles,
        "absolute_errors": absolute_errors,
        "relative_errors": relative_errors,
        "mean_absolute_error": mean_absolute_error,
        "median_absolute_error": median_absolute_error,
        "max_absolute_error": max_absolute_error,
        "mean_relative_error": mean_relative_error,
        "median_relative_error": median_relative_error,
        "max_relative_error": max_relative_error,
        "rmse": rmse,
        "correlation": correlation
    }


def calculate_percentile_preservation_score(original_data: np.ndarray, 
                                           bin_edges: np.ndarray, 
                                           bin_counts: np.ndarray,
                                           percentiles: List[float] = None,
                                           reconstruction_method: str = "uniform",
                                           weights: Dict[str, float] = None) -> float:
    """
    Calcule un score global de préservation des percentiles entre 0 et 1.
    
    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        percentiles: Liste des percentiles à évaluer
        reconstruction_method: Méthode de reconstruction des données
        weights: Poids pour les différentes composantes du score
        
    Returns:
        float: Score de préservation des percentiles (0-1)
    """
    # Calculer les métriques d'erreur
    metrics = calculate_percentile_preservation_error(
        original_data, bin_edges, bin_counts, percentiles, reconstruction_method
    )
    
    # Définir les poids par défaut si non spécifiés
    if weights is None:
        weights = {
            "correlation": 0.4,
            "mean_relative_error": 0.3,
            "max_relative_error": 0.3
        }
    
    # Normaliser les métriques pour le calcul du score
    correlation_score = max(0, metrics["correlation"])  # 0-1, plus élevé est meilleur
    
    # Convertir les erreurs relatives en scores (0-1, plus bas est meilleur)
    mean_relative_error_score = np.exp(-metrics["mean_relative_error"] / 20)  # Décroissance exponentielle
    max_relative_error_score = np.exp(-metrics["max_relative_error"] / 50)    # Décroissance exponentielle
    
    # Calculer le score pondéré
    score = (
        weights["correlation"] * correlation_score +
        weights["mean_relative_error"] * mean_relative_error_score +
        weights["max_relative_error"] * max_relative_error_score
    )
    
    # Normaliser le score entre 0 et 1
    return max(0, min(1, score))


def evaluate_percentile_preservation_quality(score: float) -> str:
    """
    Évalue la qualité de préservation des percentiles en fonction du score.
    
    Args:
        score: Score de préservation des percentiles (0-1)
        
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


def calculate_percentile_weighted_error(original_data: np.ndarray, 
                                       bin_edges: np.ndarray, 
                                       bin_counts: np.ndarray,
                                       percentile_weights: Dict[float, float] = None,
                                       reconstruction_method: str = "uniform") -> Dict[str, Any]:
    """
    Calcule l'erreur de préservation des percentiles pondérée par l'importance
    de chaque percentile.
    
    Args:
        original_data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        percentile_weights: Poids pour chaque percentile
        reconstruction_method: Méthode de reconstruction des données
        
    Returns:
        Dict[str, Any]: Métriques d'erreur pondérée
    """
    # Définir les poids par défaut si non spécifiés
    if percentile_weights is None:
        # Donner plus de poids aux percentiles extrêmes (queue de distribution)
        percentile_weights = {
            1: 2.0,   # Très important pour la queue inférieure
            5: 1.5,   # Important pour la queue inférieure
            10: 1.2,  # Modérément important
            25: 1.0,  # Standard
            50: 1.0,  # Standard (médiane)
            75: 1.0,  # Standard
            90: 1.2,  # Modérément important
            95: 1.5,  # Important pour la queue supérieure
            99: 2.0   # Très important pour la queue supérieure
        }
    
    # Calculer les métriques d'erreur
    metrics = calculate_percentile_preservation_error(
        original_data, bin_edges, bin_counts, list(percentile_weights.keys()), reconstruction_method
    )
    
    # Calculer l'erreur pondérée
    weighted_absolute_errors = {}
    weighted_relative_errors = {}
    
    for p, weight in percentile_weights.items():
        weighted_absolute_errors[p] = metrics["absolute_errors"][p] * weight
        weighted_relative_errors[p] = metrics["relative_errors"][p] * weight
    
    # Calculer les métriques agrégées pondérées
    mean_weighted_absolute_error = np.mean(list(weighted_absolute_errors.values()))
    max_weighted_absolute_error = max(weighted_absolute_errors.values())
    
    mean_weighted_relative_error = np.mean([e for e in weighted_relative_errors.values() if e != float('inf')])
    max_weighted_relative_error = max([e for e in weighted_relative_errors.values() if e != float('inf')])
    
    return {
        "percentiles": list(percentile_weights.keys()),
        "percentile_weights": percentile_weights,
        "weighted_absolute_errors": weighted_absolute_errors,
        "weighted_relative_errors": weighted_relative_errors,
        "mean_weighted_absolute_error": mean_weighted_absolute_error,
        "max_weighted_absolute_error": max_weighted_absolute_error,
        "mean_weighted_relative_error": mean_weighted_relative_error,
        "max_weighted_relative_error": max_weighted_relative_error
    }


def compare_binning_strategies_percentile_preservation(data: np.ndarray, 
                                                      strategies: List[str] = None,
                                                      num_bins: int = 20,
                                                      percentiles: List[float] = None) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de préservation des percentiles.
    
    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        percentiles: Liste des percentiles à évaluer
        
    Returns:
        Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]
    
    if percentiles is None:
        percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
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
        
        # Calculer les métriques de préservation des percentiles
        metrics = calculate_percentile_preservation_error(data, bin_edges, bin_counts, percentiles)
        score = calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
        quality = evaluate_percentile_preservation_quality(score)
        
        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "metrics": metrics,
            "score": score,
            "quality": quality
        }
    
    return results


def find_optimal_bin_count_for_percentile_preservation(data: np.ndarray, 
                                                     strategy: str = "uniform",
                                                     min_bins: int = 5,
                                                     max_bins: int = 100,
                                                     step: int = 5,
                                                     percentiles: List[float] = None,
                                                     target_score: float = 0.9) -> Dict[str, Any]:
    """
    Trouve le nombre optimal de bins pour préserver les percentiles.
    
    Args:
        data: Données originales
        strategy: Stratégie de binning
        min_bins: Nombre minimum de bins à tester
        max_bins: Nombre maximum de bins à tester
        step: Pas d'incrémentation du nombre de bins
        percentiles: Liste des percentiles à évaluer
        target_score: Score cible de préservation des percentiles
        
    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    if percentiles is None:
        percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
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
        
        # Calculer le score de préservation des percentiles
        score = calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
        
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
    
    # Tester les métriques de préservation des percentiles
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")
        
        # Comparer différentes stratégies de binning
        results = compare_binning_strategies_percentile_preservation(data)
        
        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Score de préservation des percentiles: {result['score']:.4f}")
            print(f"Qualité: {result['quality']}")
            print(f"Erreur relative moyenne: {result['metrics']['mean_relative_error']:.2f}%")
            print(f"Erreur relative maximale: {result['metrics']['max_relative_error']:.2f}%")
            print(f"Corrélation: {result['metrics']['correlation']:.4f}")
        
        # Trouver le nombre optimal de bins
        print("\nRecherche du nombre optimal de bins:")
        for strategy in ["uniform", "quantile", "logarithmic"]:
            optimization = find_optimal_bin_count_for_percentile_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            print(f"  {strategy}: {optimization['optimal_bins']} bins (score: {optimization['best_score']:.4f})")
