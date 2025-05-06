#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques de conservation de la multimodalité pour évaluer
la qualité des histogrammes et des représentations de distributions.

Ce module fournit des fonctions pour détecter les modes dans une distribution et
mesurer à quel point ces modes sont préservés dans une représentation simplifiée.
"""

import numpy as np
import scipy.stats
import scipy.signal
from typing import Dict, List, Tuple, Union, Optional, Any, Callable, TypeVar

T = TypeVar('T')  # Type générique pour les annotations

# Constantes pour les paramètres par défaut
DEFAULT_KDE_BANDWIDTH = 'scott'  # Méthode de Scott pour la largeur de bande KDE
DEFAULT_MODE_PROMINENCE = 0.05   # Proéminence minimale pour qu'un pic soit considéré comme un mode
DEFAULT_MODE_WIDTH = 0.1         # Largeur minimale pour qu'un pic soit considéré comme un mode
DEFAULT_MODE_HEIGHT = 0.1        # Hauteur minimale pour qu'un pic soit considéré comme un mode


def detect_modes(data: np.ndarray,
                kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                mode_prominence: float = DEFAULT_MODE_PROMINENCE,
                mode_width: float = DEFAULT_MODE_WIDTH,
                mode_height: float = DEFAULT_MODE_HEIGHT,
                grid_points: int = 1000) -> Dict[str, Any]:
    """
    Détecte les modes dans une distribution en utilisant l'estimation par noyau
    de la densité (KDE) et la détection de pics.

    Args:
        data: Données d'entrée
        kde_bandwidth: Largeur de bande pour l'estimation KDE ('scott', 'silverman' ou valeur numérique)
        mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
        mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
        mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
        grid_points: Nombre de points pour la grille d'évaluation KDE

    Returns:
        Dict[str, Any]: Informations sur les modes détectés
    """
    # Créer une grille pour l'évaluation KDE
    x_min, x_max = np.min(data), np.max(data)
    x_range = x_max - x_min
    x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, grid_points)

    # Estimer la densité avec KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=kde_bandwidth)
    density = kde(x_grid)

    # Normaliser la densité pour que son maximum soit 1
    density_normalized = density / np.max(density)

    # Détecter les pics (modes) dans la densité
    peaks, properties = scipy.signal.find_peaks(
        density_normalized,
        prominence=mode_prominence,
        width=mode_width * grid_points / (x_range * 1.2),
        height=mode_height
    )

    # Si aucun pic n'est détecté, considérer le maximum global comme un mode
    if len(peaks) == 0:
        max_idx = np.argmax(density_normalized)
        peaks = np.array([max_idx])
        properties = {
            'prominences': np.array([1.0]),
            'widths': np.array([grid_points / 10]),
            'width_heights': np.array([0.5]),
            'left_bases': np.array([0]),
            'right_bases': np.array([grid_points - 1]),
            'peak_heights': np.array([density_normalized[max_idx]])
        }

    # Extraire les informations sur les modes
    modes = []
    for i, peak_idx in enumerate(peaks):
        mode = {
            'position': x_grid[peak_idx],
            'height': properties['peak_heights'][i],
            'prominence': properties['prominences'][i],
            'width': properties['widths'][i] * (x_range * 1.2) / grid_points,
            'left_base': x_grid[int(properties['left_bases'][i])],
            'right_base': x_grid[int(properties['right_bases'][i])],
            'area': properties['widths'][i] * properties['peak_heights'][i] / np.sum(density_normalized)
        }
        modes.append(mode)

    # Trier les modes par position
    modes.sort(key=lambda x: x['position'])

    return {
        'x_grid': x_grid,
        'density': density_normalized,
        'modes': modes,
        'num_modes': len(modes)
    }


def calculate_mode_preservation(original_data: np.ndarray,
                               reconstructed_data: np.ndarray,
                               kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                               mode_prominence: float = DEFAULT_MODE_PROMINENCE,
                               mode_width: float = DEFAULT_MODE_WIDTH,
                               mode_height: float = DEFAULT_MODE_HEIGHT) -> Dict[str, Any]:
    """
    Calcule les métriques de préservation des modes entre les données originales
    et les données reconstruites.

    Args:
        original_data: Données originales
        reconstructed_data: Données reconstruites
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
        mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
        mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode

    Returns:
        Dict[str, Any]: Métriques de préservation des modes
    """
    # Détecter les modes dans les données originales et reconstruites
    original_modes_info = detect_modes(
        original_data, kde_bandwidth, mode_prominence, mode_width, mode_height
    )
    reconstructed_modes_info = detect_modes(
        reconstructed_data, kde_bandwidth, mode_prominence, mode_width, mode_height
    )

    original_modes = original_modes_info['modes']
    reconstructed_modes = reconstructed_modes_info['modes']

    # Calculer les métriques de préservation des modes
    num_original_modes = len(original_modes)
    num_reconstructed_modes = len(reconstructed_modes)

    # Calculer le ratio de préservation du nombre de modes
    if num_original_modes == 0:
        mode_count_ratio = 1.0 if num_reconstructed_modes == 0 else 0.0
    else:
        mode_count_ratio = min(1.0, num_reconstructed_modes / num_original_modes)

    # Si les deux distributions ont le même nombre de modes, calculer les métriques détaillées
    mode_position_errors = []
    mode_height_errors = []
    mode_width_errors = []
    mode_area_errors = []

    if num_original_modes == num_reconstructed_modes and num_original_modes > 0:
        for i in range(num_original_modes):
            orig_mode = original_modes[i]
            recon_mode = reconstructed_modes[i]

            # Erreur de position (normalisée par la plage des données)
            data_range = np.max(original_data) - np.min(original_data)
            position_error = abs(orig_mode['position'] - recon_mode['position']) / data_range
            mode_position_errors.append(position_error)

            # Erreur de hauteur
            height_error = abs(orig_mode['height'] - recon_mode['height']) / orig_mode['height']
            mode_height_errors.append(height_error)

            # Erreur de largeur
            width_error = abs(orig_mode['width'] - recon_mode['width']) / orig_mode['width']
            mode_width_errors.append(width_error)

            # Erreur d'aire
            area_error = abs(orig_mode['area'] - recon_mode['area']) / orig_mode['area']
            mode_area_errors.append(area_error)

    # Calculer les métriques agrégées
    metrics = {
        'original_num_modes': num_original_modes,
        'reconstructed_num_modes': num_reconstructed_modes,
        'mode_count_ratio': mode_count_ratio,
        'mode_count_preserved': num_original_modes == num_reconstructed_modes
    }

    # Ajouter les métriques détaillées si les deux distributions ont le même nombre de modes
    if num_original_modes == num_reconstructed_modes and num_original_modes > 0:
        metrics.update({
            'mean_position_error': np.mean(mode_position_errors),
            'max_position_error': np.max(mode_position_errors) if mode_position_errors else 0,
            'mean_height_error': np.mean(mode_height_errors),
            'max_height_error': np.max(mode_height_errors) if mode_height_errors else 0,
            'mean_width_error': np.mean(mode_width_errors),
            'max_width_error': np.max(mode_width_errors) if mode_width_errors else 0,
            'mean_area_error': np.mean(mode_area_errors),
            'max_area_error': np.max(mode_area_errors) if mode_area_errors else 0
        })

    # Ajouter les informations sur les modes
    metrics['original_modes'] = original_modes
    metrics['reconstructed_modes'] = reconstructed_modes

    return metrics


def calculate_multimodality_preservation_score(original_data: np.ndarray,
                                             reconstructed_data: np.ndarray,
                                             kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                             mode_prominence: float = DEFAULT_MODE_PROMINENCE,
                                             mode_width: float = DEFAULT_MODE_WIDTH,
                                             mode_height: float = DEFAULT_MODE_HEIGHT,
                                             weights: Optional[Dict[str, float]] = None) -> float:
    """
    Calcule un score global de préservation de la multimodalité entre 0 et 1.

    Args:
        original_data: Données originales
        reconstructed_data: Données reconstruites
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
        mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
        mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
        weights: Poids pour les différentes composantes du score

    Returns:
        float: Score de préservation de la multimodalité (0-1)
    """
    # Calculer les métriques de préservation des modes
    metrics = calculate_mode_preservation(
        original_data, reconstructed_data,
        kde_bandwidth, mode_prominence, mode_width, mode_height
    )

    # Définir les poids par défaut si non spécifiés
    if weights is None:
        weights = {
            'mode_count': 0.4,
            'position': 0.3,
            'height': 0.15,
            'width': 0.15
        }

    # Initialiser le score avec le ratio de préservation du nombre de modes
    score = weights['mode_count'] * metrics['mode_count_ratio']

    # Si les deux distributions ont le même nombre de modes, ajouter les autres composantes
    if metrics['mode_count_preserved'] and metrics['original_num_modes'] > 0:
        # Composante de position (1 - erreur moyenne de position)
        position_score = 1.0 - min(1.0, metrics['mean_position_error'])
        score += weights['position'] * position_score

        # Composante de hauteur (1 - erreur moyenne de hauteur)
        height_score = 1.0 - min(1.0, metrics['mean_height_error'])
        score += weights['height'] * height_score

        # Composante de largeur (1 - erreur moyenne de largeur)
        width_score = 1.0 - min(1.0, metrics['mean_width_error'])
        score += weights['width'] * width_score

    # Normaliser le score entre 0 et 1
    return max(0.0, min(1.0, score))


def evaluate_multimodality_preservation_quality(score: float) -> str:
    """
    Évalue la qualité de préservation de la multimodalité en fonction du score.

    Args:
        score: Score de préservation de la multimodalité (0-1)

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


