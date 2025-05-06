#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques de résolution pour les histogrammes.

Ce module fournit des fonctions pour quantifier la résolution effective
des histogrammes par rapport à la largeur des modes.
"""

import numpy as np
import scipy.signal
import scipy.interpolate
import scipy.ndimage
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple, Union, Optional, Any

# Constantes pour les paramètres par défaut
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter les divisions par zéro
DEFAULT_INTERPOLATION_FACTOR = 10  # Facteur d'interpolation pour améliorer la précision
DEFAULT_SMOOTHING_SIGMA = 1.0  # Écart-type pour le lissage gaussien


def calculate_fwhm(histogram: np.ndarray,
                  bin_edges: Optional[np.ndarray] = None,
                  interpolate: bool = True) -> Dict[str, Any]:
    """
    Calcule la largeur à mi-hauteur (FWHM) pour chaque pic dans l'histogramme.

    La largeur à mi-hauteur est une mesure standard de la résolution d'un pic,
    définie comme la largeur du pic à la moitié de sa hauteur maximale.

    Args:
        histogram: Valeurs de l'histogramme
        bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
        interpolate: Si True, utilise une interpolation pour améliorer la précision

    Returns:
        Dict[str, Any]: Résultats contenant les FWHM pour chaque pic
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return {
            "peaks": [],
            "fwhm_bins": [],
            "fwhm_values": [],
            "mean_fwhm_bins": 0.0,
            "mean_fwhm_values": 0.0
        }

    # Interpoler l'histogramme pour une meilleure précision si demandé
    if interpolate:
        x_orig = np.arange(len(normalized_hist))
        x_interp = np.linspace(0, len(normalized_hist) - 1,
                              len(normalized_hist) * DEFAULT_INTERPOLATION_FACTOR)

        # Utiliser une interpolation cubique pour préserver la forme des pics
        interp_func = scipy.interpolate.interp1d(x_orig, normalized_hist,
                                               kind='cubic', bounds_error=False,
                                               fill_value=0)

        # Appliquer l'interpolation
        interp_hist = interp_func(x_interp)

        # Utiliser l'histogramme interpolé pour les calculs suivants
        working_hist = interp_hist
        working_x = x_interp
    else:
        working_hist = normalized_hist
        working_x = np.arange(len(normalized_hist))

    # Détecter les pics
    peaks, properties = scipy.signal.find_peaks(working_hist, height=0.5, prominence=0.1)

    if len(peaks) == 0:
        return {
            "peaks": [],
            "fwhm_bins": [],
            "fwhm_values": [],
            "mean_fwhm_bins": 0.0,
            "mean_fwhm_values": 0.0
        }

    # Calculer la largeur à mi-hauteur pour chaque pic
    # La fonction peak_widths calcule la largeur à la hauteur relative spécifiée
    widths_result = scipy.signal.peak_widths(working_hist, peaks, rel_height=0.5)

    # Extraire les résultats
    widths = widths_result[0]  # Largeurs en unités de bins
    width_heights = widths_result[1]  # Hauteurs auxquelles les largeurs sont mesurées
    left_ips = widths_result[2]  # Positions des points d'intersection gauches
    right_ips = widths_result[3]  # Positions des points d'intersection droits

    # Convertir les largeurs en unités réelles si bin_edges est fourni
    fwhm_values = []
    if bin_edges is not None and len(bin_edges) > 1:
        bin_width = (bin_edges[-1] - bin_edges[0]) / (len(bin_edges) - 1)

        if interpolate:
            # Ajuster pour l'interpolation
            scale_factor = len(normalized_hist) / len(working_hist)
            fwhm_values = widths * bin_width * scale_factor
        else:
            fwhm_values = widths * bin_width
    else:
        fwhm_values = widths

    # Convertir les indices des pics en unités réelles si bin_edges est fourni
    peak_positions = []
    if bin_edges is not None and len(bin_edges) > 1:
        if interpolate:
            # Convertir les indices interpolés en indices originaux
            orig_peaks = peaks / DEFAULT_INTERPOLATION_FACTOR

            # Convertir en valeurs réelles
            bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
            peak_positions = [bin_centers[int(p)] if int(p) < len(bin_centers) else bin_centers[-1]
                             for p in orig_peaks]
        else:
            bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
            peak_positions = [bin_centers[p] if p < len(bin_centers) else bin_centers[-1]
                             for p in peaks]
    else:
        peak_positions = peaks.tolist()

    return {
        "peaks": peak_positions,
        "fwhm_bins": widths.tolist(),
        "fwhm_values": fwhm_values.tolist(),
        "mean_fwhm_bins": float(np.mean(widths)) if len(widths) > 0 else 0.0,
        "mean_fwhm_values": float(np.mean(fwhm_values)) if len(fwhm_values) > 0 else 0.0
    }


