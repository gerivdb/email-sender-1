Help on module search_strategies:

NAME
    search_strategies

DESCRIPTION
    Module pour les strat�gies de recherche et de rescoring.
    Ce module fournit des classes et fonctions pour am�liorer la pr�cision des recherches s�mantiques.

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
     |  Classe pour le rescoring des r�sultats de recherche.
     |
     |  Static methods defined here:
     |
     |  custom_rescorer(results: List[search_strategies.SearchResult], query: str, rescoring_function: Callable[[List[search_strategies.SearchResult], str, Dict[str, Any]], List[search_strategies.SearchResult]], params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring personnalis�.
     |
     |      Args:
     |          results: Liste de r�sultats � rescorer.
     |          query: Requ�te de recherche.
     |          rescoring_function: Fonction de rescoring personnalis�e.
     |          params: Param�tres de rescoring.
     |
     |      Returns:
     |          Liste de r�sultats rescor�s.
     |
     |  keyword_match_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring bas� sur la pr�sence de mots-cl�s.
     |
     |      Args:
     |          results: Liste de r�sultats � rescorer.
     |          query: Requ�te de recherche.
     |          params: Param�tres de rescoring.
     |
     |      Returns:
     |          Liste de r�sultats rescor�s.
     |
     |  length_penalty_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring avec p�nalit� de longueur.
     |
     |      Args:
     |          results: Liste de r�sultats � rescorer.
     |          query: Requ�te de recherche.
     |          params: Param�tres de rescoring.
     |
     |      Returns:
     |          Liste de r�sultats rescor�s.
     |
     |  recency_rescorer(results: List[search_strategies.SearchResult], query: str, params: Optional[Dict[str, Any]] = None) -> List[search_strategies.SearchResult]
     |      Rescoring bas� sur la r�cence.
     |
     |      Args:
     |          results: Liste de r�sultats � rescorer.
     |          query: Requ�te de recherche.
     |          params: Param�tres de rescoring.
     |
     |      Returns:
     |          Liste de r�sultats rescor�s.
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
     |  �num�ration des strat�gies de rescoring disponibles.
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
     |  Classe pour repr�senter un filtre de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, field: str, operator: str, value: Any)
     |      Initialise un filtre de recherche.
     |
     |      Args:
     |          field: Champ sur lequel appliquer le filtre.
     |          operator: Op�rateur de comparaison.
     |          value: Valeur � comparer.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le filtre en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant le filtre.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchFilter'
     |      Cr�e un filtre � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant le filtre.
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
     |  Classe pour repr�senter les param�tres de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, query: str, limit: int = 10, filters: Optional[List[search_strategies.SearchFilter]] = None, strategy: search_strategies.SearchStrategy = <SearchStrategy.SEMANTIC: 1>, rescoring_strategy: search_strategies.RescoringStrategy = <RescoringStrategy.NONE: 1>, rescoring_params: Optional[Dict[str, Any]] = None, min_score_threshold: Optional[float] = None)
     |      Initialise les param�tres de recherche.
     |
     |      Args:
     |          query: Requ�te de recherche.
     |          limit: Nombre maximum de r�sultats.
     |          filters: Liste de filtres � appliquer.
     |          strategy: Strat�gie de recherche � utiliser.
     |          rescoring_strategy: Strat�gie de rescoring � utiliser.
     |          rescoring_params: Param�tres pour la strat�gie de rescoring.
     |          min_score_threshold: Seuil minimum de score pour les r�sultats.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit les param�tres en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant les param�tres.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchParams'
     |      Cr�e des param�tres � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant les param�tres.
     |
     |      Returns:
     |          Param�tres de recherche.
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
     |  Classe pour repr�senter un r�sultat de recherche.
     |
     |  Methods defined here:
     |
     |  __init__(self, document_id: str, text: str, metadata: Dict[str, Any], score: float, vector: Optional[List[float]] = None)
     |      Initialise un r�sultat de recherche.
     |
     |      Args:
     |          document_id: Identifiant du document.
     |          text: Texte du document.
     |          metadata: M�tadonn�es du document.
     |          score: Score de similarit�.
     |          vector: Vecteur d'embedding du document.
     |
     |  to_dict(self) -> Dict[str, Any]
     |      Convertit le r�sultat en dictionnaire.
     |
     |      Returns:
     |          Dictionnaire repr�sentant le r�sultat.
     |
     |  ----------------------------------------------------------------------
     |  Class methods defined here:
     |
     |  from_dict(data: Dict[str, Any]) -> 'SearchResult'
     |      Cr�e un r�sultat � partir d'un dictionnaire.
     |
     |      Args:
     |          data: Dictionnaire repr�sentant le r�sultat.
     |
     |      Returns:
     |          R�sultat de recherche.
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
     |  Classe pour les strat�gies de recherche.
     |
     |  Static methods defined here:
     |
     |  apply_rescoring(results: List[search_strategies.SearchResult], query: str, strategy: search_strategies.RescoringStrategy, params: Optional[Dict[str, Any]] = None, custom_rescorer: Optional[Callable[[List[search_strategies.SearchResult], str, Dict[str, Any]], List[search_strategies.SearchResult]]] = None) -> List[search_strategies.SearchResult]
     |      Applique une strat�gie de rescoring aux r�sultats.
     |
     |      Args:
     |          results: Liste de r�sultats � rescorer.
     |          query: Requ�te de recherche.
     |          strategy: Strat�gie de rescoring � utiliser.
     |          params: Param�tres de rescoring.
     |          custom_rescorer: Fonction de rescoring personnalis�e.
     |
     |      Returns:
     |          Liste de r�sultats rescor�s.
     |
     |  filter_results(results: List[search_strategies.SearchResult], filters: List[search_strategies.SearchFilter]) -> List[search_strategies.SearchResult]
     |      Filtre les r�sultats selon les crit�res sp�cifi�s.
     |
     |      Args:
     |          results: Liste de r�sultats � filtrer.
     |          filters: Liste de filtres � appliquer.
     |
     |      Returns:
     |          Liste de r�sultats filtr�s.
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
     |  �num�ration des strat�gies de recherche disponibles.
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


