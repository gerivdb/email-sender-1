#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester la normalisation des tags avec des données réelles
Version: 1.0
Date: 2025-05-15
"""

import json
from tag_normalizer import TagNormalizer


# Données réelles
real_tags = [
    "Projet de développement web de vingt jours environ",
    "Réunion de planification de 1 heure et 30 minutes",
    "Tâche de documentation de 3 jours",
    "Environ 5 jours de tests et débogage",
    "Déploiement en production de 2 heures environ",
    "Maintenance mensuelle de 4 heures",
    "Formation des utilisateurs de 2 jours",
    "Revue de code de 3 heures",
    "Intégration continue de 1 jour",
    "Mise à jour des dépendances de 2 heures",
]


def main():
    """Fonction principale"""
    # Normaliser les tags
    normalizer = TagNormalizer()
    
    print("=== Normalisation des tags avec des données réelles ===")
    
    for tag in real_tags:
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
    
    for tag in real_tags:
        result = normalizer.normalize_tag(tag)
        results.append(result)
    
    with open("normalized_tags.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    print(f"Résultats exportés dans le fichier normalized_tags.json")


if __name__ == "__main__":
    main()
