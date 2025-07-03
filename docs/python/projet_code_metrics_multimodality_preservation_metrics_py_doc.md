Help on module multimodality_preservation_metrics:

NAME
    multimodality_preservation_metrics

DESCRIPTION
    Module implémentant des métriques de conservation de la multimodalité pour évaluer
    la qualité des histogrammes et des représentations de distributions.

    Ce module fournit des fonctions pour détecter les modes dans une distribution et
    mesurer à quel point ces modes sont préservés dans une représentation simplifiée.

FUNCTIONS
    calculate_mode_preservation(original_data: numpy.ndarray, reconstructed_data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1) -> Dict[str, Any]
        Calcule les métriques de préservation des modes entre les données originales
        et les données reconstruites.

        Args:
            original_data: Données originales
            reconstructed_data: Données reconstruites
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
            mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode

        Returns:
            Dict[str, Any]: Métriques de préservation des modes

    calculate_multimodality_preservation_score(original_data: numpy.ndarray, reconstructed_data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, weights: Optional[Dict[str, float]] = None) -> float
        Calcule un score global de préservation de la multimodalité entre 0 et 1.

        Args:
            original_data: Données originales
            reconstructed_data: Données reconstruites
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
            mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
            weights: Poids pour les différentes composantes du score

        Returns:
            float: Score de préservation de la multimodalité (0-1)

    compare_binning_strategies_multimodality_preservation(data: numpy.ndarray, strategies: Optional[List[str]] = None, num_bins: int = 20, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes de préservation de la multimodalité.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
            mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    detect_modes(data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, grid_points: int = 1000) -> Dict[str, Any]
        Détecte les modes dans une distribution en utilisant l'estimation par noyau
        de la densité (KDE) et la détection de pics.

        Args:
            data: Données d'entrée
            kde_bandwidth: Largeur de bande pour l'estimation KDE ('scott', 'silverman' ou valeur numérique)
            mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
            mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
            grid_points: Nombre de points pour la grille d'évaluation KDE

        Returns:
            Dict[str, Any]: Informations sur les modes détectés

    evaluate_multimodality_preservation_quality(score: float) -> str
        Évalue la qualité de préservation de la multimodalité en fonction du score.

        Args:
            score: Score de préservation de la multimodalité (0-1)

        Returns:
            str: Niveau de qualité

    find_optimal_bin_count_for_multimodality_preservation(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5, kde_bandwidth: Union[str, float] = 'scott', mode_prominence: float = 0.05, mode_width: float = 0.1, mode_height: float = 0.1, target_score: float = 0.9) -> Dict[str, Any]
        Trouve le nombre optimal de bins pour préserver la multimodalité.

        Args:
            data: Données originales
            strategy: Stratégie de binning
            min_bins: Nombre minimum de bins à tester
            max_bins: Nombre maximum de bins à tester
            step: Pas d'incrémentation du nombre de bins
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            mode_prominence: Proéminence minimale pour qu'un pic soit considéré comme un mode
            mode_width: Largeur minimale pour qu'un pic soit considéré comme un mode
            mode_height: Hauteur minimale pour qu'un pic soit considéré comme un mode
            target_score: Score cible de préservation de la multimodalité

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

    DEFAULT_KDE_BANDWIDTH = 'scott'
    DEFAULT_MODE_HEIGHT = 0.1
    DEFAULT_MODE_PROMINENCE = 0.05
    DEFAULT_MODE_WIDTH = 0.1
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

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\multimodality_preservation_metrics.py


