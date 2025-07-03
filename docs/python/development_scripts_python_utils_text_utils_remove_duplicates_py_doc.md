Help on module remove_duplicates:

NAME
    remove_duplicates

DESCRIPTION
    Détecteur et suppresseur de fichiers en double
    ----------------------------------------------
    Ce script détecte et supprime les fichiers en double dans un répertoire.
    Il utilise le hachage de contenu pour identifier les doublons exacts.

FUNCTIONS
    calculate_file_hash(file_path: pathlib.Path, block_size: int = 65536) -> str
        Calcule le hachage SHA-256 d'un fichier.

        Args:
            file_path: Chemin du fichier
            block_size: Taille du bloc pour la lecture du fichier

        Returns:
            Hachage SHA-256 du fichier

    find_duplicates(directory: Union[str, pathlib.Path], recursive: bool = True, ignore_extensions: List[str] = None) -> Dict[str, List[pathlib.Path]]
        Trouve les fichiers en double dans un répertoire.

        Args:
            directory: Répertoire à analyser
            recursive: Si True, recherche récursivement dans les sous-répertoires
            ignore_extensions: Liste des extensions de fichiers à ignorer

        Returns:
            Dictionnaire des hachages de fichiers avec leurs chemins

    main()
        Fonction principale pour l'exécution en ligne de commande.

    remove_duplicates(duplicates: Dict[str, List[pathlib.Path]], keep_strategy: str = 'newest', move_to_dir: Union[str, pathlib.Path, NoneType] = None) -> Dict[str, List[pathlib.Path]]
        Supprime les fichiers en double.

        Args:
            duplicates: Dictionnaire des hachages de fichiers avec leurs chemins
            keep_strategy: Stratégie pour choisir le fichier à conserver
                          ("newest", "oldest", "shortest_path", "longest_path")
            move_to_dir: Si spécifié, déplace les doublons dans ce répertoire au lieu de les supprimer

        Returns:
            Dictionnaire des fichiers supprimés par hachage

DATA
    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Set = typing.Set
        A generic version of set.

    Tuple = typing.Tuple
        Deprecated alias to builtins.tuple.

        Tuple[X, Y] is the cross-product type of X and Y.

        Example: Tuple[T1, T2] is a tuple of two elements corresponding
        to type variables T1 and T2.  Tuple[int, float, str] is a tuple
        of an int, a float and a string.

        To specify a variable-length tuple of homogeneous type, use Tuple[T, ...].

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\utils\text_utils\remove_duplicates.py