def compare_binning_strategies_multimodality_preservation(data: np.ndarray,
                                                        strategies: Optional[List[str]] = None,
                                                        num_bins: int = 20,
                                                        kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                                        mode_prominence: float = DEFAULT_MODE_PROMINENCE,
                                                        mode_width: float = DEFAULT_MODE_WIDTH,
                                                        mode_height: float = DEFAULT_MODE_HEIGHT) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de préservation de la multimodalité.

    Args:
        data: Données originales
        strategies: Liste des stratégies de binning à comparer
        num_bins: Nombre de bins pour les histogrammes
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
        mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
        mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode

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

        # Calculer les métriques de préservation de la multimodalité
        metrics = calculate_mode_preservation(
            data, reconstructed_data,
            kde_bandwidth, mode_prominence, mode_width, mode_height
        )

        # Calculer le score de préservation de la multimodalité
        score = calculate_multimodality_preservation_score(
            data, reconstructed_data,
            kde_bandwidth, mode_prominence, mode_width, mode_height
        )

        # Évaluer la qualité de préservation
        quality = evaluate_multimodality_preservation_quality(score)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "metrics": metrics,
            "score": score,
            "quality": quality
        }

    return results


def find_optimal_bin_count_for_multimodality_preservation(data: np.ndarray,
                                                        strategy: str = "uniform",
                                                        min_bins: int = 5,
                                                        max_bins: int = 100,
                                                        step: int = 5,
                                                        kde_bandwidth: Union[str, float] = DEFAULT_KDE_BANDWIDTH,
                                                        mode_prominence: float = DEFAULT_MODE_PROMINENCE,
                                                        mode_width: float = DEFAULT_MODE_WIDTH,
                                                        mode_height: float = DEFAULT_MODE_HEIGHT,
                                                        target_score: float = 0.9) -> Dict[str, Any]:
    """
    Trouve le nombre optimal de bins pour préserver la multimodalité.

    Args:
        data: Données originales
        strategy: Stratégie de binning
        min_bins: Nombre minimum de bins à tester
        max_bins: Nombre maximum de bins à tester
        step: Pas d'incrémentation du nombre de bins
        kde_bandwidth: Largeur de bande pour l'estimation KDE
        mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
        mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
        mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
        target_score: Score cible de préservation de la multimodalité

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

        # Reconstruire les données à partir de l'histogramme
        reconstructed_data = []
        for i in range(len(bin_counts)):
            bin_count = bin_counts[i]
            bin_start = bin_edges[i]
            bin_end = bin_edges[i + 1]

            # Répartir uniformément les points dans le bin
            if bin_count > 0:
                step_size = (bin_end - bin_start) / bin_count
                bin_data = [bin_start + step_size * (j + 0.5) for j in range(bin_count)]
                reconstructed_data.extend(bin_data)

        reconstructed_data = np.array(reconstructed_data)

        # Calculer le score de préservation de la multimodalité
        score = calculate_multimodality_preservation_score(
            data, reconstructed_data,
            kde_bandwidth, mode_prominence, mode_width, mode_height
        )

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
        ]),
        "trimodal": np.concatenate([
            np.random.normal(loc=50, scale=8, size=300),
            np.random.normal(loc=100, scale=10, size=400),
            np.random.normal(loc=150, scale=12, size=300)
        ])
    }

    # Tester les métriques de préservation de la multimodalité
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Détecter les modes dans la distribution originale
        modes_info = detect_modes(data)
        print(f"Nombre de modes détectés: {modes_info['num_modes']}")
        for i, mode in enumerate(modes_info['modes']):
            print(f"  Mode {i+1}: position={mode['position']:.2f}, hauteur={mode['height']:.2f}, largeur={mode['width']:.2f}")

        # Comparer différentes stratégies de binning
        results = compare_binning_strategies_multimodality_preservation(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Score de préservation de la multimodalité: {result['score']:.4f}")
            print(f"Qualité: {result['quality']}")

            metrics = result['metrics']
            print(f"Nombre de modes originaux: {metrics['original_num_modes']}")
            print(f"Nombre de modes reconstruits: {metrics['reconstructed_num_modes']}")

            if metrics['mode_count_preserved'] and metrics['original_num_modes'] > 0:
                print(f"Erreur moyenne de position: {metrics['mean_position_error']:.4f}")
                print(f"Erreur moyenne de hauteur: {metrics['mean_height_error']:.4f}")
                print(f"Erreur moyenne de largeur: {metrics['mean_width_error']:.4f}")

        # Trouver le nombre optimal de bins
        print("\nRecherche du nombre optimal de bins:")
        for strategy in ["uniform", "quantile", "logarithmic"]:
            optimization = find_optimal_bin_count_for_multimodality_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            print(f"  {strategy}: {optimization['optimal_bins']} bins (score: {optimization['best_score']:.4f})")
