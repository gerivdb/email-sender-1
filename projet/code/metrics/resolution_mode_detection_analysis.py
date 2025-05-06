#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour analyser l'effet de la résolution sur la détection des modes.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, Optional, Any, Union, List, Tuple
from scipy.signal import find_peaks, peak_widths
import scipy.stats

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def create_synthetic_distribution(distribution_type: str,
                                mode_params: List[Dict[str, float]],
                                num_samples: int = 1000,
                                random_seed: Optional[int] = None) -> Tuple[np.ndarray, Dict[str, Any]]:
    """
    Crée une distribution synthétique avec des modes connus.

    Args:
        distribution_type: Type de distribution ('gaussian', 'lognormal', 'gamma', 'mixture')
        mode_params: Liste de dictionnaires contenant les paramètres des modes
        num_samples: Nombre d'échantillons à générer
        random_seed: Graine pour le générateur de nombres aléatoires

    Returns:
        Tuple[np.ndarray, Dict[str, Any]]: Données générées et métadonnées
    """
    # Initialiser le générateur de nombres aléatoires
    if random_seed is not None:
        np.random.seed(random_seed)

    # Métadonnées pour stocker les informations sur les modes
    metadata = {
        "distribution_type": distribution_type,
        "mode_params": mode_params,
        "num_samples": num_samples,
        "true_modes": []
    }

    if distribution_type == 'gaussian':
        # Vérifier qu'il y a au moins un mode
        if len(mode_params) == 0:
            raise ValueError("Au moins un mode doit être spécifié")

        # Extraire les paramètres du mode
        mu = mode_params[0].get('mu', 0)
        sigma = mode_params[0].get('sigma', 1)

        # Générer les données
        data = np.random.normal(loc=mu, scale=sigma, size=num_samples)

        # Stocker les informations sur le mode
        metadata["true_modes"].append({
            "position": mu,
            "height": 1.0 / (sigma * np.sqrt(2 * np.pi)),
            "width": 2 * sigma
        })

    elif distribution_type == 'lognormal':
        # Vérifier qu'il y a au moins un mode
        if len(mode_params) == 0:
            raise ValueError("Au moins un mode doit être spécifié")

        # Extraire les paramètres du mode
        mu = mode_params[0].get('mu', 0)
        sigma = mode_params[0].get('sigma', 0.5)

        # Générer les données
        data = np.random.lognormal(mean=mu, sigma=sigma, size=num_samples)

        # Calculer la position du mode
        mode_position = np.exp(mu - sigma**2)

        # Calculer la hauteur du mode
        mode_height = 1.0 / (mode_position * sigma * np.sqrt(2 * np.pi))

        # Stocker les informations sur le mode
        metadata["true_modes"].append({
            "position": mode_position,
            "height": mode_height,
            "width": 2 * sigma * mode_position
        })

    elif distribution_type == 'gamma':
        # Vérifier qu'il y a au moins un mode
        if len(mode_params) == 0:
            raise ValueError("Au moins un mode doit être spécifié")

        # Extraire les paramètres du mode
        k = mode_params[0].get('k', 2)  # Paramètre de forme
        theta = mode_params[0].get('theta', 2)  # Paramètre d'échelle

        # Générer les données
        data = np.random.gamma(shape=k, scale=theta, size=num_samples)

        # Calculer la position du mode
        mode_position = (k - 1) * theta if k >= 1 else 0

        # Calculer la hauteur du mode (approximation)
        mode_height = scipy.stats.gamma.pdf(mode_position, a=k, scale=theta)

        # Stocker les informations sur le mode
        metadata["true_modes"].append({
            "position": mode_position,
            "height": mode_height,
            "width": 2 * np.sqrt(k) * theta
        })

    elif distribution_type == 'mixture':
        # Vérifier qu'il y a au moins un mode
        if len(mode_params) == 0:
            raise ValueError("Au moins un mode doit être spécifié")

        # Initialiser les données
        data = np.array([])

        # Pour chaque mode, générer les données correspondantes
        for i, params in enumerate(mode_params):
            # Extraire les paramètres du mode
            mu = params.get('mu', 0)
            sigma = params.get('sigma', 1)
            weight = params.get('weight', 1)

            # Normaliser les poids
            total_weight = sum(p.get('weight', 1) for p in mode_params)
            normalized_weight = weight / total_weight

            # Calculer le nombre d'échantillons pour ce mode
            num_samples_mode = int(num_samples * normalized_weight)

            # Générer les données pour ce mode
            mode_data = np.random.normal(loc=mu, scale=sigma, size=num_samples_mode)

            # Ajouter les données à l'ensemble
            data = np.concatenate([data, mode_data])

            # Stocker les informations sur le mode
            metadata["true_modes"].append({
                "position": mu,
                "height": normalized_weight / (sigma * np.sqrt(2 * np.pi)),
                "width": 2 * sigma
            })

        # Ajuster le nombre d'échantillons si nécessaire
        if len(data) != num_samples:
            # Tronquer ou compléter les données
            if len(data) > num_samples:
                data = data[:num_samples]
            else:
                # Compléter avec des échantillons aléatoires
                additional_samples = np.random.choice(data, size=num_samples - len(data))
                data = np.concatenate([data, additional_samples])

    else:
        raise ValueError(f"Type de distribution inconnu: {distribution_type}")

    # Mélanger les données
    np.random.shuffle(data)

    return data, metadata

