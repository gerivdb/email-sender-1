#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Script d'initialisation de la synchronisation entre le plan de développement v25
et la base vectorielle Qdrant.

Ce script:
1. Extrait toutes les tâches du plan-dev-v25-meta-roadmap-sync.md
2. Génère des embeddings pour chaque tâche
3. Stocke les tâches et leurs embeddings dans la collection Qdrant 'roadmap_tasks'
4. Crée les métadonnées nécessaires pour le suivi et la synchronisation
"""

import os
import re
import sys
import json
import time
import numpy as np
from datetime import datetime
from qdrant_client import QdrantClient
from qdrant_client.http.models import Distance, VectorParams, PointStruct

# Configuration
ROADMAP_DIR = "projet/roadmaps/plans/consolidated"
QDRANT_URL = "http://localhost:6333"
COLLECTION_NAME = "roadmap_tasks"
VECTOR_SIZE = 1536  # Taille des vecteurs d'embedding

def extract_tasks_from_markdown(file_path):
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
            
            # Déterminer la phase d'implémentation
            phase = int(section.split(" ")[0].split(".")[0]) if section.split(" ")[0].split(".")[0].isdigit() else 0
            
            # Déterminer la catégorie
            category = "non_categorise"
            category_match = re.search(r'\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b', description, re.IGNORECASE)
            if category_match:
                category = category_match.group(1).lower()
            
            # Déterminer si c'est une tâche fondamentale ou core
            is_foundation = "fondation" in description.lower() or "foundation" in description.lower() or "fondation" in section.lower() or "foundation" in section.lower()
            is_core = "core" in description.lower() or "core" in section.lower()
            
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
                "phase": phase,
                "category": category,
                "is_foundation": is_foundation,
                "is_core": is_core,
                "last_updated": datetime.now().isoformat()
            })
        
        return tasks
    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
        return []

def generate_embedding(text):
    """Générer un embedding pour un texte (simulé pour ce script)"""
    # Dans un cas réel, on utiliserait une API comme OpenAI ou un modèle local
    # Ici, on génère un vecteur déterministe basé sur le hash du texte
    np.random.seed(hash(text) % 2**32)
    return np.random.normal(0, 1, VECTOR_SIZE).tolist()

def ensure_qdrant_collection(client, collection_name, vector_size):
    """Assurer que la collection Qdrant existe avec la configuration correcte"""
    collections = client.get_collections().collections
    collection_names = [c.name for c in collections]
    
    if collection_name in collection_names:
        print(f"La collection {collection_name} existe déjà.")
        return True
    
    print(f"Création de la collection {collection_name}...")
    client.create_collection(
        collection_name=collection_name,
        vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE)
    )
    print(f"Collection {collection_name} créée avec succès.")
    return True

def store_tasks_in_qdrant(client, collection_name, tasks):
    """Stocker les tâches dans Qdrant"""
    points = []
    
    for i, task in enumerate(tasks):
        # Créer un texte enrichi pour l'embedding
        enriched_text = f"ID: {task['task_id']} | Description: {task['description']} | Section: {task['section']} | Phase: {task['phase']} | Catégorie: {task['category']}"
        
        # Générer l'embedding
        vector = generate_embedding(enriched_text)
        
        # Créer le point
        points.append(PointStruct(
            id=i,
            vector=vector,
            payload=task
        ))
    
    # Insérer les points par lots
    batch_size = 100
    for i in range(0, len(points), batch_size):
        batch = points[i:i+batch_size]
        print(f"Insertion du lot {i//batch_size + 1}/{(len(points) + batch_size - 1) // batch_size}...")
        client.upsert(
            collection_name=collection_name,
            points=batch
        )
    
    print(f"Tous les points ({len(points)}) ont été insérés avec succès.")
    return len(points)

def create_sync_metadata(file_path, tasks_count, vector_count):
    """Créer les métadonnées de synchronisation"""
    metadata = {
        "file_path": file_path,
        "last_sync": datetime.now().isoformat(),
        "tasks_count": tasks_count,
        "vector_count": vector_count,
        "sync_status": "success" if tasks_count == vector_count else "partial",
        "version": "1.0"
    }
    
    metadata_path = os.path.join(os.path.dirname(file_path), ".sync", os.path.basename(file_path) + ".sync.json")
    os.makedirs(os.path.dirname(metadata_path), exist_ok=True)
    
    with open(metadata_path, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"Métadonnées de synchronisation créées: {metadata_path}")
    return metadata

def main():
    # Vérifier que le fichier existe
    file_path = os.path.join(ROADMAP_DIR, "plan-dev-v25-meta-roadmap-sync.md")
    if not os.path.exists(file_path):
        print(f"Erreur: Le fichier {file_path} n'existe pas.")
        return 1
    
    # Extraire les tâches du fichier
    print(f"Extraction des tâches de {file_path}...")
    tasks = extract_tasks_from_markdown(file_path)
    print(f"Nombre de tâches extraites: {len(tasks)}")
    
    if not tasks:
        print("Aucune tâche trouvée dans le fichier.")
        return 1
    
    # Connexion à Qdrant
    try:
        print(f"Connexion à Qdrant ({QDRANT_URL})...")
        client = QdrantClient(url=QDRANT_URL)
        
        # Assurer que la collection existe
        ensure_qdrant_collection(client, COLLECTION_NAME, VECTOR_SIZE)
        
        # Stocker les tâches dans Qdrant
        print("Stockage des tâches dans Qdrant...")
        vector_count = store_tasks_in_qdrant(client, COLLECTION_NAME, tasks)
        
        # Créer les métadonnées de synchronisation
        create_sync_metadata(file_path, len(tasks), vector_count)
        
        print("Initialisation de la synchronisation terminée avec succès.")
        return 0
    
    except Exception as e:
        print(f"Erreur lors de l'initialisation de la synchronisation: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
