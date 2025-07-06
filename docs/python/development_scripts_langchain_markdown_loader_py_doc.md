Help on module markdown_loader:

NAME
    markdown_loader

DESCRIPTION
    Module pour charger et traiter des fichiers markdown avec Langchain.
    Ce module fournit des fonctions pour charger des fichiers markdown individuels
    ou des répertoires entiers, et les convertir en documents Langchain.

CLASSES
    builtins.object
        MarkdownDirectoryLoader
        MarkdownLoader

    class MarkdownDirectoryLoader(builtins.object)
     |  MarkdownDirectoryLoader(glob: str = '**/*.md', encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None)
     |
     |  Classe pour charger et traiter des répertoires contenant des fichiers markdown.
     |
     |  Methods defined here:
     |
     |  __init__(self, glob: str = '**/*.md', encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None)
     |      Initialise le MarkdownDirectoryLoader.
     |
     |      Args:
     |          glob: Pattern glob pour filtrer les fichiers.
     |          encoding: L'encodage à utiliser pour lire les fichiers.
     |          autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
     |          metadata_extractor: Fonction optionnelle pour extraire des métadonnées du contenu markdown.
     |
     |  load_documents(self, directory_path: str) -> List[langchain_core.documents.base.Document]
     |      Charge tous les fichiers markdown d'un répertoire et les convertit en documents Langchain.
     |
     |      Args:
     |          directory_path: Chemin vers le répertoire contenant les fichiers markdown.
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

    class MarkdownLoader(builtins.object)
     |  MarkdownLoader(encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None)
     |
     |  Classe pour charger et traiter des fichiers markdown.
     |
     |  Methods defined here:
     |
     |  __init__(self, encoding: str = 'utf-8', autodetect_encoding: bool = False, metadata_extractor: Optional[Callable[[str], Dict[str, Any]]] = None)
     |      Initialise le MarkdownLoader.
     |
     |      Args:
     |          encoding: L'encodage à utiliser pour lire les fichiers.
     |          autodetect_encoding: Si True, tente de détecter automatiquement l'encodage.
     |          metadata_extractor: Fonction optionnelle pour extraire des métadonnées du contenu markdown.
     |
     |  load_document(self, file_path: str) -> List[langchain_core.documents.base.Document]
     |      Charge un fichier markdown et le convertit en document Langchain.
     |
     |      Args:
     |          file_path: Chemin vers le fichier markdown à charger.
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
    split_markdown_documents(documents: List[langchain_core.documents.base.Document], chunk_size: int = 1000, chunk_overlap: int = 200) -> List[langchain_core.documents.base.Document]
        Divise les documents markdown en chunks plus petits.

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\langchain\markdown_loader.py


