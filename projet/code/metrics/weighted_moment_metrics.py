#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant des métriques pondérées pour chaque moment statistique.
"""

import numpy as np
import scipy.stats


def weighted_mean_error(real_data, bin_edges, bin_counts, weight=1.0):
    """
    Calcule l'erreur pondérée pour la moyenne.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weight: Poids attribué à cette métrique

    Returns:
        weighted_error: Erreur pondérée
        raw_error: Erreur brute (non pondérée)
    """
    # Vérifier si les données sont vides
    if len(real_data) == 0:
        raise ValueError("Les données ne peuvent pas être vides")

    # Calculer la moyenne réelle
    real_mean = np.mean(real_data)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return weight * 100.0, 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer l'erreur relative en pourcentage
    if abs(real_mean) > 1e-10:
        relative_error = abs(real_mean - hist_mean) / abs(real_mean) * 100
    else:
        relative_error = 100.0 if abs(hist_mean) > 1e-10 else 0.0

    # Appliquer la pondération
    weighted_error = weight * relative_error

    return weighted_error, relative_error


def weighted_variance_error(real_data, bin_edges, bin_counts, weight=1.0, apply_correction=True):
    """
    Calcule l'erreur pondérée pour la variance.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weight: Poids attribué à cette métrique
        apply_correction: Appliquer la correction de Sheppard

    Returns:
        weighted_error: Erreur pondérée
        raw_error: Erreur brute (non pondérée)
    """
    # Vérifier si les données sont vides
    if len(real_data) == 0:
        raise ValueError("Les données ne peuvent pas être vides")

    # Calculer la variance réelle
    real_variance = np.var(real_data, ddof=1)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return weight * 100.0, 100.0

    frequencies = bin_counts / total_count

    # Calculer la moyenne de l'histogramme
    hist_mean = np.sum(bin_centers * frequencies)

    # Calculer la variance non corrigée
    hist_variance_uncorrected = np.sum(frequencies * (bin_centers - hist_mean)**2)

    # Appliquer la correction de Sheppard si demandé
    if apply_correction:
        bin_widths = np.diff(bin_edges)
        if len(bin_widths) > 0:
            # Pour les bins à largeur variable, utiliser la largeur moyenne pondérée
            weighted_bin_width = np.sum(bin_widths * frequencies)
            correction = weighted_bin_width**2 / 12

            # Variance corrigée (soustraire la correction pour réduire l'erreur)
            hist_variance = hist_variance_uncorrected - correction
        else:
            hist_variance = hist_variance_uncorrected
    else:
        hist_variance = hist_variance_uncorrected

    # Calculer l'erreur relative en pourcentage
    if abs(real_variance) > 1e-10:
        relative_error = abs(real_variance - hist_variance) / abs(real_variance) * 100
    else:
        relative_error = 100.0 if abs(hist_variance) > 1e-10 else 0.0

    # Appliquer la pondération
    weighted_error = weight * relative_error

    return weighted_error, relative_error


def weighted_skewness_error(real_data, bin_edges, bin_counts, weight=1.0):
    """
    Calcule l'erreur pondérée pour l'asymétrie.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weight: Poids attribué à cette métrique

    Returns:
        weighted_error: Erreur pondérée
        raw_error: Erreur brute (non pondérée)
    """
    # Vérifier si les données sont vides
    if len(real_data) == 0:
        raise ValueError("Les données ne peuvent pas être vides")

    # Calculer l'asymétrie réelle
    real_skewness = scipy.stats.skew(real_data, bias=False)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return weight * 100.0, 100.0

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

    # Appliquer la pondération
    weighted_error = weight * relative_error

    return weighted_error, relative_error


def weighted_kurtosis_error(real_data, bin_edges, bin_counts, weight=1.0):
    """
    Calcule l'erreur pondérée pour l'aplatissement.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weight: Poids attribué à cette métrique

    Returns:
        weighted_error: Erreur pondérée
        raw_error: Erreur brute (non pondérée)
    """
    # Vérifier si les données sont vides
    if len(real_data) == 0:
        raise ValueError("Les données ne peuvent pas être vides")

    # Calculer l'aplatissement réel
    real_kurtosis = scipy.stats.kurtosis(real_data, fisher=False, bias=False)

    # Calculer les centres des bins
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

    # Calculer les fréquences relatives
    total_count = np.sum(bin_counts)
    if total_count == 0:
        return weight * 100.0, 100.0

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

    # Appliquer la pondération
    weighted_error = weight * relative_error

    return weighted_error, relative_error


def calculate_total_weighted_error(real_data, bin_edges, bin_counts, weights=None):
    """
    Calcule l'erreur totale pondérée pour tous les moments.

    Args:
        real_data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Liste des poids [w₁, w₂, w₃, w₄] pour chaque moment

    Returns:
        total_weighted_error: Erreur totale pondérée
        component_errors: Dictionnaire des erreurs par composante
    """
    # Définir les poids par défaut si non spécifiés
    if weights is None:
        weights = [0.40, 0.30, 0.20, 0.10]  # [moyenne, variance, asymétrie, aplatissement]

    # Normaliser les poids
    sum_weights = sum(weights)
    if sum_weights > 0:
        weights = [w / sum_weights for w in weights]
    else:
        weights = [0.25, 0.25, 0.25, 0.25]  # Poids égaux par défaut

    # Si tous les poids sont à zéro, ne pas normaliser et retourner une erreur totale de zéro
    if all(w == 0.0 for w in weights):
        # Calculer les erreurs brutes pour chaque moment (pour les inclure dans les composantes)
        _, mean_raw = weighted_mean_error(real_data, bin_edges, bin_counts, 0.0)
        _, variance_raw = weighted_variance_error(real_data, bin_edges, bin_counts, 0.0)
        _, skewness_raw = weighted_skewness_error(real_data, bin_edges, bin_counts, 0.0)
        _, kurtosis_raw = weighted_kurtosis_error(real_data, bin_edges, bin_counts, 0.0)

        return 0.0, {
            "mean": {"raw_error": mean_raw, "weight": 0.0, "weighted_error": 0.0},
            "variance": {"raw_error": variance_raw, "weight": 0.0, "weighted_error": 0.0},
            "skewness": {"raw_error": skewness_raw, "weight": 0.0, "weighted_error": 0.0},
            "kurtosis": {"raw_error": kurtosis_raw, "weight": 0.0, "weighted_error": 0.0}
        }

    # Calculer les erreurs pondérées pour chaque moment
    mean_error, mean_raw = weighted_mean_error(real_data, bin_edges, bin_counts, weights[0])
    variance_error, variance_raw = weighted_variance_error(real_data, bin_edges, bin_counts, weights[1])
    skewness_error, skewness_raw = weighted_skewness_error(real_data, bin_edges, bin_counts, weights[2])
    kurtosis_error, kurtosis_raw = weighted_kurtosis_error(real_data, bin_edges, bin_counts, weights[3])

    # Calculer l'erreur totale pondérée
    total_weighted_error = mean_error + variance_error + skewness_error + kurtosis_error

    # Préparer le dictionnaire des erreurs par composante
    component_errors = {
        "mean": {
            "raw_error": mean_raw,
            "weight": weights[0],
            "weighted_error": mean_error
        },
        "variance": {
            "raw_error": variance_raw,
            "weight": weights[1],
            "weighted_error": variance_error
        },
        "skewness": {
            "raw_error": skewness_raw,
            "weight": weights[2],
            "weighted_error": skewness_error
        },
        "kurtosis": {
            "raw_error": kurtosis_raw,
            "weight": weights[3],
            "weighted_error": kurtosis_error
        }
    }

    return total_weighted_error, component_errors


if __name__ == "__main__":
    # Test des métriques pondérées
    import matplotlib.pyplot as plt

    # Générer des données synthétiques
    np.random.seed(42)
    data = np.random.gamma(shape=3, scale=50, size=1000)

    # Générer un histogramme
    bin_edges = np.linspace(min(data), max(data), 21)  # 20 bins
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Calculer les erreurs pondérées avec différents jeux de poids
    weight_sets = [
        [1.0, 0.0, 0.0, 0.0],  # Uniquement la moyenne
        [0.0, 1.0, 0.0, 0.0],  # Uniquement la variance
        [0.0, 0.0, 1.0, 0.0],  # Uniquement l'asymétrie
        [0.0, 0.0, 0.0, 1.0],  # Uniquement l'aplatissement
        [0.25, 0.25, 0.25, 0.25],  # Poids égaux
        [0.40, 0.30, 0.20, 0.10],  # Poids par défaut
        [0.50, 0.30, 0.15, 0.05],  # Monitoring opérationnel
        [0.20, 0.50, 0.20, 0.10]   # Analyse de stabilité
    ]

    weight_names = [
        "Moyenne uniquement",
        "Variance uniquement",
        "Asymétrie uniquement",
        "Aplatissement uniquement",
        "Poids égaux",
        "Poids par défaut",
        "Monitoring opérationnel",
        "Analyse de stabilité"
    ]

    # Calculer et afficher les résultats
    print("Test des métriques pondérées pour les moments statistiques")
    print("=" * 80)

    for weights, name in zip(weight_sets, weight_names):
        total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)

        print(f"\nJeu de poids: {name}")
        print(f"Poids: {weights}")
        print(f"Erreur totale pondérée: {total_error:.2f}")
        print("Composantes:")
        for moment, error_info in components.items():
            print(f"  {moment.capitalize()}: Erreur brute = {error_info['raw_error']:.2f}%, "
                  f"Poids = {error_info['weight']:.2f}, "
                  f"Erreur pondérée = {error_info['weighted_error']:.2f}")

    # Visualiser l'impact des différents jeux de poids
    plt.figure(figsize=(12, 8))

    # Préparer les données pour le graphique
    moments = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]

    # Calculer les erreurs brutes (non pondérées)
    _, components = calculate_total_weighted_error(data, bin_edges, bin_counts, [1, 1, 1, 1])
    raw_errors = [components[m.lower()]["raw_error"] for m in moments]

    # Créer le graphique à barres groupées pour les erreurs pondérées
    x = np.arange(len(moments))
    width = 0.1

    for i, (weights, name) in enumerate(zip(weight_sets[4:], weight_names[4:])):
        _, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
        weighted_errors = [components[m.lower()]["weighted_error"] for m in moments]

        plt.bar(x + (i - 2) * width, weighted_errors, width, label=name)

    plt.xlabel('Moment statistique')
    plt.ylabel('Erreur pondérée')
    plt.title('Impact des différents jeux de poids sur les erreurs')
    plt.xticks(x, moments)
    plt.legend()
    plt.grid(axis='y', linestyle='--', alpha=0.7)

    plt.tight_layout()
    plt.savefig("weighted_metrics_comparison.png")

    print("\nVisualisation enregistrée dans 'weighted_metrics_comparison.png'")
    print("=" * 80)
