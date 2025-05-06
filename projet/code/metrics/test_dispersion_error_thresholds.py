#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les seuils d'erreur des mesures de dispersion.
"""

from dispersion_error_thresholds import define_dispersion_error_thresholds_high_resolution_histogram

def main():
    """
    Fonction principale pour tester les seuils d'erreur des mesures de dispersion.
    """
    # Tester les seuils pour différentes mesures de dispersion
    measures = ["range", "std", "iqr"]  # Réduit pour accélérer le test

    # Tester uniquement les seuils pour les histogrammes à haute résolution
    print("=== Test des seuils d'erreur pour les mesures de dispersion (histogrammes à haute résolution) ===")
    for measure in measures:
        print(f"\nSeuils d'erreur pour {measure}:")
        thresholds = define_dispersion_error_thresholds_high_resolution_histogram(measure)

        print(f"  Excellent: < {thresholds['excellent']:.1%}")
        print(f"  Good: < {thresholds['good']:.1%}")
        print(f"  Acceptable: < {thresholds['acceptable']:.1%}")
        print(f"  Poor: < {thresholds['poor']:.1%}")
        print(f"  Unacceptable: >= {thresholds['poor']:.1%}")

    print("\nTest terminé avec succès!")

if __name__ == "__main__":
    main()
