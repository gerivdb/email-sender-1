#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Script pour détecter les unités de temps dans les tags
Version: 1.0
Date: 2025-05-15
"""

import re
import json
from typing import Dict, List, Optional, Union, Any


# Dictionnaires des unités de temps en français et en anglais
french_time_units = {
    "seconde": "seconds",
    "secondes": "seconds",
    "minute": "minutes",
    "minutes": "minutes",
    "heure": "hours",
    "heures": "hours",
    "jour": "days",
    "jours": "days",
    "semaine": "weeks",
    "semaines": "weeks",
    "mois": "months",
    "année": "years",
    "années": "years",
    "an": "years",
    "ans": "years",
}

english_time_units = {
    "second": "seconds",
    "seconds": "seconds",
    "sec": "seconds",
    "secs": "seconds",
    "minute": "minutes",
    "minutes": "minutes",
    "min": "minutes",
    "mins": "minutes",
    "hour": "hours",
    "hours": "hours",
    "hr": "hours",
    "hrs": "hours",
    "day": "days",
    "days": "days",
    "week": "weeks",
    "weeks": "weeks",
    "month": "months",
    "months": "months",
    "year": "years",
    "years": "years",
    "yr": "years",
    "yrs": "years",
}


class TimeUnit:
    """Classe pour représenter une unité de temps"""

    def __init__(
        self,
        expression: str,
        start_index: int,
        length: int,
        value: float,
        unit: str,
        unit_type: str,
    ):
        self.expression = expression
        self.start_index = start_index
        self.length = length
        self.info = {
            "Value": value,
            "Unit": unit,
            "UnitType": unit_type,
            "NormalizedValue": self._normalize_value(value, unit),
            "NormalizedUnit": "seconds",
        }

    def _normalize_value(self, value: float, unit: str) -> float:
        """Normaliser la valeur en secondes"""
        unit_type = french_time_units.get(unit, english_time_units.get(unit, "unknown"))

        if unit_type == "seconds":
            return value
        elif unit_type == "minutes":
            return value * 60
        elif unit_type == "hours":
            return value * 3600
        elif unit_type == "days":
            return value * 86400
        elif unit_type == "weeks":
            return value * 604800
        elif unit_type == "months":
            return value * 2592000  # 30 jours
        elif unit_type == "years":
            return value * 31536000  # 365 jours
        else:
            return value

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


def get_time_units(text: str, language: str = "Auto") -> List[TimeUnit]:
    """
    Détecter les unités de temps dans un texte

    Args:
        text: Le texte à analyser
        language: La langue du texte ("Auto", "French", "English")

    Returns:
        Une liste d'objets TimeUnit
    """
    # Déterminer la langue si Auto est spécifié
    if language == "Auto":
        if re.search(r"seconde|minute|heure|jour|semaine|mois|année|an", text, re.IGNORECASE):
            language = "French"
        else:
            language = "English"

    # Résultats
    results = []

    # Expressions régulières pour le français
    if language == "French":
        # Nombre suivi d'une unité de temps
        pattern = r"(\d+)\s+(seconde|secondes|minute|minutes|heure|heures|jour|jours|semaine|semaines|mois|année|années|an|ans)"
        matches = re.finditer(pattern, text, re.IGNORECASE)

        for match in matches:
            value = float(match.group(1))
            unit = match.group(2).lower()
            unit_type = french_time_units.get(unit, "unknown")

            # Correction pour les unités de temps en français
            if unit == "seconde" or unit == "secondes":
                unit_type = "seconds"
            elif unit == "minute" or unit == "minutes":
                unit_type = "minutes"
            elif unit == "heure" or unit == "heures":
                unit_type = "hours"
            elif unit == "jour" or unit == "jours":
                unit_type = "days"
            elif unit == "semaine" or unit == "semaines":
                unit_type = "weeks"
            elif unit == "mois":
                unit_type = "months"
            elif unit == "année" or unit == "années" or unit == "an" or unit == "ans":
                unit_type = "years"

            results.append(
                TimeUnit(
                    expression=match.group(0),
                    start_index=match.start(),
                    length=len(match.group(0)),
                    value=value,
                    unit=unit,
                    unit_type=unit_type,
                )
            )

    # Expressions régulières pour l'anglais
    else:
        # Nombre suivi d'une unité de temps
        pattern = r"(\d+)\s+(second|seconds|sec|secs|minute|minutes|min|mins|hour|hours|hr|hrs|day|days|week|weeks|month|months|year|years|yr|yrs)"
        matches = re.finditer(pattern, text, re.IGNORECASE)

        for match in matches:
            value = float(match.group(1))
            unit = match.group(2).lower()
            unit_type = english_time_units.get(unit, "unknown")

            # Correction pour les unités de temps en anglais
            if unit == "second" or unit == "seconds" or unit == "sec" or unit == "secs":
                unit_type = "seconds"
            elif unit == "minute" or unit == "minutes" or unit == "min" or unit == "mins":
                unit_type = "minutes"
            elif unit == "hour" or unit == "hours" or unit == "hr" or unit == "hrs":
                unit_type = "hours"
            elif unit == "day" or unit == "days":
                unit_type = "days"
            elif unit == "week" or unit == "weeks":
                unit_type = "weeks"
            elif unit == "month" or unit == "months":
                unit_type = "months"
            elif unit == "year" or unit == "years" or unit == "yr" or unit == "yrs":
                unit_type = "years"

            results.append(
                TimeUnit(
                    expression=match.group(0),
                    start_index=match.start(),
                    length=len(match.group(0)),
                    value=value,
                    unit=unit,
                    unit_type=unit_type,
                )
            )

    return results


def main():
    """Fonction principale"""
    # Textes à tester
    text1 = "Le projet prendra 10 jours et 5 heures."
    text2 = "The project will take 10 days and 5 hours."
    text3 = "La tâche durera 30 minutes."
    text4 = "The task will last 30 minutes."

    # Tester la fonction
    print(f"Texte 1: {text1}")
    results1 = get_time_units(text1, "French")
    if results1:
        print(f"Résultats trouvés: {len(results1)}")
        for result in results1:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 2: {text2}")
    results2 = get_time_units(text2, "English")
    if results2:
        print(f"Résultats trouvés: {len(results2)}")
        for result in results2:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 3: {text3}")
    results3 = get_time_units(text3, "French")
    if results3:
        print(f"Résultats trouvés: {len(results3)}")
        for result in results3:
            print(result)
    else:
        print("Aucun résultat trouvé")

    print(f"\nTexte 4: {text4}")
    results4 = get_time_units(text4, "English")
    if results4:
        print(f"Résultats trouvés: {len(results4)}")
        for result in results4:
            print(result)
    else:
        print("Aucun résultat trouvé")


if __name__ == "__main__":
    main()
