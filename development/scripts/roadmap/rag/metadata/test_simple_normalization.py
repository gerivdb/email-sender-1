#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester la normalisation des tags avec des données simples
Version: 1.0
Date: 2025-05-15
"""

from tag_normalizer import TagNormalizer


# Données simples
simple_tags = [
    "Projet de vingt jours environ",
    "Project of about twenty days",
    "Tâche de 30 minutes",
    "Task of 30 minutes",
]


def main():
    """Fonction principale"""
    # Normaliser les tags
    normalizer = TagNormalizer()
    
    print("=== Normalisation des tags avec des données simples ===")
    
    for tag in simple_tags:
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
        
        print()


if __name__ == "__main__":
    main()
