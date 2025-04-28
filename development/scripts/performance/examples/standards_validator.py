#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import re
import argparse
import multiprocessing

def validate_script(file_path, standards):
    """Valide un script PowerShell selon les standards définis."""
    try:
        # Lire le contenu du fichier
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Initialiser les résultats
        violations = []
        
        # Valider les standards de nommage
        if "naming" in standards:
            # Valider les noms de fonctions
            if "functions" in standards["naming"]:
                function_pattern = r'function\s+([A-Za-z0-9_-]+)'
                functions = re.findall(function_pattern, content, re.IGNORECASE)
                
                for function in functions:
                    if not re.match(standards["naming"]["functions"]["pattern"], function):
                        violations.append({
                            "type": "naming.functions",
                            "description": standards["naming"]["functions"]["description"],
                            "severity": standards["naming"]["functions"]["severity"],
                            "item": function,
                            "line": find_line_number(content, f"function {function}")
                        })
            
            # Valider les noms de variables
            if "variables" in standards["naming"]:
                variable_pattern = r'\$([A-Za-z0-9_]+)\s*='
                variables = re.findall(variable_pattern, content)
                
                for variable in variables:
                    if not re.match(standards["naming"]["variables"]["pattern"], variable):
                        violations.append({
                            "type": "naming.variables",
                            "description": standards["naming"]["variables"]["description"],
                            "severity": standards["naming"]["variables"]["severity"],
                            "item": variable,
                            "line": find_line_number(content, f"${variable}")
                        })
            
            # Valider les noms de paramètres
            if "parameters" in standards["naming"]:
                param_pattern = r'param\s*\(\s*\[\s*([^]]+)\s*\]\s*\$([A-Za-z0-9_]+)'
                params = re.findall(param_pattern, content, re.IGNORECASE | re.DOTALL)
                
                for _, param in params:
                    if not re.match(standards["naming"]["parameters"]["pattern"], param):
                        violations.append({
                            "type": "naming.parameters",
                            "description": standards["naming"]["parameters"]["description"],
                            "severity": standards["naming"]["parameters"]["severity"],
                            "item": param,
                            "line": find_line_number(content, f"${param}")
                        })
        
        # Valider la structure
        if "structure" in standards:
            # Valider la présence de #Requires
            if "requires" in standards["structure"]:
                if not re.search(standards["structure"]["requires"]["pattern"], content):
                    violations.append({
                        "type": "structure.requires",
                        "description": standards["structure"]["requires"]["description"],
                        "severity": standards["structure"]["requires"]["severity"],
                        "item": "#Requires",
                        "line": 1
                    })
            
            # Valider la présence d'un bloc d'aide
            if "help" in standards["structure"]:
                if not re.search(standards["structure"]["help"]["pattern"], content, re.DOTALL):
                    violations.append({
                        "type": "structure.help",
                        "description": standards["structure"]["help"]["description"],
                        "severity": standards["structure"]["help"]["severity"],
                        "item": "Help block",
                        "line": 1
                    })
            
            # Valider l'encodage (note: ceci est une vérification simplifiée)
            if "encoding" in standards["structure"]:
                # Cette vérification est approximative et devrait être améliorée
                if standards["structure"]["encoding"]["pattern"] == "utf8":
                    try:
                        content.encode('utf-8')
                    except UnicodeEncodeError:
                        violations.append({
                            "type": "structure.encoding",
                            "description": standards["structure"]["encoding"]["description"],
                            "severity": standards["structure"]["encoding"]["severity"],
                            "item": "File encoding",
                            "line": 1
                        })
        
        # Valider les bonnes pratiques
        if "practices" in standards:
            # Valider la gestion des erreurs
            if "errorHandling" in standards["practices"]:
                if not re.search(standards["practices"]["errorHandling"]["pattern"], content, re.DOTALL):
                    violations.append({
                        "type": "practices.errorHandling",
                        "description": standards["practices"]["errorHandling"]["description"],
                        "severity": standards["practices"]["errorHandling"]["severity"],
                        "item": "Error handling",
                        "line": 1
                    })
            
            # Valider les verbes approuvés
            if "approvedVerbs" in standards["practices"]:
                function_pattern = r'function\s+([A-Za-z0-9]+-[A-Za-z0-9_]+)'
                functions = re.findall(function_pattern, content, re.IGNORECASE)
                
                for function in functions:
                    verb = function.split('-')[0]
                    if not re.match(standards["practices"]["approvedVerbs"]["pattern"], function):
                        violations.append({
                            "type": "practices.approvedVerbs",
                            "description": standards["practices"]["approvedVerbs"]["description"],
                            "severity": standards["practices"]["approvedVerbs"]["severity"],
                            "item": verb,
                            "line": find_line_number(content, f"function {function}")
                        })
            
            # Valider le ratio de commentaires
            if "commentRatio" in standards["practices"]:
                lines = content.splitlines()
                total_lines = len(lines)
                comment_lines = len([line for line in lines if line.strip().startswith('#')])
                
                if total_lines > 0:
                    ratio = comment_lines / total_lines
                    if ratio < standards["practices"]["commentRatio"]["value"]:
                        violations.append({
                            "type": "practices.commentRatio",
                            "description": standards["practices"]["commentRatio"]["description"],
                            "severity": standards["practices"]["commentRatio"]["severity"],
                            "item": f"Comment ratio: {ratio:.2f}",
                            "line": 1
                        })
        
        # Calculer le résultat final
        is_compliant = len(violations) == 0
        
        # Compter les erreurs et avertissements
        errors = len([v for v in violations if v["severity"] == "Error"])
        warnings = len([v for v in violations if v["severity"] == "Warning"])
        
        return {
            "file_info": {
                "file_path": file_path,
                "file_name": os.path.basename(file_path),
                "file_size": os.path.getsize(file_path)
            },
            "is_compliant": is_compliant,
            "total_violations": len(violations),
            "errors": errors,
            "warnings": warnings,
            "violations": violations
        }
    
    except Exception as e:
        return {
            "file_info": {
                "file_path": file_path,
                "file_name": os.path.basename(file_path),
                "file_size": os.path.getsize(file_path) if os.path.exists(file_path) else 0
            },
            "is_compliant": False,
            "total_violations": 1,
            "errors": 1,
            "warnings": 0,
            "violations": [{
                "type": "error.processing",
                "description": f"Erreur lors du traitement du fichier: {str(e)}",
                "severity": "Error",
                "item": "File processing",
                "line": 1
            }]
        }

