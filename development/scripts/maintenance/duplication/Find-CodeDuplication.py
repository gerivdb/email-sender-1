#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de détection des duplications de code.

Ce script analyse les scripts pour détecter les duplications de code et génère
un rapport détaillé des duplications trouvées. Il utilise plusieurs méthodes
pour identifier les duplications, y compris la comparaison de chaînes et
l'analyse de similarité.

Utilise le multiprocessing pour accélérer les comparaisons sur de grands volumes de fichiers.
"""

import os
import sys
import hashlib
import json
import argparse
from pathlib import Path
from datetime import datetime
from difflib import SequenceMatcher
from multiprocessing import Pool, cpu_count

# Configuration par défaut
DEFAULT_MIN_LINES = 5
DEFAULT_SIMILARITY_THRESHOLD = 0.8
DEFAULT_OUTPUT_PATH = "development/scripts/manager/data/duplication_report.json"

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
    log_file = "development/scripts/manager/data/duplication_detection.log"
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(formatted_message + "\n")

def get_script_files(path, script_type="All"):
    """Obtient tous les fichiers de script du type spécifié."""
    script_extensions = {
        "PowerShell": [".ps1", ".psm1", ".psd1"],
        "Python": [".py"],
        "Batch": [".cmd", ".bat"],
        "Shell": [".sh"]
    }
    
    files = []
    
    if script_type == "All":
        for extensions in script_extensions.values():
            for ext in extensions:
                files.extend(list(Path(path).glob(f"**/*{ext}")))
    else:
        for ext in script_extensions.get(script_type, []):
            files.extend(list(Path(path).glob(f"**/*{ext}")))
    
    return files

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

def get_normalized_content(file_path):
    """Lit et normalise le contenu d'un fichier."""
    try:
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        
        script_type = get_script_type(file_path)
        
        # Supprimer les commentaires et les lignes vides
        lines = content.splitlines()
        normalized_lines = []
        
        for line in lines:
            trimmed_line = line.strip()
            
            # Ignorer les lignes vides
            if not trimmed_line:
                continue
            
            # Ignorer les commentaires selon le type de script
            is_comment = False
            if script_type == "PowerShell":
                is_comment = trimmed_line.startswith("#") or trimmed_line.startswith("<#")
            elif script_type == "Python":
                is_comment = trimmed_line.startswith("#")
            elif script_type == "Batch":
                is_comment = trimmed_line.startswith("::") or trimmed_line.startswith("REM ")
            elif script_type == "Shell":
                is_comment = trimmed_line.startswith("#")
            
            if not is_comment:
                # Normaliser les espaces
                normalized_line = " ".join(trimmed_line.split())
                normalized_lines.append(normalized_line)
        
        return normalized_lines
    except Exception as e:
        write_log(f"Erreur lors de la lecture du fichier {file_path}: {e}", "ERROR")
        return []

def get_code_blocks(normalized_lines, min_line_count):
    """Extrait les blocs de code de taille minimale."""
    blocks = []
    
    for i in range(len(normalized_lines) - min_line_count + 1):
        block = normalized_lines[i:i + min_line_count]
        block_text = "\n".join(block)
        block_hash = hashlib.md5(block_text.encode()).hexdigest()
        
        blocks.append({
            "start_line": i,
            "end_line": i + min_line_count - 1,
            "line_count": min_line_count,
            "text": block_text,
            "hash": block_hash
        })
    
    return blocks

def calculate_similarity(text1, text2):
    """Calcule la similarité entre deux textes."""
    return SequenceMatcher(None, text1, text2).ratio()

def process_file(file_path, min_line_count):
    """Traite un fichier pour extraire ses blocs de code."""
    try:
        normalized_lines = get_normalized_content(file_path)
        
        if len(normalized_lines) < min_line_count:
            return None
        
        blocks = get_code_blocks(normalized_lines, min_line_count)
        
        return {
            "file_path": str(file_path),
            "blocks": blocks
        }
    except Exception as e:
        write_log(f"Erreur lors du traitement du fichier {file_path}: {e}", "ERROR")
        return None

