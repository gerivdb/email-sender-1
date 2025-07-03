Help on module DocumentManager:

NAME
    DocumentManager - Module de gestion de documents pour MCP.

DESCRIPTION
    Ce module fournit une classe de base pour gérer les documents dans le contexte MCP.
    Il permet de récupérer, rechercher et lire des documents.

CLASSES
    builtins.object
        DocumentManager

    class DocumentManager(builtins.object)
     |  DocumentManager(base_path: Optional[str] = None, cache_path: Optional[str] = None)
     |
     |  Gestionnaire de documents pour MCP.
     |
     |  Cette classe fournit les fonctionnalités de base pour gérer les documents :
     |  - Récupérer des documents
     |  - Rechercher dans des documents
     |  - Lire des fichiers
     |
     |  Methods defined here:
     |
     |  __init__(self, base_path: Optional[str] = None, cache_path: Optional[str] = None)
     |      Initialise le gestionnaire de documents.
     |
     |      Args:
     |          base_path (str, optional): Chemin de base pour les documents.
     |              Si non spécifié, utilise le répertoire courant.
     |          cache_path (str, optional): Chemin pour le cache des documents.
     |              Si non spécifié, utilise un emplacement par défaut.
     |
     |  fetch_documentation(self, path: str, recursive: bool = False, file_patterns: Optional[List[str]] = None) -> List[Dict[str, Any]]
     |      Récupère la documentation à partir d'un chemin.
     |
     |      Args:
     |          path (str): Chemin du dossier ou du fichier
     |          recursive (bool, optional): Recherche récursive dans les sous-dossiers
     |          file_patterns (List[str], optional): Patterns de fichiers à inclure
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des documents trouvés avec leurs métadonnées
     |
     |  read_file(self, file_path: str, encoding: Optional[str] = None) -> Dict[str, Any]
     |      Lit le contenu d'un fichier.
     |
     |      Args:
     |          file_path (str): Chemin du fichier
     |          encoding (str, optional): Encodage du fichier
     |
     |      Returns:
     |          Dict[str, Any]: Contenu et métadonnées du fichier
     |
     |  search_documentation(self, query: str, paths: Optional[List[str]] = None, recursive: bool = False, file_patterns: Optional[List[str]] = None, max_results: int = 10) -> List[Dict[str, Any]]
     |      Recherche dans la documentation.
     |
     |      Args:
     |          query (str): Requête de recherche
     |          paths (List[str], optional): Liste des chemins à rechercher
     |          recursive (bool, optional): Recherche récursive dans les sous-dossiers
     |          file_patterns (List[str], optional): Patterns de fichiers à inclure
     |          max_results (int, optional): Nombre maximum de résultats
     |
     |      Returns:
     |          List[Dict[str, Any]]: Liste des documents correspondants
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    Callable = typing.Callable
        Deprecated alias to collections.abc.Callable.

        Callable[[int], str] signifies a function that takes a single
        parameter of type int and returns a str.

        The subscription syntax must always be used with exactly two
        values: the argument list and the return type.
        The argument list must be a list of types, a ParamSpec,
        Concatenate or ellipsis. The return type must be a single type.

        There is no syntax to indicate optional or keyword arguments;
        such function types are rarely used as callback types.

    Dict = typing.Dict
        A generic version of dict.

    List = typing.List
        A generic version of list.

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

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

    logger = <Logger mcp.document (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\mcp\core\document\documentmanager.py