def find_line_number(content, search_string):
    """Trouve le numéro de ligne d'une chaîne dans le contenu."""
    lines = content.splitlines()
    for i, line in enumerate(lines):
        if search_string in line:
            return i + 1
    return 1

def validate_scripts_batch(batch, standards):
    """Valide un lot de scripts PowerShell en parallèle."""
    # Utiliser tous les cœurs disponibles
    num_processes = min(multiprocessing.cpu_count(), len(batch))
    
    # Créer un pool de processus
    with multiprocessing.Pool(processes=num_processes) as pool:
        # Exécuter la validation en parallèle
        results = pool.starmap(validate_script, [(file_path, standards) for file_path in batch])
    
    return results

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description='Validation de standards PowerShell')
    parser.add_argument('--input', required=True, help='Fichier JSON contenant la liste des fichiers à valider')
    parser.add_argument('--output', required=True, help='Fichier de sortie JSON')
    parser.add_argument('--standards', required=True, help='Fichier JSON contenant les standards à valider')
    parser.add_argument('--cache', help='Chemin vers le répertoire de cache (ignoré)')
    
    args = parser.parse_args()
    
    # Charger la liste des fichiers à valider
    try:
        with open(args.input, 'r', encoding='utf-8-sig') as f:
            file_paths = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier d'entrée : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Charger les standards
    try:
        with open(args.standards, 'r', encoding='utf-8-sig') as f:
            standards = json.load(f)
    except Exception as e:
        print(f"Erreur lors de la lecture des standards : {e}", file=sys.stderr)
        sys.exit(1)
    
    # Valider les scripts
    try:
        results = validate_scripts_batch(file_paths, standards)
    except Exception as e:
        print(f"Erreur lors de la validation des scripts : {e}", file=sys.stderr)
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
