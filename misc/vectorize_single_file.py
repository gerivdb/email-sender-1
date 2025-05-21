#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import numpy as np
from datetime import datetime
import requests

def main():
    # Vérifier les arguments
    if len(sys.argv) < 2:
        print("Usage: python vectorize_single_file.py <chemin_du_fichier>")
        return 1

    # Configuration
    file_path = sys.argv[1]  # Chemin du fichier à traiter
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"

    print(f"Traitement du fichier: {file_path}")

    # Vérifier que le fichier existe
    if not os.path.exists(file_path):
        print(f"Erreur: Le fichier {file_path} n'existe pas.")
        return 1

    # Vérifier la connexion à Qdrant
    try:
        response = requests.get(f"{qdrant_url}/collections")
        if response.status_code != 200:
            print(f"Erreur de connexion à Qdrant: {response.text}")
            return 1

        collections = response.json()["result"]["collections"]
        collection_names = [c["name"] for c in collections]

        # Vérifier si la collection existe
        if collection_name not in collection_names:
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

    # Extraire les tâches du fichier
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
            category_match = re.search(r'\b(backend|frontend|infrastructure|api|database|ui|ux|test|doc)\b', description, re.IGNORECASE)
            if category_match:
                category = category_match.group(1).lower()

            # Créer un vecteur (simulé ici)
            np.random.seed(hash(task_id + description) % 2**32)
            vector = np.random.normal(0, 1, 1536).tolist()

            # Créer le point
            point = {
                "id": int(hash(task_id) % 2**31),
                "vector": vector,
                "payload": {
                    "taskId": task_id,
                    "description": description,
                    "status": "completed" if status in ['x', 'X'] else "pending",
                    "indentLevel": indent_level,
                    "parentId": parent_id,
                    "section": section,
                    "isMVP": is_mvp,
                    "priority": priority,
                    "estimatedTime": estimated_time,
                    "category": category,
                    "lastUpdated": datetime.now().isoformat(),
                    "filePath": os.path.basename(file_path)
                }
            }

            tasks.append(point)

        print(f"Nombre de tâches extraites: {len(tasks)}")

        if not tasks:
            print("Aucune tâche trouvée dans le fichier.")
            return 0

        # Insérer les points dans Qdrant par lots
        print("Insertion des points dans Qdrant par lots...")

        # Taille de lot maximale
        batch_size = 100
        total_batches = (len(tasks) + batch_size - 1) // batch_size

        for i in range(0, len(tasks), batch_size):
            batch = tasks[i:i+batch_size]
            batch_num = i // batch_size + 1

            print(f"Traitement du lot {batch_num}/{total_batches} ({len(batch)} tâches)...")

            response = requests.put(
                f"{qdrant_url}/collections/{collection_name}/points",
                json={"points": batch},
                headers={"Content-Type": "application/json"}
            )

            if response.status_code != 200:
                print(f"Erreur lors de l'insertion du lot {batch_num}: {response.text}")
                return 1

            print(f"Lot {batch_num}/{total_batches} inséré avec succès")

        print(f"Vectorisation réussie: {len(tasks)} tâches insérées dans Qdrant.")
        return 0

    except Exception as e:
        print(f"Erreur lors du traitement du fichier: {str(e)}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
