#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques d'interprétabilité des modes
pour évaluer la fidélité perceptuelle des représentations de distributions.

Ce module fournit des fonctions pour quantifier la facilité avec laquelle
un utilisateur peut identifier et comprendre les différents modes (pics)
dans une distribution.
"""

import numpy as np
import scipy.stats
import scipy.signal
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Constantes pour les paramètres par défaut
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter les divisions par zéro
DEFAULT_PROMINENCE = 0.1  # Seuil de proéminence par défaut pour la détection des pics


def detect_modes(data: np.ndarray,
                bin_edges: Optional[np.ndarray] = None,
                bin_counts: Optional[np.ndarray] = None,
                prominence_threshold: float = DEFAULT_PROMINENCE) -> Dict[str, Any]:
    """
    Détecte les modes (pics) dans une distribution.

    Args:
        data: Données brutes (utilisées si bin_counts est None)
        bin_edges: Limites des bins (utilisées si bin_counts est None)
        bin_counts: Valeurs de l'histogramme (si None, calculées à partir de data)
        prominence_threshold: Seuil de proéminence pour considérer un pic

    Returns:
        Dict[str, Any]: Informations sur les modes détectés
    """
    # Si les valeurs de l'histogramme ne sont pas fournies, les calculer
    if bin_counts is None:
        if bin_edges is None:
            # Utiliser la règle de Freedman-Diaconis pour déterminer le nombre de bins
            q75, q25 = np.percentile(data, [75, 25])
            iqr = q75 - q25
            bin_width = 2 * iqr / (len(data) ** (1/3))
            if bin_width == 0:  # Éviter la division par zéro
                bin_width = 1
            num_bins = int(np.ceil((np.max(data) - np.min(data)) / bin_width))
            num_bins = max(10, min(100, num_bins))  # Limiter entre 10 et 100 bins

            bin_edges = np.linspace(np.min(data), np.max(data), num_bins + 1)

        bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Normaliser les valeurs de l'histogramme
    if np.sum(bin_counts) > 0:
        normalized_counts = bin_counts / np.max(bin_counts)
    else:
        return {
            "num_modes": 0,
            "mode_positions": [],
            "mode_heights": [],
            "mode_prominences": [],
            "mode_widths": []
        }

    # Détecter les pics (modes)
    peaks, properties = scipy.signal.find_peaks(normalized_counts, prominence=prominence_threshold)

    # Calculer les positions réelles des modes (en unités de données)
    if bin_edges is not None:
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
        mode_positions = bin_centers[peaks]
    else:
        mode_positions = peaks

    # Calculer les largeurs des modes (en unités de bins)
    if len(peaks) > 0 and 'prominences' in properties:
        # Utiliser la largeur à mi-hauteur (FWHM)
        widths_result = scipy.signal.peak_widths(normalized_counts, peaks, rel_height=0.5)
        widths = widths_result[0]  # Le premier élément contient les largeurs
    else:
        widths = []

    return {
        "num_modes": len(peaks),
        "mode_positions": mode_positions,
        "mode_heights": normalized_counts[peaks] if len(peaks) > 0 else [],
        "mode_prominences": properties.get('prominences', []) if len(peaks) > 0 else [],
        "mode_widths": widths
    }


def calculate_mode_clarity(mode_info: Dict[str, Any]) -> float:
    """
    Calcule la clarté des modes, basée sur leur proéminence et leur séparation.

    Args:
        mode_info: Informations sur les modes détectés

    Returns:
        float: Score de clarté des modes (0-1)
    """
    # Si aucun mode n'est détecté, la clarté est nulle
    if mode_info["num_modes"] == 0:
        return 0.0

    # Calculer la clarté basée sur la proéminence moyenne des modes
    if len(mode_info["mode_prominences"]) > 0:
        prominence_clarity = np.mean(mode_info["mode_prominences"])
    else:
        prominence_clarity = 0.0

    # Calculer la clarté basée sur la séparation des modes
    if mode_info["num_modes"] > 1:
        # Trier les positions des modes
        sorted_positions = np.sort(mode_info["mode_positions"])
        # Calculer les distances entre modes adjacents
        distances = np.diff(sorted_positions)
        # Calculer la séparation moyenne normalisée
        if len(distances) > 0 and np.max(sorted_positions) > np.min(sorted_positions):
            separation_clarity = np.mean(distances) / (np.max(sorted_positions) - np.min(sorted_positions))
        else:
            separation_clarity = 0.0
    else:
        separation_clarity = 1.0  # Un seul mode est parfaitement séparé

    # Combiner les deux aspects de la clarté
    clarity_score = 0.7 * prominence_clarity + 0.3 * separation_clarity

    return min(1.0, max(0.0, clarity_score))


def calculate_mode_distinctness(mode_info: Dict[str, Any]) -> float:
    """
    Calcule la distinctivité des modes, basée sur leur largeur relative.

    Args:
        mode_info: Informations sur les modes détectés

    Returns:
        float: Score de distinctivité des modes (0-1)
    """
    # Si aucun mode n'est détecté, la distinctivité est nulle
    if mode_info["num_modes"] == 0 or len(mode_info["mode_widths"]) == 0:
        return 0.0

    # Calculer la distinctivité basée sur l'inverse de la largeur relative des modes
    widths = np.array(mode_info["mode_widths"])

    # Normaliser les largeurs par rapport à l'étendue des données
    if len(mode_info["mode_positions"]) > 0:
        data_range = np.max(mode_info["mode_positions"]) - np.min(mode_info["mode_positions"])
        if data_range > 0:
            normalized_widths = widths / data_range
        else:
            normalized_widths = widths
    else:
        normalized_widths = widths

    # Calculer la distinctivité comme l'inverse de la largeur moyenne normalisée
    if np.mean(normalized_widths) > 0:
        distinctness_score = 1.0 / (1.0 + 5.0 * np.mean(normalized_widths))
    else:
        distinctness_score = 1.0

    return float(min(1.0, max(0.0, distinctness_score)))


def calculate_mode_consistency(original_mode_info: Dict[str, Any],
                             simplified_mode_info: Dict[str, Any]) -> float:
    """
    Calcule la cohérence des modes entre une distribution originale et sa version simplifiée.

    Args:
        original_mode_info: Informations sur les modes de la distribution originale
        simplified_mode_info: Informations sur les modes de la distribution simplifiée

    Returns:
        float: Score de cohérence des modes (0-1)
    """
    # Si aucun mode n'est détecté dans l'original, la cohérence dépend de la simplification
    if original_mode_info["num_modes"] == 0:
        return 1.0 if simplified_mode_info["num_modes"] == 0 else 0.0

    # Si les nombres de modes sont différents, pénaliser proportionnellement
    num_modes_ratio = min(simplified_mode_info["num_modes"] / original_mode_info["num_modes"],
                         original_mode_info["num_modes"] / simplified_mode_info["num_modes"]) if simplified_mode_info["num_modes"] > 0 else 0.0

    # Si aucun mode n'est détecté dans la simplification, la cohérence est nulle
    if simplified_mode_info["num_modes"] == 0:
        return 0.0

    # Calculer la correspondance des positions des modes
    # Pour chaque mode original, trouver le mode simplifié le plus proche
    position_errors = []

    if len(original_mode_info["mode_positions"]) > 0 and len(simplified_mode_info["mode_positions"]) > 0:
        # Normaliser les positions dans l'intervalle [0, 1]
        orig_min = np.min(original_mode_info["mode_positions"])
        orig_max = np.max(original_mode_info["mode_positions"])
        orig_range = orig_max - orig_min

        simp_min = np.min(simplified_mode_info["mode_positions"])
        simp_max = np.max(simplified_mode_info["mode_positions"])
        simp_range = simp_max - simp_min

        if orig_range > 0 and simp_range > 0:
            norm_orig_pos = (original_mode_info["mode_positions"] - orig_min) / orig_range
            norm_simp_pos = (simplified_mode_info["mode_positions"] - simp_min) / simp_range

            for orig_pos in norm_orig_pos:
                # Trouver le mode simplifié le plus proche
                distances = np.abs(norm_simp_pos - orig_pos)
                min_distance = np.min(distances)
                position_errors.append(min_distance)
        else:
            position_errors = [1.0]  # Erreur maximale si les plages sont nulles
    else:
        position_errors = [1.0]  # Erreur maximale si aucun mode n'est détecté

    # Calculer l'erreur moyenne de position
    mean_position_error = np.mean(position_errors)

    # Convertir l'erreur en score de cohérence (0-1)
    position_consistency = 1.0 - mean_position_error

    # Combiner les aspects de la cohérence
    consistency_score = 0.5 * num_modes_ratio + 0.5 * position_consistency

    return float(min(1.0, max(0.0, float(consistency_score))))


def evaluate_interpretability_quality(score: float) -> str:
    """
    Évalue la qualité d'interprétabilité des modes en fonction du score.

    Args:
        score: Score d'interprétabilité (0-1)

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


