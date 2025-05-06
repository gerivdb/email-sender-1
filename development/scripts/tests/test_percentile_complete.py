#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test complet pour les métriques de préservation des percentiles.
"""

import sys
import os
import numpy as np
import matplotlib.pyplot as plt

# Ajouter le chemin du module
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))

# Importer le module
import percentile_preservation_metrics as ppm


def generate_test_data(distribution_type="normal", size=1000):
    """
    Génère des données de test selon le type de distribution spécifié.
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
    """
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
    return bin_edges, bin_counts


def test_percentile_metrics():
    """
    Teste les métriques de préservation des percentiles.
    """
    print("=== Test des métriques de préservation des percentiles ===")
    
    # Générer des données de test pour différentes distributions
    distributions = {
        "normale": generate_test_data("normal"),
        "asymétrique": generate_test_data("asymmetric"),
        "leptokurtique": generate_test_data("leptokurtic"),
        "multimodale": generate_test_data("multimodal")
    }
    
    # Définir les percentiles à évaluer
    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
    # Tester pour chaque distribution
    for dist_name, data in distributions.items():
        print(f"\n=== Distribution {dist_name} ===")
        
        # Calculer les percentiles des données originales
        original_percentiles = ppm.calculate_percentiles(data, percentiles)
        
        print("Percentiles originaux:")
        for p, value in original_percentiles.items():
            print(f"  P{p}: {value:.2f}")
        
        # Comparer différentes stratégies de binning
        strategies = ["uniform", "quantile", "logarithmic"]
        num_bins = 20
        
        print("\nComparaison des stratégies de binning:")
        for strategy in strategies:
            # Générer l'histogramme
            bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
            
            # Calculer les métriques de préservation des percentiles
            metrics = ppm.calculate_percentile_preservation_error(data, bin_edges, bin_counts, percentiles)
            score = ppm.calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
            quality = ppm.evaluate_percentile_preservation_quality(score)
            
            print(f"\nStratégie: {strategy}")
            print(f"  Score: {score:.4f}")
            print(f"  Qualité: {quality}")
            print(f"  Erreur relative moyenne: {metrics['mean_relative_error']:.2f}%")
            print(f"  Erreur relative maximale: {metrics['max_relative_error']:.2f}%")
            print(f"  Corrélation: {metrics['correlation']:.4f}")
            
            # Afficher les erreurs par percentile
            print("\n  Erreurs par percentile:")
            for p in sorted(percentiles):
                original = metrics['original_percentiles'][p]
                reconstructed = metrics['reconstructed_percentiles'][p]
                abs_error = metrics['absolute_errors'][p]
                rel_error = metrics['relative_errors'][p]
                print(f"    P{p}: Original={original:.2f}, Reconstruit={reconstructed:.2f}, "
                      f"Erreur abs={abs_error:.2f}, Erreur rel={rel_error:.2f}%")
        
        # Trouver le nombre optimal de bins
        print("\nRecherche du nombre optimal de bins:")
        for strategy in strategies:
            optimization = ppm.find_optimal_bin_count_for_percentile_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            print(f"  {strategy}: {optimization['optimal_bins']} bins (score: {optimization['best_score']:.4f})")
    
    print("\nTest terminé avec succès!")


def visualize_percentile_preservation():
    """
    Visualise la préservation des percentiles pour différentes stratégies de binning.
    """
    print("\n=== Visualisation de la préservation des percentiles ===")
    
    # Générer des données de test
    data = generate_test_data("multimodal")
    
    # Définir les percentiles à visualiser
    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    
    # Calculer les percentiles des données originales
    original_percentiles = ppm.calculate_percentiles(data, percentiles)
    
    # Générer des histogrammes avec différentes stratégies
    strategies = ["uniform", "quantile", "logarithmic"]
    num_bins = 20
    
    # Créer la figure
    fig, axes = plt.subplots(len(strategies), 2, figsize=(15, 5 * len(strategies)))
    
    for i, strategy in enumerate(strategies):
        # Générer l'histogramme
        bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
        
        # Reconstruire les données
        reconstructed_data = ppm.reconstruct_data_from_histogram(bin_edges, bin_counts)
        
        # Calculer les percentiles des données reconstruites
        reconstructed_percentiles = ppm.calculate_percentiles(reconstructed_data, percentiles)
        
        # Calculer les métriques
        metrics = ppm.calculate_percentile_preservation_error(data, bin_edges, bin_counts, percentiles)
        score = ppm.calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
        quality = ppm.evaluate_percentile_preservation_quality(score)
        
        # Afficher l'histogramme original et reconstruit
        ax1 = axes[i, 0]
        ax1.hist(data, bins=bin_edges, alpha=0.5, label="Original")
        ax1.hist(reconstructed_data, bins=bin_edges, alpha=0.5, label="Reconstruit")
        ax1.set_title(f"Stratégie: {strategy} - Score: {score:.4f} ({quality})")
        ax1.legend()
        
        # Afficher les percentiles
        ax2 = axes[i, 1]
        ax2.plot(percentiles, [original_percentiles[p] for p in percentiles], 'o-', label="Original")
        ax2.plot(percentiles, [reconstructed_percentiles[p] for p in percentiles], 'o-', label="Reconstruit")
        ax2.set_xlabel("Percentile")
        ax2.set_ylabel("Valeur")
        ax2.set_title(f"Préservation des percentiles - Erreur rel. moy.: {metrics['mean_relative_error']:.2f}%")
        ax2.legend()
        
        # Afficher les erreurs relatives
        for j, p in enumerate(percentiles):
            rel_error = metrics['relative_errors'][p]
            ax2.annotate(f"{rel_error:.1f}%", 
                        xy=(p, reconstructed_percentiles[p]),
                        xytext=(0, 10),
                        textcoords="offset points",
                        ha='center',
                        fontsize=8)
    
    plt.tight_layout()
    
    # Sauvegarder la figure
    output_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'output')
    os.makedirs(output_dir, exist_ok=True)
    plt.savefig(os.path.join(output_dir, 'percentile_preservation.png'))
    
    print(f"Visualisation sauvegardée dans {os.path.join(output_dir, 'percentile_preservation.png')}")


if __name__ == "__main__":
    # Exécuter les tests
    test_percentile_metrics()
    
    # Visualiser les résultats
    try:
        visualize_percentile_preservation()
    except Exception as e:
        print(f"Erreur lors de la visualisation: {e}")
        print("La visualisation nécessite matplotlib. Assurez-vous qu'il est installé.")
