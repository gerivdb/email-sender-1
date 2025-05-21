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

def extract_tasks(file_path):
    """Extraire les tâches d'un fichier Markdown"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extraire les tâches avec regex
        task_pattern = r'- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
        matches = re.finditer(task_pattern, content)
        
        tasks = []
        for match in matches:
            status = match.group(1)
            task_id = match.group(2)
            description = match.group(3).strip()
            
            # Déterminer le niveau d'indentation
            indent_level = len(task_id.split('.'))
            
            # Déterminer l'ID parent
            parent_id = ""
            if indent_level > 1:
                parts = task_id.split('.')
                parent_id = '.'.join(parts[:-1])
            
            # Extraire la section (en cherchant le dernier titre avant la tâche)
            section_pattern = r'##\s+(.*?)(?:\r?\n)'
            sections = list(re.finditer(section_pattern, content))
            section = "Non spécifié"
            
            for sec in sections:
                if sec.start() < match.start():
                    section = sec.group(1).strip()
                else:
                    break
            
            # Extraire les métadonnées supplémentaires (MVP, priorité, etc.)
            is_mvp = bool(re.search(r'\bMVP\b', description))
            priority_match = re.search(r'\b(P[0-3])\b', description)
            priority = priority_match.group(1) if priority_match else "P3"
            
            # Estimer le temps (si présent dans la description)
            time_match = re.search(r'\b(\d+[hj])\b', description)
            estimated_time = time_match.group(1) if time_match else ""
            
            # Déterminer la catégorie
            category = "non_categorise"
            category_match = re.search(r'\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b', description, re.IGNORECASE)
            if category_match:
                category = category_match.group(1).lower()
            
            tasks.append({
                "task_id": task_id,
                "description": description,
                "status": "completed" if status in ['x', 'X'] else "pending",
                "indent_level": indent_level,
                "parent_id": parent_id,
                "section": section,
                "file_path": os.path.basename(file_path),
                "is_mvp": is_mvp,
                "priority": priority,
                "estimated_time": estimated_time,
                "category": category
            })
        
        return tasks
    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
        return []

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
        if filename.endswith(".md"):
            version = extract_plan_version(filename)
            plan_files.append({
                "filename": filename,
                "version": version,
                "path": os.path.join(plans_dir, filename)
            })
    
    # Trier les plans par numéro de version
    plan_files.sort(key=lambda x: (x["version"] is None, x["version"]))
    
    print(f"Nombre de fichiers de plan trouvés: {len(plan_files)}")
    
    # Analyser les tâches dans chaque plan
    all_tasks = []
    tasks_by_file = {}
    
    for plan in plan_files:
        filename = plan["filename"]
        file_path = plan["path"]
        
        print(f"Analyse du fichier {filename}...")
        
        tasks = extract_tasks(file_path)
        all_tasks.extend(tasks)
        tasks_by_file[filename] = tasks
        
        print(f"  - {len(tasks)} tâches trouvées")
    
    print(f"\nNombre total de tâches: {len(all_tasks)}")
    
    # Analyser les tâches prioritaires
    mvp_tasks = [task for task in all_tasks if task["is_mvp"]]
    p0_tasks = [task for task in all_tasks if task["priority"] == "P0"]
    p1_tasks = [task for task in all_tasks if task["priority"] == "P1"]
    
    print("\n=== STATISTIQUES DES TÂCHES PRIORITAIRES ===\n")
    print(f"Nombre de tâches MVP: {len(mvp_tasks)}")
    print(f"Nombre de tâches P0: {len(p0_tasks)}")
    print(f"Nombre de tâches P1: {len(p1_tasks)}")
    
    # Identifier les tâches qui sont à la fois MVP et P0/P1
    mvp_task_ids = set(task["task_id"] for task in mvp_tasks)
    p0_task_ids = set(task["task_id"] for task in p0_tasks)
    p1_task_ids = set(task["task_id"] for task in p1_tasks)
    
    mvp_p0_tasks = [task for task in mvp_tasks if task["task_id"] in p0_task_ids]
    mvp_p1_tasks = [task for task in mvp_tasks if task["task_id"] in p1_task_ids]
    
    print(f"\nNombre de tâches à la fois MVP et P0: {len(mvp_p0_tasks)}")
    print(f"Nombre de tâches à la fois MVP et P1: {len(mvp_p1_tasks)}")
    
    # Analyser les tâches fondamentales
    foundation_tasks = []
    for task in all_tasks:
        if ("fondation" in task["description"].lower() or 
            "foundation" in task["description"].lower() or
            "fondation" in task["section"].lower() or
            "foundation" in task["section"].lower()):
            foundation_tasks.append(task)
    
    core_tasks = []
    for task in all_tasks:
        if ("core" in task["description"].lower() or 
            "core" in task["section"].lower()):
            core_tasks.append(task)
    
    print(f"Nombre de tâches fondamentales: {len(foundation_tasks)}")
    print(f"Nombre de tâches core: {len(core_tasks)}")
    
    # Identifier les tâches fondamentales prioritaires
    foundation_priority_tasks = []
    for task in foundation_tasks:
        if (task["is_mvp"] or 
            task["priority"] == "P0" or 
            task["priority"] == "P1"):
            foundation_priority_tasks.append(task)
    
    # Trier par priorité puis par ID
    foundation_priority_tasks.sort(key=lambda x: (
        0 if x["priority"] == "P0" else (1 if x["priority"] == "P1" else 2),
        x["task_id"]
    ))
    
    print("\n=== TÂCHES FONDAMENTALES PRIORITAIRES ===\n")
    
    for task in foundation_priority_tasks:
        task_id = task["task_id"]
        description = task["description"]
        priority = task["priority"]
        is_mvp = "Oui" if task["is_mvp"] else "Non"
        file_path = task["file_path"]
        
        print(f"- {task_id} (P:{priority}, MVP:{is_mvp}, Fichier:{file_path}): {description}")
    
    # Analyser les tâches par plan
    print("\n=== TÂCHES PRIORITAIRES PAR PLAN ===\n")
    
    for plan in plan_files:
        filename = plan["filename"]
        version = plan["version"]
        
        if version is None:
            continue
        
        tasks = tasks_by_file[filename]
        
        # Filtrer les tâches prioritaires
        priority_tasks = [task for task in tasks if task["is_mvp"] or task["priority"] in ["P0", "P1"]]
        
        if priority_tasks:
            print(f"\nPlan v{version} ({filename}): {len(priority_tasks)} tâches prioritaires")
            
            # Trier par priorité puis par ID
            priority_tasks.sort(key=lambda x: (
                0 if x["priority"] == "P0" else (1 if x["priority"] == "P1" else 2),
                x["task_id"]
            ))
            
            for task in priority_tasks[:10]:  # Limiter à 10 tâches par plan pour la lisibilité
                task_id = task["task_id"]
                description = task["description"]
                priority = task["priority"]
                is_mvp = "Oui" if task["is_mvp"] else "Non"
                
                print(f"- {task_id} (P:{priority}, MVP:{is_mvp}): {description}")
            
            if len(priority_tasks) > 10:
                print(f"... et {len(priority_tasks) - 10} autres tâches")
    
    # Générer un rapport JSON pour une utilisation ultérieure
    report = {
        "statistics": {
            "total_tasks": len(all_tasks),
            "mvp_count": len(mvp_tasks),
            "p0_count": len(p0_tasks),
            "p1_count": len(p1_tasks),
            "foundation_count": len(foundation_tasks),
            "core_count": len(core_tasks),
            "mvp_p0_count": len(mvp_p0_tasks),
            "mvp_p1_count": len(mvp_p1_tasks)
        },
        "tasks_by_file": {filename: [task for task in tasks] for filename, tasks in tasks_by_file.items()},
        "foundation_priority_tasks": foundation_priority_tasks,
        "mvp_tasks": mvp_tasks,
        "p0_tasks": p0_tasks,
        "p1_tasks": p1_tasks
    }
    
    with open("markdown_tasks_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print("\nRapport JSON généré: markdown_tasks_report.json")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
