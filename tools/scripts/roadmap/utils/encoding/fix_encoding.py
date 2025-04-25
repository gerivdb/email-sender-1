#!/usr/bin/env python3
"""
Script pour corriger les problèmes d'encodage dans un fichier Markdown.
"""

import sys
import os
import re

def fix_encoding(input_path, output_path=None):
    """
    Corrige les problèmes d'encodage des caractères accentués dans un fichier Markdown.
    
    Args:
        input_path (str): Chemin vers le fichier Markdown à corriger.
        output_path (str, optional): Chemin où le fichier corrigé sera enregistré.
            Si non spécifié, le fichier original sera remplacé.
    """
    if output_path is None:
        output_path = input_path
    
    try:
        # Lire le contenu du fichier
        with open(input_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Définir les remplacements
        replacements = {
            'Ã©': 'é',
            'Ã¨': 'è',
            'Ã ': 'à',
            'Ã¢': 'â',
            'Ãª': 'ê',
            'Ã«': 'ë',
            'Ã®': 'î',
            'Ã¯': 'ï',
            'Ã´': 'ô',
            'Ã¶': 'ö',
            'Ã¹': 'ù',
            'Ã»': 'û',
            'Ã¼': 'ü',
            'Ã§': 'ç',
            'Ã‰': 'É',
            'Ã€': 'À',
            'Ã‚': 'Â',
            'ÃŠ': 'Ê',
            'Ã‹': 'Ë',
            'ÃŽ': 'Î',
            'Ã': 'Ï',
            'Ã"': 'Ô',
            'Ã–': 'Ö',
            'Ã™': 'Ù',
            'Ã›': 'Û',
            'Ãœ': 'Ü',
            'Ã‡': 'Ç',
            'ComplexitÃ©': 'Complexité',
            'DÃ©pendances': 'Dépendances',
            'SÃ©curitÃ©': 'Sécurité',
            'Ã‰quipe': 'Équipe',
            'dÃ©veloppement': 'développement',
            'estimÃ©': 'estimé',
            'approuvÃ©s': 'approuvés',
            'donnÃ©es': 'données',
            'terminÃ©e': 'terminée'
        }
        
        # Appliquer les remplacements
        for old, new in replacements.items():
            content = content.replace(old, new)
        
        # Enregistrer le contenu corrigé
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Encodage corrigé avec succès: {output_path}")
        return True
    
    except Exception as e:
        print(f"Erreur lors de la correction de l'encodage: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_encoding.py <input_path> [output_path]")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = fix_encoding(input_path, output_path)
    sys.exit(0 if success else 1)
