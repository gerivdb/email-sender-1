#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les fonctions d'évaluation de l'IQR.
"""

import numpy as np
import sys
import os

# Ajouter le répertoire courant au chemin de recherche des modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Importer les modules nécessaires
from iqr_report_symmetric import create_iqr_precision_report_symmetric
from iqr_report_heavy_tailed import create_iqr_precision_report_heavy_tailed
from iqr_report_multimodal import create_iqr_precision_report_multimodal

def main():
    """
    Fonction principale pour tester les fonctions d'évaluation de l'IQR.
    """
    print("=== Test des fonctions d'évaluation de l'IQR ===")
    
    # Générer des distributions synthétiques pour les tests
    np.random.seed(42)  # Pour la reproductibilité
    
    # Distribution gaussienne (symétrique)
    gaussian_data = np.random.normal(loc=50, scale=10, size=1000)
    
    # Distribution bimodale (multimodale)
    bimodal_data = np.concatenate([
        np.random.normal(loc=30, scale=5, size=500),
        np.random.normal(loc=70, scale=8, size=500)
    ])
    
    # Distribution asymétrique (log-normale, queue lourde)
    lognormal_data = np.random.lognormal(mean=1.0, sigma=0.5, size=1000)
    
    # Tester les fonctions d'évaluation sur différentes distributions
    for name, data, distribution_type in [
        ("Gaussienne", gaussian_data, "symmetric"),
        ("Bimodale", bimodal_data, "multimodal"),
        ("Log-normale", lognormal_data, "heavy_tailed")
    ]:
        print(f"\nDistribution {name} ({distribution_type}):")
        
        # Créer un rapport sur la précision de l'estimation de l'IQR
        if distribution_type == "symmetric":
            report = create_iqr_precision_report_symmetric(
                data,
                bin_counts=[10, 20, 50, 100, 200],
                kde_points=[100, 200, 500, 1000, 2000],
                save_path=f"iqr_precision_{distribution_type}_{name.lower()}.png",
                show_plot=False
            )
        elif distribution_type == "heavy_tailed":
            report = create_iqr_precision_report_heavy_tailed(
                data,
                bin_counts=[10, 20, 50, 100, 200],
                kde_points=[100, 200, 500, 1000, 2000],
                save_path=f"iqr_precision_{distribution_type}_{name.lower()}.png",
                show_plot=False
            )
        elif distribution_type == "multimodal":
            report = create_iqr_precision_report_multimodal(
                data,
                bin_counts=[10, 20, 50, 100, 200],
                kde_points=[100, 200, 500, 1000, 2000],
                save_path=f"iqr_precision_{distribution_type}_{name.lower()}.png",
                show_plot=False
            )
        
        # Afficher les recommandations pour l'IQR
        print(f"  Recommandations:")
        print(f"    Histogramme: min_bins={report['recommendations']['histogram']['min_bins']}, "
              f"optimal_bins={report['recommendations']['histogram']['optimal_bins']}, "
              f"qualité={report['recommendations']['histogram']['quality']}")
        print(f"    KDE: min_points={report['recommendations']['kde']['min_points']}, "
              f"optimal_points={report['recommendations']['kde']['optimal_points']}, "
              f"qualité={report['recommendations']['kde']['quality']}")
        print(f"    Méthode préférée: {report['recommendations']['preferred_method']}")
    
    print("\nTest terminé avec succès!")
    print("Résultats sauvegardés dans les fichiers PNG correspondants.")

if __name__ == "__main__":
    main()