def calculate_max_slope_resolution(histogram: np.ndarray,
                                bin_edges: Optional[np.ndarray] = None,
                                interpolate: bool = True,
                                smooth: bool = True,
                                sigma: float = DEFAULT_SMOOTHING_SIGMA) -> Dict[str, Any]:
    """
    Calcule la résolution basée sur la pente maximale pour chaque pic dans l'histogramme.

    La résolution basée sur la pente maximale est définie comme la largeur du pic
    divisée par la pente maximale sur les flancs du pic. Cette métrique est particulièrement
    utile pour évaluer la capacité à distinguer des pics adjacents.

    Args:
        histogram: Valeurs de l'histogramme
        bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
        interpolate: Si True, utilise une interpolation pour améliorer la précision
        smooth: Si True, applique un lissage gaussien pour réduire le bruit
        sigma: Écart-type pour le lissage gaussien

    Returns:
        Dict[str, Any]: Résultats contenant les résolutions basées sur la pente maximale
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return {
            "peaks": [],
            "max_slopes": [],
            "slope_resolutions": [],
            "mean_slope_resolution": 0.0
        }

    # Préparer les données pour le calcul
    if interpolate:
        x_orig = np.arange(len(normalized_hist))
        x_interp = np.linspace(0, len(normalized_hist) - 1,
                              len(normalized_hist) * DEFAULT_INTERPOLATION_FACTOR)

        # Utiliser une interpolation cubique pour préserver la forme des pics
        interp_func = scipy.interpolate.interp1d(x_orig, normalized_hist,
                                               kind='cubic', bounds_error=False,
                                               fill_value=0)

        # Appliquer l'interpolation
        working_hist = interp_func(x_interp)
        working_x = x_interp
    else:
        working_hist = normalized_hist
        working_x = np.arange(len(normalized_hist))

    # Appliquer un lissage gaussien si demandé
    if smooth:
        working_hist = scipy.ndimage.gaussian_filter1d(working_hist, sigma=sigma)

    # Calculer la dérivée première (gradient)
    gradient = np.gradient(working_hist, working_x)

    # Détecter les pics dans l'histogramme
    peaks, properties = scipy.signal.find_peaks(working_hist, height=0.3, prominence=0.1)

    if len(peaks) == 0:
        return {
            "peaks": [],
            "max_slopes": [],
            "slope_resolutions": [],
            "mean_slope_resolution": 0.0
        }

    # Calculer la résolution basée sur la pente maximale pour chaque pic
    max_slopes = []
    slope_resolutions = []
    peak_positions = []

    for peak_idx in peaks:
        # Trouver les vallées (minima) à gauche et à droite du pic
        left_idx = 0
        for i in range(peak_idx, 0, -1):
            if working_hist[i] < working_hist[i-1]:
                left_idx = i
                break

        right_idx = len(working_hist) - 1
        for i in range(peak_idx, len(working_hist) - 1):
            if working_hist[i] < working_hist[i+1]:
                right_idx = i
                break

        # Calculer la largeur du pic
        peak_width = right_idx - left_idx

        # Trouver la pente maximale sur les flancs du pic
        left_slope = np.max(np.abs(gradient[left_idx:peak_idx]))
        right_slope = np.max(np.abs(gradient[peak_idx:right_idx+1]))
        max_slope = max(left_slope, right_slope)

        # Calculer la résolution basée sur la pente maximale
        # Une pente plus élevée indique une meilleure résolution
        slope_resolution = peak_width / (max_slope + DEFAULT_EPSILON)

        max_slopes.append(float(max_slope))
        slope_resolutions.append(float(slope_resolution))

        # Convertir l'indice du pic en valeur réelle si bin_edges est fourni
        if bin_edges is not None and len(bin_edges) > 1:
            if interpolate:
                # Convertir l'indice interpolé en indice original
                orig_peak_idx = peak_idx / DEFAULT_INTERPOLATION_FACTOR

                # Convertir en valeur réelle
                bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
                if int(orig_peak_idx) < len(bin_centers):
                    peak_positions.append(bin_centers[int(orig_peak_idx)])
                else:
                    peak_positions.append(bin_centers[-1])
            else:
                bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
                if peak_idx < len(bin_centers):
                    peak_positions.append(bin_centers[peak_idx])
                else:
                    peak_positions.append(bin_centers[-1])
        else:
            peak_positions.append(float(peak_idx))

    # Calculer la résolution moyenne
    mean_slope_resolution = np.mean(slope_resolutions) if slope_resolutions else 0.0

    return {
        "peaks": peak_positions,
        "max_slopes": max_slopes,
        "slope_resolutions": slope_resolutions,
        "mean_slope_resolution": float(mean_slope_resolution)
    }


def calculate_relative_resolution(histogram: np.ndarray,
                                bin_edges: Optional[np.ndarray] = None,
                                mode_distance: Optional[float] = None) -> Dict[str, Any]:
    """
    Calcule la résolution relative de l'histogramme par rapport à la distance entre les modes.

    La résolution relative est définie comme le rapport entre la largeur à mi-hauteur (FWHM)
    moyenne des pics et la distance moyenne entre les pics adjacents. Une résolution relative
    faible (< 1) indique que les pics sont bien séparés, tandis qu'une résolution relative
    élevée (> 1) indique que les pics se chevauchent.

    Args:
        histogram: Valeurs de l'histogramme
        bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
        mode_distance: Distance moyenne entre les modes (si connue)

    Returns:
        Dict[str, Any]: Résultats contenant la résolution relative
    """
    # Calculer la largeur à mi-hauteur pour chaque pic
    fwhm_results = calculate_fwhm(histogram, bin_edges)

    # Si aucun pic n'est détecté, retourner une résolution relative indéfinie
    if len(fwhm_results["peaks"]) == 0:
        return {
            "relative_resolution": None,
            "resolution_quality": "Indéfinie",
            "fwhm_results": fwhm_results
        }

    # Si la distance entre les modes est fournie, l'utiliser
    if mode_distance is not None:
        mean_mode_distance = mode_distance
    else:
        # Calculer la distance moyenne entre les pics adjacents
        peaks = fwhm_results["peaks"]
        if len(peaks) > 1:
            # Trier les pics par position
            sorted_peaks = sorted(peaks)
            # Calculer les distances entre pics adjacents
            distances = np.diff(sorted_peaks)
            # Calculer la distance moyenne
            mean_mode_distance = float(np.mean(distances))
        else:
            # Si un seul pic est détecté, utiliser la largeur totale de l'histogramme
            if bin_edges is not None and len(bin_edges) > 1:
                mean_mode_distance = bin_edges[-1] - bin_edges[0]
            else:
                mean_mode_distance = len(histogram)

    # Calculer la résolution relative
    mean_fwhm = fwhm_results["mean_fwhm_values"]
    relative_resolution = mean_fwhm / mean_mode_distance if mean_mode_distance > 0 else float('inf')

    # Évaluer la qualité de la résolution
    if relative_resolution < 0.5:
        resolution_quality = "Excellente"
    elif relative_resolution < 0.7:
        resolution_quality = "Très bonne"
    elif relative_resolution < 1.0:
        resolution_quality = "Bonne"
    elif relative_resolution < 1.5:
        resolution_quality = "Acceptable"
    elif relative_resolution < 2.0:
        resolution_quality = "Limitée"
    else:
        resolution_quality = "Insuffisante"

    return {
        "relative_resolution": float(relative_resolution),
        "resolution_quality": resolution_quality,
        "mean_mode_distance": float(mean_mode_distance),
        "fwhm_results": fwhm_results
    }


def compare_binning_strategies_resolution(data: np.ndarray,
                                        strategies: Optional[List[str]] = None,
                                        num_bins: int = 20) -> Dict[str, Dict[str, Any]]:
    """
    Compare différentes stratégies de binning en termes de résolution.

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

        # Calculer la résolution relative
        resolution_results = calculate_relative_resolution(bin_counts, bin_edges)

        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "relative_resolution": resolution_results["relative_resolution"],
            "resolution_quality": resolution_results["resolution_quality"],
            "mean_fwhm": resolution_results["fwhm_results"]["mean_fwhm_values"],
            "peaks": resolution_results["fwhm_results"]["peaks"]
        }

    return results


