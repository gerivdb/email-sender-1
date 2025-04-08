#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour générer une documentation sur l'organisation des scripts workflow.
Ce script analyse les scripts dans chaque sous-dossier et génère un fichier Markdown
avec une description de chaque script.
"""

import os
import re
from pathlib import Path

def extract_description(file_path):
    """Extrait la description d'un script à partir de ses commentaires."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Pour les scripts PowerShell
        if file_path.suffix.lower() == '.ps1':
            # Rechercher les commentaires au début du fichier
            match = re.search(r'^\s*#\s*(.+?)(?:\r?\n\s*#\s*(.+?))*(?:\r?\n\s*[^#]|\Z)', content, re.MULTILINE)
            if match:
                return match.group(0).replace('#', '').strip()
            
            # Rechercher les blocs de commentaires
            match = re.search(r'<#\s*(.+?)\s*#>', content, re.DOTALL)
            if match:
                return match.group(1).strip()
        
        # Pour les scripts Python
        elif file_path.suffix.lower() == '.py':
            # Rechercher les docstrings
            match = re.search(r'"""(.+?)"""', content, re.DOTALL)
            if match:
                return match.group(1).strip()
            
            # Rechercher les commentaires au début du fichier
            match = re.search(r'^\s*#\s*(.+?)(?:\r?\n\s*#\s*(.+?))*(?:\r?\n\s*[^#]|\Z)', content, re.MULTILINE)
            if match:
                return match.group(0).replace('#', '').strip()
        
        # Si aucune description n'est trouvée, retourner une description par défaut
        return "Aucune description disponible."
    except Exception as e:
        return f"Erreur lors de l'extraction de la description : {str(e)}"

def generate_documentation():
    """Génère une documentation sur l'organisation des scripts workflow."""
    
    # Définir le répertoire racine des scripts workflow
    workflow_dir = Path("D:/DO/WEB/N8N_tests/scripts_ json_a_ tester/EMAIL_SENDER_1/scripts/workflow")
    
    # Vérifier que le répertoire existe
    if not workflow_dir.exists():
        print(f"Le répertoire {workflow_dir} n'existe pas.")
        return
    
    # Créer le contenu du fichier Markdown
    content = "# Documentation des scripts workflow\n\n"
    content += "Ce document décrit l'organisation des scripts workflow et leur fonction.\n\n"
    
    # Parcourir chaque sous-dossier
    for category_dir in sorted(workflow_dir.glob("*")):
        if not category_dir.is_dir():
            continue
        
        category_name = category_dir.name
        content += f"## {category_name.capitalize()}\n\n"
        
        # Compter les fichiers dans le sous-dossier
        files = list(category_dir.glob("*.*"))
        content += f"Ce dossier contient {len(files)} script(s) pour {category_name.replace('-', ' ')} les workflows.\n\n"
        
        if not files:
            content += "Aucun script dans ce dossier.\n\n"
            continue
        
        # Parcourir chaque fichier dans le sous-dossier
        for file_path in sorted(files):
            file_name = file_path.name
            content += f"### {file_name}\n\n"
            
            # Extraire la description du script
            description = extract_description(file_path)
            content += f"{description}\n\n"
            
            # Ajouter un exemple d'utilisation
            if file_path.suffix.lower() == '.ps1':
                content += "**Exemple d'utilisation :**\n"
                content += "```powershell\n"
                content += f".\\{file_name}\n"
                content += "```\n\n"
            elif file_path.suffix.lower() == '.py':
                content += "**Exemple d'utilisation :**\n"
                content += "```bash\n"
                content += f"python {file_name}\n"
                content += "```\n\n"
    
    # Écrire le contenu dans un fichier Markdown
    doc_path = workflow_dir / "README.md"
    with open(doc_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Documentation générée : {doc_path}")

if __name__ == "__main__":
    generate_documentation()
