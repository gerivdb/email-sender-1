Help on module entropy_based_metrics:

NAME
    entropy_based_metrics

DESCRIPTION
    Module implémentant des métriques basées sur l'entropie pour évaluer
    la fidélité informationnelle des histogrammes et des représentations de distributions.

    Ce module fournit des fonctions pour calculer différentes métriques qui mesurent
    la quantité d'information préservée ou perdue lors de la représentation d'une
    distribution par un histogramme ou une autre approximation.

FUNCTIONS
    calculate_histogram_entropy(bin_counts: numpy.ndarray, base: float = 2.0) -> float
        Calcule l'entropie de Shannon d'un histogramme.

        Args:
            bin_counts: Comptage par bin de l'histogramme
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            float: Entropie de Shannon en unités correspondant à la base

    calculate_information_loss(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, base: float = 2.0) -> Dict[str, Any]
        Calcule la perte d'information lors de la représentation d'une distribution
        par un histogramme.

        Args:
            original_data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            Dict[str, Any]: Métriques de perte d'information

    calculate_information_preservation_score(original_data: numpy.ndarray, bin_edges: numpy.ndarray, bin_counts: numpy.ndarray, base: float = 2.0, weights: Dict[str, float] = None) -> float
        Calcule un score global de préservation de l'information entre 0 et 1.

        Args:
            original_data: Données originales
            bin_edges: Limites des bins de l'histogramme
            bin_counts: Comptage par bin de l'histogramme
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
            weights: Poids pour les différentes composantes du score

        Returns:
            float: Score de préservation de l'information (0-1)

    calculate_jensen_shannon_divergence(p: numpy.ndarray, q: numpy.ndarray, base: float = 2.0) -> float
        Calcule la divergence de Jensen-Shannon entre deux distributions discrètes.

        Args:
            p: Première distribution (doit sommer à 1)
            q: Deuxième distribution (doit sommer à 1)
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            float: Divergence JS en unités correspondant à la base

    calculate_kl_divergence(p: numpy.ndarray, q: numpy.ndarray, base: float = 2.0) -> float
        Calcule la divergence de Kullback-Leibler entre deux distributions discrètes.

        Args:
            p: Distribution de référence (doit sommer à 1)
            q: Distribution approximative (doit sommer à 1)
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            float: Divergence KL en unités correspondant à la base

    calculate_mutual_information(joint_distribution: numpy.ndarray, base: float = 2.0) -> float
        Calcule l'information mutuelle entre deux variables aléatoires discrètes.

        Args:
            joint_distribution: Distribution jointe P(X,Y) sous forme de matrice
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            float: Information mutuelle en unités correspondant à la base

    calculate_shannon_entropy(probabilities: numpy.ndarray, base: float = 2.0) -> float
        Calcule l'entropie de Shannon d'une distribution discrète.

        Args:
            probabilities: Probabilités de la distribution (doivent sommer à 1)
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            float: Entropie de Shannon en unités correspondant à la base

    compare_binning_strategies_information_preservation(data: numpy.ndarray, strategies: List[str] = None, num_bins: int = 20, base: float = 2.0) -> Dict[str, Dict[str, Any]]
        Compare différentes stratégies de binning en termes de préservation de l'information.

        Args:
            data: Données originales
            strategies: Liste des stratégies de binning à comparer
            num_bins: Nombre de bins pour les histogrammes
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)

        Returns:
            Dict[str, Dict[str, Any]]: Résultats de comparaison par stratégie

    estimate_continuous_kl_divergence(p_data: numpy.ndarray, q_data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', base: float = 2.0, num_samples: int = 1000) -> float
        Estime la divergence de Kullback-Leibler entre deux distributions continues.

        Args:
            p_data: Données de la distribution de référence
            q_data: Données de la distribution approximative
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
            num_samples: Nombre de points pour l'estimation numérique

        Returns:
            float: Divergence KL estimée

    estimate_differential_entropy(data: numpy.ndarray, kde_bandwidth: Union[str, float] = 'scott', base: float = 2.0, num_samples: int = 1000) -> float
        Estime l'entropie différentielle d'une distribution continue.

        Args:
            data: Données d'entrée
            kde_bandwidth: Largeur de bande pour l'estimation KDE
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
            num_samples: Nombre de points pour l'estimation numérique

        Returns:
            float: Entropie différentielle estimée

    evaluate_information_preservation_quality(score: float) -> str
        Évalue la qualité de préservation de l'information en fonction du score.

        Args:
            score: Score de préservation de l'information (0-1)

        Returns:
            str: Niveau de qualité

    find_optimal_bin_count_for_information_preservation(data: numpy.ndarray, strategy: str = 'uniform', min_bins: int = 5, max_bins: int = 100, step: int = 5, base: float = 2.0, target_score: float = 0.9) -> Dict[str, Any]
        Trouve le nombre optimal de bins pour préserver l'information.

        Args:
            data: Données originales
            strategy: Stratégie de binning
            min_bins: Nombre minimum de bins à tester
            max_bins: Nombre maximum de bins à tester
            step: Pas d'incrémentation du nombre de bins
            base: Base du logarithme (2 pour bits, e pour nats, 10 pour dits)
            target_score: Score cible de préservation de l'information

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

    DEFAULT_BIN_METHOD = 'auto'
    DEFAULT_EPSILON = 1e-10
    DEFAULT_KDE_BANDWIDTH = 'scott'
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
    d:\do\web\n8n_tests\projets\email_sender_1\projet\code\metrics\entropy_based_metrics.py


