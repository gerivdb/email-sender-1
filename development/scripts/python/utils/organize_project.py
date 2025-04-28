#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'organisation de projet n8n
-----------------------------------
Ce script utilise le gestionnaire de fichiers pour organiser votre projet n8n.
Il permet de scanner les fichiers, créer un inventaire, organiser les fichiers
et corriger les problèmes d'encodage.
"""

import os
import sys
from pathlib import Path
from file_manager import FileManager

def main():
    """Fonction principale pour organiser le projet."""
    # Définir le répertoire racine du projet
    root_dir = Path(os.getcwd())
    print(f"Répertoire racine: {root_dir}")
    
    # Créer une instance du gestionnaire de fichiers
    manager = FileManager(root_dir)
    
    # 1. Scanner le répertoire pour créer un inventaire
    print("\n1. Analyse des fichiers...")
    inventory = manager.scan_directory()
    print(f"Nombre de fichiers trouvés: {len(inventory)}")
    
    # 2. Créer un rapport d'inventaire
    print("\n2. Création d'un rapport d'inventaire...")
    report_path = manager.create_inventory_report(output_format="html", 
                                                output_path="rapport_inventaire.html")
    print(f"Rapport créé: {report_path}")
    
    # 3. Analyser les workflows n8n
    print("\n3. Analyse des workflows n8n...")
    workflow_stats = manager.analyze_n8n_workflows()
    print(f"Total des workflows: {workflow_stats['total_workflows']}")
    print(f"Workflows avec problèmes d'encodage: {workflow_stats['workflows_with_issues']}")
    
    # 4. Corriger les problèmes de caractères accentués
    print("\n4. Correction des problèmes de caractères accentués...")
    modified_files = manager.fix_accented_characters(create_backup=True)
    print(f"Nombre de fichiers modifiés: {len(modified_files)}")
    
    # 5. Organiser les fichiers
    print("\n5. Organisation des fichiers...")
    organized_dir = root_dir / "fichiers_organises"
    organized_files = manager.organize_files(
        target_dir=organized_dir,
        organize_by="type",
        move_files=False  # Copier les fichiers au lieu de les déplacer
    )
    
    # Afficher un résumé de l'organisation
    print("\nRésumé de l'organisation:")
    for category, files in organized_files.items():
        print(f"  - {category}: {len(files)} fichiers")
    
    print(f"\nLes fichiers organisés se trouvent dans: {organized_dir}")
    print("Organisation terminée!")

if __name__ == "__main__":
    main()
