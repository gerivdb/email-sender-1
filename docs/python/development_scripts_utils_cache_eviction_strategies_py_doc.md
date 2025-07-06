Help on module eviction_strategies:

NAME
    eviction_strategies - Module de strat�gies d'�viction pour le cache.

DESCRIPTION
    Ce module fournit diff�rentes strat�gies d'�viction pour le cache,
    permettant d'optimiser l'utilisation de la m�moire en supprimant les �l�ments
    selon diff�rents crit�res (LRU, LFU, FIFO, etc.).

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
     |  Strat�gie d'�viction composite.
     |
     |  Cette strat�gie combine plusieurs strat�gies d'�viction avec des poids diff�rents.
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
     |      Initialise la strat�gie composite.
     |
     |      Args:
     |          strategies (Dict[EvictionStrategy, float]): Dictionnaire des strat�gies avec leurs poids.
     |              Les poids doivent �tre positifs et leur somme doit �tre �gale � 1.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Interface abstraite pour les strat�gies d'�viction.
     |
     |  Cette classe d�finit l'interface commune � toutes les strat�gies d'�viction.
     |
     |  Method resolution order:
     |      EvictionStrategy
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Strat�gie d'�viction First In, First Out (FIFO).
     |
     |  Cette strat�gie supprime les �l�ments les plus anciens.
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
     |      Initialise la strat�gie FIFO.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Strat�gie d'�viction Least Frequently Used (LFU).
     |
     |  Cette strat�gie supprime les �l�ments les moins fr�quemment utilis�s.
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
     |      Initialise la strat�gie LFU.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Strat�gie d'�viction Least Recently Used (LRU).
     |
     |  Cette strat�gie supprime les �l�ments les moins r�cemment utilis�s.
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
     |      Initialise la strat�gie LRU.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Strat�gie d'�viction bas�e sur la taille des �l�ments.
     |
     |  Cette strat�gie supprime les �l�ments les plus volumineux.
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
     |      Initialise la strat�gie bas�e sur la taille.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
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
     |  Strat�gie d'�viction bas�e sur la dur�e de vie (TTL) des �l�ments.
     |
     |  Cette strat�gie supprime les �l�ments dont la dur�e de vie est la plus courte.
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
     |      Initialise la strat�gie bas�e sur la dur�e de vie.
     |
     |  clear(self) -> None
     |      Vide la strat�gie d'�viction.
     |
     |  get_eviction_candidates(self, count: int = 1) -> List[str]
     |      R�cup�re les cl�s candidates � l'�viction.
     |
     |      Args:
     |          count (int, optional): Nombre de cl�s � r�cup�rer. Par d�faut: 1.
     |
     |      Returns:
     |          List[str]: Liste des cl�s candidates � l'�viction.
     |
     |  register_access(self, key: str) -> None
     |      Enregistre un acc�s � une cl�.
     |
     |      Args:
     |          key (str): Cl� acc�d�e.
     |
     |  register_delete(self, key: str) -> None
     |      Enregistre la suppression d'une cl�.
     |
     |      Args:
     |          key (str): Cl� supprim�e.
     |
     |  register_set(self, key: str, size: int = 1, ttl: Optional[int] = None) -> None
     |      Enregistre l'ajout ou la mise � jour d'une cl�.
     |
     |      Args:
     |          key (str): Cl� ajout�e ou mise � jour.
     |          size (int, optional): Taille de la valeur. Par d�faut: 1.
     |          ttl (int, optional): Dur�e de vie en secondes. Par d�faut: None.
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
        Cr�e une strat�gie d'�viction.

        Args:
            strategy_name (str): Nom de la strat�gie d'�viction.
                Valeurs possibles: "lru", "lfu", "fifo", "size", "ttl", "composite".

        Returns:
            EvictionStrategy: Instance de la strat�gie d'�viction.

        Raises:
            ValueError: Si le nom de la strat�gie est invalide.

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


