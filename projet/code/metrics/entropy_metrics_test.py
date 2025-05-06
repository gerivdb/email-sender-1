#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test complet des métriques basées sur l'entropie.
"""

import numpy as np
import scipy.stats
import scipy.integrate
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple, Union, Optional, Any, Callable

# Constantes pour les paramètres par défaut
DEFAULT_EPSILON = 1e-10  # Valeur minimale pour éviter log(0)

# Fonction pour calculer l'entropie de Shannon
def calculate_shannon_entropy(probabilities, base=2.0):
    valid_probs = probabilities[probabilities > 0]
    if not np.isclose(np.sum(valid_probs), 1.0):
        valid_probs = valid_probs / np.sum(valid_probs)
    
    if base == 2.0:
        entropy = -np.sum(valid_probs * np.log2(valid_probs))
    elif base == np.e:
        entropy = -np.sum(valid_probs * np.log(valid_probs))
    else:
        entropy = -np.sum(valid_probs * np.log(valid_probs)) / np.log(base)
    
    return entropy

# Fonction pour estimer l'entropie différentielle
def estimate_differential_entropy(data, kde_bandwidth='scott', base=2.0, num_samples=1000):
    # Estimer la densité avec KDE
    kde = scipy.stats.gaussian_kde(data, bw_method=kde_bandwidth)
    
    # Créer une grille pour l'évaluation
    x_min, x_max = np.min(data), np.max(data)
    x_range = x_max - x_min
    x_grid = np.linspace(x_min - 0.1 * x_range, x_max + 0.1 * x_range, num_samples)
    
    # Évaluer la densité sur la grille
    density = kde(x_grid)
    
    # Éviter les valeurs nulles ou négatives
    density = np.maximum(density, DEFAULT_EPSILON)
    
    # Calculer l'entropie différentielle
    if base == 2.0:
        log_density = np.log2(density)
    elif base == np.e:
        log_density = np.log(density)
    else:
        log_density = np.log(density) / np.log(base)
    
    # Intégration numérique: -∫ f(x) log(f(x)) dx
    entropy = -np.trapz(density * log_density, x_grid)
    
    return entropy

# Fonction pour calculer la divergence KL
def calculate_kl_divergence(p, q, base=2.0):
    # Filtrer les probabilités nulles et s'assurer que q > 0 où p > 0
    mask = p > 0
    p_valid = p[mask]
    q_valid = np.maximum(q[mask], DEFAULT_EPSILON)
    
    # Normaliser si nécessaire
    if not np.isclose(np.sum(p_valid), 1.0):
        p_valid = p_valid / np.sum(p_valid)
    if not np.isclose(np.sum(q_valid), 1.0):
        q_valid = q_valid / np.sum(q_valid)
    
    # Calculer la divergence KL
    if base == 2.0:
        kl_div = np.sum(p_valid * np.log2(p_valid / q_valid))
    elif base == np.e:
        kl_div = np.sum(p_valid * np.log(p_valid / q_valid))
    else:
        kl_div = np.sum(p_valid * np.log(p_valid / q_valid)) / np.log(base)
    
    return kl_div

# Fonction pour calculer la divergence JS
def calculate_jensen_shannon_divergence(p, q, base=2.0):
    # Normaliser si nécessaire
    if not np.isclose(np.sum(p), 1.0):
        p = p / np.sum(p)
    if not np.isclose(np.sum(q), 1.0):
        q = q / np.sum(q)
    
    # Calculer la distribution moyenne
    m = 0.5 * (p + q)
    
    # Calculer la divergence JS
    js_div = 0.5 * calculate_kl_divergence(p, m, base) + 0.5 * calculate_kl_divergence(q, m, base)
    
    return js_div

# Fonction pour reconstruire les données à partir d'un histogramme
def reconstruct_data_from_histogram(bin_edges, bin_counts, method="uniform"):
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

# Fonction pour calculer la perte d'information
def calculate_information_loss(original_data, bin_edges, bin_counts, base=2.0):
    # Estimer l'entropie différentielle des données originales
    original_entropy = estimate_differential_entropy(original_data, base=base)
    
    # Calculer l'entropie de l'histogramme
    probabilities = bin_counts / np.sum(bin_counts)
    histogram_entropy = calculate_shannon_entropy(probabilities, base=base)
    
    # Reconstruire les données à partir de l'histogramme
    reconstructed_data = reconstruct_data_from_histogram(bin_edges, bin_counts)
    
    # Estimer l'entropie différentielle des données reconstruites
    if len(reconstructed_data) > 0:
        reconstructed_entropy = estimate_differential_entropy(reconstructed_data, base=base)
    else:
        reconstructed_entropy = 0.0
    
    # Calculer le ratio d'information préservée
    if original_entropy != 0:
        information_preservation_ratio = reconstructed_entropy / original_entropy
    else:
        information_preservation_ratio = 1.0 if reconstructed_entropy == 0 else 0.0
    
    # Calculer le ratio de perte d'information
    information_loss_ratio = 1.0 - information_preservation_ratio
    
    return {
        "original_entropy": original_entropy,
        "histogram_entropy": histogram_entropy,
        "reconstructed_entropy": reconstructed_entropy,
        "information_preservation_ratio": information_preservation_ratio,
        "information_loss_ratio": information_loss_ratio
    }

# Fonction pour comparer différentes stratégies de binning
def compare_binning_strategies(data, strategies=None, num_bins=20, base=2.0):
    if strategies is None:
        strategies = ["uniform", "quantile", "logarithmic"]
    
    results = {}
    
    for strategy in strategies:
        # Générer l'histogramme selon la stratégie
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
        
        # Calculer les métriques de perte d'information
        metrics = calculate_information_loss(data, bin_edges, bin_counts, base)
        
        # Stocker les résultats
        results[strategy] = {
            "bin_edges": bin_edges,
            "bin_counts": bin_counts,
            "metrics": metrics
        }
    
    return results

# Fonction pour trouver le nombre optimal de bins
def find_optimal_bin_count(data, strategy="uniform", min_bins=5, max_bins=100, step=5, base=2.0):
    results = {}
    best_ratio = 0
    optimal_bins = min_bins
    
    for num_bins in range(min_bins, max_bins + 1, step):
        # Générer l'histogramme
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
        
        # Calculer les métriques de perte d'information
        metrics = calculate_information_loss(data, bin_edges, bin_counts, base)
        
        # Stocker les résultats
        results[num_bins] = metrics["information_preservation_ratio"]
        
        # Mettre à jour le meilleur ratio
        if metrics["information_preservation_ratio"] > best_ratio:
            best_ratio = metrics["information_preservation_ratio"]
            optimal_bins = num_bins
    
    return {
        "optimal_bins": optimal_bins,
        "best_ratio": best_ratio,
        "ratios": results
    }

# Générer des données de test
np.random.seed(42)

# Différentes distributions pour les tests
distributions = {
    "normal": np.random.normal(loc=100, scale=15, size=1000),
    "asymmetric": np.random.gamma(shape=3, scale=10, size=1000),
    "leptokurtic": np.random.standard_t(df=3, size=1000) * 15 + 100,
    "multimodal": np.concatenate([
        np.random.normal(loc=70, scale=10, size=500),
        np.random.normal(loc=130, scale=15, size=500)
    ])
}

print("=== Test des métriques basées sur l'entropie ===")

# Test 1: Calcul de l'entropie de Shannon
print("\n1. Test du calcul de l'entropie de Shannon")
probabilities = np.array([0.1, 0.2, 0.3, 0.4])
entropy = calculate_shannon_entropy(probabilities)
print(f"Entropie de Shannon: {entropy:.4f} bits")

# Test 2: Estimation de l'entropie différentielle
print("\n2. Test de l'estimation de l'entropie différentielle")
for dist_name, data in distributions.items():
    entropy = estimate_differential_entropy(data)
    print(f"Distribution {dist_name}: {entropy:.4f} bits")

# Test 3: Calcul de la divergence KL
print("\n3. Test du calcul de la divergence KL")
p = np.array([0.1, 0.4, 0.5])
q = np.array([0.2, 0.3, 0.5])
kl_div = calculate_kl_divergence(p, q)
print(f"Divergence KL: {kl_div:.4f} bits")

# Test 4: Calcul de la divergence JS
print("\n4. Test du calcul de la divergence JS")
js_div = calculate_jensen_shannon_divergence(p, q)
print(f"Divergence JS: {js_div:.4f} bits")

# Test 5: Calcul de la perte d'information
print("\n5. Test du calcul de la perte d'information")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    # Comparer différentes stratégies de binning
    results = compare_binning_strategies(data)
    
    for strategy, result in results.items():
        metrics = result["metrics"]
        print(f"  Stratégie {strategy}:")
        print(f"    Entropie originale: {metrics['original_entropy']:.4f} bits")
        print(f"    Entropie reconstruite: {metrics['reconstructed_entropy']:.4f} bits")
        print(f"    Ratio de préservation: {metrics['information_preservation_ratio']:.4f}")
        print(f"    Ratio de perte: {metrics['information_loss_ratio']:.4f}")

# Test 6: Recherche du nombre optimal de bins
print("\n6. Test de la recherche du nombre optimal de bins")
for dist_name, data in distributions.items():
    print(f"\nDistribution {dist_name}:")
    
    for strategy in ["uniform", "quantile", "logarithmic"]:
        optimization = find_optimal_bin_count(data, strategy=strategy, min_bins=5, max_bins=50, step=5)
        print(f"  Stratégie {strategy}: {optimization['optimal_bins']} bins (ratio: {optimization['best_ratio']:.4f})")

print("\nTest terminé avec succès!")
