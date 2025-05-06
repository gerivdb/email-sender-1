#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Test simplifié de la relation théorique entre largeur des bins et résolution.
"""

import numpy as np
import matplotlib.pyplot as plt
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

print("=== Test simplifié de la relation théorique entre largeur des bins et résolution ===")

# Définir les relations théoriques directement
print("\nRelations théoriques entre largeur des bins et résolution:")
print("1. FWHM: FWHM_mesurée ≈ sqrt(FWHM_vraie^2 + bin_width^2)")
print("   - Cette relation montre que la FWHM mesurée est toujours plus grande que la FWHM vraie")
print("   - L'erreur augmente quadratiquement avec la largeur des bins")
print("2. Pente: slope_mesurée ≈ slope_vraie / (1 + k * (bin_width/sigma)^2)")
print("   - La pente mesurée est toujours plus faible que la pente vraie")
print("   - L'erreur augmente quadratiquement avec la largeur des bins")
print("3. Courbure: curvature_mesurée ≈ curvature_vraie / (1 + k' * (bin_width/sigma)^2)")
print("   - La courbure mesurée est toujours plus faible que la courbure vraie")
print("   - L'erreur augmente quadratiquement avec la largeur des bins")

# Visualiser les relations théoriques
print("\nVisualisation des relations théoriques...")

# Créer la figure
fig, axes = plt.subplots(3, 1, figsize=(10, 12), sharex=True)

# Relation pour FWHM
ax1 = axes[0]
bin_width_to_fwhm_ratio = np.linspace(0.1, 2, 100)
theoretical_fwhm_error = np.sqrt(1 + bin_width_to_fwhm_ratio**2) - 1
ax1.plot(bin_width_to_fwhm_ratio, theoretical_fwhm_error, 'b-', linewidth=2)
ax1.set_ylabel('Erreur relative FWHM')
ax1.set_title('Relation entre largeur des bins et erreur FWHM')
ax1.grid(True, alpha=0.3)

# Relation pour la pente
ax2 = axes[1]
bin_width_to_sigma_ratio = np.linspace(0.1, 2, 100)
k = 0.5  # Coefficient empirique
theoretical_slope_error = 1 / (1 + k * bin_width_to_sigma_ratio**2) - 1
ax2.plot(bin_width_to_sigma_ratio, theoretical_slope_error, 'g-', linewidth=2)
ax2.set_ylabel('Erreur relative pente maximale')
ax2.set_title('Relation entre largeur des bins et erreur de pente')
ax2.grid(True, alpha=0.3)

# Relation pour la courbure
ax3 = axes[2]
k_prime = 1.0  # Coefficient empirique
theoretical_curvature_error = 1 / (1 + k_prime * bin_width_to_sigma_ratio**2) - 1
ax3.plot(bin_width_to_sigma_ratio, theoretical_curvature_error, 'r-', linewidth=2)
ax3.set_xlabel('Largeur des bins / paramètre d\'échelle')
ax3.set_ylabel('Erreur relative courbure maximale')
ax3.set_title('Relation entre largeur des bins et erreur de courbure')
ax3.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("bin_width_resolution_relationship_simple.png", dpi=300, bbox_inches='tight')
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