def calculate_curvature_resolution(histogram: np.ndarray,
                                 bin_edges: Optional[np.ndarray] = None,
                                 interpolate: bool = True,
                                 smooth: bool = True,
                                 sigma: float = DEFAULT_SMOOTHING_SIGMA) -> Dict[str, Any]:
    """
    Calcule la résolution basée sur la courbure pour chaque pic dans l'histogramme.

    La résolution basée sur la courbure est définie comme la capacité à distinguer
    les changements de direction dans l'histogramme. Une courbure élevée indique
    des transitions nettes entre les pics et les vallées, ce qui correspond à une
    meilleure résolution.

    Args:
        histogram: Valeurs de l'histogramme
        bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)
        interpolate: Si True, utilise une interpolation pour améliorer la précision
        smooth: Si True, applique un lissage gaussien pour réduire le bruit
        sigma: Écart-type pour le lissage gaussien

    Returns:
        Dict[str, Any]: Résultats contenant les résolutions basées sur la courbure
    """
    # Normaliser l'histogramme
    if np.sum(histogram) > 0:
        normalized_hist = histogram / np.max(histogram)
    else:
        return {
            "peaks": [],
            "max_curvatures": [],
            "curvature_resolutions": [],
            "mean_curvature_resolution": 0.0
        }

    # Préparer les données pour le calcul
    if interpolate:
        x_orig = np.arange(len(normalized_hist))
        x_interp = np.linspace(0, len(normalized_hist) - 1,
                              len(normalized_hist) * DEFAULT_INTERPOLATION_FACTOR)

        # Utiliser une interpolation cubique pour préserver la forme des pics
        interp_func = scipy.interpolate.interp1d(x_orig, normalized_hist,
                                               kind='cubic', bounds_error=False,
                                               fill_value=0)

        # Appliquer l'interpolation
        working_hist = interp_func(x_interp)
        working_x = x_interp
    else:
        working_hist = normalized_hist
        working_x = np.arange(len(normalized_hist))

    # Appliquer un lissage gaussien si demandé
    if smooth:
        working_hist = scipy.ndimage.gaussian_filter1d(working_hist, sigma=sigma)

    # Calculer la dérivée seconde (approximation de la courbure)
    curvature = np.gradient(np.gradient(working_hist, working_x), working_x)

    # Prendre la valeur absolue pour mesurer l'ampleur de la courbure
    curvature_map = np.abs(curvature)

    # Détecter les pics dans l'histogramme
    peaks, properties = scipy.signal.find_peaks(working_hist, height=0.3, prominence=0.1)

    if len(peaks) == 0:
        return {
            "peaks": [],
            "max_curvatures": [],
            "curvature_resolutions": [],
            "mean_curvature_resolution": 0.0
        }

    # Calculer la résolution basée sur la courbure pour chaque pic
    max_curvatures = []
    curvature_resolutions = []
    peak_positions = []

    for peak_idx in peaks:
        # Trouver les vallées (minima) à gauche et à droite du pic
        left_idx = 0
        for i in range(peak_idx, 0, -1):
            if working_hist[i] < working_hist[i-1]:
                left_idx = i
                break

        right_idx = len(working_hist) - 1
        for i in range(peak_idx, len(working_hist) - 1):
            if working_hist[i] < working_hist[i+1]:
                right_idx = i
                break

        # Calculer la largeur du pic
        peak_width = right_idx - left_idx

        # Trouver la courbure maximale autour du pic
        # Nous cherchons les points d'inflexion où la courbure est maximale
        max_curvature = np.max(curvature_map[max(left_idx, 0):min(right_idx+1, len(curvature_map))])

        # Calculer la résolution basée sur la courbure
        # Une courbure plus élevée indique une meilleure résolution
        curvature_resolution = peak_width / (max_curvature + DEFAULT_EPSILON)

        max_curvatures.append(float(max_curvature))
        curvature_resolutions.append(float(curvature_resolution))

        # Convertir l'indice du pic en valeur réelle si bin_edges est fourni
        if bin_edges is not None and len(bin_edges) > 1:
            if interpolate:
                # Convertir l'indice interpolé en indice original
                orig_peak_idx = peak_idx / DEFAULT_INTERPOLATION_FACTOR

                # Convertir en valeur réelle
                bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
                if int(orig_peak_idx) < len(bin_centers):
                    peak_positions.append(bin_centers[int(orig_peak_idx)])
                else:
                    peak_positions.append(bin_centers[-1])
            else:
                bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
                if peak_idx < len(bin_centers):
                    peak_positions.append(bin_centers[peak_idx])
                else:
                    peak_positions.append(bin_centers[-1])
        else:
            peak_positions.append(float(peak_idx))

    # Calculer la résolution moyenne
    mean_curvature_resolution = np.mean(curvature_resolutions) if curvature_resolutions else 0.0

    return {
        "peaks": peak_positions,
        "max_curvatures": max_curvatures,
        "curvature_resolutions": curvature_resolutions,
        "mean_curvature_resolution": float(mean_curvature_resolution)
    }


