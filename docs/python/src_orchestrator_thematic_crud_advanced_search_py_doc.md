Help on module advanced_search:

NAME
    advanced_search - Module de recherche avanc�e pour le syst�me CRUD th�matique.

DESCRIPTION
    Ce module fournit des fonctionnalit�s avanc�es pour la recherche d'�l�ments
    par th�me, multi-crit�res et requ�tes vectorielles.

CLASSES
    builtins.object
        ThematicAdvancedSearch

    class ThematicAdvancedSearch(builtins.object)
     |  ThematicAdvancedSearch(storage_path: str)
     |
     |  Classe pour la recherche avanc�e th�matique.
     |
     |  Methods defined here:
     |
     |  __init__(self, storage_path: str)
     |      Initialise le gestionnaire de recherche avanc�e th�matique.
     |
     |      Args:
     |          storage_path: Chemin vers le r�pertoire de stockage des donn�es
     |
     |  search_by_multi_criteria(self, themes: Optional[List[str]] = None, content_query: Optional[str] = None, metadata_filters: Optional[Dict[str, Any]] = None, date_range: Optional[Dict[str, str]] = None, theme_weights: Optional[Dict[str, float]] = None, sort_by: str = 'relevance', limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon plusieurs crit�res combin�s.
     |
     |      Args:
     |          themes: Liste des th�mes � inclure dans la recherche (optionnel)
     |          content_query: Requ�te textuelle � rechercher dans le contenu (optionnel)
     |          metadata_filters: Filtres sur les m�tadonn�es (optionnel)
     |          date_range: Plage de dates pour la recherche (optionnel)
     |          theme_weights: Poids minimum pour chaque th�me (optionnel)
     |          sort_by: Crit�re de tri ("relevance", "date", "title", "theme_weight")
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_by_theme_hierarchy(self, theme: str, include_subthemes: bool = True, include_parent_themes: bool = False, max_depth: int = 3, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon une hi�rarchie th�matique.
     |
     |      Args:
     |          theme: Th�me principal
     |          include_subthemes: Inclure les sous-th�mes
     |          include_parent_themes: Inclure les th�mes parents
     |          max_depth: Profondeur maximale de la hi�rarchie
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
     |
     |  search_by_theme_relationships(self, primary_theme: str, related_themes: Optional[List[str]] = None, relationship_type: str = 'any', min_overlap: int = 1, limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]
     |      Recherche des �l�ments selon les relations entre th�mes.
     |
     |      Args:
     |          primary_theme: Th�me principal
     |          related_themes: Th�mes li�s (optionnel)
     |          relationship_type: Type de relation ("any", "all", "only")
     |          min_overlap: Nombre minimum de th�mes li�s requis
     |          limit: Nombre maximum d'�l�ments � r�cup�rer (d�faut: 100)
     |          offset: D�calage pour la pagination (d�faut: 0)
     |
     |      Returns:
     |          Liste des �l�ments correspondant aux crit�res de recherche
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
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\thematic_crud\advanced_search.py


