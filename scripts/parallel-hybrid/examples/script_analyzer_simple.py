#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import argparse
import re
import multiprocessing

def analyze_powershell_script(file_path):
    """Analyse un script PowerShell."""
    try:
        # Lire le contenu du fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Compter les lignes
        lines = content.splitlines()
        total_lines = len(lines)
        non_empty_lines = len([line for line in lines if line.strip()])
        comment_lines = len([line for line in lines if line.strip().startswith('#')])
        code_lines = non_empty_lines - comment_lines

        # Extraire les fonctions
        function_pattern = r'function\s+([A-Za-z0-9_-]+)'
        functions = re.findall(function_pattern, content, re.IGNORECASE)

        # Extraire les cmdlets
        cmdlet_pattern = r'([A-Za-z0-9]+-[A-Za-z0-9]+)'
        cmdlets = re.findall(cmdlet_pattern, content)

        # Calculer la complexité approximative
        if_count = len(re.findall(r'\bif\b', content, re.IGNORECASE))
        for_count = len(re.findall(r'\bfor\b', content, re.IGNORECASE))
        foreach_count = len(re.findall(r'\bforeach\b', content, re.IGNORECASE))
        while_count = len(re.findall(r'\bwhile\b', content, re.IGNORECASE))
        switch_count = len(re.findall(r'\bswitch\b', content, re.IGNORECASE))
        complexity = 1 + if_count + for_count + foreach_count + while_count + switch_count

        # Résultat de l'analyse
        return {
            "file_path": file_path,
            "file_name": os.path.basename(file_path),
            "file_size": os.path.getsize(file_path),
            "total_lines": total_lines,
            "code_lines": code_lines,
            "comment_lines": comment_lines,
            "functions": functions,
            "functions_count": len(functions),
            "cmdlets_count": len(set(cmdlets)),
            "complexity": complexity
        }

    except Exception as e:
        return {
            "file_path": file_path,
            "error": str(e)
        }

def analyze_scripts_batch(batch):
    """Analyse un lot de scripts PowerShell en parallèle."""
    # Utiliser tous les cœurs disponibles
    num_processes = min(multiprocessing.cpu_count(), len(batch))

    # Créer un pool de processus
    with multiprocessing.Pool(processes=num_processes) as pool:
        # Exécuter l'analyse en parallèle
        results = pool.map(analyze_powershell_script, batch)

    return results

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Analyse de scripts PowerShell')
    parser.add_argument('--input', required=True, help='Fichier JSON contenant la liste des fichiers à analyser')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--cache', help='Chemin vers le répertoire de cache (ignoré)')

    args = parser.parse_args()

    # Charger la liste des fichiers à analyser
    try:
        with open(args.input, 'r', encoding='utf-8-sig') as f:
            file_paths = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrée : {e}", file=sys.stderr)
        sys.exit(1)

    # Analyser les scripts
    try:
        results = analyze_scripts_batch(file_paths)
    except Exception as e:
        print(f"Erreur lors de l'analyse des scripts : {e}", file=sys.stderr)
        sys.exit(1)

    # Écrire les résultats
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"Erreur lors de l'écriture du fichier de sortie : {e}", file=sys.stderr)
        sys.exit(1)

    sys.exit(0)

if __name__ == '__main__':
    main()
