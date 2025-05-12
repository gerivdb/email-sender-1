#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour analyser les expressions de durée effective/réelle dans un texte.
Ce script détecte les expressions qui indiquent une durée réelle (par opposition à une estimation).

Usage:
    python analyze_actual_duration_expressions.py -t "Tâche: Développer la fonctionnalité X (a pris 4 heures)"
    python analyze_actual_duration_expressions.py -i chemin/vers/fichier.txt
    python analyze_actual_duration_expressions.py -t "Tâche: 2.5 jours réels" --format json

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

# Patterns pour détecter les expressions de durée effective
ACTUAL_DURATION_PATTERNS = [
    # Pattern pour "a pris X heures/jours/semaines/mois" (avec et sans accents, avec variations de genre)
    r'(?:a\s+pris|a\s+dure|a\s+duré|a\s+necessite|a\s+nécessité|a\s+demande|a\s+demandé|a\s+requis|realise[e]?\s+en|réalisé[e]?\s+en|effectue[e]?\s+en|effectué[e]?\s+en|termine[e]?\s+en|terminé[e]?\s+en|complete[e]?\s+en|complété[e]?\s+en|acheve[e]?\s+en|achevé[e]?\s+en|fait[e]?\s+en)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',

    # Pattern pour "durée réelle: X heures/jours/semaines/mois" (avec et sans accents)
    r'(?:duree\s+reelle|durée\s+réelle|temps\s+reel|temps\s+réel|duree\s+effective|durée\s+effective|temps\s+effectif|duree\s+passee|durée\s+passée|temps\s+passe|temps\s+passé|duree\s+constatee|durée\s+constatée|temps\s+constate|temps\s+constaté)\s*(?::|=|\s+de)?\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',

    # Pattern pour "X heures/jours/semaines/mois réel(le)s" (avec et sans accents)
    r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)\s+(?:reel(?:le)?s?|réel(?:le)?s?|effecti(?:f|ve)s?|passe(?:e)?s?|passée?s?|constate(?:e)?s?|constatée?s?)',

    # Pattern pour "temps passé: X heures/jours/semaines/mois" (avec et sans accents)
    r'(?:temps\s+passe|temps\s+passé|temps\s+consacre|temps\s+consacré|temps\s+investi|effort\s+reel|effort\s+réel|effort\s+passe|effort\s+passé)\s*(?::|=|\s+de)?\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',

    # Pattern pour les tags spécifiques comme #actual:X ou #real:X (avec et sans accents)
    r'#(?:actual|real|duree[-_]reelle|durée[-_]réelle|temps[-_]reel|temps[-_]réel|duree[-_]effective|durée[-_]effective|temps[-_]effectif|duree[-_]passee|durée[-_]passée|temps[-_]passe|temps[-_]passé)(?::|\s+)(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)?',

    # Pattern pour "réalisé le YYYY-MM-DD" (pour calculer la durée par différence de dates) (avec et sans accents, avec variations de genre)
    r'(?:realise[e]?|réalisé[e]?|termine[e]?|terminé[e]?|complete[e]?|complété[e]?|acheve[e]?|achevé[e]?|fini[e]?)\s+le\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})',

    # Pattern pour "du YYYY-MM-DD au YYYY-MM-DD" (pour calculer la durée par différence de dates)
    r'du\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})\s+au\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})'
]

