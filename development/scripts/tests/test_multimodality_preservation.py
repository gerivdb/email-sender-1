#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les métriques de conservation de la multimodalité.
"""

import os
import sys
import numpy as np
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple, Any

# Ajouter le répertoire racine au chemin de recherche des modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# Importer le module de métriques de conservation de la multimodalité
try:
    from projet.code.metrics.multimodality_preservation_metrics import (
        detect_modes,
        calculate_mode_preservation,
        calculate_multimodality_preservation_score,
        evaluate_multimodality_preservation_quality,
        compare_binning_strategies_multimodality_preservation,
        find_optimal_bin_count_for_multimodality_preservation
    )
except ImportError:
    print("Erreur d'importation du module. Essai avec un chemin alternatif...")
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'projet', 'code', 'metrics')))
    from multimodality_preservation_metrics import (
        detect_modes,
        calculate_mode_preservation,
        calculate_multimodality_preservation_score,
        evaluate_multimodality_preservation_quality,
        compare_binning_strategies_multimodality_preservation,
        find_optimal_bin_count_for_multimodality_preservation
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
    elif distribution_type == "trimodal":
        return np.concatenate([
            np.random.normal(loc=50, scale=8, size=size // 3),
            np.random.normal(loc=100, scale=10, size=size // 3),
            np.random.normal(loc=150, scale=12, size=size // 3)
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


def reconstruct_data_from_histogram(bin_edges, bin_counts, method="uniform"):
    """
    Reconstruit un ensemble de données approximatif à partir d'un histogramme.
    
    Args:
        bin_edges: Limites des bins de l'histogramme
        bin_counts: Comptage par bin de l'histogramme
        method: Méthode de reconstruction ("uniform", "midpoint", "random")
        
    Returns:
        np.ndarray: Données reconstruites
    """
    reconstructed_data = []
    
    for i in range(len(bin_counts)):
        bin_count = bin_counts[i]
        bin_start = bin_edges[i]
        bin_end = bin_edges[i + 1]
        
        if method == "uniform":
            # Répartir uniformément les points dans le bin
            if bin_count > 0:
                step = (bin_end - bin_start) / bin_count
                bin_data = [bin_start + step * (j + 0.5) for j in range(bin_count)]
                reconstructed_data.extend(bin_data)
        
        elif method == "midpoint":
            # Placer tous les points au milieu du bin
            bin_midpoint = (bin_start + bin_end) / 2
            bin_data = [bin_midpoint] * bin_count
            reconstructed_data.extend(bin_data)
        
        elif method == "random":
            # Répartir aléatoirement les points dans le bin
            bin_data = np.random.uniform(bin_start, bin_end, bin_count)
            reconstructed_data.extend(bin_data)
        
        else:
            raise ValueError(f"Méthode de reconstruction inconnue: {method}")
    
    return np.array(reconstructed_data)


def test_mode_detection():
    """
    Teste la détection des modes dans différentes distributions.
    """
    print("\n=== Test de la détection des modes ===")
    
    # Tester sur différentes distributions
    distributions = {
        "normal": generate_test_data("normal"),
        "asymmetric": generate_test_data("asymmetric"),
        "leptokurtic": generate_test_data("leptokurtic"),
        "multimodal": generate_test_data("multimodal"),
        "trimodal": generate_test_data("trimodal")
    }
    
    for dist_name, data in distributions.items():
        print(f"\nDistribution: {dist_name}")
        
        # Détecter les modes
        modes_info = detect_modes(data)
        
        # Afficher les résultats
        print(f"  Nombre de modes détectés: {modes_info['num_modes']}")
        for i, mode in enumerate(modes_info['modes']):
            print(f"    Mode {i+1}: position={mode['position']:.2f}, hauteur={mode['height']:.2f}, largeur={mode['width']:.2f}")
        
        # Vérifier que le nombre de modes détectés est cohérent avec le type de distribution
        if dist_name == "normal":
            assert modes_info['num_modes'] == 1, f"La distribution normale devrait avoir 1 mode, mais {modes_info['num_modes']} ont été détectés"
        elif dist_name == "multimodal":
            assert modes_info['num_modes'] == 2, f"La distribution bimodale devrait avoir 2 modes, mais {modes_info['num_modes']} ont été détectés"
        elif dist_name == "trimodal":
            assert modes_info['num_modes'] == 3, f"La distribution trimodale devrait avoir 3 modes, mais {modes_info['num_modes']} ont été détectés"
    
    print("\nTest de détection des modes réussi!")


def test_mode_preservation():
    """
    Teste le calcul de la préservation des modes.
    """
    print("\n=== Test du calcul de la préservation des modes ===")
    
    # Générer des données de test
    data = generate_test_data("multimodal")
    
    # Générer un histogramme avec différentes stratégies
    strategies = ["uniform", "quantile", "logarithmic"]
    num_bins = 20
    
    for strategy in strategies:
        print(f"\nStratégie: {strategy}")
        
        # Générer l'histogramme
        bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
        
        # Reconstruire les données
        reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
        
        # Calculer les métriques de préservation des modes
        metrics = calculate_mode_preservation(data, reconstructed_data)
        
        # Afficher les résultats
        print(f"  Nombre de modes originaux: {metrics['original_num_modes']}")
        print(f"  Nombre de modes reconstruits: {metrics['reconstructed_num_modes']}")
        print(f"  Ratio de préservation du nombre de modes: {metrics['mode_count_ratio']:.2f}")
        
        if metrics['mode_count_preserved'] and metrics['original_num_modes'] > 0:
            print(f"  Erreur moyenne de position: {metrics['mean_position_error']:.4f}")
            print(f"  Erreur moyenne de hauteur: {metrics['mean_height_error']:.4f}")
            print(f"  Erreur moyenne de largeur: {metrics['mean_width_error']:.4f}")
            print(f"  Erreur moyenne d'aire: {metrics['mean_area_error']:.4f}")
    
    print("\nTest de préservation des modes réussi!")


def test_multimodality_preservation_score():
    """
    Teste le calcul du score de préservation de la multimodalité.
    """
    print("\n=== Test du calcul du score de préservation de la multimodalité ===")
    
    # Générer des données de test pour différentes distributions
    distributions = {
        "normal": generate_test_data("normal"),
        "asymmetric": generate_test_data("asymmetric"),
        "multimodal": generate_test_data("multimodal"),
        "trimodal": generate_test_data("trimodal")
    }
    
    for dist_name, data in distributions.items():
        print(f"\nDistribution: {dist_name}")
        
        # Générer un histogramme avec différentes stratégies
        strategies = ["uniform", "quantile", "logarithmic"]
        num_bins = 20
        
        for strategy in strategies:
            # Générer l'histogramme
            bin_edges, bin_counts = generate_histogram(data, strategy, num_bins)
            
            # Reconstruire les données
            reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
            
            # Calculer le score de préservation de la multimodalité
            score = calculate_multimodality_preservation_score(data, reconstructed_data)
            quality = evaluate_multimodality_preservation_quality(score)
            
            # Afficher les résultats
            print(f"  Stratégie: {strategy}")
            print(f"    Score: {score:.4f}")
            print(f"    Qualité: {quality}")
            
            # Vérifier que le score est entre 0 et 1
            assert 0 <= score <= 1, f"Score {score} hors de l'intervalle [0, 1]"
    
    print("\nTest du score de préservation de la multimodalité réussi!")


def test_compare_binning_strategies():
    """
    Teste la comparaison des stratégies de binning.
    """
    print("\n=== Test de la comparaison des stratégies de binning ===")
    
    # Générer des données de test pour différentes distributions
    distributions = {
        "normal": generate_test_data("normal"),
        "multimodal": generate_test_data("multimodal"),
        "trimodal": generate_test_data("trimodal")
    }
    
    for dist_name, data in distributions.items():
        print(f"\nDistribution: {dist_name}")
        
        # Comparer les stratégies de binning
        results = compare_binning_strategies_multimodality_preservation(data)
        
        # Afficher les résultats
        for strategy, result in results.items():
            print(f"  Stratégie: {strategy}")
            print(f"    Score: {result['score']:.4f}")
            print(f"    Qualité: {result['quality']}")
            
            metrics = result['metrics']
            print(f"    Nombre de modes originaux: {metrics['original_num_modes']}")
            print(f"    Nombre de modes reconstruits: {metrics['reconstructed_num_modes']}")
    
    print("\nTest de comparaison des stratégies de binning réussi!")


def test_find_optimal_bin_count():
    """
    Teste la recherche du nombre optimal de bins.
    """
    print("\n=== Test de la recherche du nombre optimal de bins ===")
    
    # Générer des données de test pour différentes distributions
    distributions = {
        "normal": generate_test_data("normal"),
        "multimodal": generate_test_data("multimodal"),
        "trimodal": generate_test_data("trimodal")
    }
    
    for dist_name, data in distributions.items():
        print(f"\nDistribution: {dist_name}")
        
        # Trouver le nombre optimal de bins pour différentes stratégies
        for strategy in ["uniform", "quantile", "logarithmic"]:
            optimization = find_optimal_bin_count_for_multimodality_preservation(
                data, strategy=strategy, min_bins=5, max_bins=50, step=5
            )
            
            # Afficher les résultats
            print(f"  Stratégie: {strategy}")
            print(f"    Nombre optimal de bins: {optimization['optimal_bins']}")
            print(f"    Meilleur score: {optimization['best_score']:.4f}")
            print(f"    Cible atteinte: {optimization['target_reached']}")
    
    print("\nTest de recherche du nombre optimal de bins réussi!")


def visualize_multimodality_preservation():
    """
    Visualise la préservation de la multimodalité pour différentes stratégies de binning.
    """
    print("\n=== Visualisation de la préservation de la multimodalité ===")
    
    # Générer des données de test
    data_multimodal = generate_test_data("multimodal")
    data_trimodal = generate_test_data("trimodal")
    
    # Créer la figure pour la distribution bimodale
    fig1, axes1 = plt.subplots(3, 2, figsize=(15, 12))
    fig1.suptitle("Préservation de la multimodalité - Distribution bimodale", fontsize=16)
    
    # Stratégies de binning à tester
    strategies = ["uniform", "quantile", "logarithmic"]
    
    # Tester chaque stratégie sur la distribution bimodale
    for i, strategy in enumerate(strategies):
        # Générer l'histogramme
        bin_edges, bin_counts = generate_histogram(data_multimodal, strategy, 20)
        
        # Reconstruire les données
        reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
        
        # Calculer les métriques de préservation de la multimodalité
        metrics = calculate_mode_preservation(data_multimodal, reconstructed_data)
        score = calculate_multimodality_preservation_score(data_multimodal, reconstructed_data)
        quality = evaluate_multimodality_preservation_quality(score)
        
        # Détecter les modes dans les données originales et reconstruites
        original_modes = detect_modes(data_multimodal)
        reconstructed_modes = detect_modes(reconstructed_data)
        
        # Afficher l'histogramme original et reconstruit
        ax1 = axes1[i, 0]
        ax1.hist(data_multimodal, bins=30, alpha=0.5, label="Original")
        ax1.hist(reconstructed_data, bins=30, alpha=0.5, label="Reconstruit")
        ax1.set_title(f"Stratégie: {strategy} - Score: {score:.4f} ({quality})")
        ax1.legend()
        
        # Afficher les densités KDE et les modes détectés
        ax2 = axes1[i, 1]
        ax2.plot(original_modes['x_grid'], original_modes['density'], 'b-', label="Original")
        ax2.plot(reconstructed_modes['x_grid'], reconstructed_modes['density'], 'r-', label="Reconstruit")
        
        # Marquer les modes originaux
        for j, mode in enumerate(original_modes['modes']):
            ax2.axvline(x=mode['position'], color='b', linestyle='--', alpha=0.5)
            ax2.text(mode['position'], 0.1 + 0.05*j, f"Mode {j+1}", color='b', ha='center')
        
        # Marquer les modes reconstruits
        for j, mode in enumerate(reconstructed_modes['modes']):
            ax2.axvline(x=mode['position'], color='r', linestyle=':', alpha=0.5)
            ax2.text(mode['position'], 0.9 - 0.05*j, f"Mode {j+1}", color='r', ha='center')
        
        ax2.set_title(f"Modes détectés - Erreur position: {metrics.get('mean_position_error', 'N/A')}")
        ax2.legend()
    
    plt.tight_layout()
    
    # Créer la figure pour la distribution trimodale
    fig2, axes2 = plt.subplots(3, 2, figsize=(15, 12))
    fig2.suptitle("Préservation de la multimodalité - Distribution trimodale", fontsize=16)
    
    # Tester chaque stratégie sur la distribution trimodale
    for i, strategy in enumerate(strategies):
        # Générer l'histogramme
        bin_edges, bin_counts = generate_histogram(data_trimodal, strategy, 20)
        
        # Reconstruire les données
        reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
        
        # Calculer les métriques de préservation de la multimodalité
        metrics = calculate_mode_preservation(data_trimodal, reconstructed_data)
        score = calculate_multimodality_preservation_score(data_trimodal, reconstructed_data)
        quality = evaluate_multimodality_preservation_quality(score)
        
        # Détecter les modes dans les données originales et reconstruites
        original_modes = detect_modes(data_trimodal)
        reconstructed_modes = detect_modes(reconstructed_data)
        
        # Afficher l'histogramme original et reconstruit
        ax1 = axes2[i, 0]
        ax1.hist(data_trimodal, bins=30, alpha=0.5, label="Original")
        ax1.hist(reconstructed_data, bins=30, alpha=0.5, label="Reconstruit")
        ax1.set_title(f"Stratégie: {strategy} - Score: {score:.4f} ({quality})")
        ax1.legend()
        
        # Afficher les densités KDE et les modes détectés
        ax2 = axes2[i, 1]
        ax2.plot(original_modes['x_grid'], original_modes['density'], 'b-', label="Original")
        ax2.plot(reconstructed_modes['x_grid'], reconstructed_modes['density'], 'r-', label="Reconstruit")
        
        # Marquer les modes originaux
        for j, mode in enumerate(original_modes['modes']):
            ax2.axvline(x=mode['position'], color='b', linestyle='--', alpha=0.5)
            ax2.text(mode['position'], 0.1 + 0.05*j, f"Mode {j+1}", color='b', ha='center')
        
        # Marquer les modes reconstruits
        for j, mode in enumerate(reconstructed_modes['modes']):
            ax2.axvline(x=mode['position'], color='r', linestyle=':', alpha=0.5)
            ax2.text(mode['position'], 0.9 - 0.05*j, f"Mode {j+1}", color='r', ha='center')
        
        ax2.set_title(f"Modes détectés - Erreur position: {metrics.get('mean_position_error', 'N/A')}")
        ax2.legend()
    
    plt.tight_layout()
    
    # Sauvegarder les figures
    output_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'output')
    os.makedirs(output_dir, exist_ok=True)
    fig1.savefig(os.path.join(output_dir, 'multimodality_preservation_bimodal.png'))
    fig2.savefig(os.path.join(output_dir, 'multimodality_preservation_trimodal.png'))
    
    print(f"Visualisations sauvegardées dans {output_dir}")


def main():
    """
    Fonction principale exécutant tous les tests.
    """
    print("=== Tests des métriques de conservation de la multimodalité ===")
    
    # Exécuter les tests
    test_mode_detection()
    test_mode_preservation()
    test_multimodality_preservation_score()
    test_compare_binning_strategies()
    test_find_optimal_bin_count()
    
    # Visualiser les résultats
    try:
        visualize_multimodality_preservation()
    except Exception as e:
        print(f"Erreur lors de la visualisation: {e}")
        print("La visualisation nécessite matplotlib. Assurez-vous qu'il est installé.")
    
    print("\nTous les tests ont été exécutés avec succès!")


if __name__ == "__main__":
    main()
