Help on module fix_n8n_encoding:

NAME
    fix_n8n_encoding

DESCRIPTION
    Correcteur d'encodage pour workflows n8n
    ----------------------------------------
    Ce script corrige les probl�mes d'encodage des caract�res accentu�s
    dans les workflows n8n. Il recherche les fichiers JSON de workflow,
    d�tecte les probl�mes d'encodage et les corrige.

FUNCTIONS
    fix_encoding_in_json(json_data: Dict) -> Dict
        Corrige les probl�mes d'encodage dans les donn�es JSON.

        Args:
            json_data: Donn�es JSON � corriger

        Returns:
            Donn�es JSON corrig�es

    fix_workflow_files(directory: Union[str, pathlib.Path], create_backup: bool = True, recursive: bool = True) -> List[Dict]
        Corrige les probl�mes d'encodage dans les fichiers de workflow n8n.

        Args:
            directory: R�pertoire contenant les fichiers de workflow
            create_backup: Si True, cr�e une sauvegarde avant modification
            recursive: Si True, recherche r�cursivement dans les sous-r�pertoires

        Returns:
            Liste des fichiers corrig�s avec leurs chemins

    main()
        Fonction principale pour l'ex�cution en ligne de commande.

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    Union = typing.Union
        Union type; Union[X, Y] means either X or Y.

        On Python 3.10 and higher, the | operator
        can also be used to denote unions;
        X | Y means the same thing to the type checker as Union[X, Y].

        To define a union, use e.g. Union[int, str]. Details:
        - The arguments must be types and there must be at least one.
        - None as an argument is a special case and is replaced by
          type(None).
        - Unions of unions are flattened, e.g.::

            assert Union[Union[int, str], float] == Union[int, str, float]

        - Unions of a single argument vanish, e.g.::

            assert Union[int] == int  # The constructor actually returns int

        - Redundant arguments are skipped, e.g.::

            assert Union[int, str, int] == Union[int, str]

        - When comparing unions, the argument order is ignored, e.g.::

            assert Union[int, str] == Union[str, int]

        - You cannot subclass or instantiate a union.
        - You can use Optional[X] as a shorthand for Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\utils\file_utils\fix_n8n_encoding.py


