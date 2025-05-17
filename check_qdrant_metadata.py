#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import requests

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
    
    # Récupérer quelques points pour examiner leur structure
    try:
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "limit": 10,
                "with_payload": True
            }
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de la récupération des points: {response.text}")
            return 1
        
        points = response.json()["result"]["points"]
        
        print("\n=== STRUCTURE DES POINTS DANS QDRANT ===\n")
        
        for i, point in enumerate(points):
            print(f"\nPoint {i+1}:")
            print(f"ID: {point['id']}")
            print("Payload:")
            
            for key, value in point["payload"].items():
                print(f"  {key}: {value}")
        
        # Vérifier les valeurs possibles pour certains champs
        print("\n=== ANALYSE DES MÉTADONNÉES ===\n")
        
        # Récupérer plus de points pour l'analyse
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/scroll",
            json={
                "limit": 1000,
                "with_payload": True
            }
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de la récupération des points pour l'analyse: {response.text}")
            return 1
        
        analysis_points = response.json()["result"]["points"]
        
        # Analyser les valeurs de priorité
        priorities = {}
        for point in analysis_points:
            priority = point["payload"].get("priority", "N/A")
            priorities[priority] = priorities.get(priority, 0) + 1
        
        print("Valeurs de priorité:")
        for priority, count in priorities.items():
            print(f"  {priority}: {count} points")
        
        # Analyser les valeurs de MVP
        mvp_values = {}
        for point in analysis_points:
            is_mvp = point["payload"].get("isMVP", "N/A")
            mvp_values[str(is_mvp)] = mvp_values.get(str(is_mvp), 0) + 1
        
        print("\nValeurs de MVP:")
        for value, count in mvp_values.items():
            print(f"  {value}: {count} points")
        
        # Analyser les valeurs de catégorie
        categories = {}
        for point in analysis_points:
            category = point["payload"].get("category", "N/A")
            categories[category] = categories.get(category, 0) + 1
        
        print("\nValeurs de catégorie (top 10):")
        sorted_categories = sorted(categories.items(), key=lambda x: x[1], reverse=True)
        for category, count in sorted_categories[:10]:
            print(f"  {category}: {count} points")
        
        # Analyser les fichiers source
        files = {}
        for point in analysis_points:
            file_path = point["payload"].get("filePath", "N/A")
            files[file_path] = files.get(file_path, 0) + 1
        
        print("\nFichiers source (top 10):")
        sorted_files = sorted(files.items(), key=lambda x: x[1], reverse=True)
        for file_path, count in sorted_files[:10]:
            print(f"  {file_path}: {count} points")
        
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
