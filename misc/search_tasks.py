#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import numpy as np
import requests
import json

def main():
    # Configuration
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    
    # Vérifier les arguments
    if len(sys.argv) < 2:
        print("Usage: python search_tasks.py <requête> [filtre]")
        print("Exemples de filtres: --mvp, --priority=P0, --category=backend")
        return 1
    
    query = sys.argv[1]
    
    # Traiter les filtres
    filters = []
    for arg in sys.argv[2:]:
        if arg == "--mvp":
            filters.append({"key": "isMVP", "match": {"value": True}})
        elif arg.startswith("--priority="):
            priority = arg.split("=")[1]
            filters.append({"key": "priority", "match": {"value": priority}})
        elif arg.startswith("--category="):
            category = arg.split("=")[1]
            filters.append({"key": "category", "match": {"value": category}})
        elif arg.startswith("--status="):
            status = arg.split("=")[1]
            filters.append({"key": "status", "match": {"value": status}})
    
    # Générer un vecteur pour la requête (simulé ici)
    np.random.seed(hash(query) % 2**32)
    vector = np.random.normal(0, 1, 1536).tolist()
    
    # Préparer la requête de recherche
    search_body = {
        "vector": vector,
        "limit": 10,
        "with_payload": True,
        "with_vectors": False
    }
    
    # Ajouter les filtres si nécessaire
    if filters:
        search_body["filter"] = {
            "must": filters
        }
    
    # Effectuer la recherche
    try:
        response = requests.post(
            f"{qdrant_url}/collections/{collection_name}/points/search",
            json=search_body,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code != 200:
            print(f"Erreur lors de la recherche: {response.text}")
            return 1
        
        results = response.json()["result"]
        
        print(f"Résultats de recherche pour '{query}':")
        print(f"Nombre de résultats: {len(results)}")
        
        if not results:
            print("Aucun résultat trouvé.")
            return 0
        
        print("\nRésultats:")
        for i, result in enumerate(results):
            print(f"\n{i+1}. Score: {result['score']:.4f}")
            print(f"   ID: {result['payload']['taskId']}")
            print(f"   Description: {result['payload']['description']}")
            print(f"   Statut: {result['payload']['status']}")
            print(f"   Priorité: {result['payload']['priority']}")
            print(f"   MVP: {'Oui' if result['payload']['isMVP'] else 'Non'}")
            print(f"   Catégorie: {result['payload']['category']}")
            print(f"   Fichier: {result['payload']['filePath']}")
        
        return 0
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
