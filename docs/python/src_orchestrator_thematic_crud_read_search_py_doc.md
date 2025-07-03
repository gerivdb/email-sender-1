Help on module read_search:

NAME
    read_search - Module de lecture et recherche thématique.

DESCRIPTION
    Ce module fournit des fonctionnalités pour lire et rechercher des éléments
    de roadmap par thème et autres critères.

CLASSES
    builtins.object
        ThematicReadSearch

    class ThematicReadSearch(builtins.object)
     |  ThematicReadSearch(storage_path: str)
     |
     |  Classe pour la lecture et recherche thématique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str)
     |      Initialise le gestionnaire de lecture et recherche thématique.
     |
     |      Args:
     |          storage_path: Chemin vers le répertoire de stockage des données
     |
     |  get_item(self, item_id: str) -> Optional[Dict[str, Any]]
     |      Récupère un élément par son identifiant.
     |
     |      Args:
     |          item_id: Identifiant de l'élément à récupérer
     |
     |      Returns:
     |          Élément récupéré ou None si l'élément n'existe pas
     |
     |  get_items_by_theme(self, theme: str, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Récupère les éléments par thème.
     |
     |      Args:
     |          theme: Thème à rechercher
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant au thème
     |
     |  get_theme_statistics(self) -> Dict[str, Dict[str, Any]]
     |      Récupère des statistiques sur les thèmes.
     |
     |      Returns:
     |          Dictionnaire des statistiques par thème
     |
     |  search_items(self, query: str, themes: Optional[List[str]] = None, metadata_filters: Optional[Dict[str, Any]] = None, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des éléments par requête textuelle et filtres.
     |
     |      Args:
     |          query: Requête textuelle à rechercher
     |          themes: Liste des thèmes à inclure dans la recherche (optionnel)
     |          metadata_filters: Filtres sur les métadonnées (optionnel)
     |          limit: Nombre maximum d'éléments à récupérer (défaut: 100)
     |          offset: Décalage pour la pagination (défaut: 0)
     |
     |      Returns:
     |          Liste des éléments correspondant aux critères de recherche
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

    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\read_search.py


