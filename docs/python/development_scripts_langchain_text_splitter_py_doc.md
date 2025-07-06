Help on module text_splitter:

NAME
    text_splitter

DESCRIPTION
    Module pour configurer et optimiser les TextSplitters de Langchain.
    Ce module fournit des fonctions pour diviser les documents en chunks optimaux
    pour différents types de contenu.

CLASSES
    builtins.object
        OptimizedTextSplitter

    class OptimizedTextSplitter(builtins.object)
     |  OptimizedTextSplitter(chunk_size: int = 1000, chunk_overlap: int = 200, length_function: Callable[[str], int] = <built-in function len>, add_start_index: bool = True)
     |
     |  Classe pour configurer et optimiser les TextSplitters de Langchain.
     |
     |  Methods defined here:
     |
     |  __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200, length_function: Callable[[str], int] = <built-in function len>, add_start_index: bool = True)
     |      Initialise l'OptimizedTextSplitter.
     |
     |      Args:
     |          chunk_size: Taille maximale de chaque chunk.
     |          chunk_overlap: Chevauchement entre les chunks.
     |          length_function: Fonction pour calculer la longueur du texte.
     |          add_start_index: Si True, ajoute l'index de début du chunk dans les métadonnées.
     |
     |  split_documents(self, documents: List[langchain_core.documents.base.Document]) -> List[langchain_core.documents.base.Document]
     |      Divise les documents en chunks en utilisant le splitter approprié pour chaque type.
     |
     |      Args:
     |          documents: Liste de documents à diviser.
     |
     |      Returns:
     |          Liste de documents divisés.
     |
     |  split_text(self, text: str, doc_type: str = 'text', metadata: Optional[Dict[str, Any]] = None) -> List[langchain_core.documents.base.Document]
     |      Divise un texte en chunks en utilisant le splitter approprié.
     |
     |      Args:
     |          text: Texte à diviser.
     |          doc_type: Type de document.
     |          metadata: Métadonnées à ajouter aux documents.
     |
     |      Returns:
     |          Liste de documents.
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
    get_optimal_chunk_params(doc_type: str, model_context_size: int = 8192, token_overlap_ratio: float = 0.1) -> Tuple[int, int]
        Calcule les paramètres optimaux de chunk_size et chunk_overlap pour un type de document
        et une taille de contexte de modèle donnés.

        Args:
            doc_type: Type de document.
            model_context_size: Taille maximale du contexte du modèle en tokens.
            token_overlap_ratio: Ratio de chevauchement entre les chunks (0.0 à 0.5).

        Returns:
            Tuple (chunk_size, chunk_overlap).

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\langchain\text_splitter.py


