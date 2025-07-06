Help on module vector_search:

NAME
    vector_search - Module de recherche vectorielle thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour effectuer des recherches
    vectorielles sur les éléments thématiques.

CLASSES
    builtins.object
        ThematicVectorSearch

    class ThematicVectorSearch(builtins.object)
     |  ThematicVectorSearch(storage_path: str, embeddings_path: Optional[str] = None, embedding_model: Optional[str] = None, api_key: Optional[str] = None, api_url: Optional[str] = None, api_provider: str = 'openrouter')
     |
     |  Classe pour la recherche vectorielle thématique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str, embeddings_path: Optional[str] = None, embedding_model: Optional[str] = None, api_key: Optional[str] = None, api_url: Optional[str] = None, api_provider: str = 'openrouter')
     |      Initialise le gestionnaire de recherche vectorielle thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |          embeddings_path: Chemin vers le répertoire de stockage des embeddings (optionnel)
     |          embedding_model: Modèle d'embedding à utiliser
     |          api_key: Clé API pour le service d'embedding (optionnel)
     |          api_url: URL de l'API pour le service d'embedding (optionnel)
     |          api_provider: Fournisseur d'API à utiliser ('openrouter' or 'gemini')
     |
     |  compute_similarity(self, embedding1: List[float], embedding2: List[float]) -> float
     |      Calcule la similarité cosinus entre deux embeddings.
     |
     |      Args:
     |          embedding1: Premier vecteur d'embedding
     |          embedding2: Deuxième vecteur d'embedding
     |
     |      Returns:
     |          Score de similarité cosinus (entre -1 et 1)
     |
     |  find_theme_clusters(self, min_similarity: float = 0.8, min_cluster_size: int = 3) -> List[Dict[str, Any]]
     |      Identifie des clusters thématiques basés sur la similarité vectorielle.
     |
     |      Args:
     |          min_similarity: Similarité minimum pour considérer deux éléments comme similaires
     |          min_cluster_size: Taille minimum d'un cluster
     |
     |      Returns:
     |          Liste des clusters identifiés
     |
     |  generate_embedding(self, text: str) -> Optional[List[float]]
     |      Génère un embedding pour un texte donné.
     |
     |      Args:
     |          text: Texte à encoder
     |
     |      Returns:
     |          Vecteur d'embedding ou None en cas d'erreur
     |
     |  index_item(self, item: Dict[str, Any]) -> bool
     |      Indexe un élément pour la recherche vectorielle.
     |
     |      Args:
     |          item: Élément à indexer
     |
     |      Returns:
     |          True si l'indexation a réussi, False sinon
     |
     |  index_items_by_theme(self, theme: str) -> Dict[str, Any]
     |      Indexe tous les éléments d'un thème pour la recherche vectorielle.
     |
     |      Args:
     |          theme: Thème des éléments à indexer
     |
     |      Returns:
     |          Statistiques sur l'indexation
     |
     |  search_similar(self, query: str, themes: Optional[List[str]] = None, top_k: int = 10, similarity_threshold: float = 0.7) -> List[Dict[str, Any]]
     |      Recherche des éléments similaires à une requête textuelle.
     |
     |      Args:
     |          query: Requête textuelle
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          top_k: Nombre maximum d'éléments à récupérer (défaut: 10)
     |          similarity_threshold: Seuil de similarité minimum (défaut: 0.7)
     |
     |      Returns:
     |          Liste des éléments similaires avec leur score de similarité
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\vector_search.py


