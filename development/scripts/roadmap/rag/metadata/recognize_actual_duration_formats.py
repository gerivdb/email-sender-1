#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour reconnaître les formats de durée réelle dans un texte.
Ce script identifie et analyse différents formats d'expression de durée réelle.

Usage:
    python recognize_actual_duration_formats.py -t "Tâche: Développer la fonctionnalité X (a pris 4 heures)"
    python recognize_actual_duration_formats.py -i chemin/vers/fichier.txt
    python recognize_actual_duration_formats.py -t "Tâche: 2.5 jours réels" --format json

Options:
    -t, --text TEXT       Texte à analyser
    -i, --input FILE      Fichier d'entrée à analyser
    --format FORMAT       Format de sortie (text, json, csv)
    --debug               Activer le mode débogage
"""

import re
import sys
import json
import argparse
import csv
from io import StringIO
from datetime import datetime, timedelta

# Formats de durée réelle
ACTUAL_DURATION_FORMATS = {
    "simple": {
        "description": "Format simple (valeur + unité)",
        "examples": ["4 heures", "2.5 jours", "1 semaine"],
        "patterns": [
            r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.6
    },
    "qualified": {
        "description": "Format avec qualificatif (réel, effectif, etc.)",
        "examples": ["4 heures réelles", "2.5 jours effectifs", "1 semaine passée"],
        "patterns": [
            r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)\s+(?:réel(?:le)?s?|effecti(?:f|ve)s?|passée?s?|constatée?s?)',
            r'(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)\s+(?:reel(?:le)?s?|effecti(?:f|ve)s?|passe(?:e)?s?|constate(?:e)?s?)'
        ],
        "confidence": 0.7
    },
    "prefixed": {
        "description": "Format avec préfixe (durée réelle, temps passé, etc.)",
        "examples": ["durée réelle: 4 heures", "temps passé: 2.5 jours", "durée effective: 1 semaine"],
        "patterns": [
            r'(?:durée\s+réelle|temps\s+réel|durée\s+effective|temps\s+effectif|durée\s+passée|temps\s+passé|durée\s+constatée|temps\s+constaté)\s*(?::|=|\s+de)?\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',
            r'(?:duree\s+reelle|temps\s+reel|duree\s+effective|temps\s+effectif|duree\s+passee|temps\s+passe|duree\s+constatee|temps\s+constate)\s*(?::|=|\s+de)?\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.8
    },
    "verbal": {
        "description": "Format verbal (a pris, a duré, etc.)",
        "examples": ["a pris 4 heures", "a duré 2.5 jours", "a nécessité 1 semaine"],
        "patterns": [
            r'(?:a\s+pris|a\s+duré|a\s+nécessité|a\s+demandé|a\s+requis|réalisé\s+en|effectué\s+en|terminé\s+en|complété\s+en|achevé\s+en|fait\s+en)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',
            r'(?:a\s+pris|a\s+dure|a\s+necessite|a\s+demande|a\s+requis|realise\s+en|effectue\s+en|termine\s+en|complete\s+en|acheve\s+en|fait\s+en)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.75
    },
    "tagged": {
        "description": "Format avec tag (#actual, #real, etc.)",
        "examples": ["#actual:4h", "#real:2.5j", "#durée_réelle:1s"],
        "patterns": [
            r'#(?:actual|real|durée[-_]réelle|temps[-_]réel|durée[-_]effective|temps[-_]effectif|durée[-_]passée|temps[-_]passé)(?::|\s+)(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)?',
            r'#(?:actual|real|duree[-_]reelle|temps[-_]reel|duree[-_]effective|temps[-_]effectif|duree[-_]passee|temps[-_]passe)(?::|\s+)(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)?'
        ],
        "confidence": 0.85
    },
    "date_range": {
        "description": "Format avec plage de dates (du ... au ...)",
        "examples": ["du 2023-01-01 au 2023-01-15", "du 01/01/2023 au 15/01/2023"],
        "patterns": [
            r'du\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})\s+au\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})'
        ],
        "confidence": 0.9
    },
    "completion_date": {
        "description": "Format avec date de réalisation (réalisé le ...)",
        "examples": ["réalisé le 2023-01-15", "terminé le 15/01/2023"],
        "patterns": [
            r'(?:réalisé[e]?|terminé[e]?|complété[e]?|achevé[e]?|fini[e]?)\s+le\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})',
            r'(?:realise[e]?|termine[e]?|complete[e]?|acheve[e]?|fini[e]?)\s+le\s+(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4})'
        ],
        "confidence": 0.85
    },
    "range": {
        "description": "Format avec plage de durée (entre X et Y)",
        "examples": ["entre 4 et 6 heures", "de 2 à 3 jours"],
        "patterns": [
            r'(?:entre|de)\s+(\d+(?:[.,]\d+)?)\s+(?:et|à|a)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.7
    },
    "approximate": {
        "description": "Format approximatif (environ X, ~X, etc.)",
        "examples": ["environ 4 heures", "~2.5 jours", "approximativement 1 semaine"],
        "patterns": [
            r'(?:environ|approximativement|~|≈|≃|≅|≒|≓|≔|≕|≖|≗|≘|≙|≚|≛|≜|≝|≞|≟|≠|≡|≢|≣|≤|≥|≦|≧|≨|≩|≪|≫|≬|≭|≮|≯|≰|≱|≲|≳|≴|≵|≶|≷|≸|≹|≺|≻|≼|≽|≾|≿|⊀|⊁|⊂|⊃|⊄|⊅|⊆|⊇|⊈|⊉|⊊|⊋|⊌|⊍|⊎|⊏|⊐|⊑|⊒|⊓|⊔|⊕|⊖|⊗|⊘|⊙|⊚|⊛|⊜|⊝|⊞|⊟|⊠|⊡|⊢|⊣|⊤|⊥|⊦|⊧|⊨|⊩|⊪|⊫|⊬|⊭|⊮|⊯|⊰|⊱|⊲|⊳|⊴|⊵|⊶|⊷|⊸|⊹|⊺|⊻|⊼|⊽|⊾|⊿|⋀|⋁|⋂|⋃|⋄|⋅|⋆|⋇|⋈|⋉|⋊|⋋|⋌|⋍|⋎|⋏|⋐|⋑|⋒|⋓|⋔|⋕|⋖|⋗|⋘|⋙|⋚|⋛|⋜|⋝|⋞|⋟|⋠|⋡|⋢|⋣|⋤|⋥|⋦|⋧|⋨|⋩|⋪|⋫|⋬|⋭|⋮|⋯|⋰|⋱|⋲|⋳|⋴|⋵|⋶|⋷|⋸|⋹|⋺|⋻|⋼|⋽|⋾|⋿)\s*(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.65
    },
    "precise": {
        "description": "Format précis (exactement X, précisément X, etc.)",
        "examples": ["exactement 4 heures", "précisément 2.5 jours", "exactement 1 semaine"],
        "patterns": [
            r'(?:exactement|précisément|exact|précis)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)',
            r'(?:exactement|precisement|exact|precis)\s+(\d+(?:[.,]\d+)?)\s*(h(?:eure)?s?|j(?:our)?s?|d(?:ay)?s?|w(?:eek)?s?|s(?:emaine)?s?|mo(?:is|nth)?s?|min(?:ute)?s?)'
        ],
        "confidence": 0.9
    }
}

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

def convert_to_hours(value, unit):
    """Convertit une durée en heures."""
    if unit == "Minutes":
        return value / 60.0
    elif unit == "Hours":
        return value
    elif unit == "Days":
        return value * 24.0
    elif unit == "Weeks":
        return value * 24.0 * 7.0
    elif unit == "Months":
        return value * 24.0 * 30.0  # Approximation
    else:
        return value  # Par défaut, on suppose que c'est déjà en heures

def calculate_date_range_duration(start_date_str, end_date_str):
    """Calcule la durée entre deux dates."""
    # Convertir les chaînes de date en objets datetime
    try:
        # Essayer le format YYYY-MM-DD
        if "-" in start_date_str:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
        else:
            # Essayer le format DD/MM/YYYY
            start_date = datetime.strptime(start_date_str, "%d/%m/%Y")
        
        if "-" in end_date_str:
            end_date = datetime.strptime(end_date_str, "%Y-%m-%d")
        else:
            end_date = datetime.strptime(end_date_str, "%d/%m/%Y")
        
        # Calculer la différence en jours
        delta = end_date - start_date
        days = delta.days + delta.seconds / 86400.0
        
        return days * 24.0  # Convertir en heures
    except Exception as e:
        return None  # En cas d'erreur, retourner None

def recognize_actual_duration_formats(text):
    """Reconnaît les formats de durée réelle dans un texte."""
    recognized_formats = []
    
    # Parcourir tous les formats définis
    for format_name, format_info in ACTUAL_DURATION_FORMATS.items():
        # Parcourir tous les patterns du format
        for pattern in format_info["patterns"]:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            
            for match in matches:
                # Extraire le contexte (30 caractères avant et après)
                start = max(0, match.start() - 30)
                end = min(len(text), match.end() + 30)
                context = text[start:end]
                
                # Créer un dictionnaire pour stocker les informations sur le format reconnu
                recognized_format = {
                    "format": format_name,
                    "description": format_info["description"],
                    "original_text": match.group(0),
                    "context": context,
                    "confidence": format_info["confidence"]
                }
                
                # Traiter les différents formats
                if format_name == "date_range":
                    # Format avec plage de dates
                    start_date = match.group(1)
                    end_date = match.group(2)
                    
                    recognized_format["start_date"] = start_date
                    recognized_format["end_date"] = end_date
                    
                    # Calculer la durée en heures
                    duration_hours = calculate_date_range_duration(start_date, end_date)
                    if duration_hours is not None:
                        recognized_format["duration_hours"] = duration_hours
                elif format_name == "completion_date":
                    # Format avec date de réalisation
                    completion_date = match.group(1)
                    recognized_format["completion_date"] = completion_date
                elif format_name == "range":
                    # Format avec plage de durée
                    min_value = float(match.group(1).replace(',', '.'))
                    max_value = float(match.group(2).replace(',', '.'))
                    unit = match.group(3)
                    
                    normalized_unit = normalize_unit(unit)
                    
                    recognized_format["min_value"] = min_value
                    recognized_format["max_value"] = max_value
                    recognized_format["unit"] = normalized_unit
                    
                    # Calculer la durée moyenne en heures
                    min_hours = convert_to_hours(min_value, normalized_unit)
                    max_hours = convert_to_hours(max_value, normalized_unit)
                    recognized_format["min_hours"] = min_hours
                    recognized_format["max_hours"] = max_hours
                    recognized_format["avg_hours"] = (min_hours + max_hours) / 2.0
                else:
                    # Formats avec valeur et unité
                    if len(match.groups()) >= 2:
                        value_str = match.group(1)
                        unit = match.group(2) if len(match.groups()) >= 2 else None
                        
                        # Convertir la valeur en nombre
                        value = float(value_str.replace(',', '.'))
                        
                        # Normaliser l'unité
                        normalized_unit = normalize_unit(unit)
                        
                        recognized_format["value"] = value
                        recognized_format["unit"] = normalized_unit
                        
                        # Convertir en heures
                        hours = convert_to_hours(value, normalized_unit)
                        recognized_format["hours"] = hours
                
                recognized_formats.append(recognized_format)
    
    return recognized_formats

def analyze_text_for_actual_duration_formats(text):
    """Analyse un texte pour reconnaître les formats de durée réelle."""
    # Reconnaître les formats de durée réelle
    recognized_formats = recognize_actual_duration_formats(text)
    
    # Calculer des statistiques
    format_counts = {}
    for format_name in ACTUAL_DURATION_FORMATS.keys():
        format_counts[format_name] = len([f for f in recognized_formats if f["format"] == format_name])
    
    stats = {
        "total_formats": len(recognized_formats),
        "format_counts": format_counts,
        "average_confidence": sum(f["confidence"] for f in recognized_formats) / len(recognized_formats) if recognized_formats else 0
    }
    
    return {
        "recognized_formats": recognized_formats,
        "stats": stats
    }

def format_output(analysis_result, format_type):
    """Formate les résultats selon le format spécifié."""
    if format_type == "json":
        # Convertir les valeurs non sérialisables en chaînes de caractères
        serializable_result = {
            "recognized_formats": [],
            "stats": analysis_result["stats"]
        }
        
        for format_info in analysis_result["recognized_formats"]:
            serializable_format = {}
            for key, value in format_info.items():
                if isinstance(value, (int, float, str, bool, type(None))):
                    serializable_format[key] = value
                else:
                    serializable_format[key] = str(value)
            serializable_result["recognized_formats"].append(serializable_format)
        
        return json.dumps(serializable_result, ensure_ascii=False, indent=2)
    elif format_type == "csv":
        if not analysis_result["recognized_formats"]:
            return "Aucun format de durée réelle reconnu."
        
        output = StringIO()
        writer = csv.writer(output)
        
        # Écrire l'en-tête
        writer.writerow(["Format", "Description", "Original Text", "Context", "Confidence", "Value", "Unit", "Hours"])
        
        # Écrire les données
        for format_info in analysis_result["recognized_formats"]:
            row = [
                format_info["format"],
                format_info["description"],
                format_info["original_text"],
                format_info["context"],
                format_info["confidence"],
                format_info.get("value", ""),
                format_info.get("unit", ""),
                format_info.get("hours", format_info.get("avg_hours", ""))
            ]
            writer.writerow(row)
        
        return output.getvalue()
    else:  # text
        if not analysis_result["recognized_formats"]:
            return "Aucun format de durée réelle reconnu."
        
        output = []
        output.append(f"Formats de durée réelle reconnus: {analysis_result['stats']['total_formats']}")
        
        for format_name, count in analysis_result["stats"]["format_counts"].items():
            if count > 0:
                output.append(f"- Format {format_name}: {count}")
        
        output.append(f"- Confiance moyenne: {analysis_result['stats']['average_confidence']:.2f}")
        output.append("")
        
        for i, format_info in enumerate(analysis_result["recognized_formats"], 1):
            output.append(f"Format {i}:")
            output.append(f"  Type: {format_info['format']}")
            output.append(f"  Description: {format_info['description']}")
            output.append(f"  Texte original: {format_info['original_text']}")
            output.append(f"  Contexte: {format_info['context']}")
            output.append(f"  Confiance: {format_info['confidence']:.2f}")
            
            if "value" in format_info:
                output.append(f"  Valeur: {format_info['value']} {format_info['unit']}")
                output.append(f"  Heures: {format_info['hours']:.2f}")
            elif "min_value" in format_info:
                output.append(f"  Plage: {format_info['min_value']} - {format_info['max_value']} {format_info['unit']}")
                output.append(f"  Heures (min): {format_info['min_hours']:.2f}")
                output.append(f"  Heures (max): {format_info['max_hours']:.2f}")
                output.append(f"  Heures (moyenne): {format_info['avg_hours']:.2f}")
            elif "start_date" in format_info:
                output.append(f"  Période: du {format_info['start_date']} au {format_info['end_date']}")
                if "duration_hours" in format_info:
                    output.append(f"  Heures: {format_info['duration_hours']:.2f}")
            elif "completion_date" in format_info:
                output.append(f"  Date de réalisation: {format_info['completion_date']}")
            
            output.append("")
        
        return "\n".join(output)

def main():
    # Configurer l'encodage de sortie pour gérer les caractères Unicode
    import io
    import sys
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    
    parser = argparse.ArgumentParser(description="Reconnaître les formats de durée réelle dans un texte.")
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
        for format_name, format_info in ACTUAL_DURATION_FORMATS.items():
            print(f"Format {format_name}: {format_info['description']}")
            for i, pattern in enumerate(format_info["patterns"]):
                print(f"  Pattern {i}: {pattern}")
                matches = list(re.finditer(pattern, text, re.IGNORECASE))
                print(f"    Nombre de correspondances: {len(matches)}")
                for match in matches:
                    print(f"    Match: '{match.group(0)}'")
                    for j, group in enumerate(match.groups()):
                        if group:
                            print(f"      Groupe {j+1}: '{group}'")
    
    # Analyser le texte
    analysis_result = analyze_text_for_actual_duration_formats(text)
    
    # Formater et afficher les résultats
    output = format_output(analysis_result, args.format)
    print(output)

if __name__ == "__main__":
    main()
