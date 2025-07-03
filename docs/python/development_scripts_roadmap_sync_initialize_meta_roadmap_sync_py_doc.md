Help on module initialize_meta_roadmap_sync:

NAME
    initialize_meta_roadmap_sync

DESCRIPTION
    Script d'initialisation de la synchronisation entre le plan de développement v25
    et la base vectorielle Qdrant.

    Ce script:
    1. Extrait toutes les tâches du plan-dev-v25-meta-roadmap-sync.md
    2. Génère des embeddings pour chaque tâche
    3. Stocke les tâches et leurs embeddings dans la collection Qdrant 'roadmap_tasks'
    4. Crée les métadonnées nécessaires pour le suivi et la synchronisation

FUNCTIONS
    create_sync_metadata(file_path, tasks_count, vector_count)
        Créer les métadonnées de synchronisation

    ensure_qdrant_collection(client, collection_name, vector_size)
        Assurer que la collection Qdrant existe avec la configuration correcte

    extract_tasks_from_markdown(file_path)
        Extraire les tâches d'un fichier Markdown

    generate_embedding(text)
        Générer un embedding pour un texte (simulé pour ce script)

    main()

    store_tasks_in_qdrant(client, collection_name, tasks)
        Stocker les tâches dans Qdrant

DATA
    COLLECTION_NAME = 'roadmap_tasks'
    QDRANT_URL = 'http://localhost:6333'
    ROADMAP_DIR = 'projet/roadmaps/plans/consolidated'
    VECTOR_SIZE = 1536

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\sync\initialize_meta_roadmap_sync.py


