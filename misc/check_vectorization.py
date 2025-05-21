#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import json
import sys
from datetime import datetime
from qdrant_client import QdrantClient

def get_markdown_tasks(file_path):
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
            
            tasks.append({
                "task_id": task_id,
                "description": description,
                "status": "completed" if status in ['x', 'X'] else "pending",
                "indent_level": indent_level,
                "parent_id": parent_id,
                "section": section,
                "file_path": file_path,
                "is_mvp": is_mvp,
                "priority": priority
            })
        
        return tasks
    except Exception as e:
        print(f"Erreur lors de l'analyse du fichier {file_path}: {str(e)}")
        return []

def check_qdrant_connection(qdrant_url):
    """Vérifier la connexion à Qdrant"""
    try:
        client = QdrantClient(url=qdrant_url)
        client.get_collections()
        return True, client
    except Exception as e:
        print(f"Erreur de connexion à Qdrant: {str(e)}")
        return False, None

def check_qdrant_collection(client, collection_name):
    """Vérifier si une collection existe"""
    try:
        collections = client.get_collections().collections
        collection_names = [c.name for c in collections]
        return collection_name in collection_names
    except Exception as e:
        print(f"Erreur lors de la vérification de la collection: {str(e)}")
        return False

def create_qdrant_collection(client, collection_name, vector_size=1536):
    """Créer une collection Qdrant"""
    try:
        client.create_collection(
            collection_name=collection_name,
            vectors_config={
                "size": vector_size,
                "distance": "Cosine"
            }
        )
        return True
    except Exception as e:
        print(f"Erreur lors de la création de la collection: {str(e)}")
        return False

def get_qdrant_collection_count(client, collection_name):
    """Compter les points dans une collection"""
    try:
        collection_info = client.get_collection(collection_name)
        return collection_info.vectors_count
    except Exception as e:
        print(f"Erreur lors du comptage des points: {str(e)}")
        return 0

def get_qdrant_tasks(client, collection_name):
    """Récupérer les tâches vectorisées dans Qdrant"""
    try:
        collection_info = client.get_collection(collection_name)
        vectors_count = collection_info.vectors_count
        
        if vectors_count == 0:
            return []
        
        # Récupérer tous les points
        scroll_result = client.scroll(
            collection_name=collection_name,
            limit=vectors_count,
            with_payload=True,
            with_vectors=False
        )
        
        points = scroll_result[0]
        
        # Extraire les tâches
        tasks = []
        for point in points:
            if "taskId" in point.payload:
                task = {
                    "task_id": point.payload["taskId"],
                    "description": point.payload.get("description", ""),
                    "status": point.payload.get("status", ""),
                    "qdrant_id": point.id
                }
                tasks.append(task)
        
        return tasks
    except Exception as e:
        print(f"Erreur lors de la récupération des tâches: {str(e)}")
        return []

