Help on module cache_adapter:

NAME
    cache_adapter - Module définissant l'interface générique pour les adaptateurs de cache.

DESCRIPTION
    Ce module fournit une classe abstraite CacheAdapter qui définit l'interface
    que tous les adaptateurs de cache doivent implémenter.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    abc.ABC(builtins.object)
        CacheAdapter

    class CacheAdapter(abc.ABC)
     |  CacheAdapter(cache: scripts.utils.cache.local_cache.LocalCache = None, config_path: str = None)
     |
     |  Interface abstraite pour les adaptateurs de cache.
     |
     |  Method resolution order:
     |      CacheAdapter
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, cache: scripts.utils.cache.local_cache.LocalCache = None, config_path: str = None)
     |      Initialise l'adaptateur de cache.
     |
     |      Args:
     |          cache (LocalCache, optional): Instance de LocalCache à utiliser.
     |              Si None, une nouvelle instance sera créée.
     |          config_path (str, optional): Chemin vers un fichier de configuration JSON.
     |              Si fourni, les paramètres du fichier de configuration seront utilisés.
     |
     |  cache_response(self, cache_key: str, response: Any, ttl: Optional[int] = None) -> None
     |      Met en cache une réponse.
     |
     |      Args:
     |          cache_key (str): Clé de cache.
     |          response (Any): Réponse à mettre en cache.
     |          ttl (int, optional): Durée de vie de la réponse en secondes.
     |              Si None, utilise la durée de vie par défaut du cache.
     |
     |  cached(self, ttl: Optional[int] = None) -> Callable
     |      Décorateur pour mettre en cache les résultats d'une fonction.
     |
     |      Args:
     |          ttl (int, optional): Durée de vie du résultat en secondes.
     |              Si None, utilise la durée de vie par défaut du cache.
     |
     |      Returns:
     |          Callable: Décorateur de mise en cache.
     |
     |  clear(self) -> None
     |      Vide le cache.
     |
     |  deserialize_response(self, serialized_response: Dict[str, Any]) -> Any
     |      Désérialise une réponse du cache.
     |
     |      Args:
     |          serialized_response: Réponse sérialisée.
     |
     |      Returns:
     |          Any: Réponse désérialisée.
     |
     |  generate_cache_key(self, *args, **kwargs) -> str
     |      Génère une clé de cache unique basée sur les paramètres fournis.
     |
     |      Args:
     |          *args: Arguments positionnels.
     |          **kwargs: Arguments nommés.
     |
     |      Returns:
     |          str: Clé de cache unique.
     |
     |  get_cached_response(self, cache_key: str) -> Optional[Any]
     |      Récupère une réponse du cache.
     |
     |      Args:
     |          cache_key (str): Clé de cache.
     |
     |      Returns:
     |          Optional[Any]: Réponse désérialisée ou None si la clé n'existe pas.
     |
     |  get_statistics(self) -> Dict[str, int]
     |      Récupère les statistiques d'utilisation du cache.
     |
     |      Returns:
     |          Dict[str, int]: Dictionnaire contenant les statistiques d'utilisation.
     |
     |  invalidate(self, cache_key: str) -> bool
     |      Invalide une entrée du cache.
     |
     |      Args:
     |          cache_key (str): Clé de cache à invalider.
     |
     |      Returns:
     |          bool: True si l'entrée a été invalidée, False sinon.
     |
     |  serialize_response(self, response: Any) -> Dict[str, Any]
     |      Sérialise une réponse pour le stockage dans le cache.
     |
     |      Args:
     |          response: Réponse à sérialiser.
     |
     |      Returns:
     |          Dict[str, Any]: Réponse sérialisée.
     |
     |  ----------------------------------------------------------------------
     |  Static methods defined here:
     |
     |  hash_params(*args, **kwargs) -> str
     |      Génère un hash à partir des paramètres fournis.
     |
     |      Args:
     |          *args: Arguments positionnels.
     |          **kwargs: Arguments nommés.
     |
     |      Returns:
     |          str: Hash des paramètres.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset({'deserialize_response', 'generate_cac...

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
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\cache-tools\adapters\cache_adapter.py