def create_multimodal_distribution(mode_positions: List[float],
                                 mode_widths: List[float],
                                 mode_heights: Optional[List[float]] = None,
                                 num_samples: int = 1000,
                                 random_seed: Optional[int] = None) -> Tuple[np.ndarray, Dict[str, Any]]:
    """
    Crée une distribution multimodale avec des positions, largeurs et hauteurs spécifiées.

    Args:
        mode_positions: Positions des modes
        mode_widths: Largeurs des modes (écarts-types pour les gaussiennes)
        mode_heights: Hauteurs relatives des modes (poids)
        num_samples: Nombre d'échantillons à générer
        random_seed: Graine pour le générateur de nombres aléatoires

    Returns:
        Tuple[np.ndarray, Dict[str, Any]]: Données générées et métadonnées
    """
    # Vérifier que les listes ont la même longueur
    if len(mode_positions) != len(mode_widths):
        raise ValueError("Les listes mode_positions et mode_widths doivent avoir la même longueur")

    # Si les hauteurs ne sont pas spécifiées, utiliser des hauteurs égales
    if mode_heights is None:
        mode_heights = [1.0] * len(mode_positions)
    elif len(mode_heights) != len(mode_positions):
        raise ValueError("La liste mode_heights doit avoir la même longueur que mode_positions")

    # Normaliser les hauteurs
    total_height = sum(mode_heights)
    normalized_heights = [h / total_height for h in mode_heights]

    # Créer les paramètres des modes
    mode_params = []
    for pos, width, height in zip(mode_positions, mode_widths, normalized_heights):
        mode_params.append({
            'mu': pos,
            'sigma': width / 2,  # Diviser par 2 car width est la largeur totale (2*sigma)
            'weight': height
        })

    # Créer la distribution
    return create_synthetic_distribution('mixture', mode_params, num_samples, random_seed)

def create_bimodal_with_varying_separation(base_position: float = 50,
                                         separation_factors: List[float] = [0.5, 1.0, 2.0, 4.0],
                                         width: float = 10,
                                         num_samples: int = 1000,
                                         random_seed: Optional[int] = None) -> Dict[str, Tuple[np.ndarray, Dict[str, Any]]]:
    """
    Crée plusieurs distributions bimodales avec des séparations variables entre les modes.

    Args:
        base_position: Position de base pour le premier mode
        separation_factors: Facteurs de séparation entre les modes (en multiples de la largeur)
        width: Largeur des modes
        num_samples: Nombre d'échantillons à générer pour chaque distribution
        random_seed: Graine pour le générateur de nombres aléatoires

    Returns:
        Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et métadonnées
    """
    # Initialiser le dictionnaire de résultats
    results = {}

    # Pour chaque facteur de séparation
    for factor in separation_factors:
        # Calculer la séparation
        separation = factor * width

        # Calculer les positions des modes
        pos1 = base_position - separation / 2
        pos2 = base_position + separation / 2

        # Créer la distribution
        data, metadata = create_multimodal_distribution(
            mode_positions=[pos1, pos2],
            mode_widths=[width, width],
            mode_heights=[1.0, 1.0],
            num_samples=num_samples,
            random_seed=random_seed
        )

        # Ajouter au dictionnaire de résultats
        results[f"separation_{factor:.1f}"] = (data, metadata)

    return results

