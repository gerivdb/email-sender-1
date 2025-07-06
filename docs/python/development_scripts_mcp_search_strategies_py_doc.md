Help on module search_strategies:

NAME
    search_strategies

DESCRIPTION
    Module pour les stratégies de recherche et de rescoring.
    Ce module fournit des classes et fonctions pour améliorer la précision des recherches sémantiques.

CLASSES
    builtins.object
        Rescorer
        SearchFilter
        SearchParams
        SearchResult
        SearchStrategies
    enum.Enum(builtins.object)
        RescoringStrategy
        SearchStrategy

    class Rescorer(builtins.object)
     |  Classe pour le rescoring des résultats de recherche.
     |
     |  Static methods defined here:
     |
     |  custom_rescorer(results: List[search_strategies.SearchResult], query: str, rescoring_function: Callable[[List[search_strategies.SearchResult], str, Dict[str, Any]], List[search_strategies.SearchResult]], params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring personnalisé.
     |
     |      Args:
     |          results: Liste de résultats à rescorer.
     |          query: Requête de recherche.
     |          rescoring_function: Fonction de rescoring personnalisée.
     |          params: Paramètres de rescoring.
     |
     |      Returns:
     |          Liste de résultats rescorés.
     |
     |  keyword_match_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring basé sur la présence de mots-clés.
     |
     |      Args:
     |          results: Liste de résultats à rescorer.
     |          query: Requête de recherche.
     |          params: Paramètres de rescoring.
     |
     |      Returns:
     |          Liste de résultats rescorés.
     |
     |  length_penalty_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring avec pénalité de longueur.
     |
     |      Args:
     |          results: Liste de résultats à rescorer.
     |          query: Requête de recherche.
     |          params: Paramètres de rescoring.
     |
     |      Returns:
     |          Liste de résultats rescorés.
     |
     |  recency_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring basé sur la récence.
     |
     |      Args:
     |          results: Liste de résultats à rescorer.
     |          query: Requête de recherche.
     |          params: Paramètres de rescoring.
     |
     |      Returns:
     |          Liste de résultats rescorés.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class RescoringStrategy(enum.Enum)
     |  RescoringStrategy(*values)
     |
     |  Énumération des stratégies de rescoring disponibles.
     |
     |  Method resolution order:
     |      RescoringStrategy
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  CUSTOM = <RescoringStrategy.CUSTOM: 5>
     |
     |  KEYWORD_MATCH = <RescoringStrategy.KEYWORD_MATCH: 2>
     |
     |  LENGTH_PENALTY = <RescoringStrategy.LENGTH_PENALTY: 3>
     |
     |  NONE = <RescoringStrategy.NONE: 1>
     |
     |  RECENCY = <RescoringStrategy.RECENCY: 4>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class SearchFilter(builtins.object)
     |  SearchFilter(field: str, operator: str, value: Any)
     |
     |  Classe pour représenter un filtre de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, field: str, operator: str, value: Any)
     |      Initialise un filtre de recherche.
     |
     |      Args:
     |          field: Champ sur lequel appliquer le filtre.
     |          operator: Opérateur de comparaison.
     |          value: Valeur à comparer.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le filtre en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire représentant le filtre.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchFilter'
     |      Crée un filtre à partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire représentant le filtre.
     |
     |      Returns:
     |          Filtre de recherche.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SearchParams(builtins.object)
     |  SearchParams(query: str, limit: int = 10, filters: Optional[List[search_strategies.SearchFilter]] = None, strategy: search_strategies.SearchStrategy = <SearchStrategy.SEMANTIC: 1>, rescoring_strategy: search_strategies.RescoringStrategy = <RescoringStrategy.NONE: 1>, rescoring_params: Optional[Dict[str, Any]] = None, min_score_threshold: Optional[float] = None)
     |
     |  Classe pour représenter les paramètres de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, query: str, limit: int = 10, filters: Optional[List[search_strategies.SearchFilter]] = None, strategy: search_strategies.SearchStrategy = <SearchStrategy.SEMANTIC: 1>, rescoring_strategy: search_strategies.RescoringStrategy = <RescoringStrategy.NONE: 1>, rescoring_params: Optional[Dict[str, Any]] = None, min_score_threshold: Optional[float] = None)
     |      Initialise les paramètres de recherche.
     |
     |      Args:
     |          query: Requête de recherche.
     |          limit: Nombre maximum de résultats.
     |          filters: Liste de filtres à appliquer.
     |          strategy: Stratégie de recherche à utiliser.
     |          rescoring_strategy: Stratégie de rescoring à utiliser.
     |          rescoring_params: Paramètres pour la stratégie de rescoring.
     |          min_score_threshold: Seuil minimum de score pour les résultats.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit les paramètres en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire représentant les paramètres.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchParams'
     |      Crée des paramètres à partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire représentant les paramètres.
     |
     |      Returns:
     |          Paramètres de recherche.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SearchResult(builtins.object)
     |  SearchResult(document_id: str, text: str, metadata: Dict[str, Any], score: float, vector: Optional[List[float]] = None)
     |
     |  Classe pour représenter un résultat de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, document_id: str, text: str, metadata: Dict[str, Any], score: float, vector: Optional[List[float]] = None)
     |      Initialise un résultat de recherche.
     |
     |      Args:
     |          document_id: Identifiant du document.
     |          text: Texte du document.
     |          metadata: Métadonnées du document.
     |          score: Score de similarité.
     |          vector: Vecteur d'embedding du document.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le résultat en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire représentant le résultat.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchResult'
     |      Crée un résultat à partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire représentant le résultat.
     |
     |      Returns:
     |          Résultat de recherche.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SearchStrategies(builtins.object)
     |  Classe pour les stratégies de recherche.
     |
     |  Static methods defined here:
     |
     |  apply_rescoring(results: List[search_strategies.SearchResult], query: str, strategy: search_strategies.RescoringStrategy, params: Optional[Dict[str, Any]] = None, custom_rescorer: Optional[Callable[[List[search_strategies.SearchResult], str, Dict[str, Any]], List[search_strategies.SearchResult]]] = None) -> List[search_strategies.SearchResult]
     |      Applique une stratégie de rescoring aux résultats.
     |
     |      Args:
     |          results: Liste de résultats à rescorer.
     |          query: Requête de recherche.
     |          strategy: Stratégie de rescoring à utiliser.
     |          params: Paramètres de rescoring.
     |          custom_rescorer: Fonction de rescoring personnalisée.
     |
     |      Returns:
     |          Liste de résultats rescorés.
     |
     |  filter_results(results: List[search_strategies.SearchResult], filters: List[search_strategies.SearchFilter]) -> List[search_strategies.SearchResult]
     |      Filtre les résultats selon les critères spécifiés.
     |
     |      Args:
     |          results: Liste de résultats à filtrer.
     |          filters: Liste de filtres à appliquer.
     |
     |      Returns:
     |          Liste de résultats filtrés.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SearchStrategy(enum.Enum)
     |  SearchStrategy(*values)
     |
     |  Énumération des stratégies de recherche disponibles.
     |
     |  Method resolution order:
     |      SearchStrategy
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  BM25 = <SearchStrategy.BM25: 4>
     |
     |  HYBRID = <SearchStrategy.HYBRID: 3>
     |
     |  KEYWORD = <SearchStrategy.KEYWORD: 2>
     |
     |  MMR = <SearchStrategy.MMR: 5>
     |
     |  SEMANTIC = <SearchStrategy.SEMANTIC: 1>
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\mcp\search_strategies.py


