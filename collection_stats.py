#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import requests
import json
from collections import Counter

def main():
    # Configuration
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    
    # Vérifier la connexion à Qdrant
    try:
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
        
        # Récupérer tous les points pour analyser les métadonnées
        if vector_count > 0:
            # Limiter à 1000 points pour éviter les problèmes de mémoire
            limit = min(1000, vector_count)
            
            response = requests.post(
                f"{qdrant_url}/collections/{collection_name}/points/scroll",
                json={"limit": limit, "with_payload": True, "with_vectors": False},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code != 200:
                print(f"Erreur lors de la récupération des points: {response.text}")
                return 1
            
            points = response.json()["result"]["points"]
            
            # Analyser les métadonnées
            status_counts = Counter()
            priority_counts = Counter()
            mvp_counts = Counter()
            category_counts = Counter()
            file_counts = Counter()
            
            for point in points:
                payload = point["payload"]
                status_counts[payload.get("status", "unknown")] += 1
                priority_counts[payload.get("priority", "unknown")] += 1
                mvp_counts[payload.get("isMVP", False)] += 1
                category_counts[payload.get("category", "unknown")] += 1
                file_counts[payload.get("filePath", "unknown")] += 1
            
            print("\nDistribution des statuts:")
            for status, count in status_counts.most_common():
                print(f"- {status}: {count} ({count/len(points)*100:.1f}%)")
            
            print("\nDistribution des priorités:")
            for priority, count in priority_counts.most_common():
                print(f"- {priority}: {count} ({count/len(points)*100:.1f}%)")
            
            print("\nDistribution MVP:")
            for mvp, count in mvp_counts.most_common():
                print(f"- {'Oui' if mvp else 'Non'}: {count} ({count/len(points)*100:.1f}%)")
            
            print("\nDistribution des catégories:")
            for category, count in category_counts.most_common(10):
                print(f"- {category}: {count} ({count/len(points)*100:.1f}%)")
            
            print("\nDistribution par fichier (top 10):")
            for file, count in file_counts.most_common(10):
                print(f"- {file}: {count} ({count/len(points)*100:.1f}%)")
        
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