def create_multimodal_with_varying_heights(positions: List[float],
                                         width: float = 10,
                                         height_ratios: List[List[float]] = [[1, 1], [1, 2], [1, 5], [1, 10]],
                                         num_samples: int = 1000,
                                         random_seed: Optional[int] = None) -> Dict[str, Tuple[np.ndarray, Dict[str, Any]]]:
    """
    Crée plusieurs distributions multimodales avec des hauteurs relatives variables.

    Args:
        positions: Positions des modes
        width: Largeur des modes
        height_ratios: Liste de listes de ratios de hauteurs pour chaque distribution
        num_samples: Nombre d'échantillons à générer pour chaque distribution
        random_seed: Graine pour le générateur de nombres aléatoires

    Returns:
        Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et métadonnées
    """
    # Initialiser le dictionnaire de résultats
    results = {}

    # Pour chaque ratio de hauteurs
    for i, ratios in enumerate(height_ratios):
        # Vérifier que le nombre de ratios correspond au nombre de positions
        if len(ratios) != len(positions):
            raise ValueError(f"Le nombre de ratios ({len(ratios)}) doit être égal au nombre de positions ({len(positions)})")

        # Créer la distribution
        data, metadata = create_multimodal_distribution(
            mode_positions=positions,
            mode_widths=[width] * len(positions),
            mode_heights=ratios,
            num_samples=num_samples,
            random_seed=random_seed
        )

        # Ajouter au dictionnaire de résultats
        ratio_str = "_".join([f"{r:.1f}" for r in ratios])
        results[f"heights_{ratio_str}"] = (data, metadata)

    return results

def create_multimodal_with_varying_widths(positions: List[float],
                                        base_width: float = 10,
                                        width_factors: List[List[float]] = [[1, 1], [1, 2], [1, 5], [1, 0.5]],
                                        num_samples: int = 1000,
                                        random_seed: Optional[int] = None) -> Dict[str, Tuple[np.ndarray, Dict[str, Any]]]:
    """
    Crée plusieurs distributions multimodales avec des largeurs variables.

    Args:
        positions: Positions des modes
        base_width: Largeur de base des modes
        width_factors: Liste de listes de facteurs de largeur pour chaque distribution
        num_samples: Nombre d'échantillons à générer pour chaque distribution
        random_seed: Graine pour le générateur de nombres aléatoires

    Returns:
        Dict[str, Tuple[np.ndarray, Dict[str, Any]]]: Dictionnaire de distributions et métadonnées
    """
    # Initialiser le dictionnaire de résultats
    results = {}

    # Pour chaque facteur de largeur
    for i, factors in enumerate(width_factors):
        # Vérifier que le nombre de facteurs correspond au nombre de positions
        if len(factors) != len(positions):
            raise ValueError(f"Le nombre de facteurs ({len(factors)}) doit être égal au nombre de positions ({len(positions)})")

        # Calculer les largeurs
        widths = [base_width * factor for factor in factors]

        # Créer la distribution
        data, metadata = create_multimodal_distribution(
            mode_positions=positions,
            mode_widths=widths,
            mode_heights=[1.0] * len(positions),
            num_samples=num_samples,
            random_seed=random_seed
        )

        # Ajouter au dictionnaire de résultats
        factor_str = "_".join([f"{f:.1f}" for f in factors])
        results[f"widths_{factor_str}"] = (data, metadata)

    return results

