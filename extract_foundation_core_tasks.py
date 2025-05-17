#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import json
import sys
from collections import defaultdict

def main():
    # Charger le rapport JSON
    try:
        with open("markdown_tasks_report.json", "r", encoding="utf-8") as f:
            report = json.load(f)
    except Exception as e:
        print(f"Erreur lors du chargement du rapport JSON: {str(e)}")
        return 1
    
    # Extraire les tâches fondamentales
    foundation_tasks = []
    for filename, tasks in report["tasks_by_file"].items():
        for task in tasks:
            if ("fondation" in task["description"].lower() or 
                "foundation" in task["description"].lower() or
                "fondation" in task["section"].lower() or
                "foundation" in task["section"].lower()):
                task["filename"] = filename
                foundation_tasks.append(task)
    
    # Extraire les tâches core
    core_tasks = []
    for filename, tasks in report["tasks_by_file"].items():
        for task in tasks:
            if ("core" in task["description"].lower() or 
                "core" in task["section"].lower()):
                task["filename"] = filename
                core_tasks.append(task)
    
    # Analyser les tâches fondamentales par plan
    foundation_by_plan = defaultdict(list)
    for task in foundation_tasks:
        filename = task["filename"]
        foundation_by_plan[filename].append(task)
    
    print("\n=== TÂCHES FONDAMENTALES PAR PLAN ===\n")
    
    for filename, tasks in foundation_by_plan.items():
        print(f"\n{filename}: {len(tasks)} tâches fondamentales")
        
        # Trier par ID de tâche
        tasks.sort(key=lambda x: x["task_id"])
        
        for task in tasks[:5]:  # Limiter à 5 tâches par plan pour la lisibilité
            task_id = task["task_id"]
            description = task["description"]
            section = task["section"]
            
            print(f"- {task_id} ({section}): {description}")
        
        if len(tasks) > 5:
            print(f"... et {len(tasks) - 5} autres tâches")
    
    # Analyser les tâches core par plan
    core_by_plan = defaultdict(list)
    for task in core_tasks:
        filename = task["filename"]
        core_by_plan[filename].append(task)
    
    print("\n=== TÂCHES CORE PAR PLAN ===\n")
    
    for filename, tasks in core_by_plan.items():
        print(f"\n{filename}: {len(tasks)} tâches core")
        
        # Trier par ID de tâche
        tasks.sort(key=lambda x: x["task_id"])
        
        for task in tasks[:5]:  # Limiter à 5 tâches par plan pour la lisibilité
            task_id = task["task_id"]
            description = task["description"]
            section = task["section"]
            
            print(f"- {task_id} ({section}): {description}")
        
        if len(tasks) > 5:
            print(f"... et {len(tasks) - 5} autres tâches")
    
    # Identifier les tâches fondamentales les plus importantes
    # (celles qui apparaissent dans plusieurs plans ou qui ont un niveau d'indentation faible)
    important_foundation_tasks = []
    
    # Compter les occurrences de descriptions similaires
    description_count = defaultdict(int)
    for task in foundation_tasks:
        # Simplifier la description pour la comparaison
        simplified_desc = task["description"].lower()
        simplified_desc = ' '.join(simplified_desc.split())  # Normaliser les espaces
        description_count[simplified_desc] += 1
    
    # Ajouter les tâches avec des descriptions qui apparaissent plusieurs fois
    for task in foundation_tasks:
        simplified_desc = ' '.join(task["description"].lower().split())
        if description_count[simplified_desc] > 1 or task["indent_level"] <= 2:
            if task not in important_foundation_tasks:
                important_foundation_tasks.append(task)
    
    # Trier par nombre d'occurrences de la description, puis par niveau d'indentation
    important_foundation_tasks.sort(key=lambda x: (
        -description_count[' '.join(x["description"].lower().split())],
        x["indent_level"]
    ))
    
    print("\n=== TÂCHES FONDAMENTALES IMPORTANTES (TOP 30) ===\n")
    
    for i, task in enumerate(important_foundation_tasks[:30]):
        task_id = task["task_id"]
        description = task["description"]
        filename = task["filename"]
        indent_level = task["indent_level"]
        occurrences = description_count[' '.join(description.lower().split())]
        
        print(f"{i+1}. {task_id} (Niveau:{indent_level}, Occurrences:{occurrences}, Fichier:{filename}): {description}")
    
    # Identifier les tâches core les plus importantes
    important_core_tasks = []
    
    # Compter les occurrences de descriptions similaires
    core_description_count = defaultdict(int)
    for task in core_tasks:
        # Simplifier la description pour la comparaison
        simplified_desc = task["description"].lower()
        simplified_desc = ' '.join(simplified_desc.split())  # Normaliser les espaces
        core_description_count[simplified_desc] += 1
    
    # Ajouter les tâches avec des descriptions qui apparaissent plusieurs fois
    for task in core_tasks:
        simplified_desc = ' '.join(task["description"].lower().split())
        if core_description_count[simplified_desc] > 1 or task["indent_level"] <= 2:
            if task not in important_core_tasks:
                important_core_tasks.append(task)
    
    # Trier par nombre d'occurrences de la description, puis par niveau d'indentation
    important_core_tasks.sort(key=lambda x: (
        -core_description_count[' '.join(x["description"].lower().split())],
        x["indent_level"]
    ))
    
    print("\n=== TÂCHES CORE IMPORTANTES (TOP 20) ===\n")
    
    for i, task in enumerate(important_core_tasks[:20]):
        task_id = task["task_id"]
        description = task["description"]
        filename = task["filename"]
        indent_level = task["indent_level"]
        occurrences = core_description_count[' '.join(description.lower().split())]
        
        print(f"{i+1}. {task_id} (Niveau:{indent_level}, Occurrences:{occurrences}, Fichier:{filename}): {description}")
    
    # Générer un rapport des tâches fondamentales et core importantes
    important_tasks_report = {
        "important_foundation_tasks": important_foundation_tasks[:30],
        "important_core_tasks": important_core_tasks[:20],
        "foundation_by_plan": {filename: tasks for filename, tasks in foundation_by_plan.items()},
        "core_by_plan": {filename: tasks for filename, tasks in core_by_plan.items()}
    }
    
    with open("important_tasks_report.json", "w", encoding="utf-8") as f:
        json.dump(important_tasks_report, f, ensure_ascii=False, indent=2)
    
    print("\nRapport JSON généré: important_tasks_report.json")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
