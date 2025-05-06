#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour la validation empirique des relations théoriques par simulation Monte Carlo.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from typing import Dict, List, Tuple, Optional, Any
from tqdm import tqdm

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from resolution_metrics import (
    calculate_fwhm,
    calculate_max_slope_resolution,
    calculate_curvature_resolution
)

def generate_synthetic_distribution(dist_type: str,
                                   params: Dict[str, Any],
                                   n_samples: int = 10000) -> Tuple[np.ndarray, Dict[str, Any]]:
    """
    Génère une distribution synthétique avec des paramètres connus.

    Args:
        dist_type: Type de distribution ('gaussian', 'bimodal', 'multimodal')
        params: Paramètres de la distribution
        n_samples: Nombre d'échantillons à générer

    Returns:
        Tuple[np.ndarray, Dict[str, Any]]: Données générées et paramètres théoriques
    """
    theoretical_params = {}

    if dist_type == 'gaussian':
        # Paramètres: mu (moyenne), sigma (écart-type)
        mu = params.get('mu', 0.0)
        sigma = params.get('sigma', 1.0)

        # Générer les données
        data = np.random.normal(loc=mu, scale=sigma, size=n_samples)

        # Paramètres théoriques
        theoretical_params = {
            'fwhm': 2.355 * sigma,  # FWHM pour une gaussienne
            'max_slope': 1 / (sigma * np.sqrt(2*np.pi*np.e)),  # Pente maximale au point d'inflexion
            'max_curvature': 1 / (sigma**2 * np.sqrt(2*np.pi))  # Courbure maximale
        }

    elif dist_type == 'bimodal':
        # Paramètres: mu1, mu2 (moyennes), sigma1, sigma2 (écarts-types), ratio (proportion)
        mu1 = params.get('mu1', -2.0)
        mu2 = params.get('mu2', 2.0)
        sigma1 = params.get('sigma1', 0.8)
        sigma2 = params.get('sigma2', 0.8)
        ratio = params.get('ratio', 0.5)

        # Générer les données
        n1 = int(n_samples * ratio)
        n2 = n_samples - n1
        data1 = np.random.normal(loc=mu1, scale=sigma1, size=n1)
        data2 = np.random.normal(loc=mu2, scale=sigma2, size=n2)
        data = np.concatenate([data1, data2])

        # Paramètres théoriques (pour chaque mode)
        theoretical_params = {
            'fwhm1': 2.355 * sigma1,
            'fwhm2': 2.355 * sigma2,
            'max_slope1': 1 / (sigma1 * np.sqrt(2*np.pi*np.e)),
            'max_slope2': 1 / (sigma2 * np.sqrt(2*np.pi*np.e)),
            'max_curvature1': 1 / (sigma1**2 * np.sqrt(2*np.pi)),
            'max_curvature2': 1 / (sigma2**2 * np.sqrt(2*np.pi)),
            'mode_distance': abs(mu2 - mu1)
        }

    elif dist_type == 'multimodal':
        # Paramètres: liste de moyennes, écarts-types et proportions
        means = params.get('means', [-4.0, 0.0, 4.0])
        sigmas = params.get('sigmas', [0.8, 0.8, 0.8])
        weights = params.get('weights', [0.3, 0.4, 0.3])

        # Normaliser les poids
        weights = np.array(weights) / np.sum(weights)

        # Générer les données
        data = []
        n_remaining = n_samples

        for i in range(len(means) - 1):
            n_i = int(n_samples * weights[i])
            data.append(np.random.normal(loc=means[i], scale=sigmas[i], size=n_i))
            n_remaining -= n_i

        # Dernier groupe avec le reste des échantillons
        data.append(np.random.normal(loc=means[-1], scale=sigmas[-1], size=n_remaining))
        data = np.concatenate(data)

        # Paramètres théoriques (pour chaque mode)
        theoretical_params = {
            'fwhm': [2.355 * sigma for sigma in sigmas],
            'max_slope': [1 / (sigma * np.sqrt(2*np.pi*np.e)) for sigma in sigmas],
            'max_curvature': [1 / (sigma**2 * np.sqrt(2*np.pi)) for sigma in sigmas],
            'mode_distances': [abs(means[i+1] - means[i]) for i in range(len(means)-1)]
        }

    else:
        raise ValueError(f"Type de distribution inconnu: {dist_type}")

    return data, theoretical_params

