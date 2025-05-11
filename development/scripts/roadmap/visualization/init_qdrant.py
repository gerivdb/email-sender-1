#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script pour initialiser la collection Qdrant et y ajouter des données de test
pour la visualisation des roadmaps sous forme de carte de métro.

Ce script crée une collection 'roadmaps' dans Qdrant et y ajoute des exemples
de roadmaps avec des tâches et des dépendances.

Usage:
    python init_qdrant.py

Dépendances:
    - qdrant-client
    - numpy
"""

import json
import uuid
import numpy as np
from qdrant_client import QdrantClient
from qdrant_client.http import models

# Configuration
QDRANT_HOST = "localhost"
QDRANT_PORT = 6333
COLLECTION_NAME = "roadmaps"
VECTOR_SIZE = 512  # Taille des embeddings

def create_random_embedding(size=VECTOR_SIZE):
    """Crée un embedding aléatoire pour simuler un embedding réel."""
    return np.random.rand(size).astype(np.float32) - 0.5

def create_collection():
    """Crée la collection Qdrant pour les roadmaps."""
    client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    
    # Vérifier si la collection existe déjà
    collections = client.get_collections().collections
    collection_names = [collection.name for collection in collections]
    
    if COLLECTION_NAME in collection_names:
        print(f"La collection '{COLLECTION_NAME}' existe déjà. Suppression...")
        client.delete_collection(collection_name=COLLECTION_NAME)
    
    # Créer la collection
    client.create_collection(
        collection_name=COLLECTION_NAME,
        vectors_config=models.VectorParams(
            size=VECTOR_SIZE,
            distance=models.Distance.COSINE
        )
    )
    
    print(f"Collection '{COLLECTION_NAME}' créée avec succès.")
    return client

def create_sample_roadmaps():
    """Crée des exemples de roadmaps pour les tests."""
    roadmaps = [
        {
            "id": "roadmap_1",
            "title": "Développement Frontend",
            "description": "Roadmap pour le développement de l'interface utilisateur",
            "tasks": [
                {
                    "id": "task_1_1",
                    "title": "Conception de l'UI",
                    "description": "Concevoir l'interface utilisateur de l'application",
                    "status": "Terminé",
                    "dependencies": []
                },
                {
                    "id": "task_1_2",
                    "title": "Implémentation des composants React",
                    "description": "Développer les composants React selon la conception",
                    "status": "En cours",
                    "dependencies": ["task_1_1"]
                },
                {
                    "id": "task_1_3",
                    "title": "Intégration avec l'API",
                    "description": "Connecter les composants à l'API backend",
                    "status": "À faire",
                    "dependencies": ["task_1_2"]
                },
                {
                    "id": "task_1_4",
                    "title": "Tests unitaires",
                    "description": "Écrire des tests unitaires pour les composants",
                    "status": "À faire",
                    "dependencies": ["task_1_2"]
                },
                {
                    "id": "task_1_5",
                    "title": "Optimisation des performances",
                    "description": "Optimiser les performances de l'interface utilisateur",
                    "status": "À faire",
                    "dependencies": ["task_1_3", "task_1_4"]
                }
            ]
        },
        {
            "id": "roadmap_2",
            "title": "Développement Backend",
            "description": "Roadmap pour le développement de l'API et des services backend",
            "tasks": [
                {
                    "id": "task_2_1",
                    "title": "Conception de l'API",
                    "description": "Définir les endpoints et les modèles de données",
                    "status": "Terminé",
                    "dependencies": []
                },
                {
                    "id": "task_2_2",
                    "title": "Implémentation des endpoints",
                    "description": "Développer les endpoints de l'API",
                    "status": "En cours",
                    "dependencies": ["task_2_1"]
                },
                {
                    "id": "task_2_3",
                    "title": "Intégration avec l'API",
                    "description": "Connecter l'API aux services externes",
                    "status": "À faire",
                    "dependencies": ["task_2_2"]
                },
                {
                    "id": "task_2_4",
                    "title": "Tests unitaires",
                    "description": "Écrire des tests unitaires pour l'API",
                    "status": "À faire",
                    "dependencies": ["task_2_2"]
                },
                {
                    "id": "task_2_5",
                    "title": "Optimisation des performances",
                    "description": "Optimiser les performances de l'API",
                    "status": "À faire",
                    "dependencies": ["task_2_3", "task_2_4"]
                }
            ]
        },
        {
            "id": "roadmap_3",
            "title": "Infrastructure DevOps",
            "description": "Roadmap pour la mise en place de l'infrastructure et des pipelines CI/CD",
            "tasks": [
                {
                    "id": "task_3_1",
                    "title": "Configuration des environnements",
                    "description": "Configurer les environnements de développement, test et production",
                    "status": "Terminé",
                    "dependencies": []
                },
                {
                    "id": "task_3_2",
                    "title": "Mise en place des pipelines CI/CD",
                    "description": "Configurer les pipelines d'intégration et de déploiement continus",
                    "status": "En cours",
                    "dependencies": ["task_3_1"]
                },
                {
                    "id": "task_3_3",
                    "title": "Tests unitaires",
                    "description": "Intégrer les tests unitaires dans les pipelines",
                    "status": "À faire",
                    "dependencies": ["task_3_2"]
                },
                {
                    "id": "task_3_4",
                    "title": "Monitoring et alerting",
                    "description": "Mettre en place le monitoring et les alertes",
                    "status": "À faire",
                    "dependencies": ["task_3_2"]
                },
                {
                    "id": "task_3_5",
                    "title": "Optimisation des performances",
                    "description": "Optimiser les performances de l'infrastructure",
                    "status": "À faire",
                    "dependencies": ["task_3_3", "task_3_4"]
                }
            ]
        }
    ]
    
    return roadmaps

def add_roadmaps_to_qdrant(client, roadmaps):
    """Ajoute les roadmaps à la collection Qdrant."""
    points = []
    
    for roadmap in roadmaps:
        # Créer un embedding pour la roadmap
        embedding = create_random_embedding()
        
        # Créer un point Qdrant
        point = models.PointStruct(
            id=roadmap["id"],
            vector=embedding.tolist(),
            payload=roadmap
        )
        
        points.append(point)
    
    # Ajouter les points à la collection
    client.upsert(
        collection_name=COLLECTION_NAME,
        points=points
    )
    
    print(f"{len(points)} roadmaps ajoutées à la collection '{COLLECTION_NAME}'.")

def main():
    """Fonction principale."""
    print("Initialisation de la collection Qdrant pour les roadmaps...")
    
    # Créer la collection
    client = create_collection()
    
    # Créer des exemples de roadmaps
    roadmaps = create_sample_roadmaps()
    
    # Ajouter les roadmaps à la collection
    add_roadmaps_to_qdrant(client, roadmaps)
    
    print("Initialisation terminée.")

if __name__ == "__main__":
    main()
