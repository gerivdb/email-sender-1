#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour l'algorithme de calcul de l'indice global de conservation des moments.
"""

import numpy as np
import matplotlib.pyplot as plt
from global_moment_conservation_index import (
    calculate_global_moment_conservation_index,
    get_quality_level,
    generate_histogram,
    evaluate_histogram_quality,
    optimize_histogram_config
)

def test_with_synthetic_data():
    """Test de l'algorithme avec différentes distributions synthétiques."""
    print("Test avec distributions synthétiques")
    print("=" * 80)
    
    # Générer différentes distributions synthétiques
    np.random.seed(42)
    
    # Distribution normale
    normal_data = np.random.normal(loc=100, scale=15, size=1000)
    
    # Distribution log-normale (asymétrique positive)
    lognormal_data = np.random.lognormal(mean=0, sigma=0.7, size=1000) * 100 + 50
    
    # Distribution bimodale
    bimodal_data = np.concatenate([
        np.random.normal(loc=50, scale=10, size=500),
        np.random.normal(loc=150, scale=20, size=500)
    ])
    
    # Distribution avec valeurs aberrantes
    outlier_data = np.concatenate([
        np.random.normal(loc=100, scale=15, size=950),
        np.random.normal(loc=300, scale=30, size=50)
    ])
    
    # Configurations de binning à tester
    configs = [
        {"type": "uniform", "num_bins": 10},
        {"type": "uniform", "num_bins": 20},
        {"type": "uniform", "num_bins": 50},
        {"type": "logarithmic", "num_bins": 20},
        {"type": "quantile", "num_bins": 20}
    ]
    
    # Tester chaque distribution
    distributions = [
        ("Normale", normal_data),
        ("Log-normale", lognormal_data),
        ("Bimodale", bimodal_data),
        ("Avec valeurs aberrantes", outlier_data)
    ]
    
    for dist_name, data in distributions:
        print(f"\nDistribution: {dist_name}")
        print("-" * 50)
        
        # Calculer les statistiques de base
        mean = np.mean(data)
        std = np.std(data)
        skewness = float(np.mean(((data - mean) / std) ** 3))
        kurtosis = float(np.mean(((data - mean) / std) ** 4))
        
        print(f"Statistiques: Moyenne={mean:.2f}, Écart-type={std:.2f}")
        print(f"              Asymétrie={skewness:.2f}, Aplatissement={kurtosis:.2f}")
        
        # Tester chaque configuration
        for config in configs:
            result = evaluate_histogram_quality(data, config)
            print(f"\nConfiguration: {config['type']}, {config['num_bins']} bins")
            print(f"IGCM: {result['igcm']:.4f}, Qualité: {result['quality_level']}")
            print(f"Erreurs: Moyenne={result['errors']['mean']:.2f}%, Variance={result['errors']['variance']:.2f}%")
            print(f"         Asymétrie={result['errors']['skewness']:.2f}%, Aplatissement={result['errors']['kurtosis']:.2f}%")
        
        # Trouver la configuration optimale
        print("\nRecherche de configuration optimale:")
        for quality in ["Bon", "Très bon", "Excellent"]:
            optimal_config, optimal_eval = optimize_histogram_config(data, target_quality=quality)
            print(f"Pour qualité '{quality}': {optimal_config['type']}, {optimal_config['num_bins']} bins, IGCM={optimal_eval['igcm']:.4f}")
        
        # Visualiser les histogrammes
        plt.figure(figsize=(15, 10))
        plt.suptitle(f"Distribution {dist_name} - Comparaison des histogrammes", fontsize=16)
        
        for i, config in enumerate(configs):
            plt.subplot(2, 3, i+1)
            bin_edges, _ = generate_histogram(data, config)
            plt.hist(data, bins=bin_edges, alpha=0.7)
            
            # Évaluer la qualité
            result = evaluate_histogram_quality(data, config)
            
            plt.title(f"{config['type'].capitalize()}, {config['num_bins']} bins\nIGCM: {result['igcm']:.4f}, {result['quality_level']}")
            plt.xlabel("Valeur")
            plt.ylabel("Fréquence")
        
        plt.tight_layout()
        plt.savefig(f"histogram_quality_{dist_name.lower().replace(' ', '_')}.png")
        plt.close()
        
        print(f"Visualisation enregistrée dans 'histogram_quality_{dist_name.lower().replace(' ', '_')}.png'")
        print("=" * 80)

