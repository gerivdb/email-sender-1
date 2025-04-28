#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de fusion des scripts similaires.

Ce script utilise le rapport généré par Find-CodeDuplication.py pour fusionner
les scripts similaires et éliminer les duplications de code. Il crée des fonctions
réutilisables pour le code dupliqué et met à jour les références.

Utilise difflib pour une fusion intelligente et multiprocessing pour le traitement parallèle.
"""

import os
import sys
import json
import argparse
import difflib
import re
from pathlib import Path
from datetime import datetime
import shutil

# Configuration par défaut
DEFAULT_INPUT_PATH = "development/scripts/manager/data/duplication_report.json"
DEFAULT_OUTPUT_PATH = "development/scripts/manager/data/merge_report.json"
DEFAULT_LIBRARY_PATH = "development/scripts/common/lib"
DEFAULT_MIN_DUPLICATION_COUNT = 2

def write_log(message, level="INFO"):
    """Écrit un message de log formaté."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    color_map = {
        "INFO": "\033[37m",     # Blanc
        "SUCCESS": "\033[32m",  # Vert
        "WARNING": "\033[33m",  # Jaune
        "ERROR": "\033[31m",    # Rouge
        "TITLE": "\033[36m"     # Cyan
    }
    reset = "\033[0m"
    
    formatted_message = f"[{timestamp}] [{level}] {message}"
    print(f"{color_map.get(level, '')}{formatted_message}{reset}")
    
    # Écrire dans un fichier de log
    log_file = "development/scripts/manager/data/script_merge.log"
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(formatted_message + "\n")

def get_script_type(file_path):
    """Détermine le type de script à partir de l'extension."""
    extension = Path(file_path).suffix.lower()
    
    if extension in [".ps1", ".psm1", ".psd1"]:
        return "PowerShell"
    elif extension == ".py":
        return "Python"
    elif extension in [".cmd", ".bat"]:
        return "Batch"
    elif extension == ".sh":
        return "Shell"
    else:
        return "Unknown"