def calculate_interpretability_score(clarity: float, distinctness: float, consistency: float = 1.0) -> float:
    """
    Calcule un score global d'interprétabilité des modes.

    Args:
        clarity: Score de clarté des modes
        distinctness: Score de distinctivité des modes
        consistency: Score de cohérence des modes (si applicable)

    Returns:
        float: Score global d'interprétabilité (0-1)
    """
    # Pondérer les différents aspects de l'interprétabilité
    interpretability_score = 0.4 * clarity + 0.3 * distinctness + 0.3 * consistency

    return float(min(1.0, max(0.0, interpretability_score)))


def evaluate_histogram_interpretability(data: np.ndarray,
                                      bin_edges: np.ndarray,
                                      bin_counts: np.ndarray,
                                      reference_mode_info: Optional[Dict[str, Any]] = None,
                                      prominence_threshold: float = DEFAULT_PROMINENCE) -> Dict[str, Any]:
    """
    Évalue l'interprétabilité des modes d'un histogramme.

    Args:
        data: Données originales
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Valeurs de l'histogramme
        reference_mode_info: Informations sur les modes de référence (si disponible)
        prominence_threshold: Seuil de proéminence pour la détection des modes

    Returns:
        Dict[str, Any]: Résultats de l'évaluation
    """
    # Détecter les modes dans l'histogramme
    mode_info = detect_modes(data, bin_edges, bin_counts, prominence_threshold)

    # Calculer les scores d'interprétabilité
    clarity = calculate_mode_clarity(mode_info)
    distinctness = calculate_mode_distinctness(mode_info)

    # Si des informations de référence sont fournies, calculer la cohérence
    if reference_mode_info is not None:
        consistency = calculate_mode_consistency(reference_mode_info, mode_info)
    else:
        consistency = 1.0  # Pas de référence, donc cohérence parfaite par défaut

    # Calculer le score global d'interprétabilité
    interpretability_score = calculate_interpretability_score(clarity, distinctness, consistency)

    # Évaluer la qualité d'interprétabilité
    quality = evaluate_interpretability_quality(interpretability_score)

    return {
        "mode_info": mode_info,
        "clarity": clarity,
        "distinctness": distinctness,
        "consistency": consistency,
        "interpretability_score": interpretability_score,
        "quality": quality
    }