def test_with_real_latency_data():
    """Test de l'algorithme avec des données de latence simulées."""
    print("\nTest avec données de latence simulées")
    print("=" * 80)
    
    # Simuler des données de latence pour différentes régions
    np.random.seed(42)
    
    # L1/L2 Cache (50-100 μs)
    l1l2_data = np.random.gamma(shape=5, scale=10, size=1000)
    l1l2_data = l1l2_data * (50 / np.mean(l1l2_data)) + 50  # Ajuster pour la plage cible
    
    # L3/Mémoire (150-250 μs)
    l3_data = np.random.gamma(shape=4, scale=20, size=1000)
    l3_data = l3_data * (100 / np.mean(l3_data)) + 150  # Ajuster pour la plage cible
    
    # Cache Système (400-700 μs)
    syscache_data = np.random.gamma(shape=3, scale=50, size=1000)
    syscache_data = syscache_data * (300 / np.mean(syscache_data)) + 400  # Ajuster pour la plage cible
    
    # Stockage (1500-3000 μs)
    storage_data = np.random.gamma(shape=2, scale=300, size=1000)
    storage_data = storage_data * (1500 / np.mean(storage_data)) + 1500  # Ajuster pour la plage cible
    
    # Configurations de binning à tester
    configs = [
        {"type": "uniform", "num_bins": 20},
        {"type": "logarithmic", "num_bins": 20},
        {"type": "quantile", "num_bins": 20}
    ]
    
    # Tester chaque région de latence
    latency_regions = [
        ("L1/L2 Cache", l1l2_data, "l1l2Cache"),
        ("L3/Mémoire", l3_data, "l3Memory"),
        ("Cache Système", syscache_data, "systemCache"),
        ("Stockage", storage_data, "storage")
    ]
    
    for region_name, data, region_id in latency_regions:
        print(f"\nRégion: {region_name} ({np.min(data):.0f}-{np.max(data):.0f} μs)")
        print("-" * 50)
        
        # Calculer les statistiques de base
        mean = np.mean(data)
        std = np.std(data)
        cv = std / mean
        skewness = float(np.mean(((data - mean) / std) ** 3))
        kurtosis = float(np.mean(((data - mean) / std) ** 4))
        
        print(f"Statistiques: Moyenne={mean:.2f} μs, Écart-type={std:.2f} μs, CV={cv:.2f}")
        print(f"              Asymétrie={skewness:.2f}, Aplatissement={kurtosis:.2f}")
        
        # Tester chaque configuration avec le contexte de région
        for config in configs:
            result = evaluate_histogram_quality(data, config, context=None)
            result_with_region = evaluate_histogram_quality(data, config, context=region_id)
            
            print(f"\nConfiguration: {config['type']}, {config['num_bins']} bins")
            print(f"IGCM standard: {result['igcm']:.4f}, Qualité: {result['quality_level']}")
            print(f"IGCM avec contexte région: {result_with_region['igcm']:.4f}, Qualité: {result_with_region['quality_level']}")
        
        # Trouver la configuration optimale avec contexte de région
        print("\nRecherche de configuration optimale avec contexte région:")
        optimal_config, optimal_eval = optimize_histogram_config(data, target_quality="Bon", context=region_id)
        print(f"Pour qualité 'Bon': {optimal_config['type']}, {optimal_config['num_bins']} bins, IGCM={optimal_eval['igcm']:.4f}")
        
        # Visualiser les histogrammes
        plt.figure(figsize=(15, 5))
        plt.suptitle(f"Région {region_name} - Comparaison des histogrammes", fontsize=16)
        
        for i, config in enumerate(configs):
            plt.subplot(1, 3, i+1)
            bin_edges, _ = generate_histogram(data, config)
            plt.hist(data, bins=bin_edges, alpha=0.7)
            
            # Évaluer la qualité avec contexte de région
            result = evaluate_histogram_quality(data, config, context=region_id)
            
            plt.title(f"{config['type'].capitalize()}, {config['num_bins']} bins\nIGCM: {result['igcm']:.4f}, {result['quality_level']}")
            plt.xlabel("Latence (μs)")
            plt.ylabel("Fréquence")
        
        plt.tight_layout()
        plt.savefig(f"histogram_quality_latency_{region_id}.png")
        plt.close()
        
        print(f"Visualisation enregistrée dans 'histogram_quality_latency_{region_id}.png'")
        print("=" * 80)

def test_different_contexts():
    """Test de l'algorithme avec différents contextes d'analyse."""
    print("\nTest avec différents contextes d'analyse")
    print("=" * 80)
    
    # Générer des données de latence typiques
    np.random.seed(42)
    data = np.random.gamma(shape=3, scale=50, size=1000)
    data = data * (300 / np.mean(data)) + 400  # Ajuster pour la plage Cache Système
    
    # Configuration de binning fixe
    config = {"type": "logarithmic", "num_bins": 20}
    
    # Tester différents contextes
    contexts = [
        None,  # Contexte par défaut
        "monitoring",
        "stability",
        "anomaly_detection",
        "characterization"
    ]
    
    print(f"Données: Latence Cache Système ({np.min(data):.0f}-{np.max(data):.0f} μs)")
    print(f"Configuration: {config['type']}, {config['num_bins']} bins")
    print("-" * 50)
    
    for context in contexts:
        context_name = context if context else "défaut"
        result = evaluate_histogram_quality(data, config, context=context)
        
        print(f"\nContexte: {context_name}")
        print(f"IGCM: {result['igcm']:.4f}, Qualité: {result['quality_level']}")
        print(f"Seuils utilisés: {result['thresholds']}")
        print(f"Erreurs: Moyenne={result['errors']['mean']:.2f}%, Variance={result['errors']['variance']:.2f}%")
        print(f"         Asymétrie={result['errors']['skewness']:.2f}%, Aplatissement={result['errors']['kurtosis']:.2f}%")
    
    # Trouver la configuration optimale pour chaque contexte
    print("\nConfigurations optimales par contexte pour qualité 'Très bon':")
    for context in contexts:
        context_name = context if context else "défaut"
        optimal_config, optimal_eval = optimize_histogram_config(data, target_quality="Très bon", context=context)
        print(f"Contexte '{context_name}': {optimal_config['type']}, {optimal_config['num_bins']} bins, IGCM={optimal_eval['igcm']:.4f}")
    
    print("=" * 80)

if __name__ == "__main__":
    # Exécuter les tests
    test_with_synthetic_data()
    test_with_real_latency_data()
    test_different_contexts()
    
    print("\nTous les tests terminés avec succès!")
