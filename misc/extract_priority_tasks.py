#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from qdrant_client import QdrantClient
from qdrant_client.http.models import Filter, FieldCondition, MatchValue, Range

def main():
    # Connexion à Qdrant
    client = QdrantClient(host='localhost', port=6333)
    collection_name = 'roadmap_tasks'

    # Vérifier que la collection existe
    collections = client.get_collections().collections
    collection_names = [c.name for c in collections]

    if collection_name not in collection_names:
        print(f"La collection {collection_name} n'existe pas.")
        return 1

    # Extraire les tâches MVP
    print("\n=== TÂCHES MVP (10 premières) ===\n")
    mvp_filter = Filter(
        must=[
            FieldCondition(
                key="isMVP",
                match=MatchValue(value=True)
            )
        ]
    )

    mvp_response = client.scroll(
        collection_name=collection_name,
        scroll_filter=mvp_filter,
        limit=10,
        with_payload=True
    )

    for point in mvp_response[0]:
        task_id = point.payload.get('taskId', 'N/A')
        description = point.payload.get('description', 'N/A')
        file_path = point.payload.get('filePath', 'N/A')
        print(f"- {task_id}: {description} (Fichier: {file_path})")

    # Extraire les tâches P0
    print("\n=== TÂCHES PRIORITÉ P0 (10 premières) ===\n")
    p0_filter = Filter(
        must=[
            FieldCondition(
                key="priority",
                match=MatchValue(value="P0")
            )
        ]
    )

    p0_response = client.scroll(
        collection_name=collection_name,
        scroll_filter=p0_filter,
        limit=10,
        with_payload=True
    )

    for point in p0_response[0]:
        task_id = point.payload.get('taskId', 'N/A')
        description = point.payload.get('description', 'N/A')
        file_path = point.payload.get('filePath', 'N/A')
        print(f"- {task_id}: {description} (Fichier: {file_path})")

    # Extraire les tâches P1
    print("\n=== TÂCHES PRIORITÉ P1 (10 premières) ===\n")
    p1_filter = Filter(
        must=[
            FieldCondition(
                key="priority",
                match=MatchValue(value="P1")
            )
        ]
    )

    p1_response = client.scroll(
        collection_name=collection_name,
        scroll_filter=p1_filter,
        limit=10,
        with_payload=True
    )

    for point in p1_response[0]:
        task_id = point.payload.get('taskId', 'N/A')
        description = point.payload.get('description', 'N/A')
        file_path = point.payload.get('filePath', 'N/A')
        print(f"- {task_id}: {description} (Fichier: {file_path})")

    # Extraire les tâches fondamentales (contenant "fondation" ou "foundation" dans la description)
    print("\n=== TÂCHES FONDAMENTALES (10 premières) ===\n")
    foundation_filter = Filter(
        should=[
            FieldCondition(
                key="description",
                match=MatchValue(value="fondation")
            ),
            FieldCondition(
                key="description",
                match=MatchValue(value="foundation")
            ),
            FieldCondition(
                key="section",
                match=MatchValue(value="fondation")
            ),
            FieldCondition(
                key="section",
                match=MatchValue(value="foundation")
            )
        ]
    )

    foundation_response = client.scroll(
        collection_name=collection_name,
        scroll_filter=foundation_filter,
        limit=10,
        with_payload=True
    )

    for point in foundation_response[0]:
        task_id = point.payload.get('taskId', 'N/A')
        description = point.payload.get('description', 'N/A')
        file_path = point.payload.get('filePath', 'N/A')
        print(f"- {task_id}: {description} (Fichier: {file_path})")

    # Extraire les tâches de base (contenant "core" dans la description)
    print("\n=== TÂCHES CORE (10 premières) ===\n")
    core_filter = Filter(
        should=[
            FieldCondition(
                key="description",
                match=MatchValue(value="core")
            ),
            FieldCondition(
                key="section",
                match=MatchValue(value="core")
            )
        ]
    )

    core_response = client.scroll(
        collection_name=collection_name,
        scroll_filter=core_filter,
        limit=10,
        with_payload=True
    )

    for point in core_response[0]:
        task_id = point.payload.get('taskId', 'N/A')
        description = point.payload.get('description', 'N/A')
        file_path = point.payload.get('filePath', 'N/A')
        print(f"- {task_id}: {description} (Fichier: {file_path})")

    return 0

if __name__ == "__main__":
    sys.exit(main())