# Indicateurs de durée réelle (mots-clés qui suggèrent qu'on parle de durée réelle)
ACTUAL_DURATION_INDICATORS = [
    # Avec accents
    "réel", "réelle", "réels", "réelles",
    "effectif", "effective", "effectifs", "effectives",
    "passé", "passée", "passés", "passées",
    "constaté", "constatée", "constatés", "constatées",
    "mesuré", "mesurée", "mesurés", "mesurées",
    "chronométré", "chronométrée", "chronométrés", "chronométrées",
    "a pris", "a duré", "a nécessité", "a demandé", "a requis",
    "réalisé en", "effectué en", "terminé en", "complété en", "achevé en", "fait en",
    "temps passé", "temps consacré", "temps investi", "effort réel", "effort passé",
    "durée réelle", "temps réel", "durée effective", "temps effectif", "durée passée", "temps passé",
    "durée constatée", "temps constaté",

    # Sans accents
    "reel", "reelle", "reels", "reelles",
    "effectif", "effective", "effectifs", "effectives",
    "passe", "passee", "passes", "passees",
    "constate", "constatee", "constates", "constatees",
    "mesure", "mesuree", "mesures", "mesurees",
    "chronometre", "chronometree", "chronometres", "chronometrees",
    "a pris", "a dure", "a necessite", "a demande", "a requis",
    "realise en", "effectue en", "termine en", "complete en", "acheve en", "fait en",
    "temps passe", "temps consacre", "temps investi", "effort reel", "effort passe",
    "duree reelle", "temps reel", "duree effective", "temps effectif", "duree passee", "temps passe",
    "duree constatee", "temps constate",

    # Tags
    "#actual", "#real",
    "#durée_réelle", "#temps_réel", "#durée_effective", "#temps_effectif", "#durée_passée", "#temps_passé",
    "#duree_reelle", "#temps_reel", "#duree_effective", "#temps_effectif", "#duree_passee", "#temps_passe"
]

def normalize_unit(unit):
    """Normalise l'unité de temps."""
    if not unit:
        return "Hours"  # Unité par défaut

    unit = unit.lower()

    if unit in ["min", "minute", "minutes", "m"]:
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

def extract_actual_durations(text):
    """Extrait les expressions de durée effective à partir d'un texte."""
    actual_durations = []

    # Rechercher les patterns d'expressions de durée effective
    for pattern in ACTUAL_DURATION_PATTERNS:
        matches = re.finditer(pattern, text, re.IGNORECASE)

        for match in matches:
            # Extraire le contexte (30 caractères avant et après)
            start = max(0, match.start() - 30)
            end = min(len(text), match.end() + 30)
            context = text[start:end]

            # Déterminer le type d'expression
            if "réalisé le" in match.group(0).lower() or "terminé le" in match.group(0).lower() or "complété le" in match.group(0).lower() or "achevé le" in match.group(0).lower() or "fini le" in match.group(0).lower():
                # Expression de type date de réalisation
                actual_duration = {
                    "type": "completion_date",
                    "date": match.group(1),
                    "original_text": match.group(0),
                    "context": context,
                    "confidence": 0.9  # Confiance élevée car date explicite
                }
            elif "du" in match.group(0).lower() and "au" in match.group(0).lower():
                # Expression de type période (du ... au ...)
                actual_duration = {
                    "type": "date_range",
                    "start_date": match.group(1),
                    "end_date": match.group(2),
                    "original_text": match.group(0),
                    "context": context,
                    "confidence": 0.95  # Confiance très élevée car période explicite
                }
            else:
                # Expression de type durée
                if len(match.groups()) >= 2:
                    value_str = match.group(1)
                    unit = match.group(2) if len(match.groups()) >= 2 else None

                    # Convertir la valeur en nombre
                    value = float(value_str.replace(',', '.'))

                    # Normaliser l'unité
                    normalized_unit = normalize_unit(unit)

                    # Déterminer le niveau de confiance
                    confidence = 0.8  # Confiance par défaut

                    # Ajuster la confiance en fonction des indicateurs présents
                    for indicator in ACTUAL_DURATION_INDICATORS:
                        if indicator.lower() in match.group(0).lower():
                            confidence = min(0.95, confidence + 0.05)  # Augmenter la confiance, max 0.95
                            break

                    actual_duration = {
                        "type": "duration",
                        "value": value,
                        "unit": normalized_unit,
                        "original_text": match.group(0),
                        "context": context,
                        "confidence": confidence
                    }
                else:
                    # Cas où le pattern ne capture pas correctement les groupes
                    continue

            actual_durations.append(actual_duration)

    return actual_durations

def analyze_text_for_actual_durations(text):
    """Analyse un texte pour détecter les expressions de durée effective."""
    # Extraire les expressions de durée effective
    actual_durations = extract_actual_durations(text)

    # Calculer des statistiques
    stats = {
        "total_expressions": len(actual_durations),
        "duration_expressions": len([d for d in actual_durations if d["type"] == "duration"]),
        "completion_date_expressions": len([d for d in actual_durations if d["type"] == "completion_date"]),
        "date_range_expressions": len([d for d in actual_durations if d["type"] == "date_range"]),
        "average_confidence": sum(d["confidence"] for d in actual_durations) / len(actual_durations) if actual_durations else 0
    }

    return {
        "actual_durations": actual_durations,
        "stats": stats
    }