def main():
    # Paramètres
    roadmap_dir = "projet/roadmaps/plans/consolidated"
    qdrant_url = "http://localhost:6333"
    collection_name = "roadmap_tasks"
    create_collection = True
    
    # Vérifier la connexion à Qdrant
    print("Vérification de la connexion à Qdrant...")
    connected, client = check_qdrant_connection(qdrant_url)
    
    if not connected:
        print("Impossible de se connecter à Qdrant. Vérifiez que le conteneur est en cours d'exécution.")
        return 1
    
    print("Connexion à Qdrant établie.")
    
    # Vérifier l'existence de la collection
    print(f"Vérification de l'existence de la collection {collection_name}...")
    collection_exists = check_qdrant_collection(client, collection_name)
    
    if not collection_exists:
        if create_collection:
            print(f"Création de la collection {collection_name}...")
            result = create_qdrant_collection(client, collection_name)
            
            if not result:
                print("Échec de la création de la collection.")
                return 1
            
            print(f"Collection {collection_name} créée avec succès.")
        else:
            print(f"La collection {collection_name} n'existe pas.")
            
            # Lister les collections existantes
            collections = client.get_collections().collections
            collection_names = [c.name for c in collections]
            
            print("Collections existantes:")
            for coll in collection_names:
                print(f"- {coll}")
            
            return 1
    else:
        print(f"Collection {collection_name} trouvée.")
        vector_count = get_qdrant_collection_count(client, collection_name)
        print(f"Nombre de vecteurs dans la collection: {vector_count}")
    
    # Analyser les fichiers Markdown
    print(f"Analyse des fichiers Markdown dans {roadmap_dir}...")
    files = []
    for root, _, filenames in os.walk(roadmap_dir):
        for filename in filenames:
            if filename.endswith(".md"):
                files.append(os.path.join(root, filename))
    
    if len(files) == 0:
        print(f"Aucun fichier Markdown trouvé dans {roadmap_dir}")
        return 1
    
    print(f"Nombre de fichiers Markdown trouvés: {len(files)}")
    
    all_tasks = []
    for file_path in files:
        print(f"Analyse du fichier {os.path.basename(file_path)}...")
        tasks = get_markdown_tasks(file_path)
        print(f"  - {len(tasks)} tâches trouvées")
        all_tasks.extend(tasks)
    
    print(f"Nombre total de tâches trouvées: {len(all_tasks)}")
    
    # Récupérer les tâches vectorisées dans Qdrant
    print("Récupération des tâches vectorisées dans Qdrant...")
    qdrant_tasks = get_qdrant_tasks(client, collection_name)
    
    print(f"Nombre de tâches vectorisées dans Qdrant: {len(qdrant_tasks)}")
    
    # Comparer les tâches
    markdown_task_ids = [task["task_id"] for task in all_tasks]
    qdrant_task_ids = [task["task_id"] for task in qdrant_tasks]
    
    missing_tasks = [task_id for task_id in markdown_task_ids if task_id not in qdrant_task_ids]
    extra_tasks = [task_id for task_id in qdrant_task_ids if task_id not in markdown_task_ids]
    
    if len(missing_tasks) == 0 and len(extra_tasks) == 0:
        print("Vectorisation complète: toutes les tâches sont correctement vectorisées.")
        verification_status = "SUCCESS"
    else:
        if len(missing_tasks) > 0:
            print(f"Tâches manquantes dans Qdrant: {len(missing_tasks)}")
            print(f"Exemples de tâches manquantes: {missing_tasks[:5]}")
        
        if len(extra_tasks) > 0:
            print(f"Tâches supplémentaires dans Qdrant: {len(extra_tasks)}")
            print(f"Exemples de tâches supplémentaires: {extra_tasks[:5]}")
        
        verification_status = "FAILURE"
    
    # Générer un rapport détaillé
    report_path = "projet/roadmaps/analysis/vectorization_report.md"
    report_dir = os.path.dirname(report_path)
    
    if not os.path.exists(report_dir):
        os.makedirs(report_dir, exist_ok=True)
    
    vector_count = get_qdrant_collection_count(client, collection_name)
    percentage = round((vector_count / len(all_tasks)) * 100, 2) if len(all_tasks) > 0 else 0
    
    report = f"""# Rapport de diagnostic de vectorisation
*Généré le {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*

## Résumé

- **Statut de la vérification**: {verification_status}
- **Nombre total de fichiers Markdown**: {len(files)}
- **Nombre total de tâches**: {len(all_tasks)}
- **Nombre de vecteurs dans Qdrant**: {vector_count}
- **Taux de vectorisation**: {percentage}%
- **Tâches manquantes dans Qdrant**: {len(missing_tasks)}
- **Tâches supplémentaires dans Qdrant**: {len(extra_tasks)}

## Détails par fichier

| Fichier | Nombre de tâches | Tâches MVP | Tâches P0 | Tâches P1 | Tâches P2 | Tâches P3 |
|---------|-----------------|------------|-----------|-----------|-----------|-----------|
"""
    
    for file_path in files:
        file_tasks = [task for task in all_tasks if task["file_path"] == file_path]
        mvp_count = len([task for task in file_tasks if task["is_mvp"]])
        p0_count = len([task for task in file_tasks if task["priority"] == "P0"])
        p1_count = len([task for task in file_tasks if task["priority"] == "P1"])
        p2_count = len([task for task in file_tasks if task["priority"] == "P2"])
        p3_count = len([task for task in file_tasks if task["priority"] == "P3"])
        
        report += f"\n| {os.path.basename(file_path)} | {len(file_tasks)} | {mvp_count} | {p0_count} | {p1_count} | {p2_count} | {p3_count} |"
    
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(report)
    
    print(f"Rapport de diagnostic généré: {report_path}")
    
    return 0 if verification_status == "SUCCESS" else 1

if __name__ == "__main__":
    sys.exit(main())
