Help on module organize_repo:

NAME
    organize_repo

DESCRIPTION
    Organisateur de dépôt GitHub
    ----------------------------
    Ce script organise un dépôt selon les standards GitHub, en regroupant
    les fichiers dans des répertoires appropriés et en maintenant la racine
    du dépôt propre.

FUNCTIONS
    is_github_standard_file(file_path: pathlib.Path) -> bool
        Vérifie si un fichier est un fichier standard GitHub.

        Args:
            file_path: Chemin du fichier

        Returns:
            True si le fichier est un fichier standard GitHub, False sinon

    main()
        Fonction principale pour l'exécution en ligne de commande.

    organize_repo(repo_dir: Union[str, pathlib.Path], create_backup: bool = True, move_files: bool = True, organize_workflows: bool = True) -> Dict[str, List[pathlib.Path]]
        Organise un dépôt selon les standards GitHub.

        Args:
            repo_dir: Répertoire du dépôt
            create_backup: Si True, crée une sauvegarde avant modification
            move_files: Si True, déplace les fichiers; sinon, les copie
            organize_workflows: Si True, regroupe les dossiers de workflows

        Returns:
            Dictionnaire des fichiers organisés par catégorie

DATA
    Dict = typing.Dict
        A generic version of dict.

    FILE_TYPE_DIRS = {'.bat': 'scripts', '.cmd': 'scripts', '.csv': 'data'...
    GITHUB_STANDARD_FILES = {'.editorconfig', '.gitattributes', '.github',...
    List = typing.List
        A generic version of list.

    NEVER_MOVE_FILES = {'AGENT.md'}
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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\python\utils\project_utils\organize_repo.py


