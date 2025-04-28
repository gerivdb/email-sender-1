#!/usr/bin/env python3
"""
Script simple pour corriger les problèmes d'encodage dans un fichier Markdown.
"""

import sys
import os
import codecs

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
        # Lire le contenu du fichier avec l'encodage latin-1
        with open(input_path, 'r', encoding='latin-1') as f:
            content = f.read()
        
        # Enregistrer le contenu avec l'encodage UTF-8
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Encodage corrigé avec succès: {output_path}")
        return True
    
    except Exception as e:
        print(f"Erreur lors de la correction de l'encodage: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_encoding_simple.py <input_path> [output_path]")
        sys.exit(1)
    
    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    success = fix_encoding(input_path, output_path)
    sys.exit(0 if success else 1)
