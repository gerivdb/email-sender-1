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
import asyncio
import subprocess
from pathlib import Path

# URL du dépôt à analyser
REPO_URL = "https://github.com/mem0ai/mem0"

# Fichiers importants à analyser
IMPORTANT_FILES = [
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

# Répertoire de sortie
OUTPUT_DIR = Path("output/mem0-analysis")

def install_requirements():
    """Installe les dépendances nécessaires."""
    print("Vérification et installation des dépendances...")
    try:
        # Installer mcp-git-ingest
        subprocess.run(
            [sys.executable, "-m", "pip", "install", "git+https://github.com/adhikasp/mcp-git-ingest"],
            check=True
        )
        print("Package mcp-git-ingest installé avec succès.")
        
        # Vérifier si uvicorn est installé
        try:
            import uvicorn
            print("Package uvicorn déjà installé.")
        except ImportError:
            print("Installation du package uvicorn...")
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "uvicorn"],
                check=True
            )
            print("Package uvicorn installé avec succès.")
        
        # Vérifier si fastapi est installé
        try:
            import fastapi
            print("Package fastapi déjà installé.")
        except ImportError:
            print("Installation du package fastapi...")
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "fastapi"],
                check=True
            )
            print("Package fastapi installé avec succès.")
        
        print("Toutes les dépendances sont installées.")
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de l'installation des dépendances: {e}")
        sys.exit(1)

async def run_mcp_command(tool, params):
    """Exécute une commande MCP Git Ingest."""
    try:
        # Importer le module mcp_git_ingest
        from mcp_git_ingest.main import git_directory_structure, git_read_important_files
        
        # Exécuter la commande appropriée
        if tool == "github_directory_structure":
            result = await git_directory_structure(params["repo_url"])
            return result
        elif tool == "github_read_important_files":
            result = await git_read_important_files(params["repo_url"], params["file_paths"])
            return result
        else:
            print(f"Outil inconnu: {tool}")
            return None
    except Exception as e:
        print(f"Erreur lors de l'exécution de la commande MCP: {e}")
        return None

async def get_directory_structure():
    """Obtient la structure du dépôt GitHub."""
    print(f"Récupération de la structure du dépôt {REPO_URL}...")
    
    params = {"repo_url": REPO_URL}
    result = await run_mcp_command("github_directory_structure", params)
    
    if result:
        print("Structure du dépôt récupérée avec succès.")
        return result
    else:
        print("Échec de la récupération de la structure du dépôt.")
        return None

async def read_important_files():
    """Lit le contenu des fichiers importants du dépôt GitHub."""
    print(f"Lecture des fichiers importants du dépôt {REPO_URL}...")
    
    params = {
        "repo_url": REPO_URL,
        "file_paths": IMPORTANT_FILES
    }
    
    result = await run_mcp_command("github_read_important_files", params)
    
    if result:
        print("Fichiers importants récupérés avec succès.")
        return result
    else:
        print("Échec de la récupération des fichiers importants.")
        return None

