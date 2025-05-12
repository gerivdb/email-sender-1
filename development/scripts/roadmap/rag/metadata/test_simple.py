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
    text2 = "The project will take about 10 days."
    
    results1 = get_approximate_expressions(text1, "French")
    results2 = get_approximate_expressions(text2, "English")
    
    print(f"Texte 1: {text1}")
    print(f"Résultats: {len(results1)}")
    for result in results1:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    print(f"\nTexte 2: {text2}")
    print(f"Résultats: {len(results2)}")
    for result in results2:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    # Test des nombres écrits en toutes lettres
    print("\n=== Test des nombres écrits en toutes lettres ===")
    
    text3 = "La première tâche prendra vingt jours."
    text4 = "The first task will take twenty days."
    
    results3 = get_textual_numbers(text3, "French")
    results4 = get_textual_numbers(text4, "English")
    
    print(f"Texte 3: {text3}")
    print(f"Résultats: {len(results3)}")
    for result in results3:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    print(f"\nTexte 4: {text4}")
    print(f"Résultats: {len(results4)}")
    for result in results4:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    # Test des unités de temps
    print("\n=== Test des unités de temps ===")
    
    text5 = "Le projet prendra 10 jours et 5 heures."
    text6 = "The project will take 10 days and 5 hours."
    
    results5 = get_time_units(text5, "French")
    results6 = get_time_units(text6, "English")
    
    print(f"Texte 5: {text5}")
    print(f"Résultats: {len(results5)}")
    for result in results5:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")
    
    print(f"\nTexte 6: {text6}")
    print(f"Résultats: {len(results6)}")
    for result in results6:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")


if __name__ == "__main__":
    main()
