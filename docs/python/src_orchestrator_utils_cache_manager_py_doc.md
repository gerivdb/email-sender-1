Help on module cache_manager:

NAME
    cache_manager - Module de gestion du cache.

DESCRIPTION
    Ce module fournit des fonctionnalités pour mettre en cache les résultats
    des opérations coûteuses afin d'améliorer les performances.

CLASSES
    builtins.object
        CacheManager

    class CacheManager(builtins.object)
     |  Gestionnaire de cache pour l'orchestrateur.
     |
     |  Class methods defined here:
     |
     |  clear_all_cache() -> None
     |      Vide tous les caches.
     |
     |  clear_disk_cache() -> None
     |      Vide le cache sur disque.
     |
     |  clear_memory_cache() -> None
     |      Vide le cache en mémoire.
     |
     |  get_cache_key(func_name: str, args: tuple, kwargs: Dict[str, Any]) -> str
     |      Génère une clé de cache unique pour une fonction et ses arguments.
     |
     |      Args:
     |          func_name: Nom de la fonction
     |          args: Arguments positionnels
     |          kwargs: Arguments nommés
     |
     |      Returns:
     |          Clé de cache unique
     |
     |  get_from_disk_cache(cache_key: str) -> Optional[Any]
     |      Récupère une valeur du cache sur disque.
     |
     |      Args:
     |          cache_key: Clé de cache
     |
     |      Returns:
     |          Valeur mise en cache ou None si non trouvée ou expirée
     |
     |  get_from_memory_cache(cache_key: str) -> Optional[Any]
     |      Récupère une valeur du cache en mémoire.
     |
     |      Args:
     |          cache_key: Clé de cache
     |
     |      Returns:
     |          Valeur mise en cache ou None si non trouvée ou expirée
     |
     |  initialize(cache_dir: Optional[str] = None) -> None
     |      Initialise le gestionnaire de cache.
     |
     |      Args:
     |          cache_dir: Répertoire de cache sur disque (optionnel)
     |
     |  set_in_disk_cache(cache_key: str, value: Any, ttl: int = 86400) -> None
     |      Stocke une valeur dans le cache sur disque.
     |
     |      Args:
     |          cache_key: Clé de cache
     |          value: Valeur à mettre en cache
     |          ttl: Durée de vie en secondes (défaut: 24 heures)
     |
     |  set_in_memory_cache(cache_key: str, value: Any, ttl: int = 3600) -> None
     |      Stocke une valeur dans le cache en mémoire.
     |
     |      Args:
     |          cache_key: Clé de cache
     |          value: Valeur à mettre en cache
     |          ttl: Durée de vie en secondes (défaut: 1 heure)
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
     |  __annotations__ = {'_memory_cache': typing.Dict[str, typing.Dict[str, ...

FUNCTIONS
    cached(ttl_memory: int = 3600, ttl_disk: Optional[int] = 86400) -> Callable[[Callable[..., ~T]], Callable[..., ~T]]
        Décorateur pour mettre en cache les résultats d'une fonction.

        Args:
            ttl_memory: Durée de vie en mémoire en secondes (défaut: 1 heure)
            ttl_disk: Durée de vie sur disque en secondes (défaut: 24 heures, None pour désactiver)

        Returns:
            Fonction décorée

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

    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

    T = ~T
    parent_dir = r'D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1'

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\src\orchestrator\utils\cache_manager.py


