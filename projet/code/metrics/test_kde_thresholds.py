#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script de test pour les seuils d'erreur des KDEs à différentes résolutions.
"""

from dispersion_error_thresholds import define_dispersion_error_thresholds_kde

def main():
    """
    Fonction principale pour tester les seuils d'erreur des KDEs à différentes résolutions.
    """
    # Tester uniquement pour l'IQR
    measure = "iqr"

    # Tester les seuils pour les KDEs à haute résolution
    print("=== Test des seuils d'erreur pour l'IQR (KDEs à haute résolution) ===")
    thresholds = define_dispersion_error_thresholds_kde(measure, resolution="high")

    print(f"  Excellent: < {thresholds['excellent']:.1%}")
    print(f"  Good: < {thresholds['good']:.1%}")
    print(f"  Acceptable: < {thresholds['acceptable']:.1%}")
    print(f"  Poor: < {thresholds['poor']:.1%}")
    print(f"  Unacceptable: >= {thresholds['poor']:.1%}")

    print("\nTest terminé avec succès!")

if __name__ == "__main__":
    main()
