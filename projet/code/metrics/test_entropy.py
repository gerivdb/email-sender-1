#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test direct des métriques basées sur l'entropie.
"""

import numpy as np
import scipy.stats
import scipy.integrate

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

# Générer des données de test
np.random.seed(42)

# Créer une distribution normale
data_normal = np.random.normal(loc=100, scale=15, size=1000)

# Créer une distribution asymétrique
data_asymmetric = np.random.gamma(shape=3, scale=10, size=1000)

# Créer une distribution bimodale
data_bimodal = np.concatenate([
    np.random.normal(loc=70, scale=10, size=500),
    np.random.normal(loc=130, scale=15, size=500)
])

print("=== Test des métriques basées sur l'entropie ===")

# Test 1: Calcul de l'entropie de Shannon
print("\n1. Test du calcul de l'entropie de Shannon")
probabilities = np.array([0.1, 0.2, 0.3, 0.4])
entropy = calculate_shannon_entropy(probabilities)
print(f"Entropie de Shannon: {entropy:.4f} bits")

# Test 2: Calcul de l'entropie d'un histogramme
print("\n2. Test du calcul de l'entropie d'un histogramme")
for name, data in [("normale", data_normal), ("asymétrique", data_asymmetric), ("bimodale", data_bimodal)]:
    # Créer un histogramme
    bin_counts, _ = np.histogram(data, bins=20)
    
    # Convertir les comptages en probabilités
    probabilities = bin_counts / np.sum(bin_counts)
    
    # Calculer l'entropie
    entropy = calculate_shannon_entropy(probabilities)
    
    print(f"Distribution {name}: {entropy:.4f} bits")

print("\nTest terminé avec succès!")