def compare_blocks(args):
    """Compare deux blocs de code pour détecter les duplications."""
    file1_info, file2_info, similarity_threshold = args
    
    if file1_info is None or file2_info is None:
        return []
    
    duplications = []
    
    # Comparer les blocs entre les deux fichiers
    for block1 in file1_info["blocks"]:
        for block2 in file2_info["blocks"]:
            # Si les hachages sont identiques, c'est une duplication exacte
            if block1["hash"] == block2["hash"]:
                duplications.append({
                    "type": "Exact",
                    "file1": file1_info["file_path"],
                    "block1": block1,
                    "file2": file2_info["file_path"],
                    "block2": block2,
                    "similarity": 1.0
                })
            else:
                # Sinon, calculer la similarité
                similarity = calculate_similarity(block1["text"], block2["text"])
                
                if similarity >= similarity_threshold:
                    duplications.append({
                        "type": "Similar",
                        "file1": file1_info["file_path"],
                        "block1": block1,
                        "file2": file2_info["file_path"],
                        "block2": block2,
                        "similarity": similarity
                    })
    
    return duplications

def find_duplications(files, min_line_count, similarity_threshold, show_details=False):
    """Trouve les duplications entre les fichiers."""
    write_log("Analyse des fichiers pour extraire les blocs de code...", "INFO")
    
    # Utiliser le multiprocessing pour traiter les fichiers en parallèle
    with Pool(processes=cpu_count()) as pool:
        file_infos = pool.starmap(process_file, [(file, min_line_count) for file in files])
    
    # Filtrer les résultats None
    file_infos = [info for info in file_infos if info is not None]
    
    write_log(f"Extraction des blocs terminée pour {len(file_infos)} fichiers", "SUCCESS")
    write_log("Comparaison des blocs pour détecter les duplications...", "INFO")
    
    # Préparer les paires de fichiers à comparer
    comparisons = []
    for i in range(len(file_infos)):
        for j in range(i + 1, len(file_infos)):
            comparisons.append((file_infos[i], file_infos[j], similarity_threshold))
    
    # Utiliser le multiprocessing pour comparer les blocs en parallèle
    with Pool(processes=cpu_count()) as pool:
        results = pool.map(compare_blocks, comparisons)
    
    # Fusionner les résultats
    duplications = []
    for result in results:
        duplications.extend(result)
    
    write_log(f"Comparaison terminée, {len(duplications)} duplications trouvées", "SUCCESS")
    
    return duplications

def find_intra_file_duplications(file_path, min_line_count, similarity_threshold):
    """Trouve les duplications à l'intérieur d'un fichier."""
    try:
        normalized_lines = get_normalized_content(file_path)
        
        if len(normalized_lines) < min_line_count:
            return []
        
        blocks = get_code_blocks(normalized_lines, min_line_count)
        duplications = []
        
        # Comparer les blocs entre eux
        for i in range(len(blocks)):
            for j in range(i + 1, len(blocks)):
                # Si les blocs se chevauchent, les ignorer
                if blocks[i]["end_line"] >= blocks[j]["start_line"]:
                    continue
                
                # Si les hachages sont identiques, c'est une duplication exacte
                if blocks[i]["hash"] == blocks[j]["hash"]:
                    duplications.append({
                        "type": "Exact",
                        "block1": blocks[i],
                        "block2": blocks[j],
                        "similarity": 1.0
                    })
                else:
                    # Sinon, calculer la similarité
                    similarity = calculate_similarity(blocks[i]["text"], blocks[j]["text"])
                    
                    if similarity >= similarity_threshold:
                        duplications.append({
                            "type": "Similar",
                            "block1": blocks[i],
                            "block2": blocks[j],
                            "similarity": similarity
                        })
        
        return duplications
    except Exception as e:
        write_log(f"Erreur lors de l'analyse des duplications internes dans {file_path}: {e}", "ERROR")
        return []

