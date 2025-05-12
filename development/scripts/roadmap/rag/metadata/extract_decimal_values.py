#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour extraire les valeurs d'estimation décimales dans un texte
Version: 1.0
Date: 2025-05-15
"""

import re
import sys
import json
import argparse


def extract_decimal_values(text):
    """
    Extrait les valeurs d'estimation décimales dans un texte
    
    Args:
        text (str): Le texte à analyser
        
    Returns:
        list: Liste des valeurs d'estimation trouvées
    """
    results = []
    
    # Définir les patterns pour trouver les valeurs numériques décimales suivies d'unités de temps
    patterns = [
        # Nombre avec virgule + unité (ex: 3,5 jours)
        r'(\d+,\d+)\s+(jours?)',
        # Nombre avec point + unité (ex: 3.5 jours)
        r'(\d+\.\d+)\s+(jours?)',
        # Nombre avec virgule + unité (ex: 5,5 heures)
        r'(\d+,\d+)\s+(heures?)',
        # Nombre avec point + unité (ex: 5.5 heures)
        r'(\d+\.\d+)\s+(heures?)',
        # Nombre avec virgule + unité (ex: 2,5 semaines)
        r'(\d+,\d+)\s+(semaines?)',
        # Nombre avec point + unité (ex: 2.5 semaines)
        r'(\d+\.\d+)\s+(semaines?)',
        # Nombre avec virgule + unité (ex: 1,5 mois)
        r'(\d+,\d+)\s+(mois)',
        # Nombre avec point + unité (ex: 1.5 mois)
        r'(\d+\.\d+)\s+(mois)',
        # Nombre avec virgule + unité (ex: 1,5 ans)
        r'(\d+,\d+)\s+(ans?|années?)',
        # Nombre avec point + unité (ex: 1.5 ans)
        r'(\d+\.\d+)\s+(ans?|années?)',
    ]
    
    # Définir les multiplicateurs pour convertir les unités en heures
    multipliers = {
        'heure': 1,
        'heures': 1,
        'jour': 8,
        'jours': 8,
        'semaine': 40,
        'semaines': 40,
        'mois': 160,
        'an': 1920,
        'ans': 1920,
        'année': 1920,
        'années': 1920,
    }
    
    # Parcourir chaque pattern
    for pattern in patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        
        for match in matches:
            value = match.group(1)
            unit = match.group(2).lower()
            
            # Convertir la valeur en nombre
            if ',' in value:
                value = value.replace(',', '.')
            
            numeric_value = float(value)
            
            # Déterminer l'unité de temps et le multiplicateur
            normalized_unit = unit
            multiplier = 1
            
            for unit_key, mult in multipliers.items():
                if unit.startswith(unit_key):
                    normalized_unit = unit_key
                    multiplier = mult
                    break
            
            # Calculer la valeur en heures
            hours_value = numeric_value * multiplier
            
            # Déterminer la catégorie d'estimation
            category = "precise"
            
            # Vérifier si l'expression est dans un contexte approximatif
            context_start = max(0, match.start() - 20)
            context_end = min(len(text), match.end() + 20)
            context = text[context_start:context_end]
            
            if re.search(r'(environ|approximativement|à peu près|autour de|aux alentours de|plus ou moins|±|~)', context, re.IGNORECASE):
                category = "approximate"
            elif re.search(r'(entre|de|à|-).+\d+.+\d+', context, re.IGNORECASE):
                category = "range"
            elif re.search(r'(au moins|minimum|min|au minimum)', context, re.IGNORECASE):
                category = "minimum"
            elif re.search(r'(au plus|maximum|max|au maximum)', context, re.IGNORECASE):
                category = "maximum"
            
            result = {
                'category': category,
                'value': numeric_value,
                'unit': normalized_unit,
                'hours_value': hours_value,
                'context': context
            }
            
            results.append(result)
    
    return results


def main():
    """
    Fonction principale
    """
    parser = argparse.ArgumentParser(description='Extraire les valeurs d\'estimation décimales dans un texte')
    parser.add_argument('--input', '-i', help='Fichier d\'entrée')
    parser.add_argument('--text', '-t', help='Texte à analyser')
    parser.add_argument('--output', '-o', help='Fichier de sortie')
    parser.add_argument('--format', '-f', choices=['text', 'json', 'csv'], default='text', help='Format de sortie')
    
    args = parser.parse_args()
    
    # Vérifier si un texte d'entrée ou un fichier d'entrée a été fourni
    if not args.text and not args.input:
        parser.error('Vous devez fournir soit un texte d\'entrée, soit un fichier d\'entrée')
    
    # Lire le texte d'entrée
    text = args.text
    
    if args.input:
        try:
            with open(args.input, 'r', encoding='utf-8') as f:
                text = f.read()
        except Exception as e:
            print(f'Erreur lors de la lecture du fichier d\'entrée: {e}', file=sys.stderr)
            sys.exit(1)
    
    # Extraire les valeurs d'estimation décimales
    results = extract_decimal_values(text)
    
    # Formater les résultats
    output = ''
    
    if args.format == 'text':
        output = f'Résultats de l\'analyse des valeurs d\'estimation décimales:\n'
        output += f'=====================================================\n'
        output += f'Nombre total de valeurs trouvées: {len(results)}\n\n'
        
        # Regrouper les résultats par catégorie
        results_by_category = {}
        
        for result in results:
            category = result['category']
            
            if category not in results_by_category:
                results_by_category[category] = []
            
            results_by_category[category].append(result)
        
        for category, category_results in results_by_category.items():
            output += f'Catégorie: {category} ({len(category_results)} valeurs)\n'
            output += '-' * 50 + '\n'
            
            for result in category_results:
                output += f'  Valeur: {result["value"]} {result["unit"]} (= {result["hours_value"]} heures)\n'
                output += f'  Contexte: {result["context"]}\n'
                output += '\n'
    
    elif args.format == 'json':
        output = json.dumps(results, indent=2, ensure_ascii=False)
    
    elif args.format == 'csv':
        output = 'category,value,unit,hours_value,context\n'
        
        for result in results:
            output += f'{result["category"]},{result["value"]},{result["unit"]},{result["hours_value"]},"{result["context"]}"\n'
    
    # Afficher ou enregistrer les résultats
    if args.output:
        try:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output)
        except Exception as e:
            print(f'Erreur lors de l\'écriture du fichier de sortie: {e}', file=sys.stderr)
            sys.exit(1)
    else:
        print(output)


if __name__ == '__main__':
    main()
