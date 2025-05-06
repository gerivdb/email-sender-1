#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Module implémentant un système de pondération adaptative selon le contexte pour
l'évaluation de la conservation des moments statistiques dans les histogrammes de latence.
"""

import numpy as np
import scipy.stats
from scipy.signal import find_peaks


def detect_multimodality(data, min_prominence=0.05, min_height=0.02):
    """
    Détecte si une distribution est multimodale.
    
    Args:
        data: Données à analyser
        min_prominence: Proéminence minimale pour considérer un pic (relatif à la hauteur max)
        min_height: Hauteur minimale pour considérer un pic (relatif à la hauteur max)
        
    Returns:
        is_multimodal: Booléen indiquant si la distribution est multimodale
        modes: Liste des modes détectés (positions)
    """
    # Générer un histogramme avec un nombre élevé de bins pour détecter les modes
    hist, bin_edges = np.histogram(data, bins=min(100, len(data) // 10), density=True)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    
    # Normaliser l'histogramme
    hist_max = np.max(hist)
    hist_normalized = hist / hist_max
    
    # Trouver les pics
    peaks, properties = find_peaks(
        hist_normalized,
        prominence=min_prominence,
        height=min_height,
        distance=3  # Distance minimale entre les pics en nombre de bins
    )
    
    # Filtrer les pics trop proches en valeur
    if len(peaks) > 1:
        # Trier les pics par hauteur décroissante
        peak_heights = hist_normalized[peaks]
        sorted_indices = np.argsort(-peak_heights)
        sorted_peaks = peaks[sorted_indices]
        
        # Filtrer les pics
        filtered_peaks = [sorted_peaks[0]]
        for peak in sorted_peaks[1:]:
            # Vérifier si le pic est suffisamment distant des pics déjà retenus
            min_distance = np.min(np.abs(bin_centers[peak] - bin_centers[filtered_peaks]))
            if min_distance > (np.max(data) - np.min(data)) * 0.1:  # 10% de la plage des données
                filtered_peaks.append(peak)
        
        peaks = np.array(filtered_peaks)
    
    # Déterminer si la distribution est multimodale
    is_multimodal = len(peaks) > 1
    
    # Récupérer les positions des modes
    modes = bin_centers[peaks]
    
    return is_multimodal, modes


def detect_distribution_type(data):
    """
    Détecte automatiquement le type de distribution.
    
    Args:
        data: Données à analyser
        
    Returns:
        distribution_type: Type de distribution détecté
        confidence: Niveau de confiance dans la détection
    """
    # Calculer les statistiques de base
    mean = np.mean(data)
    std = np.std(data)
    skewness = scipy.stats.skew(data)
    kurtosis = scipy.stats.kurtosis(data, fisher=False)
    
    # Vérifier la multimodalité
    is_multimodal, _ = detect_multimodality(data)
    
    # Déterminer le type de distribution
    if is_multimodal:
        distribution_type = "multimodal"
        confidence = 0.8  # Confiance élevée dans la détection de multimodalité
    elif abs(skewness) < 0.5 and abs(kurtosis - 3) < 0.5:
        distribution_type = "quasiNormal"
        confidence = 0.9 - abs(skewness) - abs(kurtosis - 3) / 3
    elif kurtosis > 5:
        distribution_type = "leptokurtic"
        confidence = min(0.8, (kurtosis - 3) / 5)
    elif skewness > 1.5:
        distribution_type = "highlyAsymmetric"
        confidence = min(0.8, skewness / 3)
    elif skewness > 0.5:
        distribution_type = "moderatelyAsymmetric"
        confidence = min(0.7, skewness / 2)
    else:
        distribution_type = "quasiNormal"  # Par défaut
        confidence = 0.5
    
    return distribution_type, confidence


def detect_latency_region(data):
    """
    Détecte la région de latence.
    
    Args:
        data: Données de latence à analyser
        
    Returns:
        latency_region: Région de latence détectée
        confidence: Niveau de confiance dans la détection
    """
    # Calculer les statistiques de base
    median = np.median(data)
    
    # Déterminer la région de latence
    if median < 100:
        latency_region = "l1l2Cache"
        confidence = 1.0 - abs(median - 75) / 75
    elif median < 250:
        latency_region = "l3Memory"
        confidence = 1.0 - abs(median - 200) / 150
    elif median < 700:
        latency_region = "systemCache"
        confidence = 1.0 - abs(median - 550) / 300
    else:
        latency_region = "storage"
        confidence = min(1.0, median / 2000)
    
    # Limiter la confiance entre 0.5 et 0.95
    confidence = max(0.5, min(0.95, confidence))
    
    return latency_region, confidence


def calculate_adaptive_weights(data, context=None, objective=None):
    """
    Calcule les poids adaptatifs pour les moments statistiques.
    
    Args:
        data: Données à analyser
        context: Contexte d'analyse (monitoring, stability, etc.)
        objective: Objectif d'analyse (performance, stability, etc.)
        
    Returns:
        weights: Vecteur de pondération [w₁, w₂, w₃, w₄]
        factors: Facteurs détectés et utilisés
    """
    # Définir les matrices de pondération
    context_weights = {
        "monitoring": [0.50, 0.30, 0.15, 0.05],
        "comparative": [0.30, 0.30, 0.25, 0.15],
        "stability": [0.20, 0.50, 0.20, 0.10],
        "anomaly_detection": [0.20, 0.25, 0.35, 0.20],
        "characterization": [0.25, 0.25, 0.25, 0.25],
        None: [0.40, 0.30, 0.20, 0.10]  # Par défaut
    }
    
    distribution_weights = {
        "quasiNormal": [0.40, 0.40, 0.10, 0.10],
        "moderatelyAsymmetric": [0.35, 0.35, 0.20, 0.10],
        "highlyAsymmetric": [0.30, 0.30, 0.30, 0.10],
        "multimodal": [0.25, 0.35, 0.25, 0.15],
        "leptokurtic": [0.30, 0.30, 0.20, 0.20]
    }
    
    latency_weights = {
        "l1l2Cache": [0.45, 0.40, 0.10, 0.05],
        "l3Memory": [0.40, 0.35, 0.15, 0.10],
        "systemCache": [0.35, 0.35, 0.20, 0.10],
        "storage": [0.30, 0.30, 0.25, 0.15]
    }
    
    objective_weights = {
        "performance": [0.70, 0.20, 0.05, 0.05],
        "stability": [0.20, 0.60, 0.15, 0.05],
        "predictability": [0.15, 0.25, 0.30, 0.30],
        "structure": [0.25, 0.25, 0.25, 0.25],
        None: [0.40, 0.30, 0.20, 0.10]  # Par défaut
    }
    
    # Détecter les facteurs automatiquement si non spécifiés
    distribution_type, dist_confidence = detect_distribution_type(data)
    latency_region, region_confidence = detect_latency_region(data)
    
    # Définir les coefficients de mélange par défaut
    alpha = 0.40  # Contexte
    beta = 0.30   # Distribution
    gamma = 0.20  # Région
    delta = 0.10  # Objectif
    
    # Ajuster les coefficients selon la confiance
    context_confidence = 1.0 if context else 0.7
    objective_confidence = 1.0 if objective else 0.7
    
    denominator = (alpha * context_confidence + 
                  beta * dist_confidence + 
                  gamma * region_confidence + 
                  delta * objective_confidence)
    
    alpha_adj = alpha * context_confidence / denominator
    beta_adj = beta * dist_confidence / denominator
    gamma_adj = gamma * region_confidence / denominator
    delta_adj = delta * objective_confidence / denominator
    
    # Récupérer les vecteurs de pondération
    w_context = context_weights[context]
    w_distribution = distribution_weights[distribution_type]
    w_region = latency_weights[latency_region]
    w_objective = objective_weights[objective]
    
    # Calculer le vecteur de pondération final
    weights = [0, 0, 0, 0]
    for i in range(4):
        weights[i] = (alpha_adj * w_context[i] + 
                     beta_adj * w_distribution[i] + 
                     gamma_adj * w_region[i] + 
                     delta_adj * w_objective[i])
    
    # Normaliser les poids
    sum_weights = sum(weights)
    weights = [w / sum_weights for w in weights]
    
    # Préparer les informations sur les facteurs
    factors = {
        "context": {
            "value": context,
            "confidence": context_confidence,
            "coefficient": alpha_adj,
            "weights": w_context
        },
        "distribution": {
            "value": distribution_type,
            "confidence": dist_confidence,
            "coefficient": beta_adj,
            "weights": w_distribution
        },
        "region": {
            "value": latency_region,
            "confidence": region_confidence,
            "coefficient": gamma_adj,
            "weights": w_region
        },
        "objective": {
            "value": objective,
            "confidence": objective_confidence,
            "coefficient": delta_adj,
            "weights": w_objective
        }
    }
    
    return weights, factors


def get_weighting_system_config():
    """
    Retourne la configuration complète du système de pondération adaptative.
    
    Returns:
        config: Dictionnaire de configuration
    """
    config = {
        "adaptiveWeightingSystem": {
            "contextWeights": {
                "monitoring": [0.50, 0.30, 0.15, 0.05],
                "comparative": [0.30, 0.30, 0.25, 0.15],
                "stability": [0.20, 0.50, 0.20, 0.10],
                "anomalyDetection": [0.20, 0.25, 0.35, 0.20],
                "characterization": [0.25, 0.25, 0.25, 0.25],
                "default": [0.40, 0.30, 0.20, 0.10]
            },
            "distributionWeights": {
                "quasiNormal": [0.40, 0.40, 0.10, 0.10],
                "moderatelyAsymmetric": [0.35, 0.35, 0.20, 0.10],
                "highlyAsymmetric": [0.30, 0.30, 0.30, 0.10],
                "multimodal": [0.25, 0.35, 0.25, 0.15],
                "leptokurtic": [0.30, 0.30, 0.20, 0.20]
            },
            "latencyWeights": {
                "l1l2Cache": [0.45, 0.40, 0.10, 0.05],
                "l3Memory": [0.40, 0.35, 0.15, 0.10],
                "systemCache": [0.35, 0.35, 0.20, 0.10],
                "storage": [0.30, 0.30, 0.25, 0.15]
            },
            "objectiveWeights": {
                "performance": [0.70, 0.20, 0.05, 0.05],
                "stability": [0.20, 0.60, 0.15, 0.05],
                "predictability": [0.15, 0.25, 0.30, 0.30],
                "structure": [0.25, 0.25, 0.25, 0.25],
                "default": [0.40, 0.30, 0.20, 0.10]
            },
            "mixingCoefficients": {
                "context": 0.40,
                "distribution": 0.30,
                "region": 0.20,
                "objective": 0.10
            }
        }
    }
    
    return config


if __name__ == "__main__":
    # Exemple d'utilisation
    import matplotlib.pyplot as plt
    
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
    
    # Tester la détection du type de distribution
    distributions = [
        ("Normale", normal_data),
        ("Log-normale", lognormal_data),
        ("Bimodale", bimodal_data),
        ("Avec valeurs aberrantes", outlier_data)
    ]
    
    for name, data in distributions:
        dist_type, confidence = detect_distribution_type(data)
        print(f"Distribution {name}: Type détecté = {dist_type}, Confiance = {confidence:.2f}")
        
        # Tester la détection de la région de latence
        region, region_conf = detect_latency_region(data)
        print(f"  Région de latence détectée = {region}, Confiance = {region_conf:.2f}")
        
        # Tester le calcul des poids adaptatifs pour différents contextes
        contexts = [None, "monitoring", "stability", "anomaly_detection", "characterization"]
        
        for context in contexts:
            weights, factors = calculate_adaptive_weights(data, context=context)
            context_name = context if context else "défaut"
            print(f"  Contexte {context_name}: Poids = [{', '.join([f'{w:.2f}' for w in weights])}]")
        
        print("-" * 50)
    
    # Visualiser les distributions et les poids adaptatifs
    plt.figure(figsize=(15, 10))
    
    for i, (name, data) in enumerate(distributions):
        plt.subplot(2, 2, i+1)
        
        # Histogramme
        plt.hist(data, bins=30, alpha=0.7, density=True)
        
        # Détecter le type et calculer les poids
        dist_type, _ = detect_distribution_type(data)
        weights, _ = calculate_adaptive_weights(data)
        
        plt.title(f"{name}\nType: {dist_type}, Poids: [{', '.join([f'{w:.2f}' for w in weights])}]")
        plt.xlabel("Valeur")
        plt.ylabel("Densité")
    
    plt.tight_layout()
    plt.savefig("adaptive_weights_distributions.png")
    plt.close()
    
    print(f"Visualisation enregistrée dans 'adaptive_weights_distributions.png'")
    
    # Tester l'impact du contexte sur les poids
    plt.figure(figsize=(10, 6))
    
    contexts = ["monitoring", "stability", "anomaly_detection", "characterization"]
    moment_names = ["Moyenne", "Variance", "Asymétrie", "Aplatissement"]
    
    # Utiliser la distribution log-normale comme exemple
    data = lognormal_data
    
    # Calculer les poids pour chaque contexte
    all_weights = []
    for context in contexts:
        weights, _ = calculate_adaptive_weights(data, context=context)
        all_weights.append(weights)
    
    # Créer le graphique à barres groupées
    x = np.arange(len(moment_names))
    width = 0.2
    
    for i, (context, weights) in enumerate(zip(contexts, all_weights)):
        plt.bar(x + i*width - 0.3, weights, width, label=context)
    
    plt.xlabel('Moment statistique')
    plt.ylabel('Poids')
    plt.title('Impact du contexte sur les poids des moments')
    plt.xticks(x, moment_names)
    plt.legend()
    plt.tight_layout()
    
    plt.savefig("context_impact_on_weights.png")
    plt.close()
    
    print(f"Visualisation de l'impact du contexte enregistrée dans 'context_impact_on_weights.png'")
