#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import json
import sys
import requests
import numpy as np

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
        
        print("Collections existantes:")
        for coll in collection_names:
            print(f"- {coll}")
        
        # Vérifier si la collection existe
        if collection_name in collection_names:
            print(f"La collection {collection_name} existe.")
            
            # Récupérer les informations sur la collection
            response = requests.get(f"{qdrant_url}/collections/{collection_name}")
            if response.status_code != 200:
                print(f"Erreur lors de la récupération des informations sur la collection: {response.text}")
                return 1
            
            collection_info = response.json()["result"]
            vector_count = collection_info.get("vectors_count", 0)
            
            print(f"Nombre de vecteurs dans la collection: {vector_count}")
        else:
            print(f"La collection {collection_name} n'existe pas.")
            
            # Créer la collection
            print(f"Création de la collection {collection_name}...")
            payload = {
                "vectors": {
                    "size": 1536,
                    "distance": "Cosine"
                }
            }
            
            response = requests.put(
                f"{qdrant_url}/collections/{collection_name}",
                json=payload
            )
            
            if response.status_code != 200:
                print(f"Erreur lors de la création de la collection: {response.text}")
                return 1
            
            print(f"Collection {collection_name} créée avec succès.")
        
        # Créer un point de test
        print("Création d'un point de test...")
        
        # Générer un vecteur aléatoire
        np.random.seed(42)
        vector = np.random.normal(0, 1, 1536).tolist()
        
        # Créer le point
        point = {
            "id": 0,
            "vector": vector,
            "payload": {
                "taskId": "0.0.0",
                "description": "Point de test",
                "status": "pending",
                "indentLevel": 3,
                "parentId": "0.0",
                "section": "Test",
                "isMVP": True,
                "priority": "P0",
                "estimatedTime": "1h",
                "category": "test",
                "lastUpdated": "2025-05-30T12:00:00Z"
            }
        }
        
        # Insérer le point dans Qdrant
        response = requests.put(
            f"{qdrant_url}/collections/{collection_name}/points",
            json={"points": [point]},
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de l'insertion du point de test: {response.text}")
            return 1
        
        print("Point de test inséré avec succès.")
        
        # Vérifier le nombre de points dans la collection
        response = requests.get(f"{qdrant_url}/collections/{collection_name}")
        if response.status_code != 200:
            print(f"Erreur lors de la récupération des informations sur la collection: {response.text}")
            return 1
        
        collection_info = response.json()["result"]
        vector_count = collection_info.get("vectors_count", 0)
        
        print(f"Nombre de vecteurs dans la collection après insertion: {vector_count}")
        
        print("Opération terminée avec succès.")
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
