#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester la normalisation des tags avec des données en anglais
Version: 1.0
Date: 2025-05-15
"""

import json
from tag_normalizer import TagNormalizer


# Données en anglais
english_tags = [
    "Web development project of about twenty days",
    "Planning meeting of 1 hour and 30 minutes",
    "Documentation task of 3 days",
    "About 5 days of testing and debugging",
    "Production deployment of approximately 2 hours",
    "Monthly maintenance of 4 hours",
    "User training of 2 days",
    "Code review of 3 hours",
    "Continuous integration of 1 day",
    "Dependencies update of 2 hours",
]


def main():
    """Fonction principale"""
    # Normaliser les tags
    normalizer = TagNormalizer()
    
    print("=== Normalisation des tags avec des données en anglais ===")
    
    for tag in english_tags:
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
    
    # Exporter les résultats au format JSON
    results = []
    
    for tag in english_tags:
        result = normalizer.normalize_tag(tag)
        results.append(result)
    
    with open("normalized_english_tags.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"Résultats exportés dans le fichier normalized_english_tags.json")


if __name__ == "__main__":
    main()