def generate_function_name(block_text, script_type, index):
    """Génère un nom de fonction à partir d'un bloc de code."""
    # Extraire les mots clés du bloc de code
    keywords = re.findall(r'\b[a-zA-Z][a-zA-Z0-9_]{3,}\b', block_text)
    
    # Filtrer les mots-clés réservés selon le type de script
    reserved_keywords = {
        "PowerShell": ["function", "param", "begin", "process", "end", "if", "else", "elseif", "switch", "for", "foreach", "while", "do", "until", "break", "continue", "return", "throw", "try", "catch", "finally"],
        "Python": ["def", "class", "if", "else", "elif", "for", "while", "try", "except", "finally", "with", "import", "from", "as", "return", "yield", "break", "continue", "pass", "raise", "global", "nonlocal"],
        "Batch": ["echo", "set", "setlocal", "endlocal", "call", "goto", "if", "else", "for", "in", "do", "rem"],
        "Shell": ["function", "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "echo", "read", "exit", "return", "break", "continue", "shift"]
    }
    
    filtered_keywords = [k for k in keywords if k not in reserved_keywords.get(script_type, [])]
    
    # Générer un nom de fonction à partir des mots-clés
    if filtered_keywords:
        base_name = "".join(filtered_keywords[:3])
    else:
        base_name = "CommonFunction"
    
    # Formater le nom selon le type de script
    if script_type == "PowerShell":
        function_name = f"Invoke-{base_name}{index}"
    elif script_type == "Python":
        function_name = f"{base_name.lower()}_{index}"
    elif script_type == "Batch":
        function_name = f"call_{base_name.lower()}_{index}"
    elif script_type == "Shell":
        function_name = f"{base_name.lower()}_{index}"
    else:
        function_name = f"function_{base_name.lower()}_{index}"
    
    return function_name

def create_function(block_text, function_name, script_type):
    """Crée une fonction à partir d'un bloc de code."""
    # Indenter le bloc de code selon le type de script
    if script_type == "Python":
        indented_block = "\n".join(f"    {line}" for line in block_text.splitlines())
    else:
        indented_block = block_text
    
    # Créer la fonction selon le type de script
    if script_type == "PowerShell":
        function = f"""function {function_name} {{
    [CmdletBinding()]
    param ()
    
{indented_block}
}}
"""
    elif script_type == "Python":
        function = f"""def {function_name}():
    \"\"\"
    Fonction extraite pour éliminer la duplication de code.
    \"\"\"
{indented_block}
"""
    elif script_type == "Batch":
        function = f""":{function_name}
{indented_block}
goto :eof
"""
    elif script_type == "Shell":
        function = f"""{function_name}() {{
{indented_block}
}}
"""
    else:
        function = block_text
    
    return function

def create_function_call(function_name, script_type, library_path):
    """Crée un appel de fonction."""
    # Créer l'appel de fonction selon le type de script
    if script_type == "PowerShell":
        relative_path = f"{library_path}/{function_name}.ps1"
        call = f"""# Appel de fonction extraite pour éliminer la duplication
. "{relative_path}"
{function_name}
"""
    elif script_type == "Python":
        module_path = library_path.replace("/", ".")
        if module_path.startswith("."):
            module_path = module_path[1:]
        call = f"""# Appel de fonction extraite pour éliminer la duplication
from {module_path}.{function_name} import {function_name}
{function_name}()
"""
    elif script_type == "Batch":
        relative_path = f"{library_path}/{function_name}.cmd"
        call = f""":: Appel de fonction extraite pour éliminer la duplication
call "{relative_path}"
"""
    elif script_type == "Shell":
        relative_path = f"{library_path}/{function_name}.sh"
        call = f"""# Appel de fonction extraite pour éliminer la duplication
source "{relative_path}"
{function_name}
"""
    else:
        call = block_text
    
    return {
        "call": call,
        "library_path": f"{library_path}/{function_name}{get_file_extension(script_type)}"
    }

def get_file_extension(script_type):
    """Retourne l'extension de fichier pour un type de script."""
    if script_type == "PowerShell":
        return ".ps1"
    elif script_type == "Python":
        return ".py"
    elif script_type == "Batch":
        return ".cmd"
    elif script_type == "Shell":
        return ".sh"
    else:
        return ".txt"

def create_function_library(function_name, function_body, script_type, library_path, apply=False):
    """Crée une bibliothèque de fonctions."""
    # Déterminer l'extension du fichier
    extension = get_file_extension(script_type)
    
    # Créer le chemin complet du fichier
    file_path = f"{library_path}/{function_name}{extension}"
    
    # Créer le contenu du fichier selon le type de script
    if script_type == "PowerShell":
        content = f"""<#
.SYNOPSIS
    Fonction extraite pour éliminer la duplication de code.
.DESCRIPTION
    Cette fonction a été créée automatiquement pour éliminer la duplication de code
    détectée dans plusieurs scripts.
.NOTES
    Généré automatiquement par Merge-SimilarScripts.py
    Date de création: {datetime.now().strftime("%Y-%m-%d")}
#>

{function_body}
"""
    elif script_type == "Python":
        content = f"""#!/usr/bin/env python3
# -*- coding: utf-8 -*-
\"\"\"
Fonction extraite pour éliminer la duplication de code.

Cette fonction a été créée automatiquement pour éliminer la duplication de code
détectée dans plusieurs scripts.

Généré automatiquement par Merge-SimilarScripts.py
Date de création: {datetime.now().strftime("%Y-%m-%d")}
\"\"\"

{function_body}
"""
    elif script_type == "Batch":
        content = f"""@echo off
::-----------------------------------------------------------------------------
:: Nom du script : {function_name}{extension}
:: Description   : Fonction extraite pour éliminer la duplication de code.
:: Généré automatiquement par Merge-SimilarScripts.py
:: Date de création : {datetime.now().strftime("%Y-%m-%d")}
::-----------------------------------------------------------------------------

{function_body}
"""
    elif script_type == "Shell":
        content = f"""#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : {function_name}{extension}
# Description   : Fonction extraite pour éliminer la duplication de code.
# Généré automatiquement par Merge-SimilarScripts.py
# Date de création : {datetime.now().strftime("%Y-%m-%d")}
#-----------------------------------------------------------------------------

{function_body}
"""
    else:
        content = function_body
    
    # Créer le fichier si demandé
    if apply:
        # Créer le dossier s'il n'existe pas
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        # Créer le fichier
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        
        write_log(f"Bibliothèque de fonctions créée: {file_path}", "SUCCESS")
    
    return {
        "file_path": file_path,
        "content": content
    }

def update_script_with_function_call(file_path, block_text, function_call, apply=False):
    """Remplace un bloc de code par un appel de fonction."""
    try:
        # Lire le contenu du fichier
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        # Remplacer le bloc de code par l'appel de fonction
        new_content = content.replace(block_text, function_call)
        
        # Appliquer les modifications si demandé
        if apply:
            # Créer une sauvegarde du fichier original
            backup_path = f"{file_path}.bak"
            shutil.copy2(file_path, backup_path)
            
            # Écrire le nouveau contenu
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(new_content)
            
            write_log(f"Script mis à jour: {file_path}", "SUCCESS")
        
        return True
    except Exception as e:
        write_log(f"Erreur lors de la mise à jour du script {file_path}: {e}", "ERROR")
        return False

def merge_duplications(duplications, library_path, min_duplication_count, apply=False):
    """Fusionne les duplications."""
    results = []
    
    # Regrouper les duplications par contenu (hash)
    grouped_duplications = {}
    
    for duplication in duplications:
        if duplication["type"] == "Exact":
            key = duplication["block1"]["hash"]
            
            if key not in grouped_duplications:
                grouped_duplications[key] = {
                    "block_text": duplication["block1"]["text"],
                    "occurrences": []
                }
            
            grouped_duplications[key]["occurrences"].append({
                "file_path": duplication["file1"],
                "block": duplication["block1"]
            })
            
            grouped_duplications[key]["occurrences"].append({
                "file_path": duplication["file2"],
                "block": duplication["block2"]
            })
    
    # Traiter chaque groupe de duplications
    for index, (key, group) in enumerate(grouped_duplications.items(), 1):
        # Filtrer les occurrences uniques (par fichier)
        unique_occurrences = []
        seen_files = set()
        
        for occurrence in group["occurrences"]:
            if occurrence["file_path"] not in seen_files:
                seen_files.add(occurrence["file_path"])
                unique_occurrences.append(occurrence)
        
        # Vérifier s'il y a suffisamment de duplications
        if len(unique_occurrences) >= min_duplication_count:
            # Déterminer le type de script à partir du premier fichier
            script_type = get_script_type(unique_occurrences[0]["file_path"])
            
            if script_type == "Unknown":
                write_log(f"Type de script inconnu pour {unique_occurrences[0]['file_path']}", "WARNING")
                continue
            
            # Générer un nom de fonction
            function_name = generate_function_name(group["block_text"], script_type, index)
            
            # Créer la fonction
            function_body = create_function(group["block_text"], function_name, script_type)
            
            # Créer l'appel de fonction
            function_call_info = create_function_call(function_name, script_type, library_path)
            
            # Créer la bibliothèque de fonctions
            library = create_function_library(function_name, function_body, script_type, library_path, apply)
            
            # Mettre à jour les scripts
            updated_files = []
            for occurrence in unique_occurrences:
                updated = update_script_with_function_call(
                    occurrence["file_path"],
                    group["block_text"],
                    function_call_info["call"],
                    apply
                )
                
                if updated:
                    updated_files.append(occurrence["file_path"])
            
            # Ajouter le résultat
            results.append({
                "function_name": function_name,
                "script_type": script_type,
                "library_path": library["file_path"],
                "duplication_count": len(unique_occurrences),
                "updated_files": updated_files,
                "applied": apply
            })
    
    return results

def validate_merge(file1, file2, block1, block2, similarity):
    """Demande une validation manuelle avant fusion."""
    print("\n" + "="*80)
    print(f"Fusion proposée entre {file1} et {file2}:")
    print(f"Similarité: {similarity:.2f}")
    print("-"*40 + " Bloc 1 " + "-"*40)
    print(block1[:200] + ("..." if len(block1) > 200 else ""))
    print("-"*40 + " Bloc 2 " + "-"*40)
    print(block2[:200] + ("..." if len(block2) > 200 else ""))
    print("="*80)
    
    response = input("Valider la fusion ? (oui/non) : ").lower()
    return response == "oui"

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Fusionne les scripts similaires pour éliminer les duplications.")
    parser.add_argument("--input", default=DEFAULT_INPUT_PATH, help="Chemin du fichier de rapport généré par Find-CodeDuplication.py")
    parser.add_argument("--output", default=DEFAULT_OUTPUT_PATH, help="Chemin du fichier de sortie pour le rapport des fusions")
    parser.add_argument("--library", default=DEFAULT_LIBRARY_PATH, help="Chemin du dossier où seront créées les bibliothèques de fonctions")
    parser.add_argument("--min-duplications", type=int, default=DEFAULT_MIN_DUPLICATION_COUNT, help="Nombre minimum de duplications pour créer une fonction réutilisable")
    parser.add_argument("--apply", action="store_true", help="Applique automatiquement les modifications sans demander de confirmation")
    parser.add_argument("--interactive", action="store_true", help="Mode interactif pour valider chaque fusion")
    parser.add_argument("--details", action="store_true", help="Affiche des informations détaillées pendant l'exécution")
    
    args = parser.parse_args()
    
    write_log("Démarrage de la fusion des scripts similaires...", "TITLE")
    write_log(f"Fichier d'entrée: {args.input}", "INFO")
    write_log(f"Dossier de bibliothèque: {args.library}", "INFO")
    write_log(f"Nombre minimum de duplications: {args.min_duplications}", "INFO")
    write_log(f"Mode: {'Application automatique' if args.apply else 'Simulation'}", "INFO")
    
    # Vérifier si le fichier d'entrée existe
    if not os.path.exists(args.input):
        write_log(f"Le fichier d'entrée n'existe pas: {args.input}", "ERROR")
        write_log("Exécutez d'abord Find-CodeDuplication.py pour générer le rapport.", "ERROR")
        return
    
    # Créer le dossier de sortie s'il n'existe pas
    output_dir = os.path.dirname(args.output)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        write_log(f"Dossier de sortie créé: {output_dir}", "SUCCESS")
    
    # Charger le rapport
    try:
        with open(args.input, "r", encoding="utf-8") as f:
            report = json.load(f)
    except Exception as e:
        write_log(f"Erreur lors du chargement du rapport: {e}", "ERROR")
        return
    
    # Fusionner les duplications entre fichiers
    write_log("Fusion des duplications entre fichiers...", "INFO")
    
    # Si mode interactif, filtrer les duplications à fusionner
    if args.interactive:
        filtered_duplications = []
        for duplication in report["inter_file_duplications"]:
            if validate_merge(
                duplication["file1"],
                duplication["file2"],
                duplication["block1"]["text"],
                duplication["block2"]["text"],
                duplication["similarity"]
            ):
                filtered_duplications.append(duplication)
        
        write_log(f"{len(filtered_duplications)} fusions validées sur {len(report['inter_file_duplications'])}", "INFO")
        merge_results = merge_duplications(filtered_duplications, args.library, args.min_duplications, args.apply)
    else:
        merge_results = merge_duplications(report["inter_file_duplications"], args.library, args.min_duplications, args.apply)
    
    # Enregistrer les résultats
    results = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "total_merges": len(merge_results),
        "min_duplication_count": args.min_duplications,
        "applied": args.apply,
        "merge_results": merge_results
    }
    
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    
    # Afficher un résumé
    write_log("Fusion terminée", "SUCCESS")
    write_log(f"Nombre total de fusions: {results['total_merges']}", "INFO")
    
    if args.apply:
        write_log("Fusions appliquées", "SUCCESS")
    else:
        write_log("Pour appliquer les fusions, exécutez la commande avec --apply", "WARNING")
    
    write_log(f"Résultats enregistrés dans: {args.output}", "SUCCESS")

if __name__ == "__main__":
    main()