def compare_resolution_metrics(histogram: np.ndarray,
                             bin_edges: Optional[np.ndarray] = None) -> Dict[str, Any]:
    """
    Compare différentes métriques de résolution pour un histogramme donné.

    Args:
        histogram: Valeurs de l'histogramme
        bin_edges: Limites des bins (optionnel, pour convertir en unités réelles)

    Returns:
        Dict[str, Any]: Résultats de comparaison des différentes métriques
    """
    # Calculer la résolution basée sur la largeur à mi-hauteur (FWHM)
    fwhm_results = calculate_fwhm(histogram, bin_edges)

    # Calculer la résolution basée sur la pente maximale
    slope_results = calculate_max_slope_resolution(histogram, bin_edges)

    # Calculer la résolution basée sur la courbure
    curvature_results = calculate_curvature_resolution(histogram, bin_edges)

    # Calculer la résolution relative
    relative_results = calculate_relative_resolution(histogram, bin_edges)

    # Comparer les résultats
    comparison = {
        "num_peaks_fwhm": len(fwhm_results["peaks"]),
        "num_peaks_slope": len(slope_results["peaks"]),
        "num_peaks_curvature": len(curvature_results["peaks"]),
        "peaks_fwhm": fwhm_results["peaks"],
        "peaks_slope": slope_results["peaks"],
        "peaks_curvature": curvature_results["peaks"],
        "mean_fwhm": fwhm_results["mean_fwhm_values"],
        "mean_slope_resolution": slope_results["mean_slope_resolution"],
        "mean_curvature_resolution": curvature_results["mean_curvature_resolution"],
        "relative_resolution": relative_results["relative_resolution"],
        "resolution_quality": relative_results["resolution_quality"]
    }

    # Évaluer quelle métrique est la plus discriminante
    # (c'est-à-dire celle qui détecte le plus de pics)
    max_peaks = max(comparison["num_peaks_fwhm"],
                   comparison["num_peaks_slope"],
                   comparison["num_peaks_curvature"])

    if comparison["num_peaks_fwhm"] == max_peaks:
        comparison["most_discriminant"] = "FWHM"
    elif comparison["num_peaks_slope"] == max_peaks:
        comparison["most_discriminant"] = "Slope"
    elif comparison["num_peaks_curvature"] == max_peaks:
        comparison["most_discriminant"] = "Curvature"
    else:
        # Si le même nombre de pics est détecté, comparer les valeurs de résolution
        # Une résolution relative plus faible est meilleure
        if (relative_results["relative_resolution"] is not None and
            relative_results["relative_resolution"] < 1.0):
            comparison["most_discriminant"] = "FWHM"
        else:
            comparison["most_discriminant"] = "Slope"

    return comparison


def analyze_bin_count_impact_on_resolution(data: np.ndarray,
                                      strategy: str = "uniform",
                                      min_bins: int = 5,
                                      max_bins: int = 100,
                                      step: int = 5) -> Dict[str, Any]:
    """
    Analyse l'impact du nombre de bins sur les différentes métriques de résolution.

    Cette fonction étudie comment le nombre de bins affecte la résolution d'un histogramme
    en calculant plusieurs métriques de résolution pour différents nombres de bins.

    Args:
        data: Données originales
        strategy: Stratégie de binning à utiliser ("uniform", "quantile", "logarithmic")
        min_bins: Nombre minimal de bins à tester
        max_bins: Nombre maximal de bins à tester
        step: Pas entre les nombres de bins à tester

    Returns:
        Dict[str, Any]: Résultats de l'analyse pour chaque nombre de bins
    """
    num_bins_range = range(min_bins, max_bins + 1, step)
    results = {}

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

        # Calculer les différentes métriques de résolution
        fwhm_results = calculate_fwhm(bin_counts, bin_edges)
        slope_results = calculate_max_slope_resolution(bin_counts, bin_edges)
        curvature_results = calculate_curvature_resolution(bin_counts, bin_edges)
        relative_results = calculate_relative_resolution(bin_counts, bin_edges)

        # Stocker les résultats
        results[num_bins] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "num_peaks_fwhm": len(fwhm_results["peaks"]),
            "num_peaks_slope": len(slope_results["peaks"]),
            "num_peaks_curvature": len(curvature_results["peaks"]),
            "mean_fwhm": fwhm_results["mean_fwhm_values"],
            "mean_slope_resolution": slope_results["mean_slope_resolution"],
            "mean_curvature_resolution": curvature_results["mean_curvature_resolution"],
            "relative_resolution": relative_results["relative_resolution"],
            "resolution_quality": relative_results["resolution_quality"],
            "bin_width": (bin_edges[-1] - bin_edges[0]) / num_bins
        }

    # Calculer des métriques supplémentaires sur l'ensemble des résultats
    optimal_num_bins = {
        "fwhm": min(results.keys(), key=lambda k: results[k]["mean_fwhm"] if results[k]["num_peaks_fwhm"] > 0 else float('inf')),
        "slope": min(results.keys(), key=lambda k: results[k]["mean_slope_resolution"] if results[k]["num_peaks_slope"] > 0 else float('inf')),
        "curvature": min(results.keys(), key=lambda k: results[k]["mean_curvature_resolution"] if results[k]["num_peaks_curvature"] > 0 else float('inf')),
        "relative": min(results.keys(), key=lambda k: results[k]["relative_resolution"] if results[k]["relative_resolution"] is not None else float('inf'))
    }

    # Trouver le nombre de bins qui maximise le nombre de pics détectés
    max_peaks_detected = max(results.values(), key=lambda r: r["num_peaks_fwhm"])["num_peaks_fwhm"]
    optimal_num_bins_for_peak_detection = min([
        num_bins for num_bins, result in results.items()
        if result["num_peaks_fwhm"] == max_peaks_detected
    ])

    return {
        "results_by_bin_count": results,
        "optimal_num_bins": optimal_num_bins,
        "optimal_num_bins_for_peak_detection": optimal_num_bins_for_peak_detection,
        "strategy": strategy,
        "min_bins": min_bins,
        "max_bins": max_bins,
        "step": step
    }


