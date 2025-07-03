Help on module directory_loader:

NAME
    directory_loader

DESCRIPTION
    Module pour charger et traiter des répertoires de documentation avec Langchain.
    Ce module fournit des fonctions pour charger des répertoires contenant différents
    types de fichiers (markdown, texte, etc.) et les convertir en documents Langchain.

CLASSES
    builtins.object
        DocumentationLoader

    class DocumentationLoader(builtins.object)
     |  DocumentationLoader(base_path: str, glob_pattern: str = '**/*.*', encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str, str], Dict[str, Any]]] = None, exclude_patterns: Optional[List[str]] = None)
     |
     |  Classe pour charger et traiter des répertoires de documentation.
     |
     |  Methods defined here:
     |
     |  __init__(self, base_path: str, glob_pattern: str = '**/*.*', encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str, str], Dict[str, Any]]] = None, exclude_patterns: Optional[List[str]] = None)
     |      Initialise le DocumentationLoader.
     |
     |      Args:
     |          base_path: Chemin de base pour la documentation.
     |          glob_pattern: Pattern glob pour filtrer les fichiers.
     |          encoding: L'encodage à utiliser pour lire les fichiers.
     |          autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
     |          metadata_extractor: Fonction optionnelle pour extraire des métadonnées.
     |          exclude_patterns: Liste de patterns glob à exclure.
     |
     |  load_documents(self) -> List[langchain_core.documents.base.Document]
     |      Charge tous les documents du répertoire de documentation.
     |
     |      Returns:
     |          Liste de documents Langchain.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    split_documents(documents: List[langchain_core.documents.base.Document], chunk_size: int = 1000, chunk_overlap: int = 200) -> List[langchain_core.documents.base.Document]
        Divise les documents en chunks plus petits.

        Args:
            documents: Liste de documents à diviser.
            chunk_size: Taille maximale de chaque chunk.
            chunk_overlap: Chevauchement entre les chunks.

        Returns:
            Liste de documents divisés.

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

    UNSTRUCTURED_AVAILABLE = True
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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\langchain\directory_loader.py


