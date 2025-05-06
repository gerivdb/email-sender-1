#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour le système de pondération adaptative.
"""

import numpy as np
import matplotlib.pyplot as plt
from adaptive_weighting_system import (
    detect_distribution_type,
    detect_latency_region,
    calculate_adaptive_weights,
    get_weighting_system_config
)

def test_distribution_detection():
    """Test de la détection automatique du type de distribution."""
    print("Test de détection du type de distribution")
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
    
    # Distribution leptokurtique
    leptokurtic_data = np.random.standard_t(df=3, size=1000) * 20 + 100
    
    # Distribution fortement asymétrique
    highly_asymmetric_data = np.random.exponential(scale=50, size=1000) + 50
    
    # Tester la détection du type de distribution
    distributions = [
        ("Normale", normal_data),
        ("Log-normale", lognormal_data),
        ("Bimodale", bimodal_data),
        ("Leptokurtique", leptokurtic_data),
        ("Fortement asymétrique", highly_asymmetric_data)
    ]
    
    for name, data in distributions:
        # Calculer les statistiques de base
        mean = np.mean(data)
        std = np.std(data)
        skewness = float(scipy.stats.skew(data))
        kurtosis = float(scipy.stats.kurtosis(data, fisher=False))
        
        print(f"\nDistribution: {name}")
        print(f"Statistiques: Moyenne={mean:.2f}, Écart-type={std:.2f}")
        print(f"              Asymétrie={skewness:.2f}, Aplatissement={kurtosis:.2f}")
        
        # Détecter le type de distribution
        dist_type, confidence = detect_distribution_type(data)
        print(f"Type détecté: {dist_type}, Confiance: {confidence:.2f}")
    
    # Visualiser les distributions et les types détectés
    plt.figure(figsize=(15, 10))
    
    for i, (name, data) in enumerate(distributions):
        plt.subplot(2, 3, i+1)
        
        # Histogramme
        plt.hist(data, bins=30, alpha=0.7, density=True)
        
        # Détecter le type
        dist_type, confidence = detect_distribution_type(data)
        
        plt.title(f"{name}\nType détecté: {dist_type}\nConfiance: {confidence:.2f}")
        plt.xlabel("Valeur")
        plt.ylabel("Densité")
    
    plt.tight_layout()
    plt.savefig("distribution_detection_test.png")
    plt.close()
    
    print(f"\nVisualisation enregistrée dans 'distribution_detection_test.png'")
    print("=" * 80)

def test_latency_region_detection():
    """Test de la détection de la région de latence."""
    print("\nTest de détection de la région de latence")
    print("=" * 80)
    
    # Générer des données de latence pour différentes régions
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
    
    # Tester la détection de la région de latence
    latency_regions = [
        ("L1/L2 Cache", l1l2_data),
        ("L3/Mémoire", l3_data),
        ("Cache Système", syscache_data),
        ("Stockage", storage_data)
    ]
    
    for name, data in latency_regions:
        # Calculer les statistiques de base
        mean = np.mean(data)
        median = np.median(data)
        min_val = np.min(data)
        max_val = np.max(data)
        
        print(f"\nRégion: {name}")
        print(f"Statistiques: Moyenne={mean:.2f} μs, Médiane={median:.2f} μs")
        print(f"              Min={min_val:.2f} μs, Max={max_val:.2f} μs")
        
        # Détecter la région de latence
        region, confidence = detect_latency_region(data)
        print(f"Région détectée: {region}, Confiance: {confidence:.2f}")
    
    # Visualiser les distributions de latence et les régions détectées
    plt.figure(figsize=(15, 10))
    
    for i, (name, data) in enumerate(latency_regions):
        plt.subplot(2, 2, i+1)
        
        # Histogramme
        plt.hist(data, bins=30, alpha=0.7, density=True)
        
        # Détecter la région
        region, confidence = detect_latency_region(data)
        
        plt.title(f"{name}\nRégion détectée: {region}\nConfiance: {confidence:.2f}")
        plt.xlabel("Latence (μs)")
        plt.ylabel("Densité")
    
    plt.tight_layout()
    plt.savefig("latency_region_detection_test.png")
    plt.close()
    
    print(f"\nVisualisation enregistrée dans 'latency_region_detection_test.png'")
    print("=" * 80)

def test_adaptive_weights_calculation():
    """Test du calcul des poids adaptatifs."""
    print("\nTest du calcul des poids adaptatifs")
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
    
    # Tester le calcul des poids adaptatifs pour différents contextes
    distributions = [
        ("Normale", normal_data),
        ("Log-normale", lognormal_data),
        ("Bimodale", bimodal_data)
    ]
    
    contexts = [None, "monitoring", "stability", "anomaly_detection", "characterization"]
    
    for name, data in distributions:
        print(f"\nDistribution: {name}")
        
        # Détecter le type de distribution et la région de latence
        dist_type, dist_conf = detect_distribution_type(data)
        region, region_conf = detect_latency_region(data)
        
        print(f"Type détecté: {dist_type}, Confiance: {dist_conf:.2f}")
        print(f"Région détectée: {region}, Confiance: {region_conf:.2f}")
        
        # Tester différents contextes
        for context in contexts:
            context_name = context if context else "défaut"
            weights, factors = calculate_adaptive_weights(data, context=context)
            
            print(f"\nContexte: {context_name}")
            print(f"Poids: [{', '.join([f'{w:.2f}' for w in weights])}]")
            print(f"Coefficients de mélange ajustés:")
            for factor, info in factors.items():
                print(f"  {factor}: {info['coefficient']:.2f}")
    
    # Visualiser l'impact du contexte sur les poids
    plt.figure(figsize=(15, 10))
    
    for i, (name, data) in enumerate(distributions):
        plt.subplot(len(distributions), 1, i+1)
        
        # Calculer les poids pour chaque contexte
        all_weights = []
        for context in contexts:
            weights, _ = calculate_adaptive_weights(data, context=context)
            all_weights.append(weights)
        
        # Créer le graphique à barres groupées
        moment_names = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]
        x = np.arange(len(moment_names))
        width = 0.15
        
        for j, (context, weights) in enumerate(zip(contexts, all_weights)):
            context_name = context if context else "défaut"
            plt.bar(x + j*width - 0.3, weights, width, label=context_name)
        
        plt.xlabel('Moment statistique')
        plt.ylabel('Poids')
        plt.title(f'Impact du contexte sur les poids - Distribution {name}')
        plt.xticks(x, moment_names)
        plt.legend()
    
    plt.tight_layout()
    plt.savefig("adaptive_weights_context_impact.png")
    plt.close()
    
    print(f"\nVisualisation de l'impact du contexte enregistrée dans 'adaptive_weights_context_impact.png'")
    print("=" * 80)

def test_combined_factors():
    """Test de l'effet combiné des différents facteurs."""
    print("\nTest de l'effet combiné des facteurs")
    print("=" * 80)
    
    # Générer des données de latence pour différentes régions
    np.random.seed(42)
    
    # L1/L2 Cache - Distribution quasi-normale
    l1l2_normal = np.random.normal(loc=75, scale=5, size=1000)
    
    # L3/Mémoire - Distribution asymétrique modérée
    l3_asymmetric = np.random.gamma(shape=4, scale=20, size=1000)
    l3_asymmetric = l3_asymmetric * (100 / np.mean(l3_asymmetric)) + 150
    
    # Cache Système - Distribution multimodale
    syscache_multimodal = np.concatenate([
        np.random.normal(loc=450, scale=30, size=700),
        np.random.normal(loc=600, scale=20, size=300)
    ])
    
    # Stockage - Distribution fortement asymétrique
    storage_highly_asymmetric = np.random.exponential(scale=300, size=1000) + 1500
    
    # Tester différentes combinaisons de facteurs
    test_cases = [
        ("L1/L2 Cache - Normale", l1l2_normal, "monitoring", "performance"),
        ("L3/Mémoire - Asymétrique", l3_asymmetric, "stability", None),
        ("Cache Système - Multimodale", syscache_multimodal, "anomaly_detection", "predictability"),
        ("Stockage - Fortement asymétrique", storage_highly_asymmetric, "characterization", "structure")
    ]
    
    for name, data, context, objective in test_cases:
        print(f"\nCas de test: {name}")
        print(f"Contexte: {context}, Objectif: {objective}")
        
        # Calculer les poids adaptatifs
        weights, factors = calculate_adaptive_weights(data, context=context, objective=objective)
        
        # Afficher les résultats
        print(f"Poids finaux: [{', '.join([f'{w:.2f}' for w in weights])}]")
        print(f"Facteurs détectés:")
        for factor, info in factors.items():
            print(f"  {factor}: {info['value']}, Confiance: {info['confidence']:.2f}, Coefficient: {info['coefficient']:.2f}")
            print(f"    Poids: [{', '.join([f'{w:.2f}' for w in info['weights']])}]")
    
    # Visualiser l'effet combiné des facteurs
    plt.figure(figsize=(15, 10))
    
    moment_names = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]
    x = np.arange(len(moment_names))
    width = 0.2
    
    for i, (name, data, context, objective) in enumerate(test_cases):
        plt.subplot(2, 2, i+1)
        
        # Calculer les poids avec différentes combinaisons
        weights_context_only, _ = calculate_adaptive_weights(data, context=context, objective=None)
        weights_objective_only, _ = calculate_adaptive_weights(data, context=None, objective=objective)
        weights_combined, _ = calculate_adaptive_weights(data, context=context, objective=objective)
        weights_default, _ = calculate_adaptive_weights(data, context=None, objective=None)
        
        # Créer le graphique à barres groupées
        plt.bar(x - 1.5*width, weights_default, width, label='Défaut')
        plt.bar(x - 0.5*width, weights_context_only, width, label='Contexte')
        plt.bar(x + 0.5*width, weights_objective_only, width, label='Objectif')
        plt.bar(x + 1.5*width, weights_combined, width, label='Combiné')
        
        plt.xlabel('Moment statistique')
        plt.ylabel('Poids')
        plt.title(f'{name}')
        plt.xticks(x, moment_names)
        plt.legend()
    
    plt.tight_layout()
    plt.savefig("combined_factors_effect.png")
    plt.close()
    
    print(f"\nVisualisation de l'effet combiné des facteurs enregistrée dans 'combined_factors_effect.png'")
    print("=" * 80)

if __name__ == "__main__":
    # Importer scipy.stats pour les tests
    import scipy.stats
    
    # Exécuter les tests
    test_distribution_detection()
    test_latency_region_detection()
    test_adaptive_weights_calculation()
    test_combined_factors()
    
    print("\nTous les tests terminés avec succès!")
