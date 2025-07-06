Help on module check_cognitive_integrity:

NAME
    check_cognitive_integrity - Script pour vérifier l'intégrité et la cohérence des données de l'architecture cognitive.

DESCRIPTION
    Ce script vérifie l'intégrité des fichiers de nœuds et la cohérence des relations parent-enfant.

FUNCTIONS
    check_relationships_consistency(storage_dir: str, repair: bool = False) -> bool
        Vérifie la cohérence des relations parent-enfant.

        Args:
            storage_dir (str): Répertoire de stockage des nœuds
            repair (bool, optional): Si True, tente de réparer les incohérences. Par défaut False.

        Returns:
            bool: True si toutes les relations sont cohérentes, False sinon

    check_storage_integrity(storage_dir: str, repair: bool = False) -> bool
        Vérifie l'intégrité des fichiers de nœuds.

        Args:
            storage_dir (str): Répertoire de stockage des nœuds
            repair (bool, optional): Si True, tente de réparer les fichiers corrompus. Par défaut False.

        Returns:
            bool: True si tous les fichiers sont intègres, False sinon

    main()
        Fonction principale.

DATA
    __warningregistry__ = {'version': 0}
    logger = <Logger check_cognitive_integrity (INFO)>
    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\tools\check_cognitive_integrity.py


