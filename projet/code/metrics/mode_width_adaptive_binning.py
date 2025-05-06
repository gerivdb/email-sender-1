#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour l'implémentation d'une méthode de binning variable selon la largeur des modes.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, Optional, Any, Union
from scipy.signal import find_peaks
import scipy.stats

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
# Importer uniquement ce qui est nécessaire
# from resolution_metrics import calculate_fwhm, calculate_relative_resolution
# from mode_interpretability_metrics import detect_modes

def detect_modes_with_widths(data: np.ndarray,
                           kde_bandwidth: Union[str, float] = 'scott',
                           prominence_threshold: float = 0.1,
                           min_height: float = 0.2,
                           min_distance: int = 3,
                           use_kde: bool = True) -> Dict[str, Any]:
    """
    Détecte les modes dans une distribution et calcule leurs largeurs.

    Args:
        data: Données à analyser
        kde_bandwidth: Largeur de bande pour l'estimation par noyau (KDE)
        prominence_threshold: Seuil de proéminence pour considérer un pic
        min_height: Hauteur minimale pour considérer un pic
        min_distance: Distance minimale entre les pics en nombre de bins
        use_kde: Si True, utilise l'estimation par noyau (KDE) pour une détection plus précise

    Returns:
        Dict[str, Any]: Informations sur les modes détectés et leurs largeurs
    """
    if use_kde:
        # Utiliser l'estimation par noyau (KDE) pour une détection plus précise des modes
        kde = scipy.stats.gaussian_kde(data, bw_method=kde_bandwidth)

        # Créer une grille de points pour évaluer la KDE
        x_min, x_max = np.min(data), np.max(data)
        x_range = x_max - x_min
        x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, 1000)

        # Évaluer la KDE sur la grille
        density = kde(x_grid)

        # Normaliser la densité
        density = density / np.max(density)

        # Trouver les pics (modes)
        peaks, properties = find_peaks(
            density,
            prominence=prominence_threshold,
            height=min_height,
            distance=min_distance
        )

        # Calculer les positions des modes
        mode_positions = x_grid[peaks]
        mode_heights = density[peaks]

        # Calculer les largeurs des modes (FWHM)
        mode_widths = []
        for i, peak in enumerate(peaks):
            # Trouver les points à mi-hauteur
            half_height = mode_heights[i] / 2

            # Chercher à gauche
            left_idx = peak
            while left_idx > 0 and density[left_idx] > half_height:
                left_idx -= 1

            # Chercher à droite
            right_idx = peak
            while right_idx < len(density) - 1 and density[right_idx] > half_height:
                right_idx += 1

            # Calculer la largeur en unités de données
            left_x = x_grid[left_idx]
            right_x = x_grid[right_idx]
            width = right_x - left_x

            mode_widths.append(width)

        # Calculer les proéminences des modes
        mode_prominences = properties["prominences"] if "prominences" in properties else []

    else:
        # Utiliser l'histogramme pour détecter les modes
        # Déterminer le nombre de bins optimal
        q75, q25 = np.percentile(data, [75, 25])
        iqr = q75 - q25
        bin_width = 2 * iqr / (len(data) ** (1/3))  # Règle de Freedman-Diaconis
        if bin_width == 0:  # Éviter la division par zéro
            bin_width = 1
        num_bins = int(np.ceil((np.max(data) - np.min(data)) / bin_width))
        num_bins = max(10, min(100, num_bins))  # Limiter entre 10 et 100 bins

        # Calculer l'histogramme
        hist, bin_edges = np.histogram(data, bins=num_bins, density=True)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

        # Normaliser l'histogramme
        hist = hist / np.max(hist)

        # Trouver les pics (modes)
        peaks, properties = find_peaks(
            hist,
            prominence=prominence_threshold,
            height=min_height,
            distance=min_distance
        )

        # Calculer les positions des modes
        mode_positions = bin_centers[peaks]
        mode_heights = hist[peaks]

        # Calculer les largeurs des modes (FWHM)
        mode_widths = []
        for i, peak in enumerate(peaks):
            # Trouver les points à mi-hauteur
            half_height = mode_heights[i] / 2

            # Chercher à gauche
            left_idx = peak
            while left_idx > 0 and hist[left_idx] > half_height:
                left_idx -= 1

            # Chercher à droite
            right_idx = peak
            while right_idx < len(hist) - 1 and hist[right_idx] > half_height:
                right_idx += 1

            # Calculer la largeur en unités de données
            left_x = bin_centers[left_idx]
            right_x = bin_centers[right_idx]
            width = right_x - left_x

            mode_widths.append(width)

        # Calculer les proéminences des modes
        mode_prominences = properties["prominences"] if "prominences" in properties else []

    # Résultats
    return {
        "num_modes": len(mode_positions),
        "mode_positions": mode_positions,
        "mode_heights": mode_heights,
        "mode_prominences": mode_prominences,
        "mode_widths": mode_widths,
        "data_range": np.max(data) - np.min(data),
        "data_min": np.min(data),
        "data_max": np.max(data)
    }

