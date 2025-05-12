#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour extraire les estimations de durée à partir d'un texte.
Ce script détecte les expressions d'estimation de temps et les convertit en format standard.

Usage:
    python extract_estimations.py -t "Tâche: Développer la fonctionnalité X (environ 4 heures)"
    python extract_estimations.py -i chemin/vers/fichier.txt
    python extract_estimations.py -t "Tâche: 2.5 jours" --format json

Options:
    -t, --text TEXT       Texte à analyser
    -i, --input FILE      Fichier d'entrée à analyser
    --format FORMAT       Format de sortie (text, json, csv)
"""

import re
import sys
import json
import argparse
import csv
from io import StringIO

# Patterns pour détecter les estimations
ESTIMATION_PATTERNS = [
    # Pattern pour "environ X heures/jours/semaines/mois"
    r'(?:environ|approximativement|~|≈|env\.|approx\.|estimation\s*:|durée\s*:|temps\s*:|délai\s*:)\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?|m(?:in)?)',

    # Pattern pour "X heures/jours/semaines/mois"
    r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?|m(?:in)?)',

    # Pattern pour les plages "X-Y heures/jours/semaines/mois"
    r'(\d+(?:[.,]\d+)?)\s*(?:-|à|to)\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?|m(?:in)?)',

    # Pattern pour "X heures/jours/semaines/mois +/- Y"
    r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?|m(?:in)?)\s*(?:\+/-|±)\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?|m(?:in)?)?',

    # Pattern pour les durées composées "XhYmin"
    r'(\d+)h(?:eures?)?(?:\s*et\s*|\s*)?(\d+)(?:min(?:utes?)?)?',

    # Pattern spécifique pour les minutes
    r'(\d+(?:[.,]\d+)?)\s*minutes?'
]

# Facteurs de conversion vers des heures
CONVERSION_FACTORS = {
    "min": 1/60,
    "minute": 1/60,
    "minutes": 1/60,
    "h": 1,
    "heure": 1,
    "heures": 1,
    "hour": 1,
    "hours": 1,
    "j": 8,
    "jour": 8,
    "jours": 8,
    "d": 8,
    "day": 8,
    "days": 8,
    "s": 40,
    "semaine": 40,
    "semaines": 40,
    "w": 40,
    "week": 40,
    "weeks": 40,
    "m": 160,
    "mois": 160,
    "month": 160,
    "months": 160
}

def normalize_unit(unit):
    """Normalise l'unité de temps."""
    unit = unit.lower()

    if unit in ["min", "m", "minute", "minutes"]:
        return "Minutes"
    elif unit in ["h", "heure", "heures", "hour", "hours"]:
        return "Hours"
    elif unit in ["j", "jour", "jours", "d", "day", "days"]:
        return "Days"
    elif unit in ["s", "sem", "semaine", "semaines", "w", "week", "weeks"]:
        return "Weeks"
    elif unit in ["mo", "mois", "month", "months"]:
        return "Months"
    else:
        # Analyse contextuelle pour déterminer l'unité
        if unit.startswith("m") and len(unit) <= 3:
            # Si c'est juste "m" ou "mi", c'est probablement des minutes
            return "Minutes"
        elif unit.startswith("h") and len(unit) <= 3:
            # Si c'est juste "h", c'est probablement des heures
            return "Hours"
        elif unit.startswith("j") or unit.startswith("d") and len(unit) <= 3:
            # Si c'est juste "j" ou "d", c'est probablement des jours
            return "Days"
        elif unit.startswith("s") or unit.startswith("w") and len(unit) <= 3:
            # Si c'est juste "s" ou "w", c'est probablement des semaines
            return "Weeks"
        elif unit.startswith("mo") and len(unit) <= 4:
            # Si c'est "mo", c'est probablement des mois
            return "Months"
        else:
            return "Hours"  # Unité par défaut

