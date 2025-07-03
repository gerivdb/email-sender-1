Help on module percentile_preservation_metrics:

NAME
    percentile_preservation_metrics

DESCRIPTION
    Module implémentant des métriques de préservation des percentiles pour évaluer
    la qualité des histogrammes et des représentations de distributions.

    Ce module fournit des fonctions pour calculer différentes métriques qui mesurent
    à quel point les percentiles d'une distribution originale sont préservés dans
    une représentation simplifiée (comme un histogramme).

FUNCTIONS
    calculate_percentile_preservation_error(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentiles: List[float] = None, reconstruction_method: str = 'uniform') -> Dict[str, Any]
        Calcule l'erreur de préservation des percentiles entre les données originales
        et une représentation par histogramme.

        Args:
            original_data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentiles: Liste des percentiles à évaluer
            reconstruction_method: Méthode de reconstruction des données

        Returns:
            Dict[str, Any]: Métriques d'erreur de préservation des percentiles

    calculate_percentile_preservation_score(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentiles: List[float] = None, reconstruction_method: str = 'uniform', weights: Dict[str, float] = None) -> float
        Calcule un score global de préservation des percentiles entre 0 et 1.

        Args:
            original_data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentiles: Liste des percentiles à évaluer
            reconstruction_method: Méthode de reconstruction des données
            weights: Poids pour les différentes composantes du score

        Returns:
            float: Score de préservation des percentiles (0-1)

    calculate_percentile_weighted_error(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, percentile_weights: Dict[float, float] = None, reconstruction_method: str = 'uniform') -> Dict[str, Any]
        Calcule l'erreur de préservation des percentiles pondérée par l'importance
        de chaque percentile.

        Args:
            original_data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            percentile_weights: Poids pour chaque percentile
            reconstruction_method: Méthode de reconstruction des données

        Returns:
            Dict[str, Any]: Métriques d'erreur pondérée

    calculate_percentiles(data: numpy.ndarray, percentiles: List[float] = None) -> Dict[float, float]
        Calcule les percentiles spécifiés pour un ensemble de données.

        Args:
            data: Données d'entrée
            percentiles: Liste des percentiles à calculer (0-100)

        Returns:
            Dict[float, float]: Dictionnaire des percentiles {percentile: valeur}

    compare_binning_strategies_percentile_preservation(data: numpy.ndarray, strategies: List[str] = None, num_bins: int = 20, percentiles: List[float] = None) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes de préservation des percentiles.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes
            percentiles: Liste des percentiles à évaluer

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    evaluate_percentile_preservation_quality(score: float) -> str
        Évalue la qualité de préservation des percentiles en fonction du score.

        Args:
            score: Score de préservation des percentiles (0-1)

        Returns:
            str: Niveau de qualité

    find_optimal_bin_count_for_percentile_preservation(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5, percentiles: List[float] = None, target_score: float = 0.9) -> Dict[str, Any]
        Trouve le nombre optimal de bins pour préserver les percentiles.

        Args:
            data: Données originales
            strategy: Stratégie de binning
            min_bins: Nombre minimum de bins à tester
            max_bins: Nombre maximum de bins à tester
            step: Pas d'incrémentation du nombre de bins
            percentiles: Liste des percentiles à évaluer
            target_score: Score cible de préservation des percentiles

        Returns:
            Dict[str, Any]: Résultats de l'optimisation

    reconstruct_data_from_histogram(bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, method: str = 'uniform') -> numpy.ndarray
        Reconstruit un ensemble de données approximatif à partir d'un histogramme.

        Args:
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            method: Méthode de reconstruction ("uniform", "midpoint", "random")

        Returns:
            np.ndarray: Données reconstruites

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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\percentile_preservation_metrics.py