def validate_bin_width_resolution_relationship_monte_carlo(
        dist_type: str = 'gaussian',
        dist_params: Optional[Dict[str, Any]] = None,
        bin_width_factors: Optional[np.ndarray] = None,
        n_simulations: int = 100,
        n_samples: int = 10000) -> Dict[str, Any]:
    """
    Valide empiriquement la relation entre largeur des bins et résolution par simulation Monte Carlo.

    Args:
        dist_type: Type de distribution ('gaussian', 'bimodal', 'multimodal')
        dist_params: Paramètres de la distribution
        bin_width_factors: Facteurs de largeur de bin par rapport à sigma
        n_simulations: Nombre de simulations Monte Carlo
        n_samples: Nombre d'échantillons par simulation

    Returns:
        Dict[str, Any]: Résultats de la validation
    """
    # Paramètres par défaut
    if dist_params is None:
        if dist_type == 'gaussian':
            dist_params = {'mu': 0.0, 'sigma': 1.0}
        elif dist_type == 'bimodal':
            dist_params = {'mu1': -2.0, 'mu2': 2.0, 'sigma1': 0.8, 'sigma2': 0.8, 'ratio': 0.5}
        elif dist_type == 'multimodal':
            dist_params = {'means': [-4.0, 0.0, 4.0], 'sigmas': [0.8, 0.8, 0.8], 'weights': [0.3, 0.4, 0.3]}

    if bin_width_factors is None:
        bin_width_factors = np.linspace(0.1, 2.0, 20)

    # Résultats
    results = {
        'dist_type': dist_type,
        'dist_params': dist_params,
        'bin_width_factors': bin_width_factors.tolist(),
        'n_simulations': n_simulations,
        'n_samples': n_samples,
        'fwhm': {
            'errors': [],
            'std_devs': [],
            'theoretical_errors': []
        },
        'slope': {
            'errors': [],
            'std_devs': [],
            'theoretical_errors': []
        },
        'curvature': {
            'errors': [],
            'std_devs': [],
            'theoretical_errors': []
        }
    }

    # Générer une distribution de référence pour obtenir les paramètres théoriques
    _, theoretical_params = generate_synthetic_distribution(dist_type, dist_params, n_samples)

    # Pour chaque facteur de largeur de bin
    for factor in tqdm(bin_width_factors, desc=f"Simulation Monte Carlo ({dist_type})"):
        # Stocker les erreurs pour chaque simulation
        fwhm_errors = []
        slope_errors = []
        curvature_errors = []

        # Exécuter n_simulations
        for _ in range(n_simulations):
            # Générer une nouvelle distribution
            data, _ = generate_synthetic_distribution(dist_type, dist_params, n_samples)

            # Déterminer la largeur des bins
            if dist_type == 'gaussian':
                sigma = dist_params['sigma']
                bin_width = factor * sigma
            elif dist_type == 'bimodal':
                sigma = min(dist_params['sigma1'], dist_params['sigma2'])
                bin_width = factor * sigma
            elif dist_type == 'multimodal':
                sigma = min(dist_params['sigmas'])
                bin_width = factor * sigma

            # Créer l'histogramme
            bin_edges = np.arange(min(data), max(data) + bin_width, bin_width)
            bin_counts, _ = np.histogram(data, bins=bin_edges)

            # Normaliser l'histogramme
            if np.sum(bin_counts) > 0:
                bin_counts = bin_counts / np.max(bin_counts)

            # Calculer les métriques de résolution
            try:
                fwhm_results = calculate_fwhm(bin_counts, bin_edges, interpolate=False)
            except Exception as e:
                print(f"Erreur lors du calcul de FWHM: {e}")
                fwhm_results = {"peaks": [], "fwhm_values": [], "mean_fwhm_values": 0.0}

            try:
                slope_results = calculate_max_slope_resolution(bin_counts, bin_edges, interpolate=False)
            except Exception as e:
                print(f"Erreur lors du calcul de la pente: {e}")
                slope_results = {"peaks": [], "max_slopes": [], "mean_slope_resolution": 0.0}

            try:
                curvature_results = calculate_curvature_resolution(bin_counts, bin_edges, interpolate=False)
            except Exception as e:
                print(f"Erreur lors du calcul de la courbure: {e}")
                curvature_results = {"peaks": [], "max_curvatures": [], "mean_curvature_resolution": 0.0}

            # Calculer les erreurs relatives par rapport aux valeurs théoriques
            if dist_type == 'gaussian':
                # FWHM
                if len(fwhm_results["fwhm_values"]) > 0:
                    measured_fwhm = fwhm_results["mean_fwhm_values"]
                    true_fwhm = theoretical_params['fwhm']
                    fwhm_error = (measured_fwhm - true_fwhm) / true_fwhm
                    fwhm_errors.append(fwhm_error)

                # Pente
                if len(slope_results["max_slopes"]) > 0:
                    measured_slope = np.mean(slope_results["max_slopes"])
                    true_slope = theoretical_params['max_slope']
                    slope_error = (measured_slope - true_slope) / true_slope
                    slope_errors.append(slope_error)

                # Courbure
                if len(curvature_results["max_curvatures"]) > 0:
                    measured_curvature = np.mean(curvature_results["max_curvatures"])
                    true_curvature = theoretical_params['max_curvature']
                    curvature_error = (measured_curvature - true_curvature) / true_curvature
                    curvature_errors.append(curvature_error)

            elif dist_type == 'bimodal':
                # Pour les distributions bimodales, on prend la moyenne des erreurs pour les deux modes
                # FWHM
                if len(fwhm_results["fwhm_values"]) >= 2:
                    measured_fwhms = fwhm_results["fwhm_values"][:2]  # Prendre les deux premiers pics
                    true_fwhms = [theoretical_params['fwhm1'], theoretical_params['fwhm2']]
                    fwhm_error = np.mean([(m - t) / t for m, t in zip(measured_fwhms, true_fwhms)])
                    fwhm_errors.append(fwhm_error)

                # Pente
                if len(slope_results["max_slopes"]) >= 2:
                    measured_slopes = slope_results["max_slopes"][:2]
                    true_slopes = [theoretical_params['max_slope1'], theoretical_params['max_slope2']]
                    slope_error = np.mean([(m - t) / t for m, t in zip(measured_slopes, true_slopes)])
                    slope_errors.append(slope_error)

                # Courbure
                if len(curvature_results["max_curvatures"]) >= 2:
                    measured_curvatures = curvature_results["max_curvatures"][:2]
                    true_curvatures = [theoretical_params['max_curvature1'], theoretical_params['max_curvature2']]
                    curvature_error = np.mean([(m - t) / t for m, t in zip(measured_curvatures, true_curvatures)])
                    curvature_errors.append(curvature_error)

            elif dist_type == 'multimodal':
                # Pour les distributions multimodales, on prend la moyenne des erreurs pour tous les modes
                n_modes = len(theoretical_params['fwhm'])

                # FWHM
                if len(fwhm_results["fwhm_values"]) >= n_modes:
                    measured_fwhms = fwhm_results["fwhm_values"][:n_modes]
                    true_fwhms = theoretical_params['fwhm']
                    fwhm_error = np.mean([(m - t) / t for m, t in zip(measured_fwhms, true_fwhms)])
                    fwhm_errors.append(fwhm_error)

                # Pente
                if len(slope_results["max_slopes"]) >= n_modes:
                    measured_slopes = slope_results["max_slopes"][:n_modes]
                    true_slopes = theoretical_params['max_slope']
                    slope_error = np.mean([(m - t) / t for m, t in zip(measured_slopes, true_slopes)])
                    slope_errors.append(slope_error)

                # Courbure
                if len(curvature_results["max_curvatures"]) >= n_modes:
                    measured_curvatures = curvature_results["max_curvatures"][:n_modes]
                    true_curvatures = theoretical_params['max_curvature']
                    curvature_error = np.mean([(m - t) / t for m, t in zip(measured_curvatures, true_curvatures)])
                    curvature_errors.append(curvature_error)

        # Calculer les moyennes et écarts-types des erreurs
        if fwhm_errors:
            results['fwhm']['errors'].append(float(np.mean(fwhm_errors)))
            results['fwhm']['std_devs'].append(float(np.std(fwhm_errors)))
        else:
            results['fwhm']['errors'].append(np.nan)
            results['fwhm']['std_devs'].append(np.nan)

        if slope_errors:
            results['slope']['errors'].append(float(np.mean(slope_errors)))
            results['slope']['std_devs'].append(float(np.std(slope_errors)))
        else:
            results['slope']['errors'].append(np.nan)
            results['slope']['std_devs'].append(np.nan)

        if curvature_errors:
            results['curvature']['errors'].append(float(np.mean(curvature_errors)))
            results['curvature']['std_devs'].append(float(np.std(curvature_errors)))
        else:
            results['curvature']['errors'].append(np.nan)
            results['curvature']['std_devs'].append(np.nan)

    # Calculer les erreurs théoriques
    # Pour FWHM: sqrt(1 + (bin_width/fwhm)^2) - 1
    if dist_type == 'gaussian':
        true_fwhm = theoretical_params['fwhm']
        bin_width_to_fwhm_ratio = bin_width_factors * dist_params['sigma'] / true_fwhm
        results['fwhm']['theoretical_errors'] = (np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1).tolist()

        # Pour la pente: 1 / (1 + k * (bin_width/sigma)^2) - 1
        k_slope = 0.5  # Coefficient empirique
        results['slope']['theoretical_errors'] = (1 / (1 + k_slope * bin_width_factors**2) - 1).tolist()

        # Pour la courbure: 1 / (1 + k' * (bin_width/sigma)^2) - 1
        k_curvature = 1.0  # Coefficient empirique
        results['curvature']['theoretical_errors'] = (1 / (1 + k_curvature * bin_width_factors**2) - 1).tolist()

    elif dist_type == 'bimodal':
        # Utiliser la moyenne des FWHM pour les deux modes
        true_fwhm = np.mean([theoretical_params['fwhm1'], theoretical_params['fwhm2']])
        sigma = np.mean([dist_params['sigma1'], dist_params['sigma2']])
        bin_width_to_fwhm_ratio = bin_width_factors * sigma / true_fwhm
        results['fwhm']['theoretical_errors'] = (np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1).tolist()

        # Pour la pente et la courbure, utiliser les mêmes formules que pour la gaussienne
        k_slope = 0.5
        results['slope']['theoretical_errors'] = (1 / (1 + k_slope * bin_width_factors**2) - 1).tolist()

        k_curvature = 1.0
        results['curvature']['theoretical_errors'] = (1 / (1 + k_curvature * bin_width_factors**2) - 1).tolist()

    elif dist_type == 'multimodal':
        # Utiliser la moyenne des FWHM pour tous les modes
        true_fwhm = np.mean(theoretical_params['fwhm'])
        sigma = np.mean(dist_params['sigmas'])
        bin_width_to_fwhm_ratio = bin_width_factors * sigma / true_fwhm
        results['fwhm']['theoretical_errors'] = (np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1).tolist()

        # Pour la pente et la courbure, utiliser les mêmes formules que pour la gaussienne
        k_slope = 0.5
        results['slope']['theoretical_errors'] = (1 / (1 + k_slope * bin_width_factors**2) - 1).tolist()

        k_curvature = 1.0
        results['curvature']['theoretical_errors'] = (1 / (1 + k_curvature * bin_width_factors**2) - 1).tolist()

    return results

