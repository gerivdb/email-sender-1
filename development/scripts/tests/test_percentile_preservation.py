#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les métriques de préservation des percentiles.
"""

import os
import sys
import numpy as np
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple, Any

# Ajouter le répertoire racine au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# Importer le module de métriques de préservation des percentiles
from projet.code.metrics.percentile_preservation_metrics import (
    calculate_percentiles,
    reconstruct_data_from_histogram,
    calculate_percentile_preservation_error,
    calculate_percentile_preservation_score,
    evaluate_percentile_preservation_quality,
    calculate_percentile_weighted_error,
    compare_binning_strategies_percentile_preservation,
    find_optimal_bin_count_for_percentile_preservation
)


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
        min_value = max(min(data), 1e-10)  # Éviter les valeurs négatives ou nulles
        bin_edges = np.logspace(np.log10(min_value), np.log10(max(data)), num_bins + 1)
    elif strategy == "quantile":
        bin_edges = np.percentile(data, np.linspace(0, 100, num_bins + 1))
    else:
        raise ValueError(f"Stratégie de binning inconnue: {strategy}")
    
    bin_counts, _ = np.histogram(data, bins=bin_edges)
    return bin_edges, bin_counts


def test_percentile_calculation():
    """
    Teste le calcul des percentiles.
    """
    print("\n=== Test du calcul des percentiles ===")
    
    # Générer des données de test
    data = generate_test_data("normal")
    
    # Calculer les percentiles
    percentiles = [1, 5, 10, 25, 50, 75, 90, 95, 99]
    percentile_values = calculate_percentiles(data, percentiles)
    
    # Afficher les résultats
    print("Percentiles calculés:")
    for p, value in percentile_values.items():
        print(f"  P{p}: {value:.2f}")
    
    # Vérifier que les percentiles sont croissants
    prev_value = float('-inf')
    for p in sorted(percentiles):
        value = percentile_values[p]
        assert value >= prev_value, f"Percentile P{p} ({value}) est inférieur au percentile précédent ({prev_value})"
        prev_value = value
    
    print("Test réussi: Les percentiles sont correctement calculés et croissants.")


def test_data_reconstruction():
    """
    Teste la reconstruction des données à partir d'un histogramme.
    """
    print("\n=== Test de la reconstruction des données ===")
    
    # Générer des données de test
    data = generate_test_data("normal")
    
    # Générer un histogramme
    bin_edges, bin_counts = generate_histogram(data, "uniform", 20)
    
    # Reconstruire les données avec différentes méthodes
    methods = ["uniform", "midpoint", "random"]
    
    for method in methods:
        reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts, method)
        
        # Vérifier que le nombre de points reconstruits est correct
        assert len(reconstructed_data) == sum(bin_counts), f"Nombre incorrect de points reconstruits avec la méthode {method}"
        
        # Vérifier que les données reconstruites sont dans les limites des bins
        assert min(reconstructed_data) >= min(data), f"Valeur minimale incorrecte avec la méthode {method}"
        assert max(reconstructed_data) <= max(data), f"Valeur maximale incorrecte avec la méthode {method}"
        
        print(f"Méthode {method}: {len(reconstructed_data)} points reconstruits")
        print(f"  Plage originale: [{min(data):.2f}, {max(data):.2f}]")
        print(f"  Plage reconstruite: [{min(reconstructed_data):.2f}, {max(reconstructed_data):.2f}]")
    
    print("Test réussi: Les données sont correctement reconstruites.")


def test_percentile_preservation_error():
    """
    Teste le calcul de l'erreur de préservation des percentiles.
    """
    print("\n=== Test du calcul de l'erreur de préservation des percentiles ===")
    
    # Générer des données de test
    data = generate_test_data("normal")
    
    # Générer un histogramme avec différentes stratégies
    strategies = ["uniform", "quantile", "logarithmic"]
    num_bins = 20
    
    for strategy in strategies:
        bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
        
        # Calculer l'erreur de préservation des percentiles
        metrics = calculate_percentile_preservation_error(data, bin_edges, bin_counts)
        
        # Afficher les résultats
        print(f"\nStratégie: {strategy}")
        print(f"  Erreur absolue moyenne: {metrics['mean_absolute_error']:.2f}")
        print(f"  Erreur absolue médiane: {metrics['median_absolute_error']:.2f}")
        print(f"  Erreur absolue maximale: {metrics['max_absolute_error']:.2f}")
        print(f"  Erreur relative moyenne: {metrics['mean_relative_error']:.2f}%")
        print(f"  Erreur relative médiane: {metrics['median_relative_error']:.2f}%")
        print(f"  Erreur relative maximale: {metrics['max_relative_error']:.2f}%")
        print(f"  RMSE: {metrics['rmse']:.2f}")
        print(f"  Corrélation: {metrics['correlation']:.4f}")
        
        # Afficher les erreurs par percentile
        print("\n  Erreurs par percentile:")
        for p in sorted(metrics['percentiles']):
            original = metrics['original_percentiles'][p]
            reconstructed = metrics['reconstructed_percentiles'][p]
            abs_error = metrics['absolute_errors'][p]
            rel_error = metrics['relative_errors'][p]
            print(f"    P{p}: Original={original:.2f}, Reconstruit={reconstructed:.2f}, "
                  f"Erreur abs={abs_error:.2f}, Erreur rel={rel_error:.2f}%")
    
    print("\nTest réussi: Les erreurs de préservation des percentiles sont correctement calculées.")


def test_percentile_preservation_score():
    """
    Teste le calcul du score de préservation des percentiles.
    """
    print("\n=== Test du calcul du score de préservation des percentiles ===")
    
    # Générer des données de test pour différentes distributions
    distributions = ["normal", "asymmetric", "leptokurtic", "multimodal"]
    
    for dist_type in distributions:
        data = generate_test_data(dist_type)
        
        # Générer un histogramme avec différentes stratégies
        strategies = ["uniform", "quantile", "logarithmic"]
        num_bins = 20
        
        print(f"\nDistribution: {dist_type}")
        
        for strategy in strategies:
            bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
            
            # Calculer le score de préservation des percentiles
            score = calculate_percentile_preservation_score(data, bin_edges, bin_counts)
            quality = evaluate_percentile_preservation_quality(score)
            
            # Afficher les résultats
            print(f"  Stratégie: {strategy}")
            print(f"    Score: {score:.4f}")
            print(f"    Qualité: {quality}")
            
            # Vérifier que le score est entre 0 et 1
            assert 0 <= score <= 1, f"Score {score} hors de l'intervalle [0, 1]"
    
    print("\nTest réussi: Les scores de préservation des percentiles sont correctement calculés.")


def test_percentile_weighted_error():
    """
    Teste le calcul de l'erreur pondérée de préservation des percentiles.
    """
    print("\n=== Test du calcul de l'erreur pondérée de préservation des percentiles ===")
    
    # Générer des données de test
    data = generate_test_data("asymmetric")
    
    # Générer un histogramme
    bin_edges, bin_counts = generate_histogram(data, "uniform", 20)
    
    # Définir des poids personnalisés pour les percentiles
    custom_weights = {
        1: 3.0,    # Très important pour la queue inférieure
        5: 2.0,    # Important pour la queue inférieure
        10: 1.5,   # Modérément important
        25: 1.0,   # Standard
        50: 1.0,   # Standard (médiane)
        75: 1.0,   # Standard
        90: 1.5,   # Modérément important
        95: 2.0,   # Important pour la queue supérieure
        99: 3.0    # Très important pour la queue supérieure
    }
    
    # Calculer l'erreur pondérée avec les poids par défaut
    default_metrics = calculate_percentile_weighted_error(data, bin_edges, bin_counts)
    
    # Calculer l'erreur pondérée avec des poids personnalisés
    custom_metrics = calculate_percentile_weighted_error(data, bin_edges, bin_counts, custom_weights)
    
    # Afficher les résultats
    print("\nErreur pondérée avec poids par défaut:")
    print(f"  Erreur absolue moyenne pondérée: {default_metrics['mean_weighted_absolute_error']:.2f}")
    print(f"  Erreur absolue maximale pondérée: {default_metrics['max_weighted_absolute_error']:.2f}")
    print(f"  Erreur relative moyenne pondérée: {default_metrics['mean_weighted_relative_error']:.2f}%")
    print(f"  Erreur relative maximale pondérée: {default_metrics['max_weighted_relative_error']:.2f}%")
    
    print("\nErreur pondérée avec poids personnalisés:")
    print(f"  Erreur absolue moyenne pondérée: {custom_metrics['mean_weighted_absolute_error']:.2f}")
    print(f"  Erreur absolue maximale pondérée: {custom_metrics['max_weighted_absolute_error']:.2f}")
    print(f"  Erreur relative moyenne pondérée: {custom_metrics['mean_weighted_relative_error']:.2f}%")
    print(f"  Erreur relative maximale pondérée: {custom_metrics['max_weighted_relative_error']:.2f}%")
    
    # Afficher les erreurs pondérées par percentile
    print("\nErreurs pondérées par percentile (poids personnalisés):")
    for p in sorted(custom_metrics['percentiles']):
        weight = custom_metrics['percentile_weights'][p]
        abs_error = custom_metrics['weighted_absolute_errors'][p]
        rel_error = custom_metrics['weighted_relative_errors'][p]
        print(f"  P{p} (poids={weight:.1f}): Erreur abs={abs_error:.2f}, Erreur rel={rel_error:.2f}%")
    
    print("\nTest réussi: Les erreurs pondérées de préservation des percentiles sont correctement calculées.")


def test_compare_binning_strategies():
    """
    Teste la comparaison des stratégies de binning.
    """
    print("\n=== Test de la comparaison des stratégies de binning ===")
    
    # Générer des données de test pour différentes distributions
    distributions = ["normal", "asymmetric", "leptokurtic", "multimodal"]
    
    for dist_type in distributions:
        data = generate_test_data(dist_type)
        
        # Comparer les stratégies de binning
        results = compare_binning_strategies_percentile_preservation(data)
        
        print(f"\nDistribution: {dist_type}")
        
        # Afficher les résultats
        for strategy, result in results.items():
            print(f"  Stratégie: {strategy}")
            print(f"    Score: {result['score']:.4f}")
            print(f"    Qualité: {result['quality']}")
            print(f"    Erreur relative moyenne: {result['metrics']['mean_relative_error']:.2f}%")
            print(f"    Erreur relative maximale: {result['metrics']['max_relative_error']:.2f}%")
            print(f"    Corrélation: {result['metrics']['correlation']:.4f}")
    
    print("\nTest réussi: La comparaison des stratégies de binning est correctement effectuée.")


def test_find_optimal_bin_count():
    """
    Teste la recherche du nombre optimal de bins.
    """
    print("\n=== Test de la recherche du nombre optimal de bins ===")
    
    # Générer des données de test pour différentes distributions
    distributions = ["normal", "asymmetric", "leptokurtic", "multimodal"]
    
    for dist_type in distributions:
        data = generate_test_data(dist_type)
        
        print(f"\nDistribution: {dist_type}")
        
        # Trouver le nombre optimal de bins pour différentes stratégies
        for strategy in ["uniform", "quantile", "logarithmic"]:
            optimization = find_optimal_bin_count_for_percentile_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            
            # Afficher les résultats
            print(f"  Stratégie: {strategy}")
            print(f"    Nombre optimal de bins: {optimization['optimal_bins']}")
            print(f"    Meilleur score: {optimization['best_score']:.4f}")
            print(f"    Cible atteinte: {optimization['target_reached']}")
            
            # Afficher l'évolution du score
            print("    Évolution du score:")
            for bins, score in sorted(optimization['scores'].items()):
                print(f"      {bins} bins: {score:.4f}")
    
    print("\nTest réussi: La recherche du nombre optimal de bins est correctement effectuée.")


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
    original_percentiles = calculate_percentiles(data, percentiles)
    
    # Générer des histogrammes avec différentes stratégies
    strategies = ["uniform", "quantile", "logarithmic"]
    num_bins = 20
    
    # Créer la figure
    fig, axes = plt.subplots(len(strategies), 2, figsize=(15, 5 * len(strategies)))
    
    for i, strategy in enumerate(strategies):
        # Générer l'histogramme
        bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
        
        # Reconstruire les données
        reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
        
        # Calculer les percentiles des données reconstruites
        reconstructed_percentiles = calculate_percentiles(reconstructed_data, percentiles)
        
        # Calculer les métriques
        metrics = calculate_percentile_preservation_error(data, bin_edges, bin_counts, percentiles)
        score = calculate_percentile_preservation_score(data, bin_edges, bin_counts, percentiles)
        quality = evaluate_percentile_preservation_quality(score)
        
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


def main():
    """
    Fonction principale exécutant tous les tests.
    """
    print("=== Tests des métriques de préservation des percentiles ===")
    
    # Exécuter les tests
    test_percentile_calculation()
    test_data_reconstruction()
    test_percentile_preservation_error()
    test_percentile_preservation_score()
    test_percentile_weighted_error()
    test_compare_binning_strategies()
    test_find_optimal_bin_count()
    
    # Visualiser les résultats
    visualize_percentile_preservation()
    
    print("\nTous les tests ont été exécutés avec succès!")


if __name__ == "__main__":
    main()
