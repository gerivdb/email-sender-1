#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Tests d'intégration pour les métriques pondérées.
"""

import numpy as np
import matplotlib.pyplot as plt
from weighted_moment_metrics import calculate_total_weighted_error
from weighting_sensitivity_analysis import adapt_weights_dynamically


def generate_test_data(distribution_type="normal", size=1000):
    """
    Génère des données de test selon le type de distribution spécifié.
    
    Args:
        distribution_type: Type de distribution à générer
        size: Taille de l'échantillon
        
    Returns:
        data: Données générées
    """
    np.random.seed(42)
    
    if distribution_type == "normal":
        return np.random.normal(loc=100, scale=15, size=size)
    elif distribution_type == "gamma":
        return np.random.gamma(shape=3, scale=10, size=size)
    elif distribution_type == "leptokurtic":
        return np.random.standard_t(df=3, size=size) * 15 + 100
    elif distribution_type == "bimodal":
        return np.concatenate([
            np.random.normal(loc=70, scale=10, size=size // 2),
            np.random.normal(loc=130, scale=15, size=size // 2)
        ])
    else:
        raise ValueError(f"Type de distribution inconnu: {distribution_type}")


def generate_histogram(data, strategy="uniform", num_bins=20):
    """
    Génère un histogramme selon la stratégie spécifiée.
    
    Args:
        data: Données à représenter
        strategy: Stratégie de binning
        num_bins: Nombre de bins
        
    Returns:
        bin_edges: Limites des bins
        bin_counts: Comptage par bin
    """
    if strategy == "uniform":
        bin_edges = np.linspace(min(data), max(data), num_bins + 1)
    elif strategy == "logarithmic":
        bin_edges = np.logspace(np.log10(max(0.1, min(data))), np.log10(max(data)), num_bins + 1)
    elif strategy == "quantile":
        bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
    else:
        raise ValueError(f"Stratégie de binning inconnue: {strategy}")
    
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    return bin_edges, bin_counts


def test_different_distributions():
    """Teste les métriques pondérées sur différentes distributions."""
    print("Test des métriques pondérées sur différentes distributions")
    print("=" * 70)
    
    distributions = ["normal", "gamma", "leptokurtic", "bimodal"]
    strategies = ["uniform", "logarithmic", "quantile"]
    contexts = [None, "monitoring", "stability", "anomaly_detection"]
    
    results = {}
    
    for dist_type in distributions:
        print(f"\nDistribution: {dist_type}")
        data = generate_test_data(dist_type)
        
        # Calculer les statistiques de base
        mean = np.mean(data)
        std = np.std(data)
        skewness = float(scipy.stats.skew(data))
        kurtosis = float(scipy.stats.kurtosis(data, fisher=False))
        
        print(f"Statistiques: Moyenne={mean:.2f}, Écart-type={std:.2f}")
        print(f"              Asymétrie={skewness:.2f}, Aplatissement={kurtosis:.2f}")
        
        dist_results = {}
        
        for strategy in strategies:
            print(f"\n  Stratégie: {strategy}")
            bin_edges, bin_counts = generate_histogram(data, strategy)
            
            strategy_results = {}
            
            for context in contexts:
                context_name = context if context else "défaut"
                
                # Adapter les poids au contexte et à la distribution
                weights = adapt_weights_dynamically(data, context=context)
                
                # Calculer l'erreur totale pondérée
                total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
                
                print(f"    Contexte '{context_name}':")
                print(f"      Poids: [{', '.join([f'{w:.2f}' for w in weights])}]")
                print(f"      Erreur totale: {total_error:.2f}")
                print(f"      Composantes:")
                for moment, error_info in components.items():
                    print(f"        {moment.capitalize()}: Erreur brute = {error_info['raw_error']:.2f}%, "
                          f"Erreur pondérée = {error_info['weighted_error']:.2f}")
                
                strategy_results[context_name] = {
                    "weights": weights,
                    "total_error": total_error,
                    "components": components
                }
            
            dist_results[strategy] = strategy_results
        
        results[dist_type] = dist_results
    
    return results


def visualize_results(results):
    """Visualise les résultats des tests."""
    distributions = list(results.keys())
    strategies = list(results[distributions[0]].keys())
    contexts = list(results[distributions[0]][strategies[0]].keys())
    
    # 1. Comparer les erreurs totales par distribution et stratégie
    plt.figure(figsize=(15, 10))
    
    for i, context in enumerate(contexts):
        plt.subplot(2, 2, i+1)
        
        # Préparer les données pour le graphique à barres groupées
        x = np.arange(len(distributions))
        width = 0.8 / len(strategies)
        
        for j, strategy in enumerate(strategies):
            errors = [results[dist][strategy][context]["total_error"] for dist in distributions]
            plt.bar(x + (j - len(strategies)/2 + 0.5) * width, errors, width, label=strategy)
        
        plt.xlabel('Distribution')
        plt.ylabel('Erreur totale pondérée')
        plt.title(f'Erreurs par distribution - Contexte {context}')
        plt.xticks(x, distributions)
        plt.legend()
        plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig("weighted_metrics_by_distribution.png")
    
    # 2. Comparer les poids adaptés par distribution et contexte
    plt.figure(figsize=(15, 10))
    
    moment_names = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]
    
    for i, dist in enumerate(distributions):
        plt.subplot(2, 2, i+1)
        
        # Utiliser la stratégie uniforme pour cette visualisation
        strategy = "uniform"
        
        # Préparer les données pour le graphique à barres groupées
        x = np.arange(len(moment_names))
        width = 0.8 / len(contexts)
        
        for j, context in enumerate(contexts):
            weights = results[dist][strategy][context]["weights"]
            plt.bar(x + (j - len(contexts)/2 + 0.5) * width, weights, width, label=context)
        
        plt.xlabel('Moment statistique')
        plt.ylabel('Poids')
        plt.title(f'Poids adaptés - Distribution {dist}')
        plt.xticks(x, moment_names)
        plt.legend()
        plt.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig("adaptive_weights_by_distribution.png")
    
    print("\nVisualisations enregistrées dans:")
    print("- weighted_metrics_by_distribution.png")
    print("- adaptive_weights_by_distribution.png")


if __name__ == "__main__":
    import scipy.stats
    
    print("Tests d'intégration pour les métriques pondérées")
    print("=" * 70)
    
    # Exécuter les tests
    results = test_different_distributions()
    
    # Visualiser les résultats
    visualize_results(results)
    
    print("\nTests d'intégration terminés avec succès!")
