Help on module init_qdrant:

NAME
    init_qdrant

DESCRIPTION
    Script pour initialiser la collection Qdrant et y ajouter des donn�es de test
    pour la visualisation des roadmaps sous forme de carte de m�tro.

    Ce script cr�e une collection 'roadmaps' dans Qdrant et y ajoute des exemples
    de roadmaps avec des t�ches et des d�pendances.

    Usage:
        python init_qdrant.py

    D�pendances:
        - qdrant-client
        - numpy

FUNCTIONS
    add_roadmaps_to_qdrant(client, roadmaps)
        Ajoute les roadmaps � la collection Qdrant.

    create_collection()
        Cr�e la collection Qdrant pour les roadmaps.

    create_random_embedding(size=512)
        Cr�e un embedding al�atoire pour simuler un embedding r�el.

    create_sample_roadmaps()
        Cr�e des exemples de roadmaps pour les tests.

    main()
        Fonction principale.

DATA
    COLLECTION_NAME = 'roadmaps'
    QDRANT_HOST = 'localhost'
    QDRANT_PORT = 6333
    VECTOR_SIZE = 512

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\roadmap\visualization\init_qdrant.py