def extract_estimations(text):
    """Extrait les estimations de durée à partir d'un texte."""
    estimations = []

    for pattern in ESTIMATION_PATTERNS:
        matches = re.finditer(pattern, text, re.IGNORECASE)

        for match in matches:
            estimation = {}

            # Extraire le contexte (20 caractères avant et après)
            start = max(0, match.start() - 20)
            end = min(len(text), match.end() + 20)
            context = text[start:end]

            # Extraire la valeur et l'unité selon le type de pattern
            if len(match.groups()) == 2:  # Simple estimation
                value_str = match.group(1)
                unit = match.group(2)

                # Convertir la valeur en nombre
                value = float(value_str.replace(',', '.'))

                estimation = {
                    "type": "simple",
                    "value": value,
                    "unit": normalize_unit(unit),
                    "original_text": match.group(0),
                    "context": context
                }
            elif len(match.groups()) == 3:
                if "-" in match.group(0) or "à" in match.group(0) or "to" in match.group(0):  # Plage
                    min_value_str = match.group(1)
                    max_value_str = match.group(2)
                    unit = match.group(3)

                    # Convertir les valeurs en nombres
                    min_value = float(min_value_str.replace(',', '.'))
                    max_value = float(max_value_str.replace(',', '.'))

                    # Calculer la valeur moyenne
                    value = (min_value + max_value) / 2

                    estimation = {
                        "type": "range",
                        "value": value,
                        "min_value": min_value,
                        "max_value": max_value,
                        "unit": normalize_unit(unit),
                        "original_text": match.group(0),
                        "context": context
                    }
                elif "+/-" in match.group(0) or "±" in match.group(0):  # Marge d'erreur
                    value_str = match.group(1)
                    unit = match.group(2)
                    margin_str = match.group(3)
                    margin_unit = match.group(4) if len(match.groups()) > 3 else unit

                    # Convertir les valeurs en nombres
                    value = float(value_str.replace(',', '.'))
                    margin = float(margin_str.replace(',', '.'))

                    # Si l'unité de la marge est différente, convertir
                    if margin_unit and margin_unit != unit:
                        margin_factor = CONVERSION_FACTORS.get(margin_unit.lower(), 1)
                        unit_factor = CONVERSION_FACTORS.get(unit.lower(), 1)
                        margin = margin * margin_factor / unit_factor

                    estimation = {
                        "type": "margin",
                        "value": value,
                        "margin": margin,
                        "min_value": value - margin,
                        "max_value": value + margin,
                        "unit": normalize_unit(unit),
                        "original_text": match.group(0),
                        "context": context
                    }
                else:  # Durée composée (XhYmin)
                    hours_str = match.group(1)
                    minutes_str = match.group(2)

                    # Convertir les valeurs en nombres
                    hours = float(hours_str)
                    minutes = float(minutes_str) / 60

                    value = hours + minutes

                    estimation = {
                        "type": "composite",
                        "value": value,
                        "hours": hours,
                        "minutes": minutes,
                        "unit": "Hours",
                        "original_text": match.group(0),
                        "context": context
                    }

            if estimation:
                # Convertir en heures pour la normalisation
                unit_factor = CONVERSION_FACTORS.get(estimation["unit"].lower(), 1)
                estimation["value_in_hours"] = estimation["value"] * unit_factor

                estimations.append(estimation)

    return estimations

def format_output(estimations, format_type):
    """Formate les estimations selon le format spécifié."""
    if format_type == "json":
        return json.dumps(estimations, ensure_ascii=False, indent=2)
    elif format_type == "csv":
        if not estimations:
            return ""

        output = StringIO()
        writer = csv.DictWriter(output, fieldnames=estimations[0].keys())
        writer.writeheader()
        writer.writerows(estimations)
        return output.getvalue()
    else:  # text
        if not estimations:
            return "Aucune estimation trouvée."

        output = []
        for i, est in enumerate(estimations, 1):
            output.append(f"Estimation {i}:")
            for key, value in est.items():
                output.append(f"  {key}: {value}")
            output.append("")

        return "\n".join(output)

def main():
    parser = argparse.ArgumentParser(description="Extraire les estimations de durée à partir d'un texte.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-t", "--text", help="Texte à analyser")
    group.add_argument("-i", "--input", help="Fichier d'entrée à analyser")
    parser.add_argument("--format", choices=["text", "json", "csv"], default="text", help="Format de sortie")

    args = parser.parse_args()

    # Obtenir le texte à analyser
    if args.text:
        text = args.text
    else:
        try:
            with open(args.input, 'r', encoding='utf-8') as f:
                text = f.read()
        except Exception as e:
            print(f"Erreur lors de la lecture du fichier: {e}", file=sys.stderr)
            sys.exit(1)

    # Extraire les estimations
    estimations = extract_estimations(text)

    # Formater et afficher les résultats
    output = format_output(estimations, args.format)
    print(output)

if __name__ == "__main__":
    main()
