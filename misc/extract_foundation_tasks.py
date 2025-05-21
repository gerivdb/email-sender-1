#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import requests
from collections import defaultdict

def main():
    # Configuration
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    
    # Vérifier que la collection existe
    try:
        response = requests.get(f"{qdrant_url}/collections")
        if response.status_code != 200:
            print(f"Erreur de connexion à Qdrant: {response.text}")
            return 1
        
        collections = response.json()["result"]["collections"]
        collection_names = [c["name"] for c in collections]
        
        if collection_name not in collection_names:
            print(f"La collection {collection_name} n'existe pas.")
            return 1
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1
    
    # Extraire les tâches MVP et prioritaires
    try:
        # Tâches MVP
        mvp_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "filter": {
                    "must": [
                        {"key": "isMVP", "match": {"value": True}}
                    ]
                },
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if mvp_response.status_code != 200:
            print(f"Erreur lors de l'extraction des tâches MVP: {mvp_response.text}")
            return 1
        
        mvp_points = mvp_response.json()["result"]["points"]
        
        # Tâches P0
        p0_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "filter": {
                    "must": [
                        {"key": "priority", "match": {"value": "P0"}}
                    ]
                },
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if p0_response.status_code != 200:
            print(f"Erreur lors de l'extraction des tâches P0: {p0_response.text}")
            return 1
        
        p0_points = p0_response.json()["result"]["points"]
        
        # Tâches P1
        p1_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "filter": {
                    "must": [
                        {"key": "priority", "match": {"value": "P1"}}
                    ]
                },
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if p1_response.status_code != 200:
            print(f"Erreur lors de l'extraction des tâches P1: {p1_response.text}")
            return 1
        
        p1_points = p1_response.json()["result"]["points"]
        
        # Tâches fondamentales (contenant "fondation" ou "foundation" dans la description)
        foundation_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "filter": {
                    "should": [
                        {"key": "description", "match": {"value": "fondation"}},
                        {"key": "description", "match": {"value": "foundation"}},
                        {"key": "section", "match": {"value": "fondation"}},
                        {"key": "section", "match": {"value": "foundation"}}
                    ]
                },
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if foundation_response.status_code != 200:
            print(f"Erreur lors de l'extraction des tâches fondamentales: {foundation_response.text}")
            return 1
        
        foundation_points = foundation_response.json()["result"]["points"]
        
        # Tâches core (contenant "core" dans la description)
        core_response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "filter": {
                    "should": [
                        {"key": "description", "match": {"value": "core"}},
                        {"key": "section", "match": {"value": "core"}}
                    ]
                },
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if core_response.status_code != 200:
            print(f"Erreur lors de l'extraction des tâches core: {core_response.text}")
            return 1
        
        core_points = core_response.json()["result"]["points"]
        
        # Statistiques
        print("\n=== STATISTIQUES DES TÂCHES PRIORITAIRES ===\n")
        print(f"Nombre de tâches MVP: {len(mvp_points)}")
        print(f"Nombre de tâches P0: {len(p0_points)}")
        print(f"Nombre de tâches P1: {len(p1_points)}")
        print(f"Nombre de tâches fondamentales: {len(foundation_points)}")
        print(f"Nombre de tâches core: {len(core_points)}")
        
        # Identifier les tâches qui sont à la fois MVP et P0/P1
        mvp_task_ids = set(point["payload"]["taskId"] for point in mvp_points)
        p0_task_ids = set(point["payload"]["taskId"] for point in p0_points)
        p1_task_ids = set(point["payload"]["taskId"] for point in p1_points)
        
        mvp_p0_tasks = mvp_task_ids.intersection(p0_task_ids)
        mvp_p1_tasks = mvp_task_ids.intersection(p1_task_ids)
        
        print(f"\nNombre de tâches à la fois MVP et P0: {len(mvp_p0_tasks)}")
        print(f"Nombre de tâches à la fois MVP et P1: {len(mvp_p1_tasks)}")
        
        # Regrouper les tâches par fichier source
        tasks_by_file = defaultdict(list)
        
        # Combiner toutes les tâches prioritaires
        all_priority_points = []
        all_priority_points.extend(mvp_points)
        all_priority_points.extend(p0_points)
        all_priority_points.extend(p1_points)
        
        # Éliminer les doublons
        unique_priority_tasks = {}
        for point in all_priority_points:
            task_id = point["payload"]["taskId"]
            if task_id not in unique_priority_tasks:
                unique_priority_tasks[task_id] = point
        
        # Regrouper par fichier
        for task_id, point in unique_priority_tasks.items():
            file_path = point["payload"].get("filePath", "unknown")
            tasks_by_file[file_path].append(point["payload"])
        
        # Afficher les tâches prioritaires par fichier
        print("\n=== TÂCHES PRIORITAIRES PAR FICHIER ===\n")
        
        for file_path, tasks in tasks_by_file.items():
            print(f"\nFichier: {file_path} ({len(tasks)} tâches prioritaires)")
            
            # Trier les tâches par ID
            tasks.sort(key=lambda x: x["taskId"])
            
            for task in tasks[:10]:  # Limiter à 10 tâches par fichier pour la lisibilité
                task_id = task["taskId"]
                description = task["description"]
                priority = task.get("priority", "N/A")
                is_mvp = "Oui" if task.get("isMVP", False) else "Non"
                
                print(f"- {task_id} (P:{priority}, MVP:{is_mvp}): {description}")
            
            if len(tasks) > 10:
                print(f"... et {len(tasks) - 10} autres tâches")
        
        # Identifier les tâches fondamentales les plus importantes
        print("\n=== TÂCHES FONDAMENTALES PRIORITAIRES ===\n")
        
        foundation_priority_tasks = []
        for point in foundation_points:
            task_id = point["payload"]["taskId"]
            if task_id in mvp_task_ids or task_id in p0_task_ids or task_id in p1_task_ids:
                foundation_priority_tasks.append(point["payload"])
        
        # Trier par priorité puis par ID
        foundation_priority_tasks.sort(key=lambda x: (
            0 if x.get("priority", "") == "P0" else (1 if x.get("priority", "") == "P1" else 2),
            x["taskId"]
        ))
        
        for task in foundation_priority_tasks:
            task_id = task["taskId"]
            description = task["description"]
            priority = task.get("priority", "N/A")
            is_mvp = "Oui" if task.get("isMVP", False) else "Non"
            file_path = task.get("filePath", "unknown")
            
            print(f"- {task_id} (P:{priority}, MVP:{is_mvp}, Fichier:{file_path}): {description}")
        
        # Générer un rapport JSON pour une utilisation ultérieure
        report = {
            "statistics": {
                "mvp_count": len(mvp_points),
                "p0_count": len(p0_points),
                "p1_count": len(p1_points),
                "foundation_count": len(foundation_points),
                "core_count": len(core_points),
                "mvp_p0_count": len(mvp_p0_tasks),
                "mvp_p1_count": len(mvp_p1_tasks)
            },
            "priority_tasks_by_file": {file_path: [task for task in tasks] for file_path, tasks in tasks_by_file.items()},
            "foundation_priority_tasks": foundation_priority_tasks
        }
        
        with open("priority_tasks_report.json", "w", encoding="utf-8") as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        
        print("\nRapport JSON généré: priority_tasks_report.json")
        
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
