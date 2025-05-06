#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Exemple d'utilisation des seuils généraux par niveau de précision.
"""

import numpy as np
import matplotlib.pyplot as plt
from precision_level_thresholds import PrecisionLevelThresholds
from acceptability_thresholds import AcceptabilityThresholds
from weighted_moment_metrics import calculate_total_weighted_error


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


def evaluate_histogram_with_precision_level(data, bin_edges, bin_counts, precision_level="medium", context="default", distribution_type=None):
    """
    Évalue la qualité d'un histogramme en utilisant les seuils par niveau de précision.
    
    Args:
        data: Données réelles
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        precision_level: Niveau de précision
        context: Contexte d'analyse
        distribution_type: Type de distribution
        
    Returns:
        evaluation: Évaluation détaillée de la qualité de l'histogramme
    """
    # Calculer les erreurs pondérées
    total_error, components = calculate_total_weighted_error(data, bin_edges, bin_counts)
    
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
    
    # Obtenir les seuils pour le niveau de précision et le contexte
    precision_levels = PrecisionLevelThresholds()
    thresholds = precision_levels.get_thresholds_for_context(precision_level, context)
    
    # Créer un objet AcceptabilityThresholds avec les seuils personnalisés
    custom_thresholds = {
        context: thresholds
    }
    
    acceptability = AcceptabilityThresholds()
    acceptability.custom_thresholds = custom_thresholds
    
    # Évaluer l'acceptabilité
    evaluation = acceptability.get_detailed_evaluation(errors, context, distribution_type)
    
    return evaluation


def compare_precision_levels(data, distribution_type=None):
    """
    Compare les résultats d'évaluation pour différents niveaux de précision.
    
    Args:
        data: Données réelles
        distribution_type: Type de distribution
    """
    # Créer une instance de PrecisionLevelThresholds
    precision_levels = PrecisionLevelThresholds()
    
    # Obtenir les niveaux de précision disponibles
    available_levels = list(precision_levels.get_all_precision_levels().keys())
    
    # Définir les contextes à tester
    contexts = ["monitoring", "stability", "anomaly_detection", "characterization"]
    
    # Créer la figure
    fig, axes = plt.subplots(len(contexts), len(available_levels), figsize=(15, 10))
    
    # Définir les couleurs pour les niveaux d'acceptabilité
    level_colors = {
        "excellent": "darkgreen",
        "good": "green",
        "acceptable": "orange",
        "poor": "red",
        "unacceptable": "darkred"
    }
    
    # Pour chaque contexte et niveau de précision
    for i, context in enumerate(contexts):
        for j, precision_level in enumerate(available_levels):
            # Obtenir la recommandation de nombre de bins
            sample_size = len(data)
            num_bins = precision_levels.get_bin_count_recommendation(precision_level, sample_size)
            
            # Générer l'histogramme
            bin_edges, bin_counts = generate_histogram(data, "uniform", num_bins)
            
            # Évaluer la qualité de l'histogramme
            evaluation = evaluate_histogram_with_precision_level(
                data, bin_edges, bin_counts, precision_level, context, distribution_type
            )
            
            # Récupérer l'axe correspondant
            if len(contexts) == 1:
                if len(available_levels) == 1:
                    ax = axes
                else:
                    ax = axes[j]
            else:
                if len(available_levels) == 1:
                    ax = axes[i]
                else:
                    ax = axes[i, j]
            
            # Tracer l'histogramme
            ax.hist(data, bins=bin_edges, alpha=0.7, density=True)
            
            # Ajouter le titre avec l'évaluation
            acceptable = evaluation["overall"]["acceptable"]
            acceptable_str = "Acceptable" if acceptable else "Non acceptable"
            acceptable_color = "green" if acceptable else "red"
            
            ax.set_title(f"{precision_level} - {context}\n{acceptable_str}", color=acceptable_color)
            
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
    output_file = f"precision_levels_comparison_{distribution_type}.png"
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
    
    # Pour chaque distribution
    for dist_type, dist_name in distributions:
        print(f"\nÉvaluation pour {dist_name}")
        print("=" * 50)
        
        # Générer les données
        data = generate_test_data(dist_type)
        
        # Comparer les niveaux de précision
        compare_precision_levels(data, dist_type)
        
        # Afficher les recommandations de taille d'échantillon et de nombre de bins
        precision_levels = PrecisionLevelThresholds()
        
        print(f"\nRecommandations pour {dist_name}:")
        for level in ["high", "medium", "low", "minimal"]:
            sample_size = precision_levels.get_sample_size_recommendation(level, dist_type)
            bin_count = precision_levels.get_bin_count_recommendation(level, sample_size)
            
            print(f"  {level}:")
            print(f"    Taille d'échantillon recommandée: {sample_size}")
            print(f"    Nombre de bins recommandé: {bin_count}")
    
    print("\nÉvaluation terminée")
