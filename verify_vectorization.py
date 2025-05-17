#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import requests
import json
from collections import Counter

def main():
    # Configuration
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    roadmap_dir = "projet/roadmaps/plans/consolidated"
    
    # Vérifier la connexion à Qdrant
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
        
        # Récupérer les informations sur la collection
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
        
        print(f"Informations sur la collection {collection_name}:")
        print(f"- Nombre total de vecteurs: {vector_count}")
        
        # Compter les tâches dans les fichiers Markdown
        markdown_tasks = []
        files = []
        for root, _, filenames in os.walk(roadmap_dir):
            for filename in filenames:
                if filename.endswith(".md"):
                    file_path = os.path.join(root, filename)
                    files.append(file_path)
                    
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        # Extraire les tâches avec regex
                        task_pattern = r'- \[([ xX])\]\s+(?:\*\*)?(\d+(?:\.\d+)*)(?:\*\*)?\s+(.*?)(?:\r?\n|$)'
                        matches = re.finditer(task_pattern, content)
                        
                        for match in matches:
                            status = match.group(1)
                            task_id = match.group(2)
                            description = match.group(3).strip()
                            
                            markdown_tasks.append({
                                "task_id": task_id,
                                "description": description,
                                "status": "completed" if status in ['x', 'X'] else "pending",
                                "file_path": os.path.basename(file_path)
                            })
                    except Exception as e:
                        print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
        
        print(f"- Nombre de fichiers Markdown: {len(files)}")
        print(f"- Nombre de tâches dans les fichiers Markdown: {len(markdown_tasks)}")
        
        # Calculer le taux de vectorisation
        vectorization_rate = (vector_count / len(markdown_tasks)) * 100 if len(markdown_tasks) > 0 else 0
        print(f"- Taux de vectorisation: {vectorization_rate:.2f}%")
        
        # Récupérer un échantillon de points pour vérifier les métadonnées
        if vector_count > 0:
            # Limiter à 10 points pour l'exemple
            limit = min(10, vector_count)
            
            response = requests.post(
                f"{qdrant_url}/collections/{collection_name}/points/scroll",
                json={"limit": limit, "with_payload": True, "with_vectors": False},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code != 200:
                print(f"Erreur lors de la récupération des points: {response.text}")
                return 1
            
            points = response.json()["result"]["points"]
            
            print("\nÉchantillon de points vectorisés:")
            for i, point in enumerate(points):
                payload = point["payload"]
                print(f"\n{i+1}. ID: {payload.get('taskId', 'N/A')}")
                print(f"   Description: {payload.get('description', 'N/A')}")
                print(f"   Statut: {payload.get('status', 'N/A')}")
                print(f"   Priorité: {payload.get('priority', 'N/A')}")
                print(f"   MVP: {'Oui' if payload.get('isMVP', False) else 'Non'}")
                print(f"   Catégorie: {payload.get('category', 'N/A')}")
                print(f"   Fichier: {payload.get('filePath', 'N/A')}")
        
        # Vérifier que tous les champs nécessaires sont présents
        print("\nVérification des champs nécessaires:")
        required_fields = ["taskId", "description", "status", "isMVP", "priority", "category", "estimatedTime"]
        
        if vector_count > 0:
            # Récupérer un point pour vérifier les champs
            response = requests.post(
                f"{qdrant_url}/collections/{collection_name}/points/scroll",
                json={"limit": 1, "with_payload": True, "with_vectors": False},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code != 200:
                print(f"Erreur lors de la récupération des points: {response.text}")
                return 1
            
            points = response.json()["result"]["points"]
            
            if points:
                payload = points[0]["payload"]
                for field in required_fields:
                    if field in payload:
                        print(f"- {field}: Présent ✓")
                    else:
                        print(f"- {field}: Manquant ✗")
            else:
                print("Aucun point trouvé pour vérifier les champs.")
        
        print("\nConclusion:")
        if vectorization_rate >= 99.5:
            print("✅ Vectorisation complète (100%) réussie!")
        elif vectorization_rate >= 90:
            print("⚠️ Vectorisation presque complète (>90%). Quelques tâches pourraient manquer.")
        else:
            print("❌ Vectorisation incomplète (<90%). De nombreuses tâches sont manquantes.")
        
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
