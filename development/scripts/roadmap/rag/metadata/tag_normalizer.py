#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour normaliser les formats de tags
Version: 1.0
Date: 2025-05-15
"""

import re
import json
from typing import Dict, List, Optional, Union, Any

from approximate_expressions import get_approximate_expressions, ApproximateExpression
from textual_numbers import get_textual_numbers, TextualNumber
from time_units import get_time_units, TimeUnit


class TagNormalizer:
    """Classe pour normaliser les formats de tags"""

    def __init__(self, language: str = "Auto"):
        self.language = language

    def normalize_tag(self, tag: str) -> Dict[str, Any]:
        """
        Normaliser un tag

        Args:
            tag: Le tag à normaliser

        Returns:
            Un dictionnaire contenant les informations normalisées
        """
        # Résultat
        result = {
            "original_tag": tag,
            "normalized_tag": tag,
            "metadata": {
                "approximate_expressions": [],
                "textual_numbers": [],
                "time_units": [],
            },
        }

        # Détecter les expressions approximatives
        approximate_expressions = get_approximate_expressions(tag, self.language)
        if approximate_expressions:
            result["metadata"]["approximate_expressions"] = [expr.to_dict() for expr in approximate_expressions]

        # Détecter les nombres écrits en toutes lettres
        textual_numbers = get_textual_numbers(tag, self.language)
        if textual_numbers:
            result["metadata"]["textual_numbers"] = [num.to_dict() for num in textual_numbers]

        # Détecter les unités de temps
        time_units = get_time_units(tag, self.language)
        if time_units:
            result["metadata"]["time_units"] = [unit.to_dict() for unit in time_units]

        # Normaliser le tag
        normalized_tag = tag

        # Remplacer les nombres écrits en toutes lettres par des chiffres
        for num in sorted(textual_numbers, key=lambda x: x.start_index, reverse=True):
            normalized_tag = normalized_tag[:num.start_index] + str(num.numeric_value) + normalized_tag[num.start_index + num.length:]

        # Normaliser les unités de temps
        for unit in sorted(time_units, key=lambda x: x.start_index, reverse=True):
            value = unit.info["Value"]
            unit_type = unit.info["Unit"]  # Utiliser Unit au lieu de UnitType

            # Format: "value unit_type"
            normalized_value = int(value) if value == int(value) else value

            normalized_unit = f"{normalized_value} {unit_type}"

            normalized_tag = normalized_tag[:unit.start_index] + normalized_unit + normalized_tag[unit.start_index + unit.length:]

        # Normaliser les expressions approximatives
        for expr in sorted(approximate_expressions, key=lambda x: x.start_index, reverse=True):
            value = expr.info["Value"]
            precision = expr.info["Precision"]

            # Format: "value (±precision%)"
            precision_percentage = int(precision * 100)
            normalized_value = int(value) if value == int(value) else value
            normalized_expr = f"{normalized_value} (±{precision_percentage}%)"

            normalized_tag = normalized_tag[:expr.start_index] + normalized_expr + normalized_tag[expr.start_index + expr.length:]

        result["normalized_tag"] = normalized_tag

        return result


def main():
    """Fonction principale"""
    # Tags à tester
    tags = [
        "Projet de vingt jours environ",
        "Project of about twenty days",
        "Tâche de 30 minutes",
        "Task of 30 minutes",
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


if __name__ == "__main__":
    main()