def plot_monte_carlo_validation_results(results: Dict[str, Any],
                                       save_path: Optional[str] = None,
                                       show_plot: bool = True) -> None:
    """
    Visualise les résultats de la validation Monte Carlo.

    Args:
        results: Résultats de la validation Monte Carlo
        save_path: Chemin où sauvegarder la figure (optionnel)
        show_plot: Si True, affiche la figure
    """
    # Extraire les données
    bin_width_factors = np.array(results['bin_width_factors'])
    dist_type = results['dist_type']

    # Créer la figure
    fig, axes = plt.subplots(3, 1, figsize=(10, 15), sharex=True)

    # Graphique 1: FWHM
    ax1 = axes[0]
    fwhm_errors = np.array(results['fwhm']['errors'])
    fwhm_std_devs = np.array(results['fwhm']['std_devs'])
    fwhm_theoretical = np.array(results['fwhm']['theoretical_errors'])

    # Filtrer les valeurs NaN
    valid_indices = ~np.isnan(fwhm_errors)
    if np.any(valid_indices):
        # Tracer les résultats empiriques avec intervalle de confiance
        ax1.errorbar(bin_width_factors[valid_indices], fwhm_errors[valid_indices],
                    yerr=fwhm_std_devs[valid_indices], fmt='o', color='blue',
                    alpha=0.7, label='Résultats empiriques')

        # Tracer la courbe théorique
        ax1.plot(bin_width_factors, fwhm_theoretical, 'r-', linewidth=2,
                label='Prédiction théorique')

        ax1.set_ylabel('Erreur relative FWHM')
        ax1.set_title(f'Validation Monte Carlo - FWHM ({dist_type}, {results["n_simulations"]} simulations)')
        ax1.grid(True, alpha=0.3)
        ax1.legend()

    # Graphique 2: Pente
    ax2 = axes[1]
    slope_errors = np.array(results['slope']['errors'])
    slope_std_devs = np.array(results['slope']['std_devs'])
    slope_theoretical = np.array(results['slope']['theoretical_errors'])

    # Filtrer les valeurs NaN
    valid_indices = ~np.isnan(slope_errors)
    if np.any(valid_indices):
        # Tracer les résultats empiriques avec intervalle de confiance
        ax2.errorbar(bin_width_factors[valid_indices], slope_errors[valid_indices],
                    yerr=slope_std_devs[valid_indices], fmt='o', color='green',
                    alpha=0.7, label='Résultats empiriques')

        # Tracer la courbe théorique
        ax2.plot(bin_width_factors, slope_theoretical, 'r-', linewidth=2,
                label='Prédiction théorique')

        ax2.set_ylabel('Erreur relative pente maximale')
        ax2.set_title(f'Validation Monte Carlo - Pente ({dist_type}, {results["n_simulations"]} simulations)')
        ax2.grid(True, alpha=0.3)
        ax2.legend()

    # Graphique 3: Courbure
    ax3 = axes[2]
    curvature_errors = np.array(results['curvature']['errors'])
    curvature_std_devs = np.array(results['curvature']['std_devs'])
    curvature_theoretical = np.array(results['curvature']['theoretical_errors'])

    # Filtrer les valeurs NaN
    valid_indices = ~np.isnan(curvature_errors)
    if np.any(valid_indices):
        # Tracer les résultats empiriques avec intervalle de confiance
        ax3.errorbar(bin_width_factors[valid_indices], curvature_errors[valid_indices],
                    yerr=curvature_std_devs[valid_indices], fmt='o', color='purple',
                    alpha=0.7, label='Résultats empiriques')

        # Tracer la courbe théorique
        ax3.plot(bin_width_factors, curvature_theoretical, 'r-', linewidth=2,
                label='Prédiction théorique')

        ax3.set_xlabel('Largeur des bins / σ')
        ax3.set_ylabel('Erreur relative courbure maximale')
        ax3.set_title(f'Validation Monte Carlo - Courbure ({dist_type}, {results["n_simulations"]} simulations)')
        ax3.grid(True, alpha=0.3)
        ax3.legend()

    plt.tight_layout()

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
    print("=== Validation Monte Carlo de la relation entre largeur des bins et résolution ===")

    # Paramètres
    n_simulations = 50  # Nombre de simulations Monte Carlo
    n_samples = 5000    # Nombre d'échantillons par simulation

    # Distribution gaussienne
    print("\nValidation pour une distribution gaussienne...")
    gaussian_results = validate_bin_width_resolution_relationship_monte_carlo(
        dist_type='gaussian',
        dist_params={'mu': 0.0, 'sigma': 1.0},
        bin_width_factors=np.linspace(0.1, 2.0, 10),
        n_simulations=n_simulations,
        n_samples=n_samples
    )

    # Visualiser les résultats
    plot_monte_carlo_validation_results(
        gaussian_results,
        save_path="monte_carlo_validation_gaussian.png",
        show_plot=False
    )

    # Distribution bimodale
    print("\nValidation pour une distribution bimodale...")
    bimodal_results = validate_bin_width_resolution_relationship_monte_carlo(
        dist_type='bimodal',
        dist_params={'mu1': -2.0, 'mu2': 2.0, 'sigma1': 0.8, 'sigma2': 0.8, 'ratio': 0.5},
        bin_width_factors=np.linspace(0.1, 2.0, 10),
        n_simulations=n_simulations,
        n_samples=n_samples
    )

    # Visualiser les résultats
    plot_monte_carlo_validation_results(
        bimodal_results,
        save_path="monte_carlo_validation_bimodal.png",
        show_plot=False
    )

    # Distribution multimodale
    print("\nValidation pour une distribution multimodale...")
    multimodal_results = validate_bin_width_resolution_relationship_monte_carlo(
        dist_type='multimodal',
        dist_params={'means': [-4.0, 0.0, 4.0], 'sigmas': [0.8, 0.8, 0.8], 'weights': [0.3, 0.4, 0.3]},
        bin_width_factors=np.linspace(0.1, 2.0, 10),
        n_simulations=n_simulations,
        n_samples=n_samples
    )

    # Visualiser les résultats
    plot_monte_carlo_validation_results(
        multimodal_results,
        save_path="monte_carlo_validation_multimodal.png",
        show_plot=False
    )

    print("\nValidation terminée avec succès!")
    print("Résultats sauvegardés dans les fichiers:")
    print("- monte_carlo_validation_gaussian.png")
    print("- monte_carlo_validation_bimodal.png")
    print("- monte_carlo_validation_multimodal.png")
