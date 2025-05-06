#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant l'algorithme de calcul de l'indice global de conservation des moments statistiques
pour les histogrammes de latence.
"""

import numpy as np
import math
import scipy.stats

# Importer le module de gestion des seuils par type de distribution
try:
    from distribution_thresholds import DistributionThresholds
    DISTRIBUTION_THRESHOLDS_AVAILABLE = True
except ImportError:
    DISTRIBUTION_THRESHOLDS_AVAILABLE = False


def calculate_mean_relative_error(real_data, bin_edges, bin_counts):
    """
    Calcule l'erreur relative de la moyenne.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme

    Returns:
        relative_error: Erreur relative en pourcentage
    """
    real_mean = np.mean(real_data)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer l'erreur relative en pourcentage
    if abs(real_mean) > 1e-10:
        relative_error = abs(real_mean - hist_mean) / abs(real_mean) * 100
    else:
        relative_error = 100.0 if abs(hist_mean) > 1e-10 else 0.0

    return relative_error


def calculate_variance_relative_error(real_data, bin_edges, bin_counts):
    """
    Calcule l'erreur relative de la variance.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme

    Returns:
        relative_error: Erreur relative en pourcentage
    """
    real_variance = np.var(real_data, ddof=1)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer la variance non corrigée
    hist_variance_uncorrected = np.sum(frequencies * (bin_centers - hist_mean)**2)

    # Appliquer la correction de Sheppard
    bin_widths = np.diff(bin_edges)
    if len(bin_widths) > 0:
        # Pour les bins à largeur variable, utiliser la largeur moyenne pondérée
        weighted_bin_width = np.sum(bin_widths * frequencies)
        correction = weighted_bin_width**2 / 12
    else:
        correction = 0

    # Variance corrigée
    hist_variance = hist_variance_uncorrected + correction

    # Calculer l'erreur relative en pourcentage
    if abs(real_variance) > 1e-10:
        relative_error = abs(real_variance - hist_variance) / abs(real_variance) * 100
    else:
        relative_error = 100.0 if abs(hist_variance) > 1e-10 else 0.0

    return relative_error


def calculate_skewness_relative_error(real_data, bin_edges, bin_counts):
    """
    Calcule l'erreur relative de l'asymétrie.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme

    Returns:
        relative_error: Erreur relative en pourcentage
    """
    real_skewness = scipy.stats.skew(real_data, bias=False)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer les moments centrés
    m2 = np.sum(frequencies * (bin_centers - hist_mean)**2)
    m3 = np.sum(frequencies * (bin_centers - hist_mean)**3)

    # Calculer l'asymétrie
    if m2 > 1e-10:
        hist_skewness = m3 / (m2**(3/2))
    else:
        hist_skewness = 0.0

    # Calculer l'erreur relative en pourcentage
    if abs(real_skewness) > 1e-10:
        relative_error = abs(real_skewness - hist_skewness) / abs(real_skewness) * 100
    else:
        relative_error = 100.0 if abs(hist_skewness) > 1e-10 else 0.0

    return relative_error


def calculate_kurtosis_relative_error(real_data, bin_edges, bin_counts):
    """
    Calcule l'erreur relative de l'aplatissement.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme

    Returns:
        relative_error: Erreur relative en pourcentage
    """
    real_kurtosis = scipy.stats.kurtosis(real_data, fisher=False, bias=False)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer les moments centrés
    m2 = np.sum(frequencies * (bin_centers - hist_mean)**2)
    m4 = np.sum(frequencies * (bin_centers - hist_mean)**4)

    # Calculer l'aplatissement
    if m2 > 1e-10:
        hist_kurtosis = m4 / (m2**2)
    else:
        hist_kurtosis = 3.0  # Valeur par défaut pour la distribution normale

    # Calculer l'erreur relative en pourcentage
    if abs(real_kurtosis) > 1e-10:
        relative_error = abs(real_kurtosis - hist_kurtosis) / abs(real_kurtosis) * 100
    else:
        relative_error = 100.0 if abs(hist_kurtosis - 3.0) > 1e-10 else 0.0

    return relative_error


def calculate_global_moment_conservation_index(real_data, bin_edges, bin_counts,
                                              weights=None, thresholds=None,
                                              saturation_values=None, context=None):
    """
    Calcule l'indice global de conservation des moments.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        thresholds: Seuils d'acceptabilité [T₁, T₂, T₃, T₄]
        saturation_values: Valeurs de saturation [S₁, S₂, S₃, S₄]
        context: Contexte d'analyse pour pondération adaptative

    Returns:
        igcm: Indice global de conservation des moments
        component_indices: Indices individuels pour chaque moment
        errors: Erreurs relatives pour chaque moment
    """
    # Définir les poids par défaut ou selon le contexte
    if weights is None:
        if context == "monitoring":
            weights = [0.50, 0.30, 0.15, 0.05]
        elif context == "stability":
            weights = [0.20, 0.50, 0.20, 0.10]
        elif context == "anomaly_detection":
            weights = [0.20, 0.25, 0.35, 0.20]
        elif context == "characterization":
            weights = [0.25, 0.25, 0.25, 0.25]
        else:
            weights = [0.40, 0.30, 0.20, 0.10]  # Défaut

    # Normaliser les poids
    weights = [w / sum(weights) for w in weights]

    # Définir les seuils d'acceptabilité par défaut
    if thresholds is None:
        thresholds = [5.0, 20.0, 30.0, 40.0]  # En pourcentage

    # Définir les valeurs de saturation par défaut
    if saturation_values is None:
        saturation_values = [20.0, 50.0, 100.0, 150.0]  # En pourcentage

    # Calculer les erreurs relatives pour chaque moment
    mean_error = calculate_mean_relative_error(real_data, bin_edges, bin_counts)
    variance_error = calculate_variance_relative_error(real_data, bin_edges, bin_counts)
    skewness_error = calculate_skewness_relative_error(real_data, bin_edges, bin_counts)
    kurtosis_error = calculate_kurtosis_relative_error(real_data, bin_edges, bin_counts)

    errors = [mean_error, variance_error, skewness_error, kurtosis_error]

    # Calculer les indices individuels avec fonction exponentielle
    alpha = 2.3  # Paramètre de sensibilité
    component_indices = []

    for i in range(4):
        # Limiter l'erreur à la valeur de saturation
        capped_error = min(errors[i], saturation_values[i])
        # Calculer l'indice normalisé avec pénalité exponentielle
        index = math.exp(-alpha * (capped_error / thresholds[i])**2)
        component_indices.append(index)

    # Calculer l'indice global comme moyenne pondérée
    igcm = sum(w * idx for w, idx in zip(weights, component_indices))

    return igcm, component_indices, errors


def get_quality_level(igcm, context=None, distribution_type=None, latency_region=None):
    """
    Détermine le niveau de qualité correspondant à l'IGCM.

    Args:
        igcm: Indice global de conservation des moments
        context: Contexte d'analyse (monitoring, stability, etc.)
        distribution_type: Type de distribution (quasiNormal, asymmetric, etc.)
        latency_region: Région de latence (l1l2Cache, l3Memory, etc.)

    Returns:
        quality_level: Niveau de qualité (Excellent, Très bon, etc.)
        thresholds: Seuils utilisés pour l'évaluation
    """
    # Utiliser le module de gestion des seuils par type de distribution si disponible
    if DISTRIBUTION_THRESHOLDS_AVAILABLE and distribution_type is not None:
        try:
            # Créer une instance du gestionnaire de seuils
            dist_thresholds = DistributionThresholds()

            # Obtenir les seuils GMCI pour le type de distribution
            thresholds = dist_thresholds.get_gmci_thresholds(distribution_type)

            # Si les seuils ont été trouvés, les utiliser
            if thresholds:
                # Déterminer le niveau de qualité
                if igcm >= thresholds.get("excellent", 0.90):
                    quality_level = "Excellent"
                elif igcm >= thresholds.get("veryGood", 0.80):
                    quality_level = "Très bon"
                elif igcm >= thresholds.get("good", 0.70):
                    quality_level = "Bon"
                elif igcm >= thresholds.get("acceptable", 0.60):
                    quality_level = "Acceptable"
                elif igcm >= thresholds.get("limited", 0.50):
                    quality_level = "Limité"
                else:
                    quality_level = "Insuffisant"

                return quality_level, thresholds
        except Exception as e:
            print(f"Erreur lors de la récupération des seuils GMCI: {e}")
            print("Utilisation des seuils par défaut.")

    # Seuils par défaut si le module n'est pas disponible ou en cas d'erreur
    default_thresholds = {
        "excellent": 0.90,
        "veryGood": 0.80,
        "good": 0.70,
        "acceptable": 0.60,
        "limited": 0.50
    }

    # Sélectionner les seuils appropriés selon le contexte
    if context == "monitoring":
        thresholds = {
            "excellent": 0.85,
            "veryGood": 0.75,
            "good": 0.65,
            "acceptable": 0.55,
            "limited": 0.45
        }
    elif context == "stability":
        thresholds = {
            "excellent": 0.92,
            "veryGood": 0.85,
            "good": 0.75,
            "acceptable": 0.65,
            "limited": 0.55
        }
    elif context == "anomaly_detection":
        thresholds = {
            "excellent": 0.88,
            "veryGood": 0.78,
            "good": 0.68,
            "acceptable": 0.58,
            "limited": 0.48
        }
    elif context == "characterization":
        thresholds = {
            "excellent": 0.95,
            "veryGood": 0.90,
            "good": 0.80,
            "acceptable": 0.70,
            "limited": 0.60
        }
    # Ajuster selon le type de distribution si spécifié
    elif distribution_type == "quasiNormal":
        thresholds = {
            "excellent": 0.88,
            "veryGood": 0.78,
            "good": 0.68,
            "acceptable": 0.58,
            "limited": 0.48
        }
    elif distribution_type == "highlyAsymmetric":
        thresholds = {
            "excellent": 0.92,
            "veryGood": 0.82,
            "good": 0.72,
            "acceptable": 0.62,
            "limited": 0.52
        }
    # Ajuster selon la région de latence si spécifiée
    elif latency_region == "l1l2Cache":
        thresholds = {
            "excellent": 0.92,
            "veryGood": 0.82,
            "good": 0.72,
            "acceptable": 0.62,
            "limited": 0.52
        }
    elif latency_region == "storage":
        thresholds = {
            "excellent": 0.85,
            "veryGood": 0.75,
            "good": 0.65,
            "acceptable": 0.55,
            "limited": 0.45
        }
    else:
        thresholds = default_thresholds

    # Déterminer le niveau de qualité
    if igcm >= thresholds["excellent"]:
        quality_level = "Excellent"
    elif igcm >= thresholds["veryGood"]:
        quality_level = "Très bon"
    elif igcm >= thresholds["good"]:
        quality_level = "Bon"
    elif igcm >= thresholds["acceptable"]:
        quality_level = "Acceptable"
    elif igcm >= thresholds["limited"]:
        quality_level = "Limité"
    else:
        quality_level = "Insuffisant"

    return quality_level, thresholds


def generate_histogram(data, config):
    """
    Génère un histogramme selon la configuration spécifiée.

    Args:
        data: Données à représenter
        config: Configuration de l'histogramme (nombre de bins, type, etc.)

    Returns:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
    """
    num_bins = config.get("num_bins", 20)
    bin_type = config.get("type", "uniform")

    if bin_type == "uniform":
        bin_edges = np.linspace(min(data), max(data), num_bins + 1)
    elif bin_type == "logarithmic":
        if min(data) <= 0:
            min_value = max(min(data), 1e-10)  # Éviter les valeurs négatives ou nulles
        else:
            min_value = min(data)
        bin_edges = np.logspace(np.log10(min_value), np.log10(max(data)), num_bins + 1)
    elif bin_type == "quantile":
        quantiles = np.linspace(0, 100, num_bins + 1)
        bin_edges = np.percentile(data, quantiles)
    else:
        # Par défaut, utiliser des bins uniformes
        bin_edges = np.linspace(min(data), max(data), num_bins + 1)

    # Calculer les comptages
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    return bin_edges, bin_counts


def evaluate_histogram_quality(real_data, config, context=None):
    """
    Évalue la qualité d'un histogramme selon l'indice global de conservation des moments.

    Args:
        real_data: Données réelles
        config: Configuration de l'histogramme
        context: Contexte d'analyse

    Returns:
        result: Dictionnaire des résultats d'évaluation
    """
    # Générer l'histogramme
    bin_edges, bin_counts = generate_histogram(real_data, config)

    # Calculer l'IGCM
    igcm, component_indices, errors = calculate_global_moment_conservation_index(
        real_data, bin_edges, bin_counts, context=context
    )

    # Déterminer le niveau de qualité
    quality_level, thresholds = get_quality_level(igcm, context=context)

    # Préparer les résultats
    result = {
        "igcm": igcm,
        "quality_level": quality_level,
        "component_indices": {
            "mean": component_indices[0],
            "variance": component_indices[1],
            "skewness": component_indices[2],
            "kurtosis": component_indices[3]
        },
        "errors": {
            "mean": errors[0],
            "variance": errors[1],
            "skewness": errors[2],
            "kurtosis": errors[3]
        },
        "thresholds": thresholds,
        "histogram_config": config
    }

    return result


def optimize_histogram_config(real_data, target_quality="Bon", context=None, max_bins=100):
    """
    Optimise la configuration d'un histogramme pour atteindre un niveau de qualité cible.

    Args:
        real_data: Données réelles
        target_quality: Niveau de qualité cible (Excellent, Très bon, Bon, etc.)
        context: Contexte d'analyse
        max_bins: Nombre maximum de bins à considérer

    Returns:
        optimal_config: Configuration optimale de l'histogramme
        evaluation: Évaluation de la qualité avec cette configuration
    """
    # Mapper le niveau de qualité cible à un seuil IGCM
    quality_thresholds = {
        "Excellent": 0.90,
        "Très bon": 0.80,
        "Bon": 0.70,
        "Acceptable": 0.60,
        "Limité": 0.50
    }

    target_igcm = quality_thresholds.get(target_quality, 0.70)  # Par défaut: Bon

    # Types de binning à tester
    bin_types = ["uniform", "logarithmic", "quantile"]

    best_igcm = 0.0
    optimal_config = None
    best_evaluation = None

    # Tester différentes configurations
    for bin_type in bin_types:
        # Commencer avec un nombre modéré de bins
        start_bins = 10 if bin_type == "uniform" else 15

        for num_bins in range(start_bins, max_bins + 1, 5):
            config = {
                "type": bin_type,
                "num_bins": num_bins
            }

            evaluation = evaluate_histogram_quality(real_data, config, context)

            # Mettre à jour la meilleure configuration si nécessaire
            if evaluation["igcm"] > best_igcm:
                best_igcm = evaluation["igcm"]
                optimal_config = config
                best_evaluation = evaluation

            # Arrêter si la qualité cible est atteinte
            if evaluation["igcm"] >= target_igcm:
                return config, evaluation

    return optimal_config, best_evaluation


if __name__ == "__main__":
    # Exemple d'utilisation
    import matplotlib.pyplot as plt
    from typing import List, Dict, Any

    # Générer des données synthétiques
    np.random.seed(42)
    data = np.random.lognormal(mean=0, sigma=1, size=1000)

    # Évaluer différentes configurations
    configs = [
        {"type": "uniform", "num_bins": 10},
        {"type": "uniform", "num_bins": 20},
        {"type": "logarithmic", "num_bins": 10},
        {"type": "logarithmic", "num_bins": 20},
        {"type": "quantile", "num_bins": 10},
        {"type": "quantile", "num_bins": 20}
    ]

    results: List[Dict[str, Any]] = []
    for config in configs:
        result = evaluate_histogram_quality(data, config)
        results.append(result)
        print(f"Configuration: {config}")
        print(f"IGCM: {result['igcm']:.4f}, Qualité: {result['quality_level']}")
        print(f"Erreurs: Moyenne={result['errors']['mean']:.2f}%, Variance={result['errors']['variance']:.2f}%")
        print(f"         Asymétrie={result['errors']['skewness']:.2f}%, Aplatissement={result['errors']['kurtosis']:.2f}%")
        print("-" * 50)

    # Tester l'utilisation du module de gestion des seuils par type de distribution
    if DISTRIBUTION_THRESHOLDS_AVAILABLE:
        print("\nTest du module de gestion des seuils par type de distribution:")
        dist_thresholds = DistributionThresholds()

        # Afficher les types de distribution disponibles
        dist_types = dist_thresholds.get_distribution_types()
        print(f"Types de distribution disponibles: {', '.join(dist_types)}")

        # Afficher les seuils pour quelques types de distribution
        for dist_type in ["normal", "asymmetric", "multimodal", "leptokurtic"]:
            if dist_type in dist_types:
                gmci_thresholds = dist_thresholds.get_gmci_thresholds(dist_type)
                print(f"\nSeuils GMCI pour le type de distribution '{dist_type}':")
                for level, value in gmci_thresholds.items():
                    print(f"  {level}: {value}")

    # Trouver la configuration optimale pour un niveau de qualité "Très bon"
    optimal_config, optimal_eval = optimize_histogram_config(data, target_quality="Très bon")
    print("\nConfiguration optimale pour qualité 'Très bon':")

    if optimal_config is not None and optimal_eval is not None:
        print(f"Configuration: {optimal_config}")
        print(f"IGCM: {optimal_eval['igcm']:.4f}, Qualité: {optimal_eval['quality_level']}")
        print(f"Erreurs: Moyenne={optimal_eval['errors']['mean']:.2f}%, Variance={optimal_eval['errors']['variance']:.2f}%")
        print(f"         Asymétrie={optimal_eval['errors']['skewness']:.2f}%, Aplatissement={optimal_eval['errors']['kurtosis']:.2f}%")
    else:
        print("Aucune configuration optimale trouvée.")

    # Visualiser les histogrammes
    plt.figure(figsize=(15, 10))

    for i, config in enumerate(configs):
        plt.subplot(2, 3, i+1)
        bin_edges, _ = generate_histogram(data, config)
        # Utiliser directement les bin_edges pour l'histogramme
        plt.hist(data, bins=len(bin_edges)-1, range=(bin_edges[0], bin_edges[-1]), alpha=0.7)
        plt.title(f"{config['type'].capitalize()}, {config['num_bins']} bins\nIGCM: {results[i]['igcm']:.4f}")
        plt.xlabel("Valeur")
        plt.ylabel("Fréquence")

    plt.tight_layout()
    plt.savefig("histogram_quality_comparison.png")
    plt.close()

    print("\nComparaison des histogrammes enregistrée dans 'histogram_quality_comparison.png'")
