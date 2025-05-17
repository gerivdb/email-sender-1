#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import requests

def main():
    # Configuration
    roadmap_dir = "projet/roadmaps/plans/consolidated"
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    
    # Vérifier que le répertoire existe
    if not os.path.exists(roadmap_dir):
        print(f"Erreur: Le répertoire {roadmap_dir} n'existe pas.")
        return 1
    
    # Vérifier la connexion à Qdrant
    try:
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
            print(f"La collection {collection_name} existe déjà.")
            
            # Supprimer la collection existante
            print(f"Suppression de la collection {collection_name}...")
            response = requests.delete(f"{qdrant_url}/collections/{collection_name}")
            if response.status_code != 200:
                print(f"Erreur lors de la suppression de la collection: {response.text}")
                return 1
            
            print(f"Collection {collection_name} supprimée avec succès.")
        
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
    
    except Exception as e:
        print(f"Erreur lors de la vérification de Qdrant: {str(e)}")
        return 1
    
    # Lister les fichiers Markdown dans le répertoire
    files = []
    for root, _, filenames in os.walk(roadmap_dir):
        for filename in filenames:
            if filename.endswith(".md"):
                files.append(os.path.join(root, filename))
    
    if not files:
        print(f"Aucun fichier Markdown trouvé dans {roadmap_dir}")
        return 1
    
    print(f"Nombre de fichiers Markdown trouvés: {len(files)}")
    
    # Traiter chaque fichier
    success_count = 0
    error_count = 0
    
    for file_path in files:
        print(f"\nTraitement du fichier: {os.path.basename(file_path)}")
        
        try:
            # Exécuter le script de vectorisation pour ce fichier
            result = subprocess.run(
                ["python", "vectorize_single_file.py", file_path],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"Succès: {os.path.basename(file_path)}")
                success_count += 1
            else:
                print(f"Erreur lors du traitement de {os.path.basename(file_path)}:")
                print(result.stderr)
                error_count += 1
        
        except Exception as e:
            print(f"Exception lors du traitement de {os.path.basename(file_path)}: {str(e)}")
            error_count += 1
    
    # Vérifier le nombre de points dans la collection
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
        
        print(f"\nRésumé de la vectorisation:")
        print(f"- Fichiers traités avec succès: {success_count}/{len(files)}")
        print(f"- Fichiers en erreur: {error_count}/{len(files)}")
        print(f"- Nombre total de vecteurs dans la collection: {vector_count}")
        
        return 0
    
    except Exception as e:
        print(f"Erreur lors de la vérification finale: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
