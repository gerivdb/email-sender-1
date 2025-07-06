Help on module check_cognitive_integrity:

NAME
    check_cognitive_integrity - Script pour v�rifier l'int�grit� et la coh�rence des donn�es de l'architecture cognitive.

DESCRIPTION
    Ce script v�rifie l'int�grit� des fichiers de n�uds et la coh�rence des relations parent-enfant.

FUNCTIONS
    check_relationships_consistency(storage_dir: str, repair: bool = False) -> bool
        V�rifie la coh�rence des relations parent-enfant.

        Args:
            storage_dir (str): R�pertoire de stockage des n�uds
            repair (bool, optional): Si True, tente de r�parer les incoh�rences. Par d�faut False.

        Returns:
            bool: True si toutes les relations sont coh�rentes, False sinon

    check_storage_integrity(storage_dir: str, repair: bool = False) -> bool
        V�rifie l'int�grit� des fichiers de n�uds.

        Args:
            storage_dir (str): R�pertoire de stockage des n�uds
            repair (bool, optional): Si True, tente de r�parer les fichiers corrompus. Par d�faut False.

        Returns:
            bool: True si tous les fichiers sont int�gres, False sinon

    main()
        Fonction principale.

DATA
    __warningregistry__ = {'version': 0}
    logger = <Logger check_cognitive_integrity (INFO)>
    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\tools\check_cognitive_integrity.py


