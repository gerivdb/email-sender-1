#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour analyser le dépôt mem0ai/mem0 avec MCP Git Ingest.
Ce script permet d'explorer la structure du dépôt et de lire les fichiers importants
pour évaluer si OpenMemory MCP serait utile et compatible avec Augment.
"""

import os
import sys
import json
import subprocess
import tempfile
from pathlib import Path

# URL du dépôt à analyser
REPO_URL = "https://github.com/mem0ai/mem0"

def install_requirements():
    """Installe les dépendances nécessaires."""
    print("Vérification et installation des dépendances...")
    try:
        # Vérifier si mcp-git-ingest est installé
        subprocess.run(
            [sys.executable, "-m", "pip", "show", "mcp-git-ingest"],
            check=False,
            capture_output=True
        )
        
        # Installer mcp-git-ingest si nécessaire
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "git+https://github.com/adhikasp/mcp-git-ingest"],
            check=True
        )
        print("Dépendances installées avec succès.")
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de l'installation des dépendances: {e}")
        sys.exit(1)

def get_directory_structure():
    """Obtient la structure du dépôt GitHub."""
    print(f"Récupération de la structure du dépôt {REPO_URL}...")
    
    try:
        # Préparer la commande MCP
        mcp_command = {
            "tool": "github_directory_structure",
            "params": {
                "repo_url": REPO_URL
            }
        }
        
        # Convertir en JSON
        mcp_json = json.dumps(mcp_command)
        
        # Exécuter la commande avec Python
        cmd = [sys.executable, "-m", "mcp_git_ingest.main"]
        
        # Lancer le processus
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Envoyer la commande JSON
        stdout, stderr = process.communicate(input=mcp_json)
        
        if stderr:
            print(f"STDERR: {stderr}", file=sys.stderr)
        
        # Analyser la réponse JSON
        try:
            result = json.loads(stdout)
            return result
        except json.JSONDecodeError:
            print(f"Erreur de décodage JSON: {stdout}")
            return None
    
    except Exception as e:
        print(f"Erreur lors de la récupération de la structure du dépôt: {e}")
        return None

def read_important_files(file_paths):
    """Lit le contenu des fichiers importants du dépôt GitHub."""
    print(f"Lecture des fichiers importants du dépôt {REPO_URL}...")
    
    try:
        # Préparer la commande MCP
        mcp_command = {
            "tool": "github_read_important_files",
            "params": {
                "repo_url": REPO_URL,
                "file_paths": file_paths
            }
        }
        
        # Convertir en JSON
        mcp_json = json.dumps(mcp_command)
        
        # Exécuter la commande avec Python
        cmd = [sys.executable, "-m", "mcp_git_ingest.main"]
        
        # Lancer le processus
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Envoyer la commande JSON
        stdout, stderr = process.communicate(input=mcp_json)
        
        if stderr:
            print(f"STDERR: {stderr}", file=sys.stderr)
        
        # Analyser la réponse JSON
        try:
            result = json.loads(stdout)
            return result
        except json.JSONDecodeError:
            print(f"Erreur de décodage JSON: {stdout}")
            return None
    
    except Exception as e:
        print(f"Erreur lors de la lecture des fichiers: {e}")
        return None

def save_results(structure, files_content):
    """Sauvegarde les résultats de l'analyse dans des fichiers."""
    output_dir = Path("output/mem0-analysis")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Sauvegarder la structure du dépôt
    if structure:
        with open(output_dir / "structure.json", "w", encoding="utf-8") as f:
            json.dump(structure, f, indent=2)
        print(f"Structure du dépôt sauvegardée dans {output_dir / 'structure.json'}")
    
    # Sauvegarder le contenu des fichiers
    if files_content:
        with open(output_dir / "files_content.json", "w", encoding="utf-8") as f:
            json.dump(files_content, f, indent=2)
        print(f"Contenu des fichiers sauvegardé dans {output_dir / 'files_content.json'}")
        
        # Sauvegarder chaque fichier individuellement
        files_dir = output_dir / "files"
        files_dir.mkdir(exist_ok=True)
        
        for file_info in files_content.get("files", []):
            file_path = file_info.get("path")
            content = file_info.get("content")
            
            if file_path and content:
                # Créer un chemin de fichier sécurisé
                safe_path = file_path.replace("/", "_").replace("\\", "_")
                with open(files_dir / safe_path, "w", encoding="utf-8") as f:
                    f.write(content)
                print(f"Fichier {file_path} sauvegardé dans {files_dir / safe_path}")

def generate_report(structure, files_content):
    """Génère un rapport d'analyse du dépôt."""
    output_dir = Path("output/mem0-analysis")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    report = []
    report.append("# Analyse du dépôt mem0ai/mem0")
    report.append("")
    report.append("## Structure du dépôt")
    report.append("")
    
    if structure and "structure" in structure:
        report.append("```")
        report.append(structure["structure"])
        report.append("```")
    else:
        report.append("*Erreur lors de la récupération de la structure du dépôt.*")
    
    report.append("")
    report.append("## Fichiers importants")
    report.append("")
    
    if files_content and "files" in files_content:
        for file_info in files_content["files"]:
            file_path = file_info.get("path", "")
            report.append(f"### {file_path}")
            report.append("")
            report.append("```")
            content = file_info.get("content", "")
            # Limiter la taille du contenu dans le rapport
            if len(content) > 1000:
                content = content[:1000] + "...\n[contenu tronqué]"
            report.append(content)
            report.append("```")
            report.append("")
    else:
        report.append("*Erreur lors de la récupération des fichiers importants.*")
    
    # Sauvegarder le rapport
    with open(output_dir / "report.md", "w", encoding="utf-8") as f:
        f.write("\n".join(report))
    
    print(f"Rapport d'analyse sauvegardé dans {output_dir / 'report.md'}")
    return output_dir / "report.md"

def main():
    """Fonction principale."""
    print("Analyse du dépôt mem0ai/mem0 avec MCP Git Ingest...")
    
    # Installer les dépendances
    install_requirements()
    
    # Obtenir la structure du dépôt
    structure = get_directory_structure()
    
    # Définir les fichiers importants à lire
    important_files = [
        "README.md",
        "pyproject.toml",
        "setup.py",
        "mem0/__init__.py",
        "mem0/main.py",
        "mem0/mcp/__init__.py",
        "mem0/mcp/server.py",
        "mem0/mcp/tools.py",
        "mem0/config.py",
        "docs/README.md"
    ]
    
    # Lire les fichiers importants
    files_content = read_important_files(important_files)
    
    # Sauvegarder les résultats
    save_results(structure, files_content)
    
    # Générer un rapport
    report_path = generate_report(structure, files_content)
    
    print(f"Analyse terminée. Rapport disponible dans {report_path}")

if __name__ == "__main__":
    main()
