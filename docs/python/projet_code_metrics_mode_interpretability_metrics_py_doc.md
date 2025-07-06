Help on module mode_interpretability_metrics:

NAME
    mode_interpretability_metrics

DESCRIPTION
    Module implémentant des métriques d'interprétabilité des modes
    pour évaluer la fidélité perceptuelle des représentations de distributions.

    Ce module fournit des fonctions pour quantifier la facilité avec laquelle
    un utilisateur peut identifier et comprendre les différents modes (pics)
    dans une distribution.

FUNCTIONS
    calculate_interpretability_score(clarity: float, distinctness: float, consistency: float = 1.0) -> float
        Calcule un score global d'interprétabilité des modes.

        Args:
            clarity: Score de clarté des modes
            distinctness: Score de distinctivité des modes
            consistency: Score de cohérence des modes (si applicable)

        Returns:
            float: Score global d'interprétabilité (0-1)

    calculate_mode_clarity(mode_info: Dict[str, Any]) -> float
        Calcule la clarté des modes, basée sur leur proéminence et leur séparation.

        Args:
            mode_info: Informations sur les modes détectés

        Returns:
            float: Score de clarté des modes (0-1)

    calculate_mode_consistency(original_mode_info: Dict[str, Any], simplified_mode_info: Dict[str, Any]) -> float
        Calcule la cohérence des modes entre une distribution originale et sa version simplifiée.

        Args:
            original_mode_info: Informations sur les modes de la distribution originale
            simplified_mode_info: Informations sur les modes de la distribution simplifiée

        Returns:
            float: Score de cohérence des modes (0-1)

    calculate_mode_distinctness(mode_info: Dict[str, Any]) -> float
        Calcule la distinctivité des modes, basée sur leur largeur relative.

        Args:
            mode_info: Informations sur les modes détectés

        Returns:
            float: Score de distinctivité des modes (0-1)

    compare_binning_strategies_interpretability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, prominence_threshold: float = 0.1) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes d'interprétabilité des modes.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes
            prominence_threshold: Seuil de proéminence pour la détection des modes

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    detect_modes(data: numpy.ndarray, bin_edges: Optional[numpy.ndarray] = None, bin_counts: Optional[numpy.ndarray] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        Détecte les modes (pics) dans une distribution.

        Args:
            data: Données brutes (utilisées si bin_counts est None)
            bin_edges: Limites des bins (utilisées si bin_counts est None)
            bin_counts: Valeurs de l'histogramme (si None, calculées à partir de data)
            prominence_threshold: Seuil de proéminence pour considérer un pic

        Returns:
            Dict[str, Any]: Informations sur les modes détectés

    evaluate_histogram_interpretability(data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, reference_mode_info: Optional[Dict[str, Any]] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        Évalue l'interprétabilité des modes d'un histogramme.

        Args:
            data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Valeurs de l'histogramme
            reference_mode_info: Informations sur les modes de référence (si disponible)
            prominence_threshold: Seuil de proéminence pour la détection des modes

        Returns:
            Dict[str, Any]: Résultats de l'évaluation

    evaluate_interpretability_quality(score: float) -> str
        Évalue la qualité d'interprétabilité des modes en fonction du score.

        Args:
            score: Score d'interprétabilité (0-1)

        Returns:
            str: Niveau de qualité

    find_optimal_binning_strategy_interpretability(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None, prominence_threshold: float = 0.1) -> Dict[str, Any]
        Trouve la stratégie de binning optimale en termes d'interprétabilité des modes.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins_range: Liste des nombres de bins à tester
            prominence_threshold: Seuil de proéminence pour la détection des modes

        Returns:
            Dict[str, Any]: Résultats de l'optimisation

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

    DEFAULT_EPSILON = 1e-10
    DEFAULT_PROMINENCE = 0.1
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\mode_interpretability_metrics.py


