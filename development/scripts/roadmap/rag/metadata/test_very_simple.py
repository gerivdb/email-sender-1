#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester les fonctionnalités de base
Version: 1.0
Date: 2025-05-15
"""

from approximate_expressions import get_approximate_expressions
from textual_numbers import get_textual_numbers
from time_units import get_time_units


def main():
    """Fonction principale"""
    # Test des expressions approximatives
    print("=== Test des expressions approximatives ===")
    
    text1 = "Le projet prendra environ 10 jours."
    
    results1 = get_approximate_expressions(text1, "French")
    
    print(f"Texte: {text1}")
    print(f"Résultats: {len(results1)}")
    for result in results1:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    # Test des nombres écrits en toutes lettres
    print("\n=== Test des nombres écrits en toutes lettres ===")
    
    text2 = "La première tâche prendra vingt jours."
    
    results2 = get_textual_numbers(text2, "French")
    
    print(f"Texte: {text2}")
    print(f"Résultats: {len(results2)}")
    for result in results2:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    # Test des unités de temps
    print("\n=== Test des unités de temps ===")
    
    text3 = "Le projet prendra 10 jours et 5 heures."
    
    results3 = get_time_units(text3, "French")
    
    print(f"Texte: {text3}")
    print(f"Résultats: {len(results3)}")
    for result in results3:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")


if __name__ == "__main__":
    main()
