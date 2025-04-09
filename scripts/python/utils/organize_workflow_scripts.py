#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour organiser méthodiquement les scripts workflow en utilisant le MCP Server Filesystem.
Ce script déplace les scripts vers les sous-dossiers appropriés selon leur fonction.
"""

import os
import shutil
from pathlib import Path

def organize_workflow_scripts():
    """Organise les scripts workflow en les déplaçant vers les sous-dossiers appropriés."""
    
    # Définir le répertoire racine des scripts workflow
    workflow_dir = Path("D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1/scripts/workflow")
    
    # Vérifier que le répertoire existe
    if not workflow_dir.exists():
        print(f"Le répertoire {workflow_dir} n'existe pas.")
        return
    
    # Définir les catégories et les motifs de noms de fichiers correspondants
    categories = {
        "delete": ["delete"],
        "fix": ["fix"],
        "import": ["import"],
        "monitoring": ["check", "verify"],
        "remove-accents": ["remove-accents"],
        "testing": ["simulate", "test"],
        "validation": ["validate", "check_"],
        "utility": []  # Catégorie par défaut pour les scripts qui ne correspondent à aucune autre catégorie
    }
    
    # Créer les sous-dossiers s'ils n'existent pas
    for category in categories:
        category_dir = workflow_dir / category
        if not category_dir.exists():
            print(f"Création du sous-dossier {category}...")
            os.makedirs(category_dir, exist_ok=True)
    
    # Lister tous les fichiers dans le répertoire racine
    root_files = [f for f in workflow_dir.glob("*.ps1") if f.is_file()]
    root_files.extend([f for f in workflow_dir.glob("*.py") if f.is_file()])
    
    # Déplacer chaque fichier vers le sous-dossier approprié
    for file_path in root_files:
        file_name = file_path.name
        
        # Déterminer la catégorie du fichier
        target_category = "utility"  # Par défaut
        
        for category, patterns in categories.items():
            for pattern in patterns:
                if pattern in file_name.lower():
                    target_category = category
                    break
            if target_category != "utility":
                break
        
        # Déplacer le fichier vers le sous-dossier approprié
        target_dir = workflow_dir / target_category
        target_path = target_dir / file_name
        
        # Vérifier si le fichier existe déjà dans le sous-dossier
        if target_path.exists():
            print(f"Le fichier {file_name} existe déjà dans {target_category}. Ignoré.")
            continue
        
        try:
            print(f"Déplacement de {file_name} vers {target_category}...")
            shutil.move(str(file_path), str(target_path))
        except Exception as e:
            print(f"Erreur lors du déplacement de {file_name} : {str(e)}")
    
    print("\nOrganisation des scripts terminée.")
    
    # Afficher un résumé de l'organisation
    print("\nRésumé de l'organisation :")
    for category in categories:
        category_dir = workflow_dir / category
        files = list(category_dir.glob("*.*"))
        print(f"  - {category}: {len(files)} fichiers")

if __name__ == "__main__":
    organize_workflow_scripts()