def compare_binning_strategies_interpretability(data: np.ndarray,
                                              strategies: Optional[List[str]] = None,
                                              num_bins: int = 20,
                                              prominence_threshold: float = DEFAULT_PROMINENCE) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes d'interprétabilité des modes.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        prominence_threshold: Seuil de proéminence pour la détection des modes

    Returns:
        Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    # Détecter les modes dans les données originales avec un grand nombre de bins
    reference_bins = min(len(data) // 10, 1000)  # Limiter à 1000 bins maximum
    reference_bin_edges = np.linspace(min(data), max(data), reference_bins + 1)
    reference_bin_counts, _ = np.histogram(data, bins=reference_bin_edges)
    reference_mode_info = detect_modes(data, reference_bin_edges, reference_bin_counts, prominence_threshold)

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

        # Évaluer l'interprétabilité des modes
        evaluation = evaluate_histogram_interpretability(data, bin_edges, bin_counts, reference_mode_info, prominence_threshold)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "mode_info": evaluation["mode_info"],
            "clarity": evaluation["clarity"],
            "distinctness": evaluation["distinctness"],
            "consistency": evaluation["consistency"],
            "interpretability_score": evaluation["interpretability_score"],
            "quality": evaluation["quality"]
        }

    return results


def find_optimal_binning_strategy_interpretability(data: np.ndarray,
                                                 strategies: Optional[List[str]] = None,
                                                 num_bins_range: Optional[List[int]] = None,
                                                 prominence_threshold: float = DEFAULT_PROMINENCE) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes d'interprétabilité des modes.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins_range: Liste des nombres de bins à tester
        prominence_threshold: Seuil de proéminence pour la détection des modes

    Returns:
        Dict[str, Any]: Résultats de l'optimisation
    """
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]

    if num_bins_range is None:
        num_bins_range = [5, 10, 20, 50, 100]

    # Détecter les modes dans les données originales avec un grand nombre de bins
    reference_bins = min(len(data) // 10, 1000)  # Limiter à 1000 bins maximum
    reference_bin_edges = np.linspace(min(data), max(data), reference_bins + 1)
    reference_bin_counts, _ = np.histogram(data, bins=reference_bin_edges)
    reference_mode_info = detect_modes(data, reference_bin_edges, reference_bin_counts, prominence_threshold)

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

            # Évaluer l'interprétabilité des modes
            evaluation = evaluate_histogram_interpretability(data, bin_edges, bin_counts, reference_mode_info, prominence_threshold)

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "mode_info": evaluation["mode_info"],
                "clarity": evaluation["clarity"],
                "distinctness": evaluation["distinctness"],
                "consistency": evaluation["consistency"],
                "interpretability_score": evaluation["interpretability_score"],
                "quality": evaluation["quality"]
            }

            # Mettre à jour la meilleure stratégie
            if evaluation["interpretability_score"] > best_score:
                best_score = evaluation["interpretability_score"]
                best_strategy = strategy
                best_num_bins = num_bins
                best_metrics = evaluation

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

    # Tester les métriques d'interprétabilité des modes
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Détecter les modes dans la distribution
        mode_info = detect_modes(data)

        print(f"Nombre de modes détectés: {mode_info['num_modes']}")
        if mode_info['num_modes'] > 0:
            print(f"Positions des modes: {mode_info['mode_positions']}")
            print(f"Hauteurs des modes: {mode_info['mode_heights']}")
            print(f"Proéminences des modes: {mode_info['mode_prominences']}")
            print(f"Largeurs des modes: {mode_info['mode_widths']}")

        # Calculer les scores d'interprétabilité
        clarity = calculate_mode_clarity(mode_info)
        distinctness = calculate_mode_distinctness(mode_info)

        print(f"\nScore de clarté: {clarity:.4f}")
        print(f"Score de distinctivité: {distinctness:.4f}")

        # Calculer le score global d'interprétabilité
        interpretability_score = calculate_interpretability_score(clarity, distinctness)
        quality = evaluate_interpretability_quality(interpretability_score)

        print(f"Score d'interprétabilité: {interpretability_score:.4f}")
        print(f"Qualité: {quality}")

        # Comparer différentes stratégies de binning
        print("\nComparaison des stratégies de binning:")
        results = compare_binning_strategies_interpretability(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Nombre de modes: {result['mode_info']['num_modes']}")
            print(f"Score de clarté: {result['clarity']:.4f}")
            print(f"Score de distinctivité: {result['distinctness']:.4f}")
            print(f"Score de cohérence: {result['consistency']:.4f}")
            print(f"Score d'interprétabilité: {result['interpretability_score']:.4f}")
            print(f"Qualité: {result['quality']}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_interpretability(data, num_bins_range=[5, 10, 20, 50])

        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Score optimal: {optimization['best_score']:.4f}")
        print(f"Qualité: {optimization['best_quality']}")
