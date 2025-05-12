#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester toutes les fonctionnalités ensemble
Version: 1.0
Date: 2025-05-15
"""

import json
from approximate_expressions import get_approximate_expressions
from textual_numbers import get_textual_numbers
from time_units import get_time_units
from tag_normalizer import TagNormalizer


def test_approximate_expressions():
    """Tester la détection des expressions approximatives"""
    print("=== Test des expressions approximatives ===")
    
    text1 = "Le projet prendra environ 10 jours."
    text2 = "The project will take about 10 days."
    text3 = "Le projet nécessitera 20 jours environ."
    text4 = "The project will require 30 days approximately."
    
    results1 = get_approximate_expressions(text1, "French")
    results2 = get_approximate_expressions(text2, "English")
    results3 = get_approximate_expressions(text3, "French")
    results4 = get_approximate_expressions(text4, "English")
    
    print(f"Texte 1: {text1}")
    print(f"Résultats: {len(results1)}")
    for result in results1:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    print(f"\nTexte 2: {text2}")
    print(f"Résultats: {len(results2)}")
    for result in results2:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    print(f"\nTexte 3: {text3}")
    print(f"Résultats: {len(results3)}")
    for result in results3:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
    
    print(f"\nTexte 4: {text4}")
    print(f"Résultats: {len(results4)}")
    for result in results4:
        print(f"  - {result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")


def test_textual_numbers():
    """Tester la détection des nombres écrits en toutes lettres"""
    print("\n=== Test des nombres écrits en toutes lettres ===")
    
    text1 = "La première tâche prendra vingt jours."
    text2 = "The first task will take twenty days."
    text3 = "Le projet durera trente-cinq jours."
    text4 = "The project will last thirty-five days."
    
    results1 = get_textual_numbers(text1, "French")
    results2 = get_textual_numbers(text2, "English")
    results3 = get_textual_numbers(text3, "French")
    results4 = get_textual_numbers(text4, "English")
    
    print(f"Texte 1: {text1}")
    print(f"Résultats: {len(results1)}")
    for result in results1:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    print(f"\nTexte 2: {text2}")
    print(f"Résultats: {len(results2)}")
    for result in results2:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    print(f"\nTexte 3: {text3}")
    print(f"Résultats: {len(results3)}")
    for result in results3:
        print(f"  - {result.textual_number}: {result.numeric_value}")
    
    print(f"\nTexte 4: {text4}")
    print(f"Résultats: {len(results4)}")
    for result in results4:
        print(f"  - {result.textual_number}: {result.numeric_value}")


def test_time_units():
    """Tester la détection des unités de temps"""
    print("\n=== Test des unités de temps ===")
    
    text1 = "Le projet prendra 10 jours et 5 heures."
    text2 = "The project will take 10 days and 5 hours."
    text3 = "La tâche durera 30 minutes."
    text4 = "The task will last 30 minutes."
    
    results1 = get_time_units(text1, "French")
    results2 = get_time_units(text2, "English")
    results3 = get_time_units(text3, "French")
    results4 = get_time_units(text4, "English")
    
    print(f"Texte 1: {text1}")
    print(f"Résultats: {len(results1)}")
    for result in results1:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")
    
    print(f"\nTexte 2: {text2}")
    print(f"Résultats: {len(results2)}")
    for result in results2:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")
    
    print(f"\nTexte 3: {text3}")
    print(f"Résultats: {len(results3)}")
    for result in results3:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")
    
    print(f"\nTexte 4: {text4}")
    print(f"Résultats: {len(results4)}")
    for result in results4:
        print(f"  - {result.expression}: {result.info['Value']} {result.info['Unit']}")


def test_tag_normalizer():
    """Tester la normalisation des tags"""
    print("\n=== Test de la normalisation des tags ===")
    
    tags = [
        "Projet de vingt jours environ",
        "Project of about twenty days",
        "Tâche de 30 minutes",
        "Task of 30 minutes",
        "Réunion de 1 heure et 30 minutes",
        "Meeting of 1 hour and 30 minutes",
        "Environ 10 jours de travail",
        "About 10 days of work",
    ]
    
    normalizer = TagNormalizer()
    
    for tag in tags:
        print(f"Tag original: {tag}")
        result = normalizer.normalize_tag(tag)
        print(f"Tag normalisé: {result['normalized_tag']}")
        print("Métadonnées:")
        
        if result["metadata"]["approximate_expressions"]:
            print("  Expressions approximatives:")
            for expr in result["metadata"]["approximate_expressions"]:
                print(f"    - {expr['Expression']}: {expr['Info']['Value']} (±{expr['Info']['Precision'] * 100}%)")
        
        if result["metadata"]["textual_numbers"]:
            print("  Nombres écrits en toutes lettres:")
            for num in result["metadata"]["textual_numbers"]:
                print(f"    - {num['TextualNumber']}: {num['NumericValue']}")
        
        if result["metadata"]["time_units"]:
            print("  Unités de temps:")
            for unit in result["metadata"]["time_units"]:
                print(f"    - {unit['Expression']}: {unit['Info']['Value']} {unit['Info']['UnitType']}")
        
        print()


def main():
    """Fonction principale"""
    test_approximate_expressions()
    test_textual_numbers()
    test_time_units()
    test_tag_normalizer()


if __name__ == "__main__":
    main()
