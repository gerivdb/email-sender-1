#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié pour les métriques basées sur l'entropie.
"""

import os
import sys
import numpy as np

# Ajouter le chemin du module
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
metrics_path = os.path.join(project_root, 'projet', 'code', 'metrics')
sys.path.insert(0, metrics_path)

# Importer directement le module
try:
    import entropy_based_metrics as ebm
    print(f"Module importé depuis {metrics_path}")
except ImportError as e:
    print(f"Erreur d'importation: {e}")
    print(f"Chemin du module: {metrics_path}")
    print(f"Contenu du répertoire:")
    if os.path.exists(metrics_path):
        for file in os.listdir(metrics_path):
            print(f"  - {file}")
    else:
        print(f"Le répertoire {metrics_path} n'existe pas")
    sys.exit(1)

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
entropy = ebm.calculate_shannon_entropy(probabilities)
print(f"Entropie de Shannon: {entropy:.4f} bits")

# Test 2: Estimation de l'entropie différentielle
print("\n2. Test de l'estimation de l'entropie différentielle")
for name, data in [("normale", data_normal), ("asymétrique", data_asymmetric), ("bimodale", data_bimodal)]:
    entropy = ebm.estimate_differential_entropy(data)
    print(f"Distribution {name}: {entropy:.4f} bits")

# Test 3: Calcul de la divergence KL
print("\n3. Test du calcul de la divergence KL")
p = np.array([0.1, 0.4, 0.5])
q = np.array([0.2, 0.3, 0.5])
kl_div = ebm.calculate_kl_divergence(p, q)
print(f"Divergence KL: {kl_div:.4f} bits")

# Test 4: Calcul de la perte d'information
print("\n4. Test du calcul de la perte d'information")
for name, data in [("normale", data_normal), ("asymétrique", data_asymmetric), ("bimodale", data_bimodal)]:
    # Créer un histogramme
    bin_edges = np.linspace(min(data), max(data), 20 + 1)
    bin_counts, _ = np.histogram(data, bins=bin_edges)

    # Calculer les métriques de perte d'information
    metrics = ebm.calculate_information_loss(data, bin_edges, bin_counts)

    print(f"\nDistribution {name}:")
    print(f"  Entropie originale: {metrics['original_entropy']:.4f} bits")
    print(f"  Entropie de l'histogramme: {metrics['histogram_entropy']:.4f} bits")
    print(f"  Entropie reconstruite: {metrics['reconstructed_entropy']:.4f} bits")
    print(f"  Divergence KL: {metrics['kl_divergence']:.4f} bits")
    print(f"  Ratio de préservation: {metrics['information_preservation_ratio']:.4f}")
    print(f"  Ratio de perte: {metrics['information_loss_ratio']:.4f}")

print("\nTest terminé avec succès!")
