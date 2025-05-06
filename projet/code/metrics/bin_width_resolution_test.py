#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test de la relation théorique entre largeur des bins et résolution.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les fonctions nécessaires
from resolution_metrics import (
    derive_bin_width_resolution_relationship,
    plot_bin_width_resolution_relationship
)

print("=== Test de la relation théorique entre largeur des bins et résolution ===")

# Dériver la relation théorique
print("\nDérivation de la relation théorique...")
relationship = derive_bin_width_resolution_relationship(
    sigma_range=np.array([1.0, 2.0, 5.0, 10.0]),
    bin_width_factors=np.linspace(0.1, 2, 10)
)

# Afficher les modèles théoriques
print("\nModèles théoriques dérivés:")
print(f"FWHM: {relationship['models']['fwhm']['formula']}")
print(f"Description: {relationship['models']['fwhm']['description']}")
print(f"Pente: {relationship['models']['slope']['formula']}")
print(f"Description: {relationship['models']['slope']['description']}")
print(f"Courbure: {relationship['models']['curvature']['formula']}")
print(f"Description: {relationship['models']['curvature']['description']}")

# Visualiser la relation théorique
print("\nVisualisation de la relation théorique...")
plot_bin_width_resolution_relationship(
    relationship,
    save_path="bin_width_resolution_relationship.png",
    show_plot=False
)

# Test avec des distributions réelles
print("\nTest avec des distributions réelles...")

# Créer différentes distributions gaussiennes
sigmas = [1.0, 2.0, 5.0, 10.0]
distributions = {}

for sigma in sigmas:
    # Générer une distribution gaussienne
    x = np.linspace(-5*sigma, 5*sigma, 1000)
    y = np.exp(-(x**2) / (2*sigma**2)) / (sigma * np.sqrt(2*np.pi))
    distributions[f"Gaussienne (σ={sigma})"] = (x, y)

# Créer une figure pour visualiser les distributions
plt.figure(figsize=(10, 6))
for name, (x, y) in distributions.items():
    plt.plot(x, y, label=name)
plt.xlabel('x')
plt.ylabel('Densité de probabilité')
plt.title('Distributions gaussiennes utilisées pour les tests')
plt.legend()
plt.grid(True, alpha=0.3)
plt.savefig("test_distributions.png", dpi=300, bbox_inches='tight')
plt.close()

# Recommandations pratiques
print("\nRecommandations pratiques pour le choix de la largeur des bins:")
print("1. Pour une résolution FWHM optimale: largeur des bins ≤ 0.5 * FWHM_vraie")
print("   - Erreur relative < 10% si largeur des bins ≤ 0.5 * FWHM_vraie")
print("   - Erreur relative < 5% si largeur des bins ≤ 0.3 * FWHM_vraie")
print("2. Pour une résolution de pente optimale: largeur des bins ≤ 0.7 * sigma")
print("   - Erreur relative < 20% si largeur des bins ≤ 0.7 * sigma")
print("   - Erreur relative < 10% si largeur des bins ≤ 0.5 * sigma")
print("3. Pour une résolution de courbure optimale: largeur des bins ≤ 0.5 * sigma")
print("   - Erreur relative < 20% si largeur des bins ≤ 0.5 * sigma")
print("   - Erreur relative < 10% si largeur des bins ≤ 0.3 * sigma")

# Formules pratiques pour déterminer le nombre optimal de bins
print("\nFormules pratiques pour déterminer le nombre optimal de bins:")
print("1. Pour une résolution FWHM optimale:")
print("   Nombre optimal de bins ≈ (max(data) - min(data)) / (0.5 * FWHM_estimée)")
print("2. Pour une résolution de pente optimale:")
print("   Nombre optimal de bins ≈ (max(data) - min(data)) / (0.7 * sigma_estimé)")
print("3. Pour une résolution de courbure optimale:")
print("   Nombre optimal de bins ≈ (max(data) - min(data)) / (0.5 * sigma_estimé)")
print("4. Règle générale pour un bon compromis:")
print("   Nombre optimal de bins ≈ (max(data) - min(data)) / (0.5 * sigma_estimé)")

print("\nTest terminé avec succès!")
