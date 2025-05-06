#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module pour analyser l'impact des pondérations sur la sensibilité des métriques.
"""

import numpy as np
import matplotlib.pyplot as plt
import scipy.stats
from weighted_moment_metrics import (
    weighted_mean_error,
    weighted_variance_error,
    weighted_skewness_error,
    weighted_kurtosis_error,
    calculate_total_weighted_error
)


def calculate_sensitivity_coefficient(data, bin_edges, bin_counts, moment_index, weight_range=(0.1, 0.5)):
    """
    Calcule le coefficient de sensibilité pour un moment donné.
    
    Args:
        data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        moment_index: Indice du moment (0=moyenne, 1=variance, 2=asymétrie, 3=aplatissement)
        weight_range: Plage de poids à tester (min, max)
        
    Returns:
        sensitivity_coefficient: Coefficient de sensibilité
    """
    # Fonctions d'erreur par moment
    error_functions = [
        weighted_mean_error,
        weighted_variance_error,
        weighted_skewness_error,
        weighted_kurtosis_error
    ]
    
    # Calculer l'erreur avec le poids minimum
    min_weight, max_weight = weight_range
    min_error, _ = error_functions[moment_index](data, bin_edges, bin_counts, min_weight)
    
    # Calculer l'erreur avec le poids maximum
    max_error, _ = error_functions[moment_index](data, bin_edges, bin_counts, max_weight)
    
    # Calculer la variation relative de l'erreur
    if min_error > 0:
        error_variation = (max_error - min_error) / min_error
    else:
        error_variation = float('inf')
    
    # Calculer la variation relative du poids
    weight_variation = (max_weight - min_weight) / min_weight
    
    # Calculer le coefficient de sensibilité
    if weight_variation > 0:
        sensitivity_coefficient = error_variation / weight_variation
    else:
        sensitivity_coefficient = float('inf')
    
    return sensitivity_coefficient


def calculate_discrimination_index(data, bin_strategies, weights):
    """
    Calcule l'indice de discrimination entre différentes stratégies de binning.
    
    Args:
        data: Données réelles
        bin_strategies: Liste de tuples (bin_edges, bin_counts) pour différentes stratégies
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        
    Returns:
        discrimination_index: Indice de discrimination
    """
    # Calculer l'erreur totale pondérée pour chaque stratégie
    total_errors = []
    for bin_edges, bin_counts in bin_strategies:
        total_error, _ = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
        total_errors.append(total_error)
    
    # Calculer l'écart-type et la moyenne des erreurs
    std_error = np.std(total_errors)
    mean_error = np.mean(total_errors)
    
    # Calculer l'indice de discrimination
    if mean_error > 0:
        discrimination_index = std_error / mean_error
    else:
        discrimination_index = 0.0
    
    return discrimination_index


def calculate_signal_to_noise_ratio(data, bin_strategies, weights, noise_level=0.05):
    """
    Calcule le ratio signal/bruit pour les métriques pondérées.
    
    Args:
        data: Données réelles
        bin_strategies: Liste de tuples (bin_edges, bin_counts) pour différentes stratégies
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        noise_level: Niveau de bruit à introduire (proportion de la variance)
        
    Returns:
        snr: Ratio signal/bruit
    """
    # Calculer l'erreur totale pondérée pour chaque stratégie
    strategy_errors = []
    for bin_edges, bin_counts in bin_strategies:
        total_error, _ = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
        strategy_errors.append(total_error)
    
    # Calculer la variance due aux différentes stratégies
    strategy_variance = np.var(strategy_errors)
    
    # Introduire du bruit dans les données
    noise_std = np.std(data) * noise_level
    noisy_errors = []
    
    # Pour chaque stratégie, calculer l'erreur avec données bruitées
    for bin_edges, bin_counts in bin_strategies:
        # Répéter plusieurs fois avec différents bruits
        strategy_noisy_errors = []
        for _ in range(10):
            noisy_data = data + np.random.normal(0, noise_std, size=len(data))
            total_error, _ = calculate_total_weighted_error(noisy_data, bin_edges, bin_counts, weights)
            strategy_noisy_errors.append(total_error)
        
        # Calculer la variance due au bruit pour cette stratégie
        noisy_errors.append(np.var(strategy_noisy_errors))
    
    # Calculer la variance moyenne due au bruit
    noise_variance = np.mean(noisy_errors)
    
    # Calculer le ratio signal/bruit
    if noise_variance > 0:
        snr = strategy_variance / noise_variance
    else:
        snr = float('inf')
    
    return snr


def analyze_weighting_impact(data, bin_strategies, weight_sets, weight_names):
    """
    Analyse l'impact des différentes stratégies de pondération.
    
    Args:
        data: Données réelles
        bin_strategies: Liste de tuples (bin_edges, bin_counts, strategy_name)
        weight_sets: Liste de listes de poids [w₁, w₂, w₃, w₄]
        weight_names: Noms des stratégies de pondération
        
    Returns:
        results: Dictionnaire des résultats d'analyse
    """
    results = {
        "sensitivity_coefficients": [],
        "discrimination_indices": [],
        "signal_to_noise_ratios": [],
        "total_errors": []
    }
    
    # Calculer les coefficients de sensibilité pour chaque moment
    bin_edges, bin_counts, _ = bin_strategies[0]  # Utiliser la première stratégie pour l'analyse de sensibilité
    
    for moment_index in range(4):
        moment_sensitivity = []
        for weight_range in [(0.1, 0.3), (0.3, 0.5), (0.5, 0.7)]:
            sc = calculate_sensitivity_coefficient(data, bin_edges, bin_counts, moment_index, weight_range)
            moment_sensitivity.append(sc)
        
        results["sensitivity_coefficients"].append(moment_sensitivity)
    
    # Calculer les indices de discrimination pour chaque stratégie de pondération
    bin_strategy_tuples = [(edges, counts) for edges, counts, _ in bin_strategies]
    
    for weights in weight_sets:
        di = calculate_discrimination_index(data, bin_strategy_tuples, weights)
        results["discrimination_indices"].append(di)
    
    # Calculer les ratios signal/bruit pour chaque stratégie de pondération
    for weights in weight_sets:
        snr = calculate_signal_to_noise_ratio(data, bin_strategy_tuples, weights)
        results["signal_to_noise_ratios"].append(snr)
    
    # Calculer les erreurs totales pour chaque combinaison de stratégie de binning et de pondération
    for bin_edges, bin_counts, strategy_name in bin_strategies:
        strategy_errors = []
        for weights in weight_sets:
            total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
            strategy_errors.append(total_error)
        
        results["total_errors"].append({
            "strategy": strategy_name,
            "errors": strategy_errors
        })
    
    return results


def visualize_weighting_impact(results, weight_names, moment_names=None, output_file=None):
    """
    Visualise l'impact des différentes stratégies de pondération.
    
    Args:
        results: Résultats de l'analyse
        weight_names: Noms des stratégies de pondération
        moment_names: Noms des moments statistiques
        output_file: Chemin du fichier de sortie pour la visualisation
    """
    if moment_names is None:
        moment_names = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]
    
    plt.figure(figsize=(15, 12))
    
    # 1. Visualiser les coefficients de sensibilité
    plt.subplot(2, 2, 1)
    weight_ranges = ["0.1-0.3", "0.3-0.5", "0.5-0.7"]
    
    for i, moment in enumerate(moment_names):
        plt.plot(weight_ranges, results["sensitivity_coefficients"][i], marker='o', label=moment)
    
    plt.axhline(y=1.0, color='r', linestyle='--', alpha=0.5)
    plt.xlabel('Plage de poids')
    plt.ylabel('Coefficient de sensibilité')
    plt.title('Sensibilité des moments aux variations de poids')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 2. Visualiser les indices de discrimination
    plt.subplot(2, 2, 2)
    x = np.arange(len(weight_names))
    plt.bar(x, results["discrimination_indices"])
    plt.axhline(y=0.2, color='g', linestyle='--', alpha=0.5, label='Bonne discrimination')
    plt.axhline(y=0.1, color='orange', linestyle='--', alpha=0.5, label='Discrimination modérée')
    plt.xlabel('Stratégie de pondération')
    plt.ylabel('Indice de discrimination')
    plt.title('Capacité à discriminer entre stratégies de binning')
    plt.xticks(x, weight_names, rotation=45, ha='right')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 3. Visualiser les ratios signal/bruit
    plt.subplot(2, 2, 3)
    plt.bar(x, results["signal_to_noise_ratios"])
    plt.axhline(y=5, color='g', linestyle='--', alpha=0.5, label='Excellent')
    plt.axhline(y=2, color='orange', linestyle='--', alpha=0.5, label='Bon')
    plt.xlabel('Stratégie de pondération')
    plt.ylabel('Ratio signal/bruit')
    plt.title('Robustesse face au bruit')
    plt.xticks(x, weight_names, rotation=45, ha='right')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    # 4. Visualiser les erreurs totales par stratégie
    plt.subplot(2, 2, 4)
    
    strategy_names = [result["strategy"] for result in results["total_errors"]]
    
    # Créer un graphique à barres groupées
    x = np.arange(len(strategy_names))
    width = 0.8 / len(weight_names)
    
    for i, weight_name in enumerate(weight_names):
        errors = [result["errors"][i] for result in results["total_errors"]]
        plt.bar(x + (i - len(weight_names)/2 + 0.5) * width, errors, width, label=weight_name)
    
    plt.xlabel('Stratégie de binning')
    plt.ylabel('Erreur totale pondérée')
    plt.title('Impact des pondérations sur l\'erreur totale')
    plt.xticks(x, strategy_names, rotation=45, ha='right')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file)
    else:
        plt.show()


def adapt_weights_dynamically(data, context=None, distribution_type=None):
    """
    Adapte dynamiquement les poids des moments statistiques.
    
    Args:
        data: Données à analyser
        context: Contexte d'analyse (monitoring, comparative, etc.)
        distribution_type: Type de distribution si connu
        
    Returns:
        weights: Vecteur de pondération [w₁, w₂, w₃, w₄]
    """
    # Détecter le type de distribution si non spécifié
    if distribution_type is None:
        skewness = scipy.stats.skew(data)
        kurtosis = scipy.stats.kurtosis(data, fisher=False)
        
        if abs(skewness) < 0.5 and abs(kurtosis - 3) < 0.5:
            distribution_type = "quasi_normal"
        elif kurtosis > 5:
            distribution_type = "leptokurtic"
        elif abs(skewness) > 1.5:
            distribution_type = "highly_asymmetric"
        else:
            distribution_type = "moderately_asymmetric"
    
    # Poids de base selon le type de distribution
    if distribution_type == "quasi_normal":
        base_weights = [0.3, 0.3, 0.3, 0.1]
    elif distribution_type == "leptokurtic":
        base_weights = [0.3, 0.3, 0.2, 0.2]
    elif distribution_type == "highly_asymmetric":
        base_weights = [0.2, 0.3, 0.35, 0.15]
    else:  # moderately_asymmetric
        base_weights = [0.3, 0.3, 0.25, 0.15]
    
    # Ajuster selon le contexte
    if context == "monitoring":
        context_weights = [0.45, 0.35, 0.15, 0.05]
    elif context == "comparative":
        context_weights = [0.3, 0.3, 0.25, 0.15]
    elif context == "stability":
        context_weights = [0.2, 0.5, 0.2, 0.1]
    elif context == "anomaly_detection":
        context_weights = [0.2, 0.25, 0.35, 0.2]
    else:  # default
        context_weights = base_weights
    
    # Combiner les poids (70% contexte, 30% distribution)
    weights = [0.7 * c + 0.3 * b for c, b in zip(context_weights, base_weights)]
    
    # Normaliser les poids
    sum_weights = sum(weights)
    weights = [w / sum_weights for w in weights]
    
    return weights


if __name__ == "__main__":
    # Générer des données synthétiques
    np.random.seed(42)
    
    # Distribution asymétrique (typique des latences)
    data = np.random.gamma(shape=3, scale=50, size=1000)
    
    # Créer différentes stratégies de binning
    bin_strategies = []
    
    # Stratégie 1: 10 bins uniformes
    bin_edges_1 = np.linspace(min(data), max(data), 11)
    bin_counts_1, _ = np.histogram(data, bins=bin_edges_1)
    bin_strategies.append((bin_edges_1, bin_counts_1, "10 bins uniformes"))
    
    # Stratégie 2: 20 bins uniformes
    bin_edges_2 = np.linspace(min(data), max(data), 21)
    bin_counts_2, _ = np.histogram(data, bins=bin_edges_2)
    bin_strategies.append((bin_edges_2, bin_counts_2, "20 bins uniformes"))
    
    # Stratégie 3: 20 bins logarithmiques
    bin_edges_3 = np.logspace(np.log10(max(0.1, min(data))), np.log10(max(data)), 21)
    bin_counts_3, _ = np.histogram(data, bins=bin_edges_3)
    bin_strategies.append((bin_edges_3, bin_counts_3, "20 bins logarithmiques"))
    
    # Stratégie 4: 20 bins basés sur quantiles
    bin_edges_4 = np.percentile(data, np.linspace(0, 100, 21))
    bin_counts_4, _ = np.histogram(data, bins=bin_edges_4)
    bin_strategies.append((bin_edges_4, bin_counts_4, "20 bins quantiles"))
    
    # Définir différentes stratégies de pondération
    weight_sets = [
        [0.25, 0.25, 0.25, 0.25],  # Équilibrée
        [0.40, 0.30, 0.20, 0.10],  # Standard
        [0.45, 0.35, 0.15, 0.05],  # Monitoring
        [0.20, 0.50, 0.20, 0.10],  # Stabilité
        [0.20, 0.25, 0.35, 0.20],  # Détection d'anomalies
        [0.30, 0.30, 0.25, 0.15]   # Comparative
    ]
    
    weight_names = [
        "Équilibrée",
        "Standard",
        "Monitoring",
        "Stabilité",
        "Détection d'anomalies",
        "Comparative"
    ]
    
    # Analyser l'impact des pondérations
    results = analyze_weighting_impact(data, bin_strategies, weight_sets, weight_names)
    
    # Visualiser les résultats
    visualize_weighting_impact(results, weight_names, output_file="weighting_impact_analysis.png")
    
    print("Analyse de l'impact des pondérations terminée")
    print("Visualisation enregistrée dans 'weighting_impact_analysis.png'")
    
    # Tester l'adaptation dynamique des poids
    print("\nTest de l'adaptation dynamique des poids:")
    
    # Générer différentes distributions
    distributions = [
        ("Normale", np.random.normal(loc=100, scale=15, size=1000)),
        ("Asymétrique", np.random.gamma(shape=3, scale=50, size=1000)),
        ("Leptokurtique", np.random.standard_t(df=3, size=1000) * 20 + 100),
        ("Multimodale", np.concatenate([
            np.random.normal(loc=50, scale=10, size=500),
            np.random.normal(loc=150, scale=20, size=500)
        ]))
    ]
    
    contexts = ["monitoring", "comparative", "stability", "anomaly_detection"]
    
    for dist_name, dist_data in distributions:
        print(f"\nDistribution: {dist_name}")
        
        # Calculer les statistiques de base
        mean = np.mean(dist_data)
        std = np.std(dist_data)
        skewness = scipy.stats.skew(dist_data)
        kurtosis = scipy.stats.kurtosis(dist_data, fisher=False)
        
        print(f"  Moyenne: {mean:.2f}, Écart-type: {std:.2f}")
        print(f"  Asymétrie: {skewness:.2f}, Aplatissement: {kurtosis:.2f}")
        
        # Adapter les poids pour chaque contexte
        for context in contexts:
            weights = adapt_weights_dynamically(dist_data, context=context)
            print(f"  Contexte '{context}': Poids = [{', '.join([f'{w:.2f}' for w in weights])}]")
