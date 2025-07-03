Help on module visual_saliency_metrics:

NAME
    visual_saliency_metrics

DESCRIPTION
    Module implémentant des métriques basées sur la saillance visuelle
    pour évaluer la fidélité perceptuelle des représentations de distributions.

    Ce module fournit des fonctions pour quantifier comment les caractéristiques
    importantes d'une distribution sont visuellement perceptibles dans sa représentation
    par histogramme ou autre visualisation.

FUNCTIONS
    calculate_contrast_map(histogram: numpy.ndarray, kernel_size: int = 5) -> numpy.ndarray
        Calcule une carte de contraste pour un histogramme.

        Le contraste est une mesure de la différence locale entre les valeurs de l'histogramme,
        qui est un facteur important de saillance visuelle.

        Args:
            histogram: Valeurs de l'histogramme
            kernel_size: Taille du noyau pour le calcul du contraste local

        Returns:
            np.ndarray: Carte de contraste

    calculate_curvature_map(histogram: numpy.ndarray) -> numpy.ndarray
        Calcule une carte de courbure pour un histogramme.

        La courbure (changements de direction) est un élément visuellement saillant.

        Args:
            histogram: Valeurs de l'histogramme

        Returns:
            np.ndarray: Carte de courbure

    calculate_edge_map(histogram: numpy.ndarray) -> numpy.ndarray
        Calcule une carte des bords pour un histogramme.

        Les bords (changements brusques) sont des éléments visuellement saillants.

        Args:
            histogram: Valeurs de l'histogramme

        Returns:
            np.ndarray: Carte des bords

    calculate_peak_map(histogram: numpy.ndarray, prominence_threshold: float = 0.1) -> numpy.ndarray
        Calcule une carte des pics pour un histogramme.

        Les pics sont des éléments visuellement saillants qui attirent l'attention.

        Args:
            histogram: Valeurs de l'histogramme
            prominence_threshold: Seuil de proéminence pour considérer un pic

        Returns:
            np.ndarray: Carte des pics

    calculate_saliency_map(histogram: numpy.ndarray, weights: Optional[Dict[str, float]] = None) -> numpy.ndarray
        Calcule une carte de saillance globale pour un histogramme en combinant
        différentes caractéristiques visuellement saillantes.

        Args:
            histogram: Valeurs de l'histogramme
            weights: Poids pour les différentes composantes de saillance

        Returns:
            np.ndarray: Carte de saillance globale

    calculate_saliency_preservation(original_histogram: numpy.ndarray, simplified_histogram: numpy.ndarray, weights: Optional[Dict[str, float]] = None) -> float
        Calcule le taux de préservation de la saillance visuelle entre un histogramme
        original et sa version simplifiée.

        Args:
            original_histogram: Histogramme original
            simplified_histogram: Histogramme simplifié
            weights: Poids pour les différentes composantes de saillance

        Returns:
            float: Taux de préservation de la saillance (0-1)

    calculate_saliency_score(histogram: numpy.ndarray, weights: Optional[Dict[str, float]] = None) -> float
        Calcule un score global de saillance pour un histogramme.

        Args:
            histogram: Valeurs de l'histogramme
            weights: Poids pour les différentes composantes de saillance

        Returns:
            float: Score de saillance (0-1)

    compare_binning_strategies_saliency(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, weights: Optional[Dict[str, float]] = None) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes de saillance visuelle.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes
            weights: Poids pour les différentes composantes de saillance

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    compare_histograms_saliency(original_histogram: numpy.ndarray, simplified_histogram: numpy.ndarray, weights: Optional[Dict[str, float]] = None) -> Dict[str, Any]
        Compare deux histogrammes en termes de saillance visuelle.

        Args:
            original_histogram: Histogramme original
            simplified_histogram: Histogramme simplifié
            weights: Poids pour les différentes composantes de saillance

        Returns:
            Dict[str, Any]: Résultats de la comparaison

    evaluate_saliency_quality(score: float) -> str
        Évalue la qualité de saillance visuelle en fonction du score.

        Args:
            score: Score de saillance (0-1)

        Returns:
            str: Niveau de qualité

    find_optimal_binning_strategy_saliency(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins_range: Optional[List[int]] = None, weights: Optional[Dict[str, float]] = None) -> Dict[str, Any]
        Trouve la stratégie de binning optimale en termes de saillance visuelle.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins_range: Liste des nombres de bins à tester
            weights: Poids pour les différentes composantes de saillance

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
    DEFAULT_KERNEL_SIZE = 5
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\visual_saliency_metrics.py