def format_output(analysis_result, format_type):
    """Formate les résultats selon le format spécifié."""
    if format_type == "json":
        # Convertir les valeurs non sérialisables en chaînes de caractères
        serializable_result = {
            "actual_durations": [],
            "stats": analysis_result["stats"]
        }

        for duration in analysis_result["actual_durations"]:
            serializable_duration = {}
            for key, value in duration.items():
                if isinstance(value, (int, float, str, bool, type(None))):
                    serializable_duration[key] = value
                else:
                    serializable_duration[key] = str(value)
            serializable_result["actual_durations"].append(serializable_duration)

        return json.dumps(serializable_result, ensure_ascii=False, indent=2)
    elif format_type == "csv":
        if not analysis_result["actual_durations"]:
            return "Aucune expression de durée effective trouvée."

        output = StringIO()
        writer = csv.writer(output)

        # Écrire l'en-tête
        writer.writerow(["Type", "Value", "Unit", "Start Date", "End Date", "Original Text", "Context", "Confidence"])

        # Écrire les données
        for duration in analysis_result["actual_durations"]:
            row = [
                duration["type"],
                duration.get("value", ""),
                duration.get("unit", ""),
                duration.get("start_date", ""),
                duration.get("end_date", ""),
                duration["original_text"],
                duration["context"],
                duration["confidence"]
            ]
            writer.writerow(row)

        return output.getvalue()
    else:  # text
        if not analysis_result["actual_durations"]:
            return "Aucune expression de durée effective trouvée."

        output = []
        output.append(f"Expressions de durée effective trouvées: {analysis_result['stats']['total_expressions']}")
        output.append(f"- Expressions de durée: {analysis_result['stats']['duration_expressions']}")
        output.append(f"- Expressions de date de réalisation: {analysis_result['stats']['completion_date_expressions']}")
        output.append(f"- Expressions de période: {analysis_result['stats']['date_range_expressions']}")
        output.append(f"- Confiance moyenne: {analysis_result['stats']['average_confidence']:.2f}")
        output.append("")

        for i, duration in enumerate(analysis_result["actual_durations"], 1):
            output.append(f"Expression {i}:")
            output.append(f"  Type: {duration['type']}")

            if duration["type"] == "duration":
                output.append(f"  Valeur: {duration['value']} {duration['unit']}")
            elif duration["type"] == "completion_date":
                output.append(f"  Date de réalisation: {duration['date']}")
            elif duration["type"] == "date_range":
                output.append(f"  Période: du {duration['start_date']} au {duration['end_date']}")

            output.append(f"  Texte original: {duration['original_text']}")
            output.append(f"  Contexte: {duration['context']}")
            output.append(f"  Confiance: {duration['confidence']:.2f}")
            output.append("")

        return "\n".join(output)

def main():
    parser = argparse.ArgumentParser(description="Analyser les expressions de durée effective dans un texte.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-t", "--text", help="Texte à analyser")
    group.add_argument("-i", "--input", help="Fichier d'entrée à analyser")
    parser.add_argument("--format", choices=["text", "json", "csv"], default="text", help="Format de sortie")
    parser.add_argument("--debug", action="store_true", help="Activer le mode débogage")

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

    # Mode débogage
    if args.debug:
        print(f"Texte à analyser: '{text}'")
        for i, pattern in enumerate(ACTUAL_DURATION_PATTERNS):
            print(f"Pattern {i}: {pattern}")
            matches = list(re.finditer(pattern, text, re.IGNORECASE))
            print(f"  Nombre de correspondances: {len(matches)}")
            for match in matches:
                print(f"  Match: '{match.group(0)}'")
                for j, group in enumerate(match.groups()):
                    print(f"    Groupe {j+1}: '{group}'")

    # Analyser le texte
    analysis_result = analyze_text_for_actual_durations(text)

    # Formater et afficher les résultats
    output = format_output(analysis_result, args.format)
    print(output)

if __name__ == "__main__":
    main()