def save_results(structure, files_content):
    """Sauvegarde les résultats de l'analyse dans des fichiers."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Sauvegarder la structure du dépôt
    if structure:
        with open(OUTPUT_DIR / "structure.json", "w", encoding="utf-8") as f:
            json.dump(structure, f, indent=2)
        print(f"Structure du dépôt sauvegardée dans {OUTPUT_DIR / 'structure.json'}")
    
    # Sauvegarder le contenu des fichiers
    if files_content:
        with open(OUTPUT_DIR / "files_content.json", "w", encoding="utf-8") as f:
            json.dump(files_content, f, indent=2)
        print(f"Contenu des fichiers sauvegardé dans {OUTPUT_DIR / 'files_content.json'}")
        
        # Sauvegarder chaque fichier individuellement
        files_dir = OUTPUT_DIR / "files"
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
    
    # Ajouter une analyse de compatibilité avec Augment
    report.append("## Analyse de compatibilité avec Augment")
    report.append("")
    report.append("### Fonctionnalités MCP détectées")
    report.append("")
    
    # Analyser les fichiers pour détecter les fonctionnalités MCP
    mcp_features = analyze_mcp_features(files_content)
    
    for feature, details in mcp_features.items():
        report.append(f"#### {feature}")
        report.append("")
        report.append(details["description"])
        report.append("")
        if details["compatible"]:
            report.append("✅ **Compatible avec Augment**")
        else:
            report.append("❌ **Non compatible avec Augment**")
        report.append("")
        report.append(f"*Détecté dans: {', '.join(details['files'])}*")
        report.append("")
    
    # Conclusion
    report.append("## Conclusion")
    report.append("")
    
    compatible_features = sum(1 for feature in mcp_features.values() if feature["compatible"])
    total_features = len(mcp_features)
    
    if total_features > 0:
        compatibility_score = (compatible_features / total_features) * 100
        report.append(f"Le projet mem0ai/mem0 est **{compatibility_score:.0f}%** compatible avec Augment.")
        
        if compatibility_score >= 75:
            report.append("")
            report.append("**Recommandation**: L'intégration de OpenMemory MCP avec Augment est fortement recommandée.")
        elif compatibility_score >= 50:
            report.append("")
            report.append("**Recommandation**: L'intégration de OpenMemory MCP avec Augment est possible mais nécessitera quelques adaptations.")
        else:
            report.append("")
            report.append("**Recommandation**: L'intégration de OpenMemory MCP avec Augment nécessitera des modifications importantes.")
    else:
        report.append("Impossible de déterminer la compatibilité avec Augment.")
    
    # Sauvegarder le rapport
    report_path = OUTPUT_DIR / "report.md"
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("\n".join(report))
    
    print(f"Rapport d'analyse sauvegardé dans {report_path}")
    return report_path

def analyze_mcp_features(files_content):
    """Analyse les fichiers pour détecter les fonctionnalités MCP."""
    features = {}
    
    if not files_content or "files" not in files_content:
        return features
    
    # Rechercher les fonctionnalités MCP dans les fichiers
    for file_info in files_content.get("files", []):
        file_path = file_info.get("path", "")
        content = file_info.get("content", "")
        
        # Détecter les outils MCP
        if "mcp/tools.py" in file_path or "tools" in file_path.lower():
            features["MCP Tools"] = {
                "description": "Outils MCP pour interagir avec le modèle",
                "compatible": True,
                "files": [file_path]
            }
        
        # Détecter le serveur MCP
        if "mcp/server.py" in file_path or "server" in file_path.lower():
            features["MCP Server"] = {
                "description": "Serveur MCP pour exposer les outils",
                "compatible": True,
                "files": [file_path]
            }
        
        # Détecter l'API MCP
        if "api" in file_path.lower() and "mcp" in content.lower():
            features["MCP API"] = {
                "description": "API pour interagir avec le serveur MCP",
                "compatible": True,
                "files": [file_path]
            }
        
        # Détecter les fonctionnalités de mémoire
        if "memory" in file_path.lower() or "memory" in content.lower():
            if "memory" not in features:
                features["Memory Management"] = {
                    "description": "Gestion de la mémoire pour les modèles",
                    "compatible": True,
                    "files": [file_path]
                }
            elif file_path not in features["Memory Management"]["files"]:
                features["Memory Management"]["files"].append(file_path)
    
    return features

async def main():
    """Fonction principale."""
    print("Analyse du dépôt mem0ai/mem0 avec MCP Git Ingest...")
    
    # Installer les dépendances
    install_requirements()
    
    # Obtenir la structure du dépôt
    structure = await get_directory_structure()
    
    # Lire les fichiers importants
    files_content = await read_important_files()
    
    # Sauvegarder les résultats
    save_results(structure, files_content)
    
    # Générer un rapport
    report_path = generate_report(structure, files_content)
    
    print(f"Analyse terminée. Rapport disponible dans {report_path}")

if __name__ == "__main__":
    asyncio.run(main())
