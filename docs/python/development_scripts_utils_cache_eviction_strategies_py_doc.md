Help on module eviction_strategies:

NAME
    eviction_strategies - Module de stratégies d'éviction pour le cache.

DESCRIPTION
    Ce module fournit différentes stratégies d'éviction pour le cache,
    permettant d'optimiser l'utilisation de la mémoire en supprimant les éléments
    selon différents critères (LRU, LFU, FIFO, etc.).

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    abc.ABC(builtins.object)
        EvictionStrategy
            CompositeStrategy
            FIFOStrategy
            LFUStrategy
            LRUStrategy
            SizeAwareStrategy
            TTLAwareStrategy

    class CompositeStrategy(EvictionStrategy)
     |  CompositeStrategy(strategies: Dict[eviction_strategies.EvictionStrategy, float])
     |
     |  Stratégie d'éviction composite.
     |
     |  Cette stratégie combine plusieurs stratégies d'éviction avec des poids différents.
     |
     |  Method resolution order:
     |      CompositeStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, strategies: Dict[eviction_strategies.EvictionStrategy, float])
     |      Initialise la stratégie composite.
     |
     |      Args:
     |          strategies (Dict[EvictionStrategy, float]): Dictionnaire des stratégies avec leurs poids.
     |              Les poids doivent être positifs et leur somme doit être égale à 1.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class EvictionStrategy(abc.ABC)
     |  Interface abstraite pour les stratégies d'éviction.
     |
     |  Cette classe définit l'interface commune à toutes les stratégies d'éviction.
     |
     |  Method resolution order:
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
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
     |  __abstractmethods__ = frozenset({'clear', 'get_eviction_candidates', '...

    class FIFOStrategy(EvictionStrategy)
     |  Stratégie d'éviction First In, First Out (FIFO).
     |
     |  Cette stratégie supprime les éléments les plus anciens.
     |
     |  Method resolution order:
     |      FIFOStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise la stratégie FIFO.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class LFUStrategy(EvictionStrategy)
     |  Stratégie d'éviction Least Frequently Used (LFU).
     |
     |  Cette stratégie supprime les éléments les moins fréquemment utilisés.
     |
     |  Method resolution order:
     |      LFUStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise la stratégie LFU.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class LRUStrategy(EvictionStrategy)
     |  Stratégie d'éviction Least Recently Used (LRU).
     |
     |  Cette stratégie supprime les éléments les moins récemment utilisés.
     |
     |  Method resolution order:
     |      LRUStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise la stratégie LRU.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class SizeAwareStrategy(EvictionStrategy)
     |  Stratégie d'éviction basée sur la taille des éléments.
     |
     |  Cette stratégie supprime les éléments les plus volumineux.
     |
     |  Method resolution order:
     |      SizeAwareStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise la stratégie basée sur la taille.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

    class TTLAwareStrategy(EvictionStrategy)
     |  Stratégie d'éviction basée sur la durée de vie (TTL) des éléments.
     |
     |  Cette stratégie supprime les éléments dont la durée de vie est la plus courte.
     |
     |  Method resolution order:
     |      TTLAwareStrategy
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialise la stratégie basée sur la durée de vie.
     |
     |  clear(self) -> None
     |      Vide la stratégie d'éviction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      Récupère les clés candidates à l'éviction.
     |
     |      Args:
     |          count (int, optional): Nombre de clés à récupérer. Par défaut: 1.
     |
     |      Returns:
     |          List[str]: Liste des clés candidates à l'éviction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un accès à une clé.
     |
     |      Args:
     |          key (str): Clé accédée.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une clé.
     |
     |      Args:
     |          key (str): Clé supprimée.
     |
     |  register_set(self, key: str, size: int = 1, ttl: Optional[int] = None) -> None
     |      Enregistre l'ajout ou la mise à jour d'une clé.
     |
     |      Args:
     |          key (str): Clé ajoutée ou mise à jour.
     |          size (int, optional): Taille de la valeur. Par défaut: 1.
     |          ttl (int, optional): Durée de vie en secondes. Par défaut: None.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from EvictionStrategy:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    create_eviction_strategy(strategy_name: str) -> eviction_strategies.EvictionStrategy
        Crée une stratégie d'éviction.

        Args:
            strategy_name (str): Nom de la stratégie d'éviction.
                Valeurs possibles: "lru", "lfu", "fifo", "size", "ttl", "composite".

        Returns:
            EvictionStrategy: Instance de la stratégie d'éviction.

        Raises:
            ValueError: Si le nom de la stratégie est invalide.

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

    logger = <Logger eviction_strategies (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\utils\cache\eviction_strategies.py