def plot_modes_with_widths(data: np.ndarray,
                         modes_info: Dict[str, Any],
                         use_kde: bool = True,
                         kde_bandwidth: Union[str, float] = 'scott',
                         save_path: Optional[str] = None,
                         show_plot: bool = True) -> None:
    """
    Visualise les modes détectés et leurs largeurs.

    Args:
        data: Données à analyser
        modes_info: Informations sur les modes détectés
        use_kde: Si True, utilise l'estimation par noyau (KDE) pour la visualisation
        kde_bandwidth: Largeur de bande pour l'estimation par noyau (KDE)
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, ax = plt.subplots(figsize=(10, 6))

    if use_kde:
        # Utiliser l'estimation par noyau (KDE) pour la visualisation
        kde = scipy.stats.gaussian_kde(data, bw_method=kde_bandwidth)

        # Créer une grille de points pour évaluer la KDE
        x_min, x_max = np.min(data), np.max(data)
        x_range = x_max - x_min
        x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, 1000)

        # Évaluer la KDE sur la grille
        density = kde(x_grid)

        # Normaliser la densité
        density = density / np.max(density)

        # Tracer la KDE
        ax.plot(x_grid, density, 'b-', linewidth=2, label='Densité (KDE)')

        # Tracer l'histogramme en arrière-plan
        ax.hist(data, bins=50, density=True, alpha=0.3, color='gray', label='Histogramme')

        # Tracer les modes
        ax.plot(modes_info["mode_positions"], modes_info["mode_heights"], 'ro', markersize=8, label='Modes')

        # Tracer les largeurs des modes (FWHM)
        for i, (pos, height, width) in enumerate(zip(modes_info["mode_positions"],
                                                   modes_info["mode_heights"],
                                                   modes_info["mode_widths"])):
            # Tracer une ligne horizontale à mi-hauteur
            half_height = height / 2
            left_x = pos - width / 2
            right_x = pos + width / 2

            ax.plot([left_x, right_x], [half_height, half_height], 'g-', linewidth=2)
            ax.plot([left_x, left_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)
            ax.plot([right_x, right_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)

            # Ajouter une annotation
            ax.text(pos, height + 0.05, f"Mode {i+1}\nLargeur: {width:.2f}",
                   ha='center', va='bottom', fontsize=9,
                   bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.8))

    else:
        # Utiliser l'histogramme pour la visualisation
        # Déterminer le nombre de bins optimal
        q75, q25 = np.percentile(data, [75, 25])
        iqr = q75 - q25
        bin_width = 2 * iqr / (len(data) ** (1/3))  # Règle de Freedman-Diaconis
        if bin_width == 0:  # Éviter la division par zéro
            bin_width = 1
        num_bins = int(np.ceil((np.max(data) - np.min(data)) / bin_width))
        num_bins = max(10, min(100, num_bins))  # Limiter entre 10 et 100 bins

        # Calculer l'histogramme
        hist, bin_edges = np.histogram(data, bins=num_bins, density=True)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

        # Normaliser l'histogramme
        hist = hist / np.max(hist)

        # Tracer l'histogramme
        ax.bar(bin_centers, hist, width=bin_width, alpha=0.7, color='blue', label='Histogramme')

        # Tracer les modes
        ax.plot(modes_info["mode_positions"], modes_info["mode_heights"], 'ro', markersize=8, label='Modes')

        # Tracer les largeurs des modes (FWHM)
        for i, (pos, height, width) in enumerate(zip(modes_info["mode_positions"],
                                                   modes_info["mode_heights"],
                                                   modes_info["mode_widths"])):
            # Tracer une ligne horizontale à mi-hauteur
            half_height = height / 2
            left_x = pos - width / 2
            right_x = pos + width / 2

            ax.plot([left_x, right_x], [half_height, half_height], 'g-', linewidth=2)
            ax.plot([left_x, left_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)
            ax.plot([right_x, right_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)

            # Ajouter une annotation
            ax.text(pos, height + 0.05, f"Mode {i+1}\nLargeur: {width:.2f}",
                   ha='center', va='bottom', fontsize=9,
                   bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.8))

    # Ajouter les informations sur les modes
    plt.figtext(0.5, 0.01,
               f"Nombre de modes: {modes_info['num_modes']}, "
               f"Largeur moyenne: {np.mean(modes_info['mode_widths']):.2f}, "
               f"Plage des données: {modes_info['data_range']:.2f}",
               ha='center', fontsize=10)

    # Configurer le graphique
    ax.set_xlabel('Valeur')
    ax.set_ylabel('Densité normalisée')
    ax.set_title('Détection des modes et de leurs largeurs')
    ax.legend()
    ax.grid(True, alpha=0.3)

    plt.tight_layout(rect=(0, 0.03, 1, 0.97))

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)

def calculate_variable_bin_widths(data: np.ndarray,
                              modes_info: Dict[str, Any],
                              min_bins_per_mode: int = 5,
                              max_bins_per_mode: int = 20) -> Dict[str, Any]:
    """
    Calcule les largeurs de bins variables en fonction des modes détectés.

    Args:
        data: Données à analyser
        modes_info: Informations sur les modes détectés
        min_bins_per_mode: Nombre minimal de bins par mode
        max_bins_per_mode: Nombre maximal de bins par mode

    Returns:
        Dict[str, Any]: Informations sur les largeurs de bins variables
    """
    # Extraire les informations sur les modes
    mode_positions = modes_info["mode_positions"]
    mode_widths = modes_info["mode_widths"]
    data_min = modes_info["data_min"]
    data_max = modes_info["data_max"]
    data_range = modes_info["data_range"]

    # Si aucun mode n'est détecté, utiliser un binning uniforme
    if len(mode_positions) == 0:
        # Utiliser la règle de Freedman-Diaconis pour déterminer le nombre de bins
        q75, q25 = np.percentile(data, [75, 25])
        iqr = q75 - q25
        bin_width = 2 * iqr / (len(data) ** (1/3))
        if bin_width == 0:  # Éviter la division par zéro
            bin_width = 1
        num_bins = int(np.ceil(data_range / bin_width))
        num_bins = max(10, min(100, num_bins))  # Limiter entre 10 et 100 bins

        return {
            "bin_widths": np.ones(num_bins) * (data_range / num_bins),
            "bin_edges": np.linspace(data_min, data_max, num_bins + 1),
            "bin_centers": np.linspace(data_min + data_range / (2 * num_bins),
                                     data_max - data_range / (2 * num_bins),
                                     num_bins),
            "num_bins": num_bins,
            "is_uniform": True,
            "mode_regions": []
        }

    # Trier les modes par position
    sorted_indices = np.argsort(mode_positions)
    sorted_positions = mode_positions[sorted_indices]
    sorted_widths = np.array(mode_widths)[sorted_indices]

    # Définir les régions des modes
    mode_regions = []

    # Ajouter la région avant le premier mode
    if sorted_positions[0] > data_min:
        mode_regions.append({
            "start": data_min,
            "end": sorted_positions[0] - sorted_widths[0] / 2,
            "width": sorted_positions[0] - data_min,
            "is_mode": False,
            "mode_index": -1
        })

    # Ajouter les régions des modes et les régions entre les modes
    for i in range(len(sorted_positions)):
        # Région du mode
        mode_start = max(data_min, sorted_positions[i] - sorted_widths[i] / 2)
        mode_end = min(data_max, sorted_positions[i] + sorted_widths[i] / 2)

        mode_regions.append({
            "start": mode_start,
            "end": mode_end,
            "width": mode_end - mode_start,
            "is_mode": True,
            "mode_index": sorted_indices[i]
        })

        # Région entre ce mode et le suivant (si ce n'est pas le dernier mode)
        if i < len(sorted_positions) - 1:
            next_mode_start = sorted_positions[i+1] - sorted_widths[i+1] / 2

            # Vérifier si les modes se chevauchent
            if mode_end < next_mode_start:
                mode_regions.append({
                    "start": mode_end,
                    "end": next_mode_start,
                    "width": next_mode_start - mode_end,
                    "is_mode": False,
                    "mode_index": -1
                })

    # Ajouter la région après le dernier mode
    if sorted_positions[-1] < data_max:
        mode_regions.append({
            "start": sorted_positions[-1] + sorted_widths[-1] / 2,
            "end": data_max,
            "width": data_max - sorted_positions[-1] - sorted_widths[-1] / 2,
            "is_mode": False,
            "mode_index": -1
        })

    # Fusionner les régions qui se chevauchent
    i = 0
    while i < len(mode_regions) - 1:
        if mode_regions[i]["end"] >= mode_regions[i+1]["start"]:
            # Fusionner les régions
            mode_regions[i]["end"] = mode_regions[i+1]["end"]
            mode_regions[i]["width"] = mode_regions[i]["end"] - mode_regions[i]["start"]

            # Si l'une des régions est un mode, la région fusionnée est un mode
            if mode_regions[i+1]["is_mode"]:
                mode_regions[i]["is_mode"] = True
                mode_regions[i]["mode_index"] = mode_regions[i+1]["mode_index"]

            # Supprimer la région suivante
            mode_regions.pop(i+1)
        else:
            i += 1

    # Calculer le nombre de bins pour chaque région
    total_bins = 0
    for region in mode_regions:
        if region["is_mode"]:
            # Pour les régions de mode, utiliser un nombre de bins proportionnel à la largeur du mode
            mode_index = region["mode_index"]
            mode_width = mode_widths[mode_index]

            # Calculer le nombre de bins en fonction de la largeur du mode
            bins_for_mode = int(np.ceil(max_bins_per_mode * (mode_width / np.max(mode_widths))))
            bins_for_mode = max(min_bins_per_mode, min(max_bins_per_mode, bins_for_mode))

            region["num_bins"] = bins_for_mode
        else:
            # Pour les régions entre les modes, utiliser un nombre de bins proportionnel à la largeur de la région
            # mais avec une densité plus faible que dans les régions de mode
            region_width = region["width"]
            region_fraction = region_width / data_range

            # Calculer le nombre de bins en fonction de la fraction de la plage totale
            bins_for_region = int(np.ceil(min_bins_per_mode * region_fraction * data_range))
            bins_for_region = max(1, min(min_bins_per_mode, bins_for_region))

            region["num_bins"] = bins_for_region

        total_bins += region["num_bins"]

    # Calculer les largeurs de bins pour chaque région
    bin_edges = [data_min]
    bin_widths = []
    bin_centers = []

    for region in mode_regions:
        region_start = region["start"]
        region_end = region["end"]
        region_width = region["width"]
        num_bins = region["num_bins"]

        if region["is_mode"]:
            # Pour les régions de mode, utiliser des bins plus étroits
            mode_index = region["mode_index"]
            mode_width = mode_widths[mode_index]

            # Calculer la largeur des bins pour cette région
            bin_width = region_width / num_bins

            # Créer les limites des bins pour cette région
            region_edges = np.linspace(region_start, region_end, num_bins + 1)

            # Ajouter les limites des bins (sauf la première qui est déjà incluse)
            bin_edges.extend(region_edges[1:])

            # Ajouter les largeurs des bins
            region_widths = np.diff(region_edges)
            bin_widths.extend(region_widths)

            # Ajouter les centres des bins
            region_centers = (region_edges[:-1] + region_edges[1:]) / 2
            bin_centers.extend(region_centers)
        else:
            # Pour les régions entre les modes, utiliser des bins plus larges
            # Calculer la largeur des bins pour cette région
            bin_width = region_width / num_bins

            # Créer les limites des bins pour cette région
            region_edges = np.linspace(region_start, region_end, num_bins + 1)

            # Ajouter les limites des bins (sauf la première qui est déjà incluse)
            bin_edges.extend(region_edges[1:])

            # Ajouter les largeurs des bins
            region_widths = np.diff(region_edges)
            bin_widths.extend(region_widths)

            # Ajouter les centres des bins
            region_centers = (region_edges[:-1] + region_edges[1:]) / 2
            bin_centers.extend(region_centers)

    # Convertir en tableaux numpy
    bin_edges = np.array(bin_edges)

    # Vérifier que les limites des bins sont monotones croissantes
    if not np.all(np.diff(bin_edges) > 0):
        # Trier les limites des bins si nécessaire
        sorted_indices = np.argsort(bin_edges)
        bin_edges = bin_edges[sorted_indices]

        # Recalculer les largeurs et les centres des bins
        bin_widths = np.diff(bin_edges)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    else:
        bin_widths = np.array(bin_widths)
        bin_centers = np.array(bin_centers)

    # Résultats
    return {
        "bin_widths": bin_widths,
        "bin_edges": bin_edges,
        "bin_centers": bin_centers,
        "num_bins": len(bin_widths),
        "is_uniform": False,
        "mode_regions": mode_regions
    }

def plot_variable_bin_widths(data: np.ndarray,
                           modes_info: Dict[str, Any],
                           bin_info: Dict[str, Any],
                           save_path: Optional[str] = None,
                           show_plot: bool = True) -> None:
    """
    Visualise les largeurs de bins variables en fonction des modes détectés.

    Args:
        data: Données à analyser
        modes_info: Informations sur les modes détectés
        bin_info: Informations sur les largeurs de bins variables
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Créer la figure
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10), gridspec_kw={'height_ratios': [3, 1]})

    # Extraire les informations
    bin_edges = bin_info["bin_edges"]
    bin_widths = bin_info["bin_widths"]
    bin_centers = bin_info["bin_centers"]
    mode_regions = bin_info["mode_regions"]

    # Calculer l'histogramme avec les bins variables
    hist, _ = np.histogram(data, bins=bin_edges)

    # Normaliser l'histogramme
    if np.sum(hist) > 0:
        hist = hist / np.max(hist)

    # Tracer l'histogramme avec les bins variables
    ax1.bar(bin_centers, hist, width=bin_widths, alpha=0.7, color='blue', label='Histogramme')

    # Tracer les modes
    if modes_info["num_modes"] > 0:
        ax1.plot(modes_info["mode_positions"], modes_info["mode_heights"], 'ro', markersize=8, label='Modes')

        # Tracer les largeurs des modes (FWHM)
        for i, (pos, height, width) in enumerate(zip(modes_info["mode_positions"],
                                                   modes_info["mode_heights"],
                                                   modes_info["mode_widths"])):
            # Tracer une ligne horizontale à mi-hauteur
            half_height = height / 2
            left_x = pos - width / 2
            right_x = pos + width / 2

            ax1.plot([left_x, right_x], [half_height, half_height], 'g-', linewidth=2)
            ax1.plot([left_x, left_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)
            ax1.plot([right_x, right_x], [half_height - 0.05, half_height + 0.05], 'g-', linewidth=2)

            # Ajouter une annotation
            ax1.text(pos, height + 0.05, f"Mode {i+1}\nLargeur: {width:.2f}",
                    ha='center', va='bottom', fontsize=9,
                    bbox=dict(boxstyle="round,pad=0.3", fc="white", ec="gray", alpha=0.8))

    # Tracer les régions des modes
    for i, region in enumerate(mode_regions):
        if region["is_mode"]:
            ax1.axvspan(region["start"], region["end"], alpha=0.2, color='green', label='_nolegend_')
            ax1.text((region["start"] + region["end"]) / 2, -0.05, f"Mode {region['mode_index'] + 1}",
                    ha='center', va='top', fontsize=8)
        else:
            ax1.axvspan(region["start"], region["end"], alpha=0.1, color='gray', label='_nolegend_')

    # Tracer les largeurs des bins
    ax2.bar(bin_centers, bin_widths, width=bin_widths, alpha=0.7, color='purple', label='Largeurs des bins')

    # Tracer les régions des modes sur le graphique des largeurs
    for i, region in enumerate(mode_regions):
        if region["is_mode"]:
            ax2.axvspan(region["start"], region["end"], alpha=0.2, color='green', label='_nolegend_')
            ax2.text((region["start"] + region["end"]) / 2, np.min(bin_widths) - 0.1 * (np.max(bin_widths) - np.min(bin_widths)),
                    f"Mode {region['mode_index'] + 1}", ha='center', va='top', fontsize=8)
        else:
            ax2.axvspan(region["start"], region["end"], alpha=0.1, color='gray', label='_nolegend_')

    # Configurer le graphique de l'histogramme
    ax1.set_xlabel('Valeur')
    ax1.set_ylabel('Fréquence normalisée')
    ax1.set_title('Histogramme avec bins variables selon la largeur des modes')
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Configurer le graphique des largeurs de bins
    ax2.set_xlabel('Valeur')
    ax2.set_ylabel('Largeur des bins')
    ax2.set_title('Largeurs des bins variables')
    ax2.grid(True, alpha=0.3)

    # Ajouter les informations sur les bins
    plt.figtext(0.5, 0.01,
               f"Nombre total de bins: {bin_info['num_bins']}, "
               f"Largeur moyenne: {np.mean(bin_widths):.2f}, "
               f"Ratio max/min: {np.max(bin_widths) / np.min(bin_widths):.2f}",
               ha='center', fontsize=10)

    plt.tight_layout(rect=(0, 0.03, 1, 0.97))

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
    print("=== Test de la détection des modes et de leurs largeurs ===")

    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité

    # Distribution gaussienne
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)

    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])

    # Distribution asymétrique (log-normale)
    lognormal_data = np.random.lognormal(mean=1.0, sigma=0.5, size=1000)

    # Distribution trimodale avec modes de largeurs différentes
    trimodal_data = np.concatenate([
        np.random.normal(loc=20, scale=2, size=300),   # Mode étroit
        np.random.normal(loc=50, scale=5, size=500),   # Mode moyen
        np.random.normal(loc=80, scale=10, size=200)   # Mode large
    ])

    # Tester la détection des modes et de leurs largeurs
    for name, data in [("Gaussienne", gaussian_data),
                      ("Bimodale", bimodal_data),
                      ("Log-normale", lognormal_data),
                      ("Trimodale", trimodal_data)]:
        print(f"\nDistribution {name}:")

        # Détecter les modes avec KDE
        modes_info_kde = detect_modes_with_widths(data, use_kde=True)

        print(f"  Avec KDE:")
        print(f"    Nombre de modes: {modes_info_kde['num_modes']}")
        if modes_info_kde['num_modes'] > 0:
            print(f"    Positions des modes: {modes_info_kde['mode_positions']}")
            print(f"    Hauteurs des modes: {modes_info_kde['mode_heights']}")
            print(f"    Largeurs des modes (FWHM): {modes_info_kde['mode_widths']}")

        # Visualiser les résultats
        plot_modes_with_widths(
            data,
            modes_info_kde,
            use_kde=True,
            save_path=f"mode_width_detection_kde_{name.lower()}.png",
            show_plot=False
        )

        # Détecter les modes avec histogramme
        modes_info_hist = detect_modes_with_widths(data, use_kde=False)

        print(f"  Avec histogramme:")
        print(f"    Nombre de modes: {modes_info_hist['num_modes']}")
        if modes_info_hist['num_modes'] > 0:
            print(f"    Positions des modes: {modes_info_hist['mode_positions']}")
            print(f"    Hauteurs des modes: {modes_info_hist['mode_heights']}")
            print(f"    Largeurs des modes (FWHM): {modes_info_hist['mode_widths']}")

        # Visualiser les résultats
        plot_modes_with_widths(
            data,
            modes_info_hist,
            use_kde=False,
            save_path=f"mode_width_detection_hist_{name.lower()}.png",
            show_plot=False
        )

        # Calculer les largeurs de bins variables
        print(f"  Calcul des largeurs de bins variables:")
        bin_info = calculate_variable_bin_widths(
            data,
            modes_info_kde,
            min_bins_per_mode=5,
            max_bins_per_mode=20
        )

        print(f"    Nombre total de bins: {bin_info['num_bins']}")
        print(f"    Largeur moyenne des bins: {np.mean(bin_info['bin_widths']):.4f}")
        print(f"    Ratio max/min des largeurs: {np.max(bin_info['bin_widths']) / np.min(bin_info['bin_widths']):.4f}")

        # Visualiser les résultats
        plot_variable_bin_widths(
            data,
            modes_info_kde,
            bin_info,
            save_path=f"variable_bin_widths_{name.lower()}.png",
            show_plot=False
        )

    print("\nTest terminé avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")
