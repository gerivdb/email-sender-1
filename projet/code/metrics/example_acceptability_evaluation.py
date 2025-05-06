#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des seuils d'acceptabilité avec les métriques pondérées.
"""

import numpy as np
import matplotlib.pyplot as plt
from weighted_moment_metrics import calculate_total_weighted_error
from acceptability_thresholds import AcceptabilityThresholds


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
    elif distribution_type == "asymmetric":
        return np.random.gamma(shape=3, scale=10, size=size)
    elif distribution_type == "leptokurtic":
        return np.random.standard_t(df=3, size=size) * 15 + 100
    elif distribution_type == "multimodal":
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


def evaluate_histogram_quality(data, bin_edges, bin_counts, weights=None, context="default", distribution_type=None):
    """
    Évalue la qualité d'un histogramme en utilisant les métriques pondérées et les seuils d'acceptabilité.
    
    Args:
        data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        weights: Poids des moments [w₁, w₂, w₃, w₄]
        context: Contexte d'analyse
        distribution_type: Type de distribution
        
    Returns:
        evaluation: Évaluation détaillée de la qualité de l'histogramme
    """
    # Calculer les erreurs pondérées
    total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts, weights)
    
    # Préparer le dictionnaire d'erreurs
    errors = {
        "total_error": total_error,
        "components": {
            "mean": {"raw_error": components["mean"]["raw_error"]},
            "variance": {"raw_error": components["variance"]["raw_error"]},
            "skewness": {"raw_error": components["skewness"]["raw_error"]},
            "kurtosis": {"raw_error": components["kurtosis"]["raw_error"]}
        }
    }
    
    # Évaluer l'acceptabilité
    thresholds = AcceptabilityThresholds()
    evaluation = thresholds.get_detailed_evaluation(errors, context, distribution_type)
    
    return evaluation


def visualize_evaluation(data, strategies, contexts, distribution_type=None):
    """
    Visualise l'évaluation de la qualité des histogrammes pour différentes stratégies et contextes.
    
    Args:
        data: Données réelles
        strategies: Liste de tuples (strategy_name, num_bins)
        contexts: Liste des contextes d'analyse
        distribution_type: Type de distribution
    """
    # Créer la figure
    fig, axes = plt.subplots(len(contexts), len(strategies), figsize=(15, 10))
    
    # Définir les couleurs pour les niveaux d'acceptabilité
    level_colors = {
        "excellent": "darkgreen",
        "good": "green",
        "acceptable": "orange",
        "poor": "red",
        "unacceptable": "darkred"
    }
    
    # Pour chaque contexte et stratégie
    for i, context in enumerate(contexts):
        for j, (strategy_name, num_bins) in enumerate(strategies):
            # Générer l'histogramme
            bin_edges, bin_counts = generate_histogram(data, strategy_name, num_bins)
            
            # Évaluer la qualité de l'histogramme
            evaluation = evaluate_histogram_quality(data, bin_edges, bin_counts, 
                                                   context=context, distribution_type=distribution_type)
            
            # Récupérer l'axe correspondant
            if len(contexts) == 1:
                if len(strategies) == 1:
                    ax = axes
                else:
                    ax = axes[j]
            else:
                if len(strategies) == 1:
                    ax = axes[i]
                else:
                    ax = axes[i, j]
            
            # Tracer l'histogramme
            ax.hist(data, bins=bin_edges, alpha=0.7, density=True)
            
            # Ajouter le titre avec l'évaluation
            acceptable = evaluation["overall"]["acceptable"]
            acceptable_str = "Acceptable" if acceptable else "Non acceptable"
            acceptable_color = "green" if acceptable else "red"
            
            ax.set_title(f"{strategy_name} ({num_bins} bins)\nContexte: {context}\n{acceptable_str}", 
                        color=acceptable_color)
            
            # Ajouter les informations d'évaluation
            y_pos = 0.95
            for component in ["total_error", "mean", "variance", "skewness", "kurtosis"]:
                if component in evaluation:
                    level = evaluation[component]["level"]
                    value = evaluation[component]["value"]
                    threshold = evaluation[component]["threshold"]
                    
                    ax.text(0.05, y_pos, f"{component}: {value:.1f}/{threshold:.1f}", 
                           transform=ax.transAxes, fontsize=8, 
                           color=level_colors.get(level, "black"))
                    
                    y_pos -= 0.05
            
            # Ajuster les axes
            ax.set_xlabel("Valeur")
            ax.set_ylabel("Densité")
    
    # Ajuster la mise en page
    plt.tight_layout()
    
    # Enregistrer la figure
    output_file = f"histogram_quality_evaluation_{distribution_type}.png"
    plt.savefig(output_file)
    plt.close()
    
    print(f"Visualisation enregistrée dans '{output_file}'")


if __name__ == "__main__":
    # Définir les distributions à tester
    distributions = [
        ("normal", "Distribution normale"),
        ("asymmetric", "Distribution asymétrique"),
        ("leptokurtic", "Distribution leptokurtique"),
        ("multimodal", "Distribution multimodale")
    ]
    
    # Définir les stratégies de binning à tester
    strategies = [
        ("uniform", 10),
        ("uniform", 20),
        ("logarithmic", 20),
        ("quantile", 20)
    ]
    
    # Définir les contextes à tester
    contexts = ["monitoring", "stability", "anomaly_detection", "characterization"]
    
    # Pour chaque distribution
    for dist_type, dist_name in distributions:
        print(f"\nÉvaluation pour {dist_name}")
        print("=" * 50)
        
        # Générer les données
        data = generate_test_data(dist_type)
        
        # Visualiser l'évaluation
        visualize_evaluation(data, strategies, contexts, dist_type)
        
        # Afficher un résumé des résultats
        print(f"Résultats pour {dist_name}:")
        
        for context in contexts:
            print(f"\nContexte: {context}")
            
            for strategy_name, num_bins in strategies:
                # Générer l'histogramme
                bin_edges, bin_counts = generate_histogram(data, strategy_name, num_bins)
                
                # Évaluer la qualité de l'histogramme
                evaluation = evaluate_histogram_quality(data, bin_edges, bin_counts, 
                                                      context=context, distribution_type=dist_type)
                
                # Afficher le résultat
                acceptable = evaluation["overall"]["acceptable"]
                acceptable_str = "Acceptable" if acceptable else "Non acceptable"
                
                print(f"  {strategy_name} ({num_bins} bins): {acceptable_str}")
                print(f"    Erreur totale: {evaluation['total_error']['value']:.2f}/{evaluation['total_error']['threshold']:.2f} - {evaluation['total_error']['level']}")
                
                for component in ["mean", "variance", "skewness", "kurtosis"]:
                    if component in evaluation:
                        level = evaluation[component]["level"]
                        value = evaluation[component]["value"]
                        threshold = evaluation[component]["threshold"]
                        print(f"    {component}: {value:.2f}/{threshold:.2f} - {level}")
    
    print("\nÉvaluation terminée")
