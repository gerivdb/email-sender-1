#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse

def process_data(data):
    """Traite les donnÃ©es de test."""
    if isinstance(data, (int, float)):
        return data * 2
    elif isinstance(data, str):
        return data.upper()
    elif isinstance(data, list):
        return [process_data(item) for item in data]
    elif isinstance(data, dict):
        return {k: process_data(v) for k, v in data.items()}
    else:
        return data

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Traitement de donnÃ©es de test')
    parser.add_argument('--input', required=True, help='Fichier d\'entrÃ©e JSON')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le rÃ©pertoire du cache')
    
    args = parser.parse_args()
    
    # Charger les donnÃ©es d'entrÃ©e
    try:
        with open(args.input, 'r', encoding='utf-8') as f:
            input_data = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrÃ©e : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Traiter les donnÃ©es
    try:
        results = process_data(input_data)
    except Exception as e:
        print(f"Erreur lors du traitement des donnÃ©es : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Ã‰crire les rÃ©sultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'Ã©criture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