def plot_synthetic_distribution(data: np.ndarray,
                              metadata: Dict[str, Any],
                              num_bins: int = 50,
                              title: Optional[str] = None,
                              save_path: Optional[str] = None,
                              show_plot: bool = True) -> None:
    """
    Visualise une distribution synthétique avec ses modes connus.

    Args:
        data: Données de la distribution
        metadata: Métadonnées de la distribution
        num_bins: Nombre de bins pour l'histogramme
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(10, 6))

    # Calculer l'histogramme
    hist, bin_edges = np.histogram(data, bins=num_bins, density=True)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Tracer l'histogramme
    ax.bar(bin_centers, hist, width=np.diff(bin_edges), alpha=0.5, color='blue', label='Histogramme')

    # Tracer la densité de probabilité (KDE)
    kde = scipy.stats.gaussian_kde(data)
    x_grid = np.linspace(min(data), max(data), 1000)
    ax.plot(x_grid, kde(x_grid), 'r-', linewidth=2, label='KDE')

    # Tracer les positions des modes connus
    for i, mode in enumerate(metadata["true_modes"]):
        ax.axvline(x=mode["position"], color='green', linestyle='--', linewidth=2,
                  label=f'Mode {i+1}' if i == 0 else None)

        # Ajouter une annotation
        ax.text(mode["position"], 0.9 * ax.get_ylim()[1], f'Mode {i+1}',
               ha='center', va='top', fontsize=10,
               bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    # Configurer le graphique
    if title is None:
        title = f"Distribution {metadata['distribution_type']} avec {len(metadata['true_modes'])} modes"
    ax.set_title(title)
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Densité de probabilité')
    ax.legend()
    ax.grid(True, alpha=0.3)

    # Ajouter des informations sur les modes
    mode_info = []
    for i, mode in enumerate(metadata["true_modes"]):
        mode_info.append(f"Mode {i+1}: pos={mode['position']:.2f}, width={mode['width']:.2f}")

    plt.figtext(0.5, 0.01, ", ".join(mode_info), ha='center', fontsize=10)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0.03, 1, 0.97))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def detect_modes_from_histogram(hist_counts: np.ndarray,
                            bin_edges: np.ndarray,
                            height_threshold: float = 0.1,
                            distance: Optional[int] = None,
                            prominence: Optional[float] = None,
                            width: Optional[int] = None) -> Dict[str, Any]:
    """
    Détecte les modes dans un histogramme.

    Args:
        hist_counts: Comptages des bins de l'histogramme
        bin_edges: Limites des bins de l'histogramme
        height_threshold: Seuil relatif de hauteur pour la détection des pics (fraction du maximum)
        distance: Distance minimale entre les pics (en nombre de bins)
        prominence: Proéminence minimale des pics
        width: Largeur minimale des pics

    Returns:
        Dict[str, Any]: Informations sur les modes détectés
    """
    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Normaliser l'histogramme si nécessaire
    if np.max(hist_counts) > 0:
        hist_normalized = hist_counts / np.max(hist_counts)
    else:
        hist_normalized = hist_counts

    # Calculer le seuil absolu de hauteur
    height = height_threshold * np.max(hist_normalized)

    # Si distance n'est pas spécifiée, utiliser 1/10 du nombre de bins
    if distance is None:
        distance = max(1, len(hist_counts) // 10)

    # Détecter les pics
    peaks, properties = find_peaks(
        hist_normalized,
        height=height,
        distance=distance,
        prominence=prominence,
        width=width
    )

    # Si aucun pic n'est détecté, retourner un résultat vide
    if len(peaks) == 0:
        return {
            "num_modes": 0,
            "mode_positions": np.array([]),
            "mode_heights": np.array([]),
            "mode_widths": np.array([]),
            "bin_centers": bin_centers,
            "hist_counts": hist_counts
        }

    # Calculer les largeurs des pics
    widths_result = peak_widths(hist_normalized, peaks, rel_height=0.5)
    widths = widths_result[0]

    # Convertir les indices des pics en positions
    mode_positions = bin_centers[peaks]

    # Obtenir les hauteurs des pics
    mode_heights = hist_normalized[peaks]

    # Calculer les largeurs des pics en unités de la variable
    width_indices = widths
    mode_widths = width_indices * (bin_edges[1] - bin_edges[0])

    # Résultats
    return {
        "num_modes": len(peaks),
        "mode_positions": mode_positions,
        "mode_heights": mode_heights,
        "mode_widths": mode_widths,
        "peak_indices": peaks,
        "bin_centers": bin_centers,
        "hist_counts": hist_counts
    }

def detect_modes_from_kde(data: np.ndarray,
                        num_points: int = 1000,
                        height_threshold: float = 0.1,
                        distance_factor: float = 0.05,
                        prominence: Optional[float] = None,
                        width: Optional[int] = None,
                        bandwidth_method: str = 'scott') -> Dict[str, Any]:
    """
    Détecte les modes dans une distribution en utilisant l'estimation par noyau de la densité (KDE).

    Args:
        data: Données de la distribution
        num_points: Nombre de points pour l'évaluation de la KDE
        height_threshold: Seuil relatif de hauteur pour la détection des pics (fraction du maximum)
        distance_factor: Facteur pour calculer la distance minimale entre les pics (fraction de la plage des données)
        prominence: Proéminence minimale des pics
        width: Largeur minimale des pics
        bandwidth_method: Méthode pour estimer la largeur de bande de la KDE

    Returns:
        Dict[str, Any]: Informations sur les modes détectés
    """
    # Calculer la KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=bandwidth_method)

    # Créer une grille de points pour évaluer la KDE
    x_min, x_max = np.min(data), np.max(data)
    x_grid = np.linspace(x_min, x_max, num_points)

    # Évaluer la KDE sur la grille
    kde_values = kde(x_grid)

    # Normaliser les valeurs de la KDE
    if np.max(kde_values) > 0:
        kde_normalized = kde_values / np.max(kde_values)
    else:
        kde_normalized = kde_values

    # Calculer le seuil absolu de hauteur
    height = height_threshold * np.max(kde_normalized)

    # Calculer la distance minimale entre les pics
    distance = int(distance_factor * num_points)

    # Détecter les pics
    peaks, properties = find_peaks(
        kde_normalized,
        height=height,
        distance=distance,
        prominence=prominence,
        width=width
    )

    # Si aucun pic n'est détecté, retourner un résultat vide
    if len(peaks) == 0:
        return {
            "num_modes": 0,
            "mode_positions": np.array([]),
            "mode_heights": np.array([]),
            "mode_widths": np.array([]),
            "x_grid": x_grid,
            "kde_values": kde_values
        }

    # Calculer les largeurs des pics
    widths_result = peak_widths(kde_normalized, peaks, rel_height=0.5)
    widths = widths_result[0]

    # Convertir les indices des pics en positions
    mode_positions = x_grid[peaks]

    # Obtenir les hauteurs des pics
    mode_heights = kde_normalized[peaks]

    # Calculer les largeurs des pics en unités de la variable
    width_indices = widths
    grid_spacing = (x_max - x_min) / (num_points - 1)
    mode_widths = width_indices * grid_spacing

    # Résultats
    return {
        "num_modes": len(peaks),
        "mode_positions": mode_positions,
        "mode_heights": mode_heights,
        "mode_widths": mode_widths,
        "peak_indices": peaks,
        "x_grid": x_grid,
        "kde_values": kde_values
    }

def analyze_mode_detection_vs_resolution(data: np.ndarray,
                                       metadata: Dict[str, Any],
                                       bin_counts: List[int] = [10, 20, 50, 100, 200],
                                       kde_points: List[int] = [100, 200, 500, 1000, 2000],
                                       height_threshold: float = 0.1,
                                       save_path: Optional[str] = None,
                                       show_plot: bool = True) -> Dict[str, Any]:
    """
    Analyse l'effet de la résolution sur la détection des modes.

    Args:
        data: Données de la distribution
        metadata: Métadonnées de la distribution
        bin_counts: Liste des nombres de bins à tester pour l'histogramme
        kde_points: Liste des nombres de points à tester pour la KDE
        height_threshold: Seuil relatif de hauteur pour la détection des pics
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure

    Returns:
        Dict[str, Any]: Résultats de l'analyse
    """
    # Initialiser les résultats
    results = {
        "histogram": {
            "bin_counts": bin_counts,
            "num_modes": [],
            "mode_positions": [],
            "mode_heights": [],
            "mode_widths": [],
            "position_errors": [],
            "detection_rate": []
        },
        "kde": {
            "num_points": kde_points,
            "num_modes": [],
            "mode_positions": [],
            "mode_heights": [],
            "mode_widths": [],
            "position_errors": [],
            "detection_rate": []
        },
        "true_modes": metadata["true_modes"]
    }

    # Extraire les positions des modes réels
    true_positions = np.array([mode["position"] for mode in metadata["true_modes"]])

    # Analyser l'effet du nombre de bins sur la détection des modes avec l'histogramme
    for num_bins in bin_counts:
        # Calculer l'histogramme
        hist_counts, bin_edges = np.histogram(data, bins=num_bins, density=True)

        # Détecter les modes
        modes = detect_modes_from_histogram(hist_counts, bin_edges, height_threshold=height_threshold)

        # Stocker les résultats
        results["histogram"]["num_modes"].append(modes["num_modes"])
        results["histogram"]["mode_positions"].append(modes["mode_positions"])
        results["histogram"]["mode_heights"].append(modes["mode_heights"])
        results["histogram"]["mode_widths"].append(modes["mode_widths"])

        # Calculer les erreurs de position des modes détectés par rapport aux modes réels
        if modes["num_modes"] > 0 and len(true_positions) > 0:
            # Pour chaque mode réel, trouver le mode détecté le plus proche
            position_errors = []
            for true_pos in true_positions:
                if len(modes["mode_positions"]) > 0:
                    # Calculer les distances aux modes détectés
                    distances = np.abs(modes["mode_positions"] - true_pos)
                    # Trouver le mode détecté le plus proche
                    min_distance = np.min(distances)
                    position_errors.append(min_distance)
                else:
                    position_errors.append(np.nan)

            results["histogram"]["position_errors"].append(position_errors)

            # Calculer le taux de détection (nombre de modes détectés / nombre de modes réels)
            detection_rate = min(1.0, modes["num_modes"] / len(true_positions))
            results["histogram"]["detection_rate"].append(detection_rate)
        else:
            results["histogram"]["position_errors"].append([np.nan] * len(true_positions))
            results["histogram"]["detection_rate"].append(0.0)

    # Analyser l'effet du nombre de points sur la détection des modes avec la KDE
    for num_points in kde_points:
        # Détecter les modes
        modes = detect_modes_from_kde(data, num_points=num_points, height_threshold=height_threshold)

        # Stocker les résultats
        results["kde"]["num_modes"].append(modes["num_modes"])
        results["kde"]["mode_positions"].append(modes["mode_positions"])
        results["kde"]["mode_heights"].append(modes["mode_heights"])
        results["kde"]["mode_widths"].append(modes["mode_widths"])

        # Calculer les erreurs de position des modes détectés par rapport aux modes réels
        if modes["num_modes"] > 0 and len(true_positions) > 0:
            # Pour chaque mode réel, trouver le mode détecté le plus proche
            position_errors = []
            for true_pos in true_positions:
                if len(modes["mode_positions"]) > 0:
                    # Calculer les distances aux modes détectés
                    distances = np.abs(modes["mode_positions"] - true_pos)
                    # Trouver le mode détecté le plus proche
                    min_distance = np.min(distances)
                    position_errors.append(min_distance)
                else:
                    position_errors.append(np.nan)

            results["kde"]["position_errors"].append(position_errors)

            # Calculer le taux de détection (nombre de modes détectés / nombre de modes réels)
            detection_rate = min(1.0, modes["num_modes"] / len(true_positions))
            results["kde"]["detection_rate"].append(detection_rate)
        else:
            results["kde"]["position_errors"].append([np.nan] * len(true_positions))
            results["kde"]["detection_rate"].append(0.0)

    # Visualiser les résultats
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))

    # Tracer le nombre de modes détectés en fonction de la résolution
    axes[0, 0].plot(bin_counts, results["histogram"]["num_modes"], 'o-', label='Histogramme')
    axes[0, 0].axhline(y=len(true_positions), color='r', linestyle='--', label='Nombre réel de modes')
    axes[0, 0].set_xlabel('Nombre de bins')
    axes[0, 0].set_ylabel('Nombre de modes détectés')
    axes[0, 0].set_title('Nombre de modes détectés (Histogramme)')
    axes[0, 0].legend()
    axes[0, 0].grid(True, alpha=0.3)

    axes[0, 1].plot(kde_points, results["kde"]["num_modes"], 'o-', label='KDE')
    axes[0, 1].axhline(y=len(true_positions), color='r', linestyle='--', label='Nombre réel de modes')
    axes[0, 1].set_xlabel('Nombre de points KDE')
    axes[0, 1].set_ylabel('Nombre de modes détectés')
    axes[0, 1].set_title('Nombre de modes détectés (KDE)')
    axes[0, 1].legend()
    axes[0, 1].grid(True, alpha=0.3)

    # Tracer les erreurs de position des modes en fonction de la résolution
    # Calculer les erreurs moyennes
    hist_mean_errors = []
    for errors in results["histogram"]["position_errors"]:
        if len(errors) > 0 and not all(np.isnan(errors)):
            hist_mean_errors.append(np.nanmean(errors))
        else:
            hist_mean_errors.append(np.nan)

    kde_mean_errors = []
    for errors in results["kde"]["position_errors"]:
        if len(errors) > 0 and not all(np.isnan(errors)):
            kde_mean_errors.append(np.nanmean(errors))
        else:
            kde_mean_errors.append(np.nan)

    axes[1, 0].plot(bin_counts, hist_mean_errors, 'o-', label='Erreur moyenne')
    axes[1, 0].set_xlabel('Nombre de bins')
    axes[1, 0].set_ylabel('Erreur de position moyenne')
    axes[1, 0].set_title('Erreur de position des modes (Histogramme)')
    axes[1, 0].legend()
    axes[1, 0].grid(True, alpha=0.3)

    axes[1, 1].plot(kde_points, kde_mean_errors, 'o-', label='Erreur moyenne')
    axes[1, 1].set_xlabel('Nombre de points KDE')
    axes[1, 1].set_ylabel('Erreur de position moyenne')
    axes[1, 1].set_title('Erreur de position des modes (KDE)')
    axes[1, 1].legend()
    axes[1, 1].grid(True, alpha=0.3)

    # Configurer le titre global
    fig.suptitle(f"Analyse de la détection des modes en fonction de la résolution\n"
                f"Distribution: {metadata['distribution_type']}, {len(true_positions)} modes",
                fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

    return results

def plot_multiple_distributions(distributions: Dict[str, Tuple[np.ndarray, Dict[str, Any]]],
                              num_bins: int = 50,
                              title: str = "Comparaison de distributions synthétiques",
                              save_path: Optional[str] = None,
                              show_plot: bool = True) -> None:
    """
    Visualise plusieurs distributions synthétiques pour comparaison.

    Args:
        distributions: Dictionnaire de distributions et métadonnées
        num_bins: Nombre de bins pour les histogrammes
        title: Titre du graphique
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Déterminer le nombre de distributions
    n = len(distributions)

    # Calculer le nombre de lignes et de colonnes pour les sous-graphiques
    n_cols = min(3, n)
    n_rows = (n + n_cols - 1) // n_cols

    # Créer la figure
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(5 * n_cols, 4 * n_rows))

    # Aplatir les axes si nécessaire
    if n_rows == 1 and n_cols == 1:
        axes = np.array([axes])
    elif n_rows == 1 or n_cols == 1:
        axes = axes.flatten()

    # Pour chaque distribution
    for i, (name, (data, metadata)) in enumerate(distributions.items()):
        # Calculer l'indice du sous-graphique
        row = i // n_cols
        col = i % n_cols

        # Obtenir l'axe correspondant
        if n_rows == 1 and n_cols == 1:
            ax = axes[0]
        elif n_rows == 1 or n_cols == 1:
            ax = axes[i]
        else:
            ax = axes[row, col]

        # Calculer l'histogramme
        hist, bin_edges = np.histogram(data, bins=num_bins, density=True)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

        # Tracer l'histogramme
        ax.bar(bin_centers, hist, width=np.diff(bin_edges), alpha=0.5, color='blue', label='Histogramme')

        # Tracer la densité de probabilité (KDE)
        kde = scipy.stats.gaussian_kde(data)
        x_grid = np.linspace(min(data), max(data), 1000)
        ax.plot(x_grid, kde(x_grid), 'r-', linewidth=2, label='KDE')

        # Tracer les positions des modes connus
        for j, mode in enumerate(metadata["true_modes"]):
            ax.axvline(x=mode["position"], color='green', linestyle='--', linewidth=2,
                      label=f'Mode {j+1}' if j == 0 else None)

        # Configurer le sous-graphique
        ax.set_title(name)
        ax.set_xlabel('Valeur')
        ax.set_ylabel('Densité de probabilité')
        ax.grid(True, alpha=0.3)

        # Ajouter une légende au premier sous-graphique
        if i == 0:
            ax.legend()

    # Masquer les sous-graphiques inutilisés
    for i in range(n, n_rows * n_cols):
        row = i // n_cols
        col = i % n_cols
        if n_rows == 1 and n_cols == 1:
            pass  # Pas de sous-graphiques inutilisés
        elif n_rows == 1 or n_cols == 1:
            axes[i].axis('off')
        else:
            axes[row, col].axis('off')

    # Configurer le titre global
    fig.suptitle(title, fontsize=16)

    # Ajuster la mise en page
    plt.tight_layout(rect=(0, 0, 1, 0.95))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

