Help on module metadata_extractor:

NAME
    metadata_extractor

DESCRIPTION
    Module pour extraire et enrichir les métadonnées des documents.
    Ce module fournit des fonctions pour extraire des métadonnées à partir du contenu
    des documents et enrichir les documents avec ces métadonnées.

CLASSES
    builtins.object
        MetadataExtractor

    class MetadataExtractor(builtins.object)
     |  MetadataExtractor(extractors: Optional[Dict[str, Callable[[str, Dict[str, Any]], Dict[str, Any]]]] = None, add_hash: bool = True, add_stats: bool = True, add_timestamp: bool = True)
     |
     |  Classe pour extraire et enrichir les métadonnées des documents.
     |
     |  Methods defined here:
     |
     |  __init__(self, extractors: Optional[Dict[str, Callable[[str, Dict[str, Any]], Dict[str, Any]]]] = None, add_hash: bool = True, add_stats: bool = True, add_timestamp: bool = True)
     |      Initialise le MetadataExtractor.
     |
     |      Args:
     |          extractors: Dictionnaire d'extracteurs spécifiques par type de document.
     |          add_hash: Si True, ajoute un hash du contenu aux métadonnées.
     |          add_stats: Si True, ajoute des statistiques sur le contenu aux métadonnées.
     |          add_timestamp: Si True, ajoute un timestamp aux métadonnées.
     |
     |  enrich_document(self, document: langchain_core.documents.base.Document) -> langchain_core.documents.base.Document
     |      Enrichit un document avec des métadonnées extraites.
     |
     |      Args:
     |          document: Document à enrichir.
     |
     |      Returns:
     |          Document enrichi.
     |
     |  enrich_documents(self, documents: List[langchain_core.documents.base.Document]) -> List[langchain_core.documents.base.Document]
     |      Enrichit une liste de documents avec des métadonnées extraites.
     |
     |      Args:
     |          documents: Liste de documents à enrichir.
     |
     |      Returns:
     |          Liste de documents enrichis.
     |
     |  extract_metadata(self, document: langchain_core.documents.base.Document) -> Dict[str, Any]
     |      Extrait les métadonnées d'un document.
     |
     |      Args:
     |          document: Document à traiter.
     |
     |      Returns:
     |          Dictionnaire de métadonnées extraites.
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
    save_metadata_to_json(documents: List[langchain_core.documents.base.Document], output_path: str) -> None
        Sauvegarde les métadonnées des documents dans un fichier JSON.

        Args:
            documents: Liste de documents.
            output_path: Chemin du fichier de sortie.

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\langchain\metadata_extractor.py