def main():
    """Fonction principale."""
    parser = argparse.ArgumentParser(description="Détecte les duplications de code dans les scripts.")
    parser.add_argument("--path", default="scripts", help="Chemin du dossier contenant les scripts à analyser")
    parser.add_argument("--output", default=DEFAULT_OUTPUT_PATH, help="Chemin du fichier de sortie pour le rapport")
    parser.add_argument("--min-lines", type=int, default=DEFAULT_MIN_LINES, help="Nombre minimum de lignes pour considérer une duplication")
    parser.add_argument("--similarity", type=float, default=DEFAULT_SIMILARITY_THRESHOLD, help="Seuil de similarité (0-1)")
    parser.add_argument("--script-type", default="All", choices=["All", "PowerShell", "Python", "Batch", "Shell"], help="Type de script à analyser")
    parser.add_argument("--details", action="store_true", help="Affiche des informations détaillées pendant l'exécution")
    
    args = parser.parse_args()
    
    write_log("Démarrage de la détection des duplications de code...", "TITLE")
    write_log(f"Dossier des scripts: {args.path}", "INFO")
    write_log(f"Nombre minimum de lignes: {args.min_lines}", "INFO")
    write_log(f"Seuil de similarité: {args.similarity}", "INFO")
    write_log(f"Type de script: {args.script_type}", "INFO")
    write_log(f"Fichier de sortie: {args.output}", "INFO")
    
    # Vérifier si le dossier des scripts existe
    if not os.path.exists(args.path):
        write_log(f"Le dossier des scripts n'existe pas: {args.path}", "ERROR")
        return
    
    # Créer le dossier de sortie s'il n'existe pas
    output_dir = os.path.dirname(args.output)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        write_log(f"Dossier de sortie créé: {output_dir}", "SUCCESS")
    
    # Obtenir tous les fichiers de script
    script_files = get_script_files(args.path, args.script_type)
    total_files = len(script_files)
    write_log(f"Nombre de fichiers à analyser: {total_files}", "INFO")
    
    # Initialiser les résultats
    results = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "total_files": total_files,
        "script_type": args.script_type,
        "min_line_count": args.min_lines,
        "similarity_threshold": args.similarity,
        "intra_file_duplications": [],
        "inter_file_duplications": []
    }
    
    # Analyser chaque fichier pour les duplications internes
    for i, file in enumerate(script_files):
        progress = round((i / total_files) * 100)
        sys.stdout.write(f"\rAnalyse des duplications internes: {i+1}/{total_files} ({progress}%)")
        sys.stdout.flush()
        
        if args.details:
            write_log(f"Analyse du fichier: {file}", "INFO")
        
        # Trouver les duplications dans le fichier
        duplications = find_intra_file_duplications(file, args.min_lines, args.similarity)
        
        if duplications:
            results["intra_file_duplications"].append({
                "file_path": str(file),
                "duplications": duplications
            })
            
            if args.details:
                write_log(f"  Duplications trouvées: {len(duplications)}", "WARNING")
    
    sys.stdout.write("\n")
    
    # Analyser les duplications entre fichiers
    write_log("Analyse des duplications entre fichiers...", "INFO")
    inter_file_duplications = find_duplications(script_files, args.min_lines, args.similarity, args.details)
    results["inter_file_duplications"] = inter_file_duplications
    
    # Enregistrer les résultats
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    
    # Afficher un résumé
    intra_file_count = sum(len(item["duplications"]) for item in results["intra_file_duplications"])
    inter_file_count = len(results["inter_file_duplications"])
    write_log("Analyse terminée", "SUCCESS")
    write_log(f"Nombre total de fichiers analysés: {total_files}", "INFO")
    write_log(f"Nombre de duplications internes trouvées: {intra_file_count}", "WARNING")
    write_log(f"Nombre de duplications entre fichiers trouvées: {inter_file_count}", "WARNING")
    write_log(f"Résultats enregistrés dans: {args.output}", "SUCCESS")

if __name__ == "__main__":
    main()
