Help on module optimized_algorithms:

NAME
    optimized_algorithms - Module d'algorithmes optimis�s pour le cache.

DESCRIPTION
    Ce module fournit des impl�mentations optimis�es des algorithmes
    utilis�s par le syst�me de cache pour am�liorer les performances.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

CLASSES
    typing.Generic(builtins.object)
        OptimizedARCache
        OptimizedLFUCache
        OptimizedLRUCache

    class OptimizedARCache(typing.Generic)
     |  OptimizedARCache(capacity: int)
     |
     |  Impl�mentation optimis�e d'un cache ARC (Adaptive Replacement Cache).
     |
     |  Cette classe impl�mente l'algorithme ARC qui combine les avantages
     |  des algorithmes LRU et LFU pour une meilleure performance.
     |
     |  Method resolution order:
     |      OptimizedARCache
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __contains__(self, key: str) -> bool
     |      V�rifie si une cl� existe dans le cache.
     |
     |  __init__(self, capacity: int)
     |      Initialise le cache ARC.
     |
     |      Args:
     |          capacity (int): Capacit� maximale du cache.
     |
     |  __len__(self) -> int
     |      Retourne le nombre d'�l�ments dans le cache.
     |
     |  clear(self) -> None
     |      Vide le cache.
     |
     |  get(self, key: str) -> Optional[~T]
     |      R�cup�re une valeur du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � r�cup�rer.
     |
     |      Returns:
     |          Optional[T]: Valeur associ�e � la cl� ou None si la cl� n'existe pas.
     |
     |  items(self) -> List[Tuple[str, ~T]]
     |      Retourne la liste des paires (cl�, valeur) dans le cache.
     |
     |  keys(self) -> List[str]
     |      Retourne la liste des cl�s dans le cache.
     |
     |  put(self, key: str, value: ~T) -> None
     |      Stocke une valeur dans le cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � stocker.
     |          value (T): Valeur de l'�l�ment � stocker.
     |
     |  remove(self, key: str) -> bool
     |      Supprime un �l�ment du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � supprimer.
     |
     |      Returns:
     |          bool: True si l'�l�ment a �t� supprim�, False sinon.
     |
     |  values(self) -> List[~T]
     |      Retourne la liste des valeurs dans le cache.
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
     |  __orig_bases__ = (typing.Generic[~T],)
     |
     |  __parameters__ = (~T,)
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Generic:
     |
     |  __class_getitem__(...)
     |      Parameterizes a generic class.
     |
     |      At least, parameterizing a generic class is the *main* thing this
     |      method does. For example, for some generic class `Foo`, this is called
     |      when we do `Foo[int]` - there, with `cls=Foo` and `params=int`.
     |
     |      However, note that this method is also called when defining generic
     |      classes in the first place with `class Foo[T]: ...`.
     |
     |  __init_subclass__(...)
     |      Function to initialize subclasses.

    class OptimizedLFUCache(typing.Generic)
     |  OptimizedLFUCache(capacity: int)
     |
     |  Impl�mentation optimis�e d'un cache LFU (Least Frequently Used).
     |
     |  Cette classe utilise une combinaison de dictionnaires et de listes
     |  pour une impl�mentation efficace de l'algorithme LFU.
     |
     |  Method resolution order:
     |      OptimizedLFUCache
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __contains__(self, key: str) -> bool
     |      V�rifie si une cl� existe dans le cache.
     |
     |  __init__(self, capacity: int)
     |      Initialise le cache LFU.
     |
     |      Args:
     |          capacity (int): Capacit� maximale du cache.
     |
     |  __len__(self) -> int
     |      Retourne le nombre d'�l�ments dans le cache.
     |
     |  clear(self) -> None
     |      Vide le cache.
     |
     |  get(self, key: str) -> Optional[~T]
     |      R�cup�re une valeur du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � r�cup�rer.
     |
     |      Returns:
     |          Optional[T]: Valeur associ�e � la cl� ou None si la cl� n'existe pas.
     |
     |  items(self) -> List[Tuple[str, ~T]]
     |      Retourne la liste des paires (cl�, valeur) dans le cache.
     |
     |  keys(self) -> List[str]
     |      Retourne la liste des cl�s dans le cache.
     |
     |  put(self, key: str, value: ~T) -> None
     |      Stocke une valeur dans le cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � stocker.
     |          value (T): Valeur de l'�l�ment � stocker.
     |
     |  remove(self, key: str) -> bool
     |      Supprime un �l�ment du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � supprimer.
     |
     |      Returns:
     |          bool: True si l'�l�ment a �t� supprim�, False sinon.
     |
     |  values(self) -> List[~T]
     |      Retourne la liste des valeurs dans le cache.
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
     |  __orig_bases__ = (typing.Generic[~T],)
     |
     |  __parameters__ = (~T,)
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Generic:
     |
     |  __class_getitem__(...)
     |      Parameterizes a generic class.
     |
     |      At least, parameterizing a generic class is the *main* thing this
     |      method does. For example, for some generic class `Foo`, this is called
     |      when we do `Foo[int]` - there, with `cls=Foo` and `params=int`.
     |
     |      However, note that this method is also called when defining generic
     |      classes in the first place with `class Foo[T]: ...`.
     |
     |  __init_subclass__(...)
     |      Function to initialize subclasses.

    class OptimizedLRUCache(typing.Generic)
     |  OptimizedLRUCache(capacity: int)
     |
     |  Impl�mentation optimis�e d'un cache LRU (Least Recently Used).
     |
     |  Cette classe utilise OrderedDict pour une impl�mentation efficace
     |  de l'algorithme LRU avec une complexit� O(1) pour les op�rations courantes.
     |
     |  Method resolution order:
     |      OptimizedLRUCache
     |      typing.Generic
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __contains__(self, key: str) -> bool
     |      V�rifie si une cl� existe dans le cache.
     |
     |  __init__(self, capacity: int)
     |      Initialise le cache LRU.
     |
     |      Args:
     |          capacity (int): Capacit� maximale du cache.
     |
     |  __len__(self) -> int
     |      Retourne le nombre d'�l�ments dans le cache.
     |
     |  clear(self) -> None
     |      Vide le cache.
     |
     |  get(self, key: str) -> Optional[~T]
     |      R�cup�re une valeur du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � r�cup�rer.
     |
     |      Returns:
     |          Optional[T]: Valeur associ�e � la cl� ou None si la cl� n'existe pas.
     |
     |  items(self) -> List[Tuple[str, ~T]]
     |      Retourne la liste des paires (cl�, valeur) dans le cache.
     |
     |  keys(self) -> List[str]
     |      Retourne la liste des cl�s dans le cache.
     |
     |  put(self, key: str, value: ~T) -> None
     |      Stocke une valeur dans le cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � stocker.
     |          value (T): Valeur de l'�l�ment � stocker.
     |
     |  remove(self, key: str) -> bool
     |      Supprime un �l�ment du cache.
     |
     |      Args:
     |          key (str): Cl� de l'�l�ment � supprimer.
     |
     |      Returns:
     |          bool: True si l'�l�ment a �t� supprim�, False sinon.
     |
     |  values(self) -> List[~T]
     |      Retourne la liste des valeurs dans le cache.
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
     |  __orig_bases__ = (typing.Generic[~T],)
     |
     |  __parameters__ = (~T,)
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from typing.Generic:
     |
     |  __class_getitem__(...)
     |      Parameterizes a generic class.
     |
     |      At least, parameterizing a generic class is the *main* thing this
     |      method does. For example, for some generic class `Foo`, this is called
     |      when we do `Foo[int]` - there, with `cls=Foo` and `params=int`.
     |
     |      However, note that this method is also called when defining generic
     |      classes in the first place with `class Foo[T]: ...`.
     |
     |  __init_subclass__(...)
     |      Function to initialize subclasses.

FUNCTIONS
    create_optimized_cache(algorithm: str, capacity: int) -> Union[optimized_algorithms.OptimizedLRUCache, optimized_algorithms.OptimizedLFUCache, optimized_algorithms.OptimizedARCache]
        Cr�e un cache optimis�.

        Args:
            algorithm (str): Algorithme � utiliser ('lru', 'lfu', 'arc').
            capacity (int): Capacit� du cache.

        Returns:
            Union[OptimizedLRUCache, OptimizedLFUCache, OptimizedARCache]: Cache optimis�.

        Raises:
            ValueError: Si l'algorithme est invalide.

    optimized_key_generator(prefix: str, *args, **kwargs) -> str
        G�n�re une cl� de cache optimis�e.

        Args:
            prefix (str): Pr�fixe de la cl�.
            *args: Arguments positionnels.
            **kwargs: Arguments nomm�s.

        Returns:
            str: Cl� de cache.

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

    T = ~T
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

    logger = <Logger optimized_algorithms (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\cache-tools\optimized_algorithms.py


