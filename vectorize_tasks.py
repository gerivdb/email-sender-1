#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import json
import sys
import time
import random
import numpy as np
from datetime import datetime
from qdrant_client import QdrantClient
import requests

def get_markdown_tasks(file_path):
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
            if re.search(r'\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b', description, re.IGNORECASE):
                category = re.search(r'\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b', description, re.IGNORECASE).group(1).lower()
            
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
                "category": category,
                "last_updated": datetime.now().isoformat()
            })
        
        return tasks
    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
        return []

def generate_embedding(text):
    """Générer un embedding pour un texte (simulé pour ce script)"""
    # Dans un cas réel, on utiliserait une API comme OpenAI ou un modèle local
    # Ici, on génère un vecteur aléatoire pour la démonstration
    np.random.seed(hash(text) % 2**32)
    return np.random.normal(0, 1, 1536).tolist()

def main():
    # Paramètres
    roadmap_dir = "projet/roadmaps/plans/consolidated"
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    
    print("Vérification de la connexion à Qdrant...")
    try:
        # Vérifier la connexion à Qdrant
        response = requests.get(f"{qdrant_url}/collections")
        if response.status_code != 200:
            print(f"Erreur de connexion à Qdrant: {response.text}")
            return 1
        
        collections = response.json()["result"]["collections"]
        collection_names = [c["name"] for c in collections]
        
        # Vérifier si la collection existe
        if collection_name not in collection_names:
            print(f"La collection {collection_name} n'existe pas.")
            return 1
        
        print(f"La collection {collection_name} existe.")
        
        # Analyser les fichiers Markdown
        print(f"Analyse des fichiers Markdown dans {roadmap_dir}...")
        files = []
        for root, _, filenames in os.walk(roadmap_dir):
            for filename in filenames:
                if filename.endswith(".md"):
                    files.append(os.path.join(root, filename))
        
        if len(files) == 0:
            print(f"Aucun fichier Markdown trouvé dans {roadmap_dir}")
            return 1
        
        print(f"Nombre de fichiers Markdown trouvés: {len(files)}")
        
        all_tasks = []
        for file_path in files:
            print(f"Analyse du fichier {os.path.basename(file_path)}...")
            tasks = get_markdown_tasks(file_path)
            print(f"  - {len(tasks)} tâches trouvées")
            all_tasks.extend(tasks)
        
        print(f"Nombre total de tâches trouvées: {len(all_tasks)}")
        
        # Vectoriser les tâches
        print("Vectorisation des tâches...")
        points = []
        for i, task in enumerate(all_tasks):
            # Créer un texte enrichi pour l'embedding
            enriched_text = f"ID: {task['task_id']} | Description: {task['description']} | Section: {task['section']} | Status: {task['status']} | Priority: {task['priority']} | Category: {task['category']}"
            
            # Générer l'embedding
            vector = generate_embedding(enriched_text)
            
            # Créer le point
            point = {
                "id": i,
                "vector": vector,
                "payload": {
                    "taskId": task["task_id"],
                    "description": task["description"],
                    "status": task["status"],
                    "indentLevel": task["indent_level"],
                    "parentId": task["parent_id"],
                    "section": task["section"],
                    "isMVP": task["is_mvp"],
                    "priority": task["priority"],
                    "estimatedTime": task["estimated_time"],
                    "category": task["category"],
                    "lastUpdated": task["last_updated"],
                    "filePath": task["file_path"]
                }
            }
            
            points.append(point)
        
        print(f"Nombre de tâches vectorisées: {len(points)}")
        
        # Insérer les points dans Qdrant
        print("Insertion des points dans Qdrant...")
        
        # Insérer les points par lots de 100
        batch_size = 100
        for i in range(0, len(points), batch_size):
            batch = points[i:i+batch_size]
            
            try:
                response = requests.put(
                    f"{qdrant_url}/collections/{collection_name}/points",
                    json={"points": batch},
                    headers={"Content-Type": "application/json"}
                )
                
                if response.status_code != 200:
                    print(f"Erreur lors de l'insertion du lot {i//batch_size + 1}: {response.text}")
                    return 1
                
                print(f"Lot {i//batch_size + 1}/{(len(points) + batch_size - 1) // batch_size} inséré avec succès")
            
            except Exception as e:
                print(f"Exception lors de l'insertion du lot {i//batch_size + 1}: {str(e)}")
                return 1
        
        print(f"Tous les vecteurs ({len(points)}) ont été insérés avec succès")
        
        # Vérifier le nombre de points dans la collection
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"Erreur lors de la récupération des informations sur la collection: {response.text}")
            return 1
        
        collection_info = response.json()["result"]
        # Vérifier si la clé vectors_count existe
        if "vectors_count" in collection_info:
            vector_count = collection_info["vectors_count"]
        else:
            # Essayer d'autres clés possibles
            vector_count = collection_info.get("points_count", 0)
        
        print(f"Nombre de vecteurs dans la collection: {vector_count}")
        
        if vector_count == len(points):
            print("Vectorisation complète: toutes les tâches sont correctement vectorisées.")
        else:
            print(f"Vectorisation incomplète: {vector_count}/{len(points)} tâches vectorisées.")
        
        print("Opération terminée avec succès.")
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