def plot_bin_count_impact_on_resolution(analysis_results: Dict[str, Any],
                                       save_path: Optional[str] = None,
                                       show_plot: bool = True) -> None:
    """
    Visualise l'impact du nombre de bins sur les différentes métriques de résolution.

    Args:
        analysis_results: Résultats de l'analyse produits par analyze_bin_count_impact_on_resolution
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    results = analysis_results["results_by_bin_count"]
    strategy = analysis_results["strategy"]

    # Extraire les données pour les graphiques
    bin_counts = sorted(results.keys())
    num_peaks_fwhm = [results[n]["num_peaks_fwhm"] for n in bin_counts]
    num_peaks_slope = [results[n]["num_peaks_slope"] for n in bin_counts]
    num_peaks_curvature = [results[n]["num_peaks_curvature"] for n in bin_counts]

    mean_fwhm = [results[n]["mean_fwhm"] if results[n]["num_peaks_fwhm"] > 0 else np.nan for n in bin_counts]
    mean_slope = [results[n]["mean_slope_resolution"] if results[n]["num_peaks_slope"] > 0 else np.nan for n in bin_counts]
    mean_curvature = [results[n]["mean_curvature_resolution"] if results[n]["num_peaks_curvature"] > 0 else np.nan for n in bin_counts]

    relative_resolution = [results[n]["relative_resolution"] if results[n]["relative_resolution"] is not None else np.nan for n in bin_counts]
    bin_widths = [results[n]["bin_width"] for n in bin_counts]

    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(12, 15), sharex=True)

    # Graphique 1: Nombre de pics détectés
    ax1 = axes[0]
    ax1.plot(bin_counts, num_peaks_fwhm, 'o-', label='FWHM')
    ax1.plot(bin_counts, num_peaks_slope, 's-', label='Pente')
    ax1.plot(bin_counts, num_peaks_curvature, '^-', label='Courbure')
    ax1.set_ylabel('Nombre de pics détectés')
    ax1.set_title(f'Impact du nombre de bins sur la détection des pics (Stratégie: {strategy})')
    ax1.grid(True, alpha=0.3)
    ax1.legend()

    # Graphique 2: Métriques de résolution
    ax2 = axes[1]
    ax2.plot(bin_counts, mean_fwhm, 'o-', label='FWHM moyenne')
    ax2.plot(bin_counts, mean_slope, 's-', label='Résolution pente moyenne')
    ax2.plot(bin_counts, mean_curvature, '^-', label='Résolution courbure moyenne')
    ax2.set_ylabel('Valeur de résolution')
    ax2.set_title('Impact du nombre de bins sur les métriques de résolution')
    ax2.grid(True, alpha=0.3)
    ax2.legend()

    # Graphique 3: Résolution relative et largeur des bins
    ax3 = axes[2]
    ax3_twin = ax3.twinx()

    line1 = ax3.plot(bin_counts, relative_resolution, 'o-', color='blue', label='Résolution relative')
    line2 = ax3_twin.plot(bin_counts, bin_widths, 's-', color='red', label='Largeur des bins')

    ax3.set_xlabel('Nombre de bins')
    ax3.set_ylabel('Résolution relative')
    ax3_twin.set_ylabel('Largeur des bins')
    ax3.set_title('Impact du nombre de bins sur la résolution relative et la largeur des bins')
    ax3.grid(True, alpha=0.3)

    # Combiner les légendes des deux axes
    lines = line1 + line2
    labels = [l.get_label() for l in lines]
    ax3.legend(lines, labels, loc='upper right')

    # Marquer les valeurs optimales
    optimal_bins = analysis_results["optimal_num_bins"]
    optimal_bins_peaks = analysis_results["optimal_num_bins_for_peak_detection"]

    ax1.axvline(x=optimal_bins_peaks, color='green', linestyle='--', alpha=0.7,
               label=f'Optimal pour détection ({optimal_bins_peaks} bins)')
    ax1.legend()

    ax2.axvline(x=optimal_bins["fwhm"], color='blue', linestyle='--', alpha=0.7,
               label=f'Optimal FWHM ({optimal_bins["fwhm"]} bins)')
    ax2.axvline(x=optimal_bins["slope"], color='orange', linestyle='--', alpha=0.7,
               label=f'Optimal pente ({optimal_bins["slope"]} bins)')
    ax2.axvline(x=optimal_bins["curvature"], color='green', linestyle='--', alpha=0.7,
               label=f'Optimal courbure ({optimal_bins["curvature"]} bins)')
    ax2.legend()

    ax3.axvline(x=optimal_bins["relative"], color='purple', linestyle='--', alpha=0.7,
               label=f'Optimal résolution relative ({optimal_bins["relative"]} bins)')
    ax3.legend(lines + [plt.Line2D([0], [0], color='purple', linestyle='--')],
              labels + [f'Optimal résolution relative ({optimal_bins["relative"]} bins)'])

    plt.tight_layout()

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)


def derive_bin_width_resolution_relationship(
        sigma_range: np.ndarray = np.linspace(1, 10, 10),
        bin_width_factors: np.ndarray = np.linspace(0.1, 2, 20)
    ) -> Dict[str, Any]:
    """
    Dérive la relation théorique entre la largeur des bins et la résolution.

    Cette fonction utilise des modèles théoriques pour établir comment la largeur des bins
    affecte les différentes métriques de résolution (FWHM, pente, courbure).

    Args:
        sigma_range: Plage d'écarts-types à tester pour les distributions gaussiennes
        bin_width_factors: Facteurs de largeur de bin par rapport à sigma (bin_width = factor * sigma)

    Returns:
        Dict[str, Any]: Résultats contenant les relations théoriques et coefficients
    """
    results = {
        "fwhm": {},
        "slope": {},
        "curvature": {},
        "models": {}
    }

    # Pour chaque écart-type, calculer la relation théorique
    for sigma in sigma_range:
        # Créer une distribution gaussienne
        x = np.linspace(-5*sigma, 5*sigma, 1000)
        gaussian = np.exp(-(x**2) / (2*sigma**2)) / (sigma * np.sqrt(2*np.pi))

        # Calculer la FWHM théorique (pour une gaussienne: 2.355 * sigma)
        true_fwhm = 2.355 * sigma

        # Calculer la pente maximale théorique (pour une gaussienne au point d'inflexion)
        true_max_slope = 1 / (sigma * np.sqrt(2*np.pi*np.e))

        # Calculer la courbure maximale théorique (pour une gaussienne)
        true_max_curvature = 1 / (sigma**2 * np.sqrt(2*np.pi))

        # Pour chaque facteur de largeur de bin
        fwhm_errors = []
        slope_errors = []
        curvature_errors = []
        bin_widths = []

        for factor in bin_width_factors:
            bin_width = factor * sigma
            bin_widths.append(bin_width)

            # Créer un histogramme avec cette largeur de bin
            bin_edges = np.arange(min(x), max(x) + bin_width, bin_width)
            bin_counts, _ = np.histogram(x, bins=bin_edges, weights=gaussian)

            # Normaliser l'histogramme
            if np.sum(bin_counts) > 0:
                bin_counts = bin_counts / np.max(bin_counts)

            # Calculer les métriques de résolution pour l'histogramme
            fwhm_results = calculate_fwhm(bin_counts, bin_edges)
            slope_results = calculate_max_slope_resolution(bin_counts, bin_edges)
            curvature_results = calculate_curvature_resolution(bin_counts, bin_edges)

            # Calculer les erreurs relatives par rapport aux valeurs théoriques
            if len(fwhm_results["fwhm_values"]) > 0:
                measured_fwhm = fwhm_results["mean_fwhm_values"]
                fwhm_error = (measured_fwhm - true_fwhm) / true_fwhm
                fwhm_errors.append(fwhm_error)
            else:
                fwhm_errors.append(np.nan)

            if len(slope_results["max_slopes"]) > 0:
                measured_slope = np.mean(slope_results["max_slopes"])
                slope_error = (measured_slope - true_max_slope) / true_max_slope
                slope_errors.append(slope_error)
            else:
                slope_errors.append(np.nan)

            if len(curvature_results["max_curvatures"]) > 0:
                measured_curvature = np.mean(curvature_results["max_curvatures"])
                curvature_error = (measured_curvature - true_max_curvature) / true_max_curvature
                curvature_errors.append(curvature_error)
            else:
                curvature_errors.append(np.nan)

        # Stocker les résultats pour cet écart-type
        results["fwhm"][sigma] = {
            "bin_widths": bin_widths,
            "errors": fwhm_errors,
            "true_value": true_fwhm
        }

        results["slope"][sigma] = {
            "bin_widths": bin_widths,
            "errors": slope_errors,
            "true_value": true_max_slope
        }

        results["curvature"][sigma] = {
            "bin_widths": bin_widths,
            "errors": curvature_errors,
            "true_value": true_max_curvature
        }

    # Dériver les modèles mathématiques pour les relations
    # Pour FWHM: Modèle théorique basé sur la convolution avec un noyau rectangulaire
    # FWHM_mesurée ≈ sqrt(FWHM_vraie^2 + bin_width^2)

    # Calculer les coefficients du modèle pour FWHM
    bin_width_to_fwhm_ratio = np.linspace(0.1, 2, 100)
    theoretical_fwhm_error = np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1

    # Modèle pour la pente: approximation basée sur la dérivée discrète
    # slope_mesurée ≈ slope_vraie / (1 + k * (bin_width/sigma)^2)
    # où k est un coefficient empirique

    # Modèle pour la courbure: approximation basée sur la dérivée seconde discrète
    # curvature_mesurée ≈ curvature_vraie / (1 + k' * (bin_width/sigma)^2)
    # où k' est un coefficient empirique

    # Stocker les modèles
    results["models"]["fwhm"] = {
        "formula": "FWHM_mesurée ≈ sqrt(FWHM_vraie^2 + bin_width^2)",
        "description": "Élargissement quadratique dû à la discrétisation",
        "bin_width_to_fwhm_ratio": bin_width_to_fwhm_ratio.tolist(),
        "theoretical_error": theoretical_fwhm_error.tolist()
    }

    results["models"]["slope"] = {
        "formula": "slope_mesurée ≈ slope_vraie / (1 + k * (bin_width/sigma)^2)",
        "description": "Atténuation de la pente due à la discrétisation",
        "k": 0.5  # Valeur empirique approximative
    }

    results["models"]["curvature"] = {
        "formula": "curvature_mesurée ≈ curvature_vraie / (1 + k' * (bin_width/sigma)^2)",
        "description": "Atténuation de la courbure due à la discrétisation",
        "k_prime": 1.0  # Valeur empirique approximative
    }

    return results


def plot_bin_width_resolution_relationship(relationship_results: Dict[str, Any],
                                         save_path: Optional[str] = None,
                                         show_plot: bool = True) -> None:
    """
    Visualise la relation théorique entre la largeur des bins et la résolution.

    Args:
        relationship_results: Résultats de la fonction derive_bin_width_resolution_relationship
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    from matplotlib.lines import Line2D  # Import explicite pour éviter les warnings

    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(12, 15), sharex=True)

    # Couleurs pour différentes valeurs de sigma
    import matplotlib.cm as cm
    colors = cm.viridis(np.linspace(0, 1, len(relationship_results["fwhm"])))

    # Graphique 1: Relation entre largeur des bins et erreur FWHM
    ax1 = axes[0]

    # Tracer les données empiriques pour chaque sigma
    for i, (sigma, results) in enumerate(relationship_results["fwhm"].items()):
        bin_widths = np.array(results["bin_widths"])
        errors = np.array(results["errors"])
        bin_width_to_fwhm_ratio = bin_widths / results["true_value"]

        # Filtrer les valeurs NaN
        valid_indices = ~np.isnan(errors)
        if np.any(valid_indices):
            ax1.plot(bin_width_to_fwhm_ratio[valid_indices], errors[valid_indices],
                    'o', color=colors[i], alpha=0.7, label=f'σ = {sigma:.1f}')

    # Tracer le modèle théorique
    model = relationship_results["models"]["fwhm"]
    bin_width_to_fwhm_ratio = np.array(model["bin_width_to_fwhm_ratio"])
    theoretical_error = np.array(model["theoretical_error"])
    ax1.plot(bin_width_to_fwhm_ratio, theoretical_error, 'k-', linewidth=2,
            label='Modèle théorique')

    ax1.set_ylabel('Erreur relative FWHM')
    ax1.set_title('Relation entre largeur des bins et erreur FWHM')
    ax1.grid(True, alpha=0.3)
    ax1.legend(loc='best')

    # Graphique 2: Relation entre largeur des bins et erreur de pente
    ax2 = axes[1]

    # Tracer les données empiriques pour chaque sigma
    for i, (sigma, results) in enumerate(relationship_results["slope"].items()):
        bin_widths = np.array(results["bin_widths"])
        errors = np.array(results["errors"])
        bin_width_to_sigma_ratio = bin_widths / sigma

        # Filtrer les valeurs NaN
        valid_indices = ~np.isnan(errors)
        if np.any(valid_indices):
            ax2.plot(bin_width_to_sigma_ratio[valid_indices], errors[valid_indices],
                    'o', color=colors[i], alpha=0.7)

    # Tracer le modèle théorique pour la pente
    k = relationship_results["models"]["slope"]["k"]
    x = np.linspace(0.1, 2, 100)
    y = 1 / (1 + k * x**2) - 1  # Erreur relative
    ax2.plot(x, y, 'k-', linewidth=2, label='Modèle théorique')

    ax2.set_ylabel('Erreur relative pente maximale')
    ax2.set_title('Relation entre largeur des bins et erreur de pente')
    ax2.grid(True, alpha=0.3)
    ax2.legend(loc='best')

    # Graphique 3: Relation entre largeur des bins et erreur de courbure
    ax3 = axes[2]

    # Tracer les données empiriques pour chaque sigma
    for i, (sigma, results) in enumerate(relationship_results["curvature"].items()):
        bin_widths = np.array(results["bin_widths"])
        errors = np.array(results["errors"])
        bin_width_to_sigma_ratio = bin_widths / sigma

        # Filtrer les valeurs NaN
        valid_indices = ~np.isnan(errors)
        if np.any(valid_indices):
            ax3.plot(bin_width_to_sigma_ratio[valid_indices], errors[valid_indices],
                    'o', color=colors[i], alpha=0.7)

    # Tracer le modèle théorique pour la courbure
    k_prime = relationship_results["models"]["curvature"]["k_prime"]
    x = np.linspace(0.1, 2, 100)
    y = 1 / (1 + k_prime * x**2) - 1  # Erreur relative
    ax3.plot(x, y, 'k-', linewidth=2, label='Modèle théorique')

    ax3.set_xlabel('Largeur des bins / σ')
    ax3.set_ylabel('Erreur relative courbure maximale')
    ax3.set_title('Relation entre largeur des bins et erreur de courbure')
    ax3.grid(True, alpha=0.3)
    ax3.legend(loc='best')

    # Ajouter une légende commune pour les valeurs de sigma
    handles = [Line2D([0], [0], marker='o', color='w', markerfacecolor=colors[i],
                     markersize=8, alpha=0.7) for i in range(len(relationship_results["fwhm"]))]
    labels = [f'σ = {sigma:.1f}' for sigma in relationship_results["fwhm"].keys()]
    fig.legend(handles, labels, loc='upper right', bbox_to_anchor=(0.95, 0.95),
              title='Écart-type (σ)')

    plt.tight_layout()

    # Sauvegarder la figure si un chemin est spécifié
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')

    # Afficher la figure si demandé
    if show_plot:
        plt.show()
    else:
        plt.close(fig)


