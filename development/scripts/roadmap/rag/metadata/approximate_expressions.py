#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour analyser les expressions numériques approximatives
Version: 1.0
Date: 2025-05-15
"""

import re
import json
from typing import Dict, List, Optional, Union, Any


class ApproximateExpression:
    """Classe pour représenter une expression numérique approximative"""

    def __init__(
        self,
        expression: str,
        start_index: int,
        length: int,
        value: float,
        marker: str,
        precision: float,
        expression_type: str = "MarkerNumber",
        precision_type: str = "Percentage",
    ):
        self.expression = expression
        self.start_index = start_index
        self.length = length
        self.info = {
            "Type": expression_type,
            "Value": value,
            "Marker": marker,
            "Precision": precision,
            "LowerBound": value * (1 - precision),
            "UpperBound": value * (1 + precision),
            "PrecisionType": precision_type,
        }

    def to_dict(self) -> Dict[str, Any]:
        """Convertir l'objet en dictionnaire"""
        return {
            "Expression": self.expression,
            "StartIndex": self.start_index,
            "Length": self.length,
            "Info": self.info,
        }

    def __str__(self) -> str:
        """Représentation sous forme de chaîne"""
        return json.dumps(self.to_dict(), indent=2)


def get_approximate_expressions(text: str, language: str = "Auto") -> List[ApproximateExpression]:
    """
    Analyser les expressions numériques approximatives dans un texte

    Args:
        text: Le texte à analyser
        language: La langue du texte ("Auto", "French", "English")

    Returns:
        Une liste d'objets ApproximateExpression
    """
    # Déterminer la langue si Auto est spécifié
    if language == "Auto":
        if re.search(r"environ|approximativement|presque|autour de", text):
            language = "French"
        else:
            language = "English"

    # Résultats
    results = []

    # Expressions régulières pour le français
    if language == "French":
        # Marqueur suivi d'un nombre
        pattern1 = r"(environ|approximativement|presque|autour de)\s+(\d+)"
        matches1 = re.search(pattern1, text)

        if matches1:
            marker = matches1.group(1)
            value = float(matches1.group(2))
            precision = 0.1  # 10% par défaut

            results.append(
                ApproximateExpression(
                    expression=matches1.group(0),
                    start_index=matches1.start(),
                    length=len(matches1.group(0)),
                    value=value,
                    marker=marker,
                    precision=precision,
                    expression_type="MarkerNumber",
                )
            )

        # Nombre suivi d'un marqueur
        pattern3 = r"(\d+)\s+jours\s+(environ|approximativement|presque|à peu près)"
        matches3 = re.search(pattern3, text)

        if matches3:
            value = float(matches3.group(1))
            marker = matches3.group(2)
            precision = 0.1  # 10% par défaut

            results.append(
                ApproximateExpression(
                    expression=matches3.group(0),
                    start_index=matches3.start(),
                    length=len(matches3.group(0)),
                    value=value,
                    marker=marker,
                    precision=precision,
                    expression_type="NumberMarker",
                )
            )

    # Expressions régulières pour l'anglais
    else:
        # Marqueur suivi d'un nombre
        pattern2 = r"(about|approximately|around|nearly|almost)\s+(\d+)"
        matches2 = re.search(pattern2, text)

        if matches2:
            marker = matches2.group(1)
            value = float(matches2.group(2))

            # Déterminer la précision en fonction du marqueur
            precision = 0.1  # 10% par défaut
            if marker == "approximately":
                precision = 0.05  # 5%
            elif marker == "nearly" or marker == "almost":
                precision = 0.02  # 2%

            results.append(
                ApproximateExpression(
                    expression=matches2.group(0),
                    start_index=matches2.start(),
                    length=len(matches2.group(0)),
                    value=value,
                    marker=marker,
                    precision=precision,
                    expression_type="MarkerNumber",
                )
            )

        # Nombre suivi d'un marqueur
        pattern4 = r"(\d+)\s+days\s+(approximately|or so|roughly|about)"
        matches4 = re.search(pattern4, text)

        if matches4:
            value = float(matches4.group(1))
            marker = matches4.group(2)
            precision = 0.05  # 5% par défaut

            results.append(
                ApproximateExpression(
                    expression=matches4.group(0),
                    start_index=matches4.start(),
                    length=len(matches4.group(0)),
                    value=value,
                    marker=marker,
                    precision=precision,
                    expression_type="NumberMarker",
                )
            )

    return results


def main():
    """Fonction principale"""
    # Textes à tester
    text1 = "Le projet prendra environ 10 jours."
    text2 = "The project will take about 10 days."
    text3 = "Le projet nécessitera 20 jours environ."
    text4 = "The project will require 30 days approximately."

    # Tester les expressions régulières
    print(f"Texte 1: {text1}")
    results1 = get_approximate_expressions(text1, "French")
    if results1:
        print(f"Résultats trouvés: {len(results1)}")
        for result in results1:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 2: {text2}")
    results2 = get_approximate_expressions(text2, "English")
    if results2:
        print(f"Résultats trouvés: {len(results2)}")
        for result in results2:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 3: {text3}")
    results3 = get_approximate_expressions(text3, "French")
    if results3:
        print(f"Résultats trouvés: {len(results3)}")
        for result in results3:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 4: {text4}")
    results4 = get_approximate_expressions(text4, "English")
    if results4:
        print(f"Résultats trouvés: {len(results4)}")
        for result in results4:
            print(result)
    else:
        print("Aucun résultat trouvé")


if __name__ == "__main__":
    main()
