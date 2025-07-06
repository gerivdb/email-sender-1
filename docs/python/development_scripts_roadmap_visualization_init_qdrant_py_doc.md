Help on module init_qdrant:

NAME
    init_qdrant

DESCRIPTION
    Script pour initialiser la collection Qdrant et y ajouter des données de test
    pour la visualisation des roadmaps sous forme de carte de métro.

    Ce script crée une collection 'roadmaps' dans Qdrant et y ajoute des exemples
    de roadmaps avec des tâches et des dépendances.

    Usage:
        python init_qdrant.py

    Dépendances:
        - qdrant-client
        - numpy

FUNCTIONS
    add_roadmaps_to_qdrant(client, roadmaps)
        Ajoute les roadmaps à la collection Qdrant.

    create_collection()
        Crée la collection Qdrant pour les roadmaps.

    create_random_embedding(size=512)
        Crée un embedding aléatoire pour simuler un embedding réel.

    create_sample_roadmaps()
        Crée des exemples de roadmaps pour les tests.

    main()
        Fonction principale.

DATA
    COLLECTION_NAME = 'roadmaps'
    QDRANT_HOST = 'localhost'
    QDRANT_PORT = 6333
    VECTOR_SIZE = 512

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\visualization\init_qdrant.py


