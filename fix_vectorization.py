#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import json
import sys
import time
from datetime import datetime
from qdrant_client import QdrantClient
import requests

def main():
    # Paramètres
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    vector_size = 1536

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
            print(f"La collection {collection_name} existe déjà.")

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

            print(f"Nombre de vecteurs dans la collection: {vector_count}")

            # Supprimer la collection existante
            print(f"Suppression de la collection {collection_name}...")
            response = requests.delete(f"{qdrant_url}/collections/{collection_name}")
            if response.status_code != 200:
                print(f"Erreur lors de la suppression de la collection: {response.text}")
                return 1

            print(f"Collection {collection_name} supprimée avec succès.")

            # Attendre un peu pour s'assurer que la collection est bien supprimée
            time.sleep(2)

        # Créer la collection
        print(f"Création de la collection {collection_name}...")
        payload = {
            "vectors": {
                "size": vector_size,
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

        # Vérifier que la collection a bien été créée
        response = requests.get(f"{qdrant_url}/collections")
        if response.status_code != 200:
            print(f"Erreur lors de la vérification des collections: {response.text}")
            return 1

        collections = response.json()["result"]["collections"]
        collection_names = [c["name"] for c in collections]

        if collection_name in collection_names:
            print(f"La collection {collection_name} a bien été créée.")
        else:
            print(f"La collection {collection_name} n'a pas été créée correctement.")
            return 1

        print("Opération terminée avec succès.")
        return 0

    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
