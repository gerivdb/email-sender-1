#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour normaliser les estimations de durée.
Ce script convertit les estimations de temps en un format standard.

Usage:
    python normalize_estimations.py -t "4 heures" -u "Hours"
    python normalize_estimations.py -i chemin/vers/fichier.txt -u "Days"
    python normalize_estimations.py -t "2.5 jours" -u "Hours" --format json

Options:
    -t, --text TEXT       Texte à analyser
    -i, --input FILE      Fichier d'entrée à analyser
    -u, --unit UNIT       Unité cible (Hours, Days, Weeks, Months)
    --format FORMAT       Format de sortie (text, json, csv)
"""

import re
import sys
import json
import argparse
import csv
from io import StringIO

# Facteurs de conversion vers des heures
CONVERSION_FACTORS = {
    "Minutes": 1/60,
    "Hours": 1,
    "Days": 8,       # 1 jour = 8 heures
    "Weeks": 40,     # 1 semaine = 40 heures (5 jours * 8 heures)
    "Months": 160    # 1 mois = 160 heures (4 semaines * 40 heures)
}

def normalize_unit(unit):
    """Normalise l'unité de temps."""
    unit = unit.lower()
    
    if unit in ["min", "minute", "minutes", "m"]:
        return "Minutes"
    elif unit in ["h", "heure", "heures", "hour", "hours"]:
        return "Hours"
    elif unit in ["j", "jour", "jours", "d", "day", "days"]:
        return "Days"
    elif unit in ["s", "semaine", "semaines", "w", "week", "weeks"]:
        return "Weeks"
    elif unit in ["mo", "mois", "month", "months"]:
        return "Months"
    else:
        return "Hours"  # Unité par défaut

def convert_to_standard(value, source_unit, target_unit):
    """Convertit une valeur d'une unité à une autre."""
    # Normaliser les unités
    source_unit = normalize_unit(source_unit)
    target_unit = normalize_unit(target_unit)
    
    # Convertir en heures d'abord
    value_in_hours = value * CONVERSION_FACTORS[source_unit]
    
    # Puis convertir de heures vers l'unité cible
    standard_value = value_in_hours / CONVERSION_FACTORS[target_unit]
    
    # Arrondir à 2 décimales
    standard_value = round(standard_value, 2)
    
    return {
        "original_value": value,
        "original_unit": source_unit,
        "standard_value": standard_value,
        "standard_unit": target_unit,
        "value_in_hours": value_in_hours
    }

def extract_simple_estimations(text):
    """Extrait les estimations simples de durée à partir d'un texte."""
    estimations = []
    
    # Pattern pour "X heures/jours/semaines/mois"
    pattern = r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
    
    matches = re.finditer(pattern, text, re.IGNORECASE)
    
    for match in matches:
        value_str = match.group(1)
        unit = match.group(2)
        
        # Convertir la valeur en nombre
        value = float(value_str.replace(',', '.'))
        
        # Extraire le contexte (20 caractères avant et après)
        start = max(0, match.start() - 20)
        end = min(len(text), match.end() + 20)
        context = text[start:end]
        
        estimation = {
            "value": value,
            "unit": normalize_unit(unit),
            "original_text": match.group(0),
            "context": context
        }
        
        estimations.append(estimation)
    
    return estimations

def normalize_estimations(estimations, target_unit):
    """Normalise les estimations selon l'unité cible."""
    normalized = []
    
    for est in estimations:
        norm = convert_to_standard(est["value"], est["unit"], target_unit)
        
        # Ajouter les informations originales
        norm["original_text"] = est["original_text"]
        norm["context"] = est["context"]
        
        normalized.append(norm)
    
    return normalized

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
    parser = argparse.ArgumentParser(description="Normaliser les estimations de durée.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-t", "--text", help="Texte à analyser")
    group.add_argument("-i", "--input", help="Fichier d'entrée à analyser")
    parser.add_argument("-u", "--unit", choices=["Minutes", "Hours", "Days", "Weeks", "Months"], default="Hours", help="Unité cible")
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
    estimations = extract_simple_estimations(text)
    
    # Normaliser les estimations
    normalized = normalize_estimations(estimations, args.unit)
    
    # Formater et afficher les résultats
    output = format_output(normalized, args.format)
    print(output)

if __name__ == "__main__":
    main()
