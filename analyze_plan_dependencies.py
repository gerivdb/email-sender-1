#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import json
from collections import defaultdict

def extract_plan_version(filename):
    """Extraire le numéro de version du plan à partir du nom de fichier"""
    match = re.search(r'plan-dev-v(\d+)', filename.lower())
    if match:
        return int(match.group(1))
    return None

def extract_references(content, all_versions):
    """Extraire les références à d'autres plans dans le contenu"""
    references = set()
    
    # Rechercher les références explicites (v1, v2, etc.)
    for version in all_versions:
        pattern = rf'\bv{version}\b'
        if re.search(pattern, content):
            references.add(version)
    
    return references

def main():
    # Répertoire des plans consolidés
    plans_dir = "projet/roadmaps/plans/consolidated"
    
    # Vérifier que le répertoire existe
    if not os.path.exists(plans_dir):
        print(f"Le répertoire {plans_dir} n'existe pas.")
        return 1
    
    # Collecter tous les fichiers de plan
    plan_files = []
    for filename in os.listdir(plans_dir):
        if filename.endswith(".md") and "plan-dev-v" in filename.lower():
            version = extract_plan_version(filename)
            if version:
                plan_files.append({
                    "filename": filename,
                    "version": version,
                    "path": os.path.join(plans_dir, filename)
                })
    
    # Trier les plans par numéro de version
    plan_files.sort(key=lambda x: x["version"])
    
    # Collecter toutes les versions
    all_versions = [plan["version"] for plan in plan_files]
    
    # Analyser les dépendances
    dependencies = defaultdict(set)
    
    for plan in plan_files:
        try:
            with open(plan["path"], 'r', encoding='utf-8') as f:
                content = f.read()
                
                # Extraire les références à d'autres plans
                refs = extract_references(content, all_versions)
                
                # Ajouter les dépendances
                dependencies[plan["version"]] = refs
        except Exception as e:
            print(f"Erreur lors de l'analyse du fichier {plan['filename']}: {str(e)}")
    
    # Afficher les dépendances
    print("\n=== DÉPENDANCES ENTRE LES PLANS ===\n")
    
    for version in sorted(dependencies.keys()):
        refs = dependencies[version]
        if refs:
            print(f"Plan v{version} dépend de: {', '.join([f'v{ref}' for ref in sorted(refs)])}")
        else:
            print(f"Plan v{version} n'a pas de dépendances explicites")
    
    # Identifier les dépendances circulaires
    print("\n=== DÉPENDANCES CIRCULAIRES ===\n")
    
    circular_deps = []
    for version, refs in dependencies.items():
        for ref in refs:
            if version in dependencies[ref]:
                circular_deps.append((version, ref))
    
    if circular_deps:
        for v1, v2 in circular_deps:
            print(f"Dépendance circulaire entre v{v1} et v{v2}")
    else:
        print("Aucune dépendance circulaire détectée")
    
    # Identifier les plans fondamentaux (ceux dont beaucoup d'autres plans dépendent)
    print("\n=== PLANS FONDAMENTAUX ===\n")
    
    # Compter combien de plans dépendent de chaque plan
    dependents_count = defaultdict(int)
    for version, refs in dependencies.items():
        for ref in refs:
            dependents_count[ref] += 1
    
    # Trier par nombre de dépendants
    sorted_deps = sorted(dependents_count.items(), key=lambda x: x[1], reverse=True)
    
    for version, count in sorted_deps:
        if count > 0:
            print(f"Plan v{version} est référencé par {count} autres plans")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
