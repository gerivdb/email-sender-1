Help on module runner:

NAME
    runner - Module d'exécution de benchmarks pour le système de cache.

DESCRIPTION
    Ce module fournit les fonctions nécessaires pour exécuter des benchmarks
    sur le système de cache et collecter des métriques de performance.

    Auteur: Augment Agent
    Date: 2025-04-17
    Version: 1.0

FUNCTIONS
    generate_key(dataset_size: int, distribution: str = 'uniform') -> str
        Génère une clé selon la distribution spécifiée.

        Args:
            dataset_size (int): Taille du jeu de données.
            distribution (str): Type de distribution ('uniform', 'zipf', 'sequential', 'normal').

        Returns:
            str: Clé générée.

    generate_value(size: int) -> str
        Génère une valeur de la taille spécifiée.

        Args:
            size (int): Taille de la valeur en octets.

        Returns:
            str: Valeur générée.

    measure_memory_usage() -> float
        Mesure l'utilisation de la mémoire du processus actuel.

        Returns:
            float: Utilisation de la mémoire en Mo.

    run_benchmark(cache, config: Dict[str, Any]) -> Dict[str, Any]
        Exécute un benchmark sur le cache selon la configuration spécifiée.

        Args:
            cache: Instance du cache à tester.
            config (Dict[str, Any]): Configuration du benchmark.

        Returns:
            Dict[str, Any]: Résultats du benchmark.

    select_operation(operation_mix: Dict[str, float]) -> str
        Sélectionne une opération selon le mélange spécifié.

        Args:
            operation_mix (Dict[str, float]): Mélange d'opérations (pourcentage de chaque type).

        Returns:
            str: Opération sélectionnée.

DATA
    BYTES_TO_MB = 1048576
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
    d:\do\web\n8n_tests\projets\email_sender_1\development\tools\cache-tools\benchmark\runner.py