if __name__ == "__main__":
    # Exemple d'utilisation
    print("=== Analyse de l'effet de la résolution sur la détection des modes ===")

    # Fixer la graine pour la reproductibilité
    np.random.seed(42)

    # Partie 1: Création de distributions synthétiques avec des modes connus
    print("\n=== Partie 1: Création de distributions synthétiques ===")

    # Créer une distribution gaussienne
    print("\nCréation d'une distribution gaussienne...")
    gaussian_data, gaussian_metadata = create_synthetic_distribution(
        distribution_type='gaussian',
        mode_params=[{'mu': 50, 'sigma': 10}],
        num_samples=1000
    )

    # Visualiser la distribution gaussienne
    plot_synthetic_distribution(
        gaussian_data,
        gaussian_metadata,
        num_bins=30,
        title="Distribution gaussienne",
        save_path="synthetic_gaussian.png",
        show_plot=False
    )

    # Créer une distribution bimodale
    print("\nCréation d'une distribution bimodale...")
    bimodal_data, bimodal_metadata = create_synthetic_distribution(
        distribution_type='mixture',
        mode_params=[
            {'mu': 30, 'sigma': 5, 'weight': 1},
            {'mu': 70, 'sigma': 8, 'weight': 1}
        ],
        num_samples=1000
    )

    # Visualiser la distribution bimodale
    plot_synthetic_distribution(
        bimodal_data,
        bimodal_metadata,
        num_bins=30,
        title="Distribution bimodale",
        save_path="synthetic_bimodal.png",
        show_plot=False
    )

    # Créer une distribution trimodale
    print("\nCréation d'une distribution trimodale...")
    trimodal_data, trimodal_metadata = create_synthetic_distribution(
        distribution_type='mixture',
        mode_params=[
            {'mu': 20, 'sigma': 3, 'weight': 1},
            {'mu': 50, 'sigma': 5, 'weight': 2},
            {'mu': 80, 'sigma': 8, 'weight': 1}
        ],
        num_samples=1000
    )

    # Visualiser la distribution trimodale
    plot_synthetic_distribution(
        trimodal_data,
        trimodal_metadata,
        num_bins=30,
        title="Distribution trimodale",
        save_path="synthetic_trimodal.png",
        show_plot=False
    )

    # Créer des distributions bimodales avec des séparations variables
    print("\nCréation de distributions bimodales avec des séparations variables...")
    separation_distributions = create_bimodal_with_varying_separation(
        base_position=50,
        separation_factors=[0.5, 1.0, 2.0, 4.0],
        width=10,
        num_samples=1000
    )

    # Visualiser les distributions avec des séparations variables
    plot_multiple_distributions(
        separation_distributions,
        num_bins=30,
        title="Distributions bimodales avec des séparations variables",
        save_path="synthetic_bimodal_separations.png",
        show_plot=False
    )

    # Partie 2: Analyse de la détection des modes en fonction de la résolution
    print("\n=== Partie 2: Analyse de la détection des modes en fonction de la résolution ===")

    # Analyser l'effet de la résolution sur la détection des modes pour la distribution gaussienne
    print("\nAnalyse de la distribution gaussienne...")
    gaussian_results = analyze_mode_detection_vs_resolution(
        gaussian_data,
        gaussian_metadata,
        bin_counts=[5, 10, 20, 50, 100, 200],
        kde_points=[50, 100, 200, 500, 1000, 2000],
        height_threshold=0.1,
        save_path="resolution_analysis_gaussian.png",
        show_plot=False
    )

    # Analyser l'effet de la résolution sur la détection des modes pour la distribution bimodale
    print("\nAnalyse de la distribution bimodale...")
    bimodal_results = analyze_mode_detection_vs_resolution(
        bimodal_data,
        bimodal_metadata,
        bin_counts=[5, 10, 20, 50, 100, 200],
        kde_points=[50, 100, 200, 500, 1000, 2000],
        height_threshold=0.1,
        save_path="resolution_analysis_bimodal.png",
        show_plot=False
    )

    # Analyser l'effet de la résolution sur la détection des modes pour la distribution trimodale
    print("\nAnalyse de la distribution trimodale...")
    trimodal_results = analyze_mode_detection_vs_resolution(
        trimodal_data,
        trimodal_metadata,
        bin_counts=[5, 10, 20, 50, 100, 200],
        kde_points=[50, 100, 200, 500, 1000, 2000],
        height_threshold=0.1,
        save_path="resolution_analysis_trimodal.png",
        show_plot=False
    )

    # Analyser l'effet de la résolution sur la détection des modes pour les distributions avec séparations variables
    print("\nAnalyse des distributions avec séparations variables...")
    separation_results = {}
    for name, (data, metadata) in separation_distributions.items():
        print(f"  Analyse de {name}...")
        separation_results[name] = analyze_mode_detection_vs_resolution(
            data,
            metadata,
            bin_counts=[5, 10, 20, 50, 100, 200],
            kde_points=[50, 100, 200, 500, 1000, 2000],
            height_threshold=0.1,
            save_path=f"resolution_analysis_{name}.png",
            show_plot=False
        )

    # Afficher un résumé des résultats
    print("\n=== Résumé des résultats ===")

    print("\nDistribution gaussienne:")
    print(f"  Nombre réel de modes: {len(gaussian_metadata['true_modes'])}")
    print(f"  Nombre de modes détectés (histogramme, 50 bins): {gaussian_results['histogram']['num_modes'][2]}")
    print(f"  Nombre de modes détectés (KDE, 500 points): {gaussian_results['kde']['num_modes'][3]}")

    print("\nDistribution bimodale:")
    print(f"  Nombre réel de modes: {len(bimodal_metadata['true_modes'])}")
    print(f"  Nombre de modes détectés (histogramme, 50 bins): {bimodal_results['histogram']['num_modes'][2]}")
    print(f"  Nombre de modes détectés (KDE, 500 points): {bimodal_results['kde']['num_modes'][3]}")

    print("\nDistribution trimodale:")
    print(f"  Nombre réel de modes: {len(trimodal_metadata['true_modes'])}")
    print(f"  Nombre de modes détectés (histogramme, 50 bins): {trimodal_results['histogram']['num_modes'][2]}")
    print(f"  Nombre de modes détectés (KDE, 500 points): {trimodal_results['kde']['num_modes'][3]}")

    print("\nDistributions avec séparations variables:")
    for name, results in separation_results.items():
        data, metadata = separation_distributions[name]
        print(f"  {name}:")
        print(f"    Nombre réel de modes: {len(metadata['true_modes'])}")
        print(f"    Nombre de modes détectés (histogramme, 50 bins): {results['histogram']['num_modes'][2]}")
        print(f"    Nombre de modes détectés (KDE, 500 points): {results['kde']['num_modes'][3]}")

    print("\nAnalyse terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")
