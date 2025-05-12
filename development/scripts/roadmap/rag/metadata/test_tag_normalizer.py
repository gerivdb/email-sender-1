#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour tester la normalisation des tags
Version: 1.0
Date: 2025-05-15
"""

import json
from tag_normalizer import TagNormalizer

# Tags à tester
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

# Normaliser les tags
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