def find_optimal_binning_strategy_resolution(data: np.ndarray,
                                           strategies: Optional[List[str]] = None,
                                           num_bins_range: Optional[List[int]] = None) -> Dict[str, Any]:
    """
    Trouve la stratégie de binning optimale en termes de résolution.

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

    best_resolution = float('inf')
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

            # Calculer la résolution relative
            resolution_results = calculate_relative_resolution(bin_counts, bin_edges)

            # Stocker les résultats
            strategy_results[num_bins] = {
                "bin_edges": bin_edges,
                "bin_counts": bin_counts,
                "relative_resolution": resolution_results["relative_resolution"],
                "resolution_quality": resolution_results["resolution_quality"],
                "mean_fwhm": resolution_results["fwhm_results"]["mean_fwhm_values"],
                "peaks": resolution_results["fwhm_results"]["peaks"]
            }

            # Mettre à jour la meilleure stratégie
            # Une résolution relative plus faible est meilleure (meilleure séparation des pics)
            if (resolution_results["relative_resolution"] is not None and
                resolution_results["relative_resolution"] < best_resolution):
                best_resolution = resolution_results["relative_resolution"]
                best_strategy = strategy
                best_num_bins = num_bins
                best_quality = resolution_results["resolution_quality"]

        results[strategy] = strategy_results

    return {
        "best_strategy": best_strategy,
        "best_num_bins": best_num_bins,
        "best_resolution": best_resolution,
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

    # Tester les métriques de résolution
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution: {dist_name} ===")

        # Créer un histogramme
        bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
        bin_counts, _ = np.histogram(data, bins=bin_edges)

        # Calculer la largeur à mi-hauteur (FWHM)
        fwhm_results = calculate_fwhm(bin_counts, bin_edges)

        print(f"Nombre de pics détectés: {len(fwhm_results['peaks'])}")
        if len(fwhm_results['peaks']) > 0:
            print(f"Positions des pics: {fwhm_results['peaks']}")
            print(f"FWHM (bins): {fwhm_results['fwhm_bins']}")
            print(f"FWHM (valeurs): {fwhm_results['fwhm_values']}")
            print(f"FWHM moyenne (bins): {fwhm_results['mean_fwhm_bins']}")
            print(f"FWHM moyenne (valeurs): {fwhm_results['mean_fwhm_values']}")

        # Calculer la résolution basée sur la courbure
        curvature_results = calculate_curvature_resolution(bin_counts, bin_edges)

        print(f"\nRésolution basée sur la courbure:")
        print(f"Nombre de pics détectés: {len(curvature_results['peaks'])}")
        if len(curvature_results['peaks']) > 0:
            print(f"Positions des pics: {curvature_results['peaks']}")
            print(f"Courbures maximales: {curvature_results['max_curvatures']}")
            print(f"Résolutions basées sur la courbure: {curvature_results['curvature_resolutions']}")
            print(f"Résolution moyenne basée sur la courbure: {curvature_results['mean_curvature_resolution']}")

        # Calculer la résolution relative
        resolution_results = calculate_relative_resolution(bin_counts, bin_edges)

        print(f"\nRésolution relative: {resolution_results['relative_resolution']}")
        print(f"Qualité de la résolution: {resolution_results['resolution_quality']}")
        print(f"Distance moyenne entre les modes: {resolution_results['mean_mode_distance']}")

        # Comparer différentes stratégies de binning
        print("\nComparaison des stratégies de binning:")
        results = compare_binning_strategies_resolution(data)

        for strategy, result in results.items():
            print(f"\nStratégie: {strategy}")
            print(f"Nombre de pics détectés: {len(result['peaks'])}")
            print(f"Résolution relative: {result['relative_resolution']}")
            print(f"Qualité de la résolution: {result['resolution_quality']}")
            print(f"FWHM moyenne: {result['mean_fwhm']}")

        # Trouver la stratégie optimale
        print("\nRecherche de la stratégie optimale:")
        optimization = find_optimal_binning_strategy_resolution(data, num_bins_range=[5, 10, 20, 50])

        print(f"Meilleure stratégie: {optimization['best_strategy']}")
        print(f"Nombre optimal de bins: {optimization['best_num_bins']}")
        print(f"Meilleure résolution relative: {optimization['best_resolution']}")
        print(f"Qualité: {optimization['best_quality']}")

        # Visualiser les résultats pour la distribution multimodale
        if dist_name == "multimodal":
            plt.figure(figsize=(15, 10))

            # Tracer l'histogramme original
            plt.subplot(2, 2, 1)
            plt.title(f"Distribution originale ({dist_name})")
            plt.hist(data, bins=50, density=True, alpha=0.5, color='gray')
            plt.grid(True, alpha=0.3)

            # Tracer les histogrammes pour chaque stratégie
            for i, (strategy, result) in enumerate(results.items()):
                plt.subplot(2, 2, i + 2)
                plt.title(f"Stratégie: {strategy} (Résolution: {result['relative_resolution']:.4f}, Qualité: {result['resolution_quality']})")

                # Tracer l'histogramme
                plt.hist(data, bins=result['bin_edges'], density=True, alpha=0.5)

                # Marquer les pics détectés
                if len(result['peaks']) > 0:
                    for peak in result['peaks']:
                        plt.axvline(x=peak, color='r', linestyle='--', alpha=0.7)

                plt.grid(True, alpha=0.3)

            plt.tight_layout()
            plt.savefig("resolution_comparison.png")
            print("Figure sauvegardée sous 'resolution_comparison.png'")
