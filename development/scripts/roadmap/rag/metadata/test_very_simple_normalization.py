#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester la normalisation des tags avec un tag simple
Version: 1.0
Date: 2025-05-15
"""

from tag_normalizer import TagNormalizer


def main():
    """Fonction principale"""
    # Normaliser le tag
    normalizer = TagNormalizer()
    
    tag = "Projet de vingt jours environ"
    
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
            print(f"    - {unit['Expression']}: {unit['Info']['Value']} {unit['Info']['Unit']}")


if __name__ == "__main__":
    main()
